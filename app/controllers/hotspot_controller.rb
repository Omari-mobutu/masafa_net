# app/controllers/hotspot_controller.rb
class HotspotController < ApplicationController
  # Assume this is the landing page after MikroTik redirect
  # e.g., accessible via /hotspot/login or root_path
  def new
    # Capture params from MikroTik
    @client_mac = params[:mac] || session[:client_mac]
    @client_ip = params[:ip] || session[:client_ip]
    @link_login = params[:"link-login"] || session[:link_login] # Essential for final redirect back to MikroTik
    @gift = GiftedSubscription.find_by(mac_address: params[:mac], redeemed_at: nil)


    # Store essential MikroTik context in the session
    # This associates the current browser session with the device
    session[:client_mac] = @client_mac
    session[:client_ip] = @client_ip
    session[:link_login] = @link_login


    # Basic validation for essential params
    unless @client_mac.present? && @client_ip.present? && @link_login.present?
      flash[:alert] = "Missing essential client information. Please try connecting again."
      # Render an error page or redirect to a general info page
      return render plain: "Error: Missing client data", status: :bad_request
    end

    # re-authenticate the user back to his sessions
    active_session = active_session_for_mac(@client_mac)
    if active_session
      # Re-authenticate the user immediately
      flash.now[:notice] = "Welcome back! Your session is still active."
      redirect_to build_mikrotik_login_url(active_session), allow_other_host: true, status: :see_other
    end

    if @gift
     redirect_to gift_hotspot_index_path
    end

    # Fetch available subscriptions from your Rails DB
    @subscriptions = Subscription.all.order(:price)

    # Render the view where the user chooses a subscription and enters phone number
  end

  def gift
    @client_mac = session[:client_mac]
    @client_ip = session[:client_ip]
    @link_login = session[:link_login]

    @gift = GiftedSubscription.find_by(mac_address: @client_mac, redeemed_at: nil)
  end

  # the logic for user to reem their gifts
  def redeem_gift
    @client_mac = session[:client_mac]
    @client_ip = session[:client_ip]
    @link_login = session[:link_login]

    @gift = GiftedSubscription.find_by(mac_address: @client_mac, redeemed_at: nil)

    if @gift
      # 2. Update the gift record to prevent future use
      # @gift.update(redeemed_at: Time.current)
      UpdateGiftRedemptionJob.set(wait: 5.seconds).perform_later(@gift.id)

      # 3. Redirect the user to log in
      puts @gift.username
      puts @gift.password
      # This URL should be the redirect URL provided by your Radius server upon successful login
      redirect_to build_mikrotik_gift_login_url(@gift.username, @gift.password, @link_login), allow_other_host: true, status: :see_other
    else
      redirect_to hotspot_new_path, alert: "This gift has already been redeemed or is invalid."
    end
  end

  # This action handles the form submission where the user selects a subscription
  # and provides their phone number.
  def choose_subscription
    @client_mac = session[:client_mac]
    @client_ip = session[:client_ip]
    @link_login = session[:link_login]

    unless @client_mac.present? && @client_ip.present? && @link_login.present?
      flash[:alert] = "Session expired or invalid context. Please restart the process."
      return redirect_to hotspot_new_path # Redirect back to start
    end

    @chosen_subscription = Subscription.find_by(id: hotspot_params[:subscription_id])
    @phone_number = hotspot_params[:phone_number]

    unless @chosen_subscription && @phone_number.present?
      flash[:alert] = "Please select a subscription and enter your phone number."
      # Re-render the login page with errors, or redirect back
      @subscriptions = Subscription.all.order(:price)
      return render :new, status: :unprocessable_entity
    end

    # --- Phone Number Format Validation ---
    # Define the regex pattern for Kenyan M-Pesa numbers starting with 07 or 01
    phone_number_regex = /\A0[71][0-9]{8}\z/

    unless @phone_number =~ phone_number_regex
      flash[:alert] = "Invalid phone number format. Please enter a valid M-Pesa number (e.g., 07XXXXXXXX or 01XXXXXXXX)."
      @subscriptions = Subscription.all.order(:price) # Re-fetch for re-render
      return render :new, status: :unprocessable_entity
    end

    # --- Initiate M-Pesa Payment ---
    # You'll call your M-Pesa service here. This service will:
    # 1. Store a pending payment record in your `payment_transactions` table
    #    (linking `client_mac`, `client_ip`, `chosen_subscription.id`, `phone_number`).
    # 2. Call the M-Pesa Daraja API for STK Push.
    # 3. Store `mpesa_checkout_request_id` etc. for the callback.
    # 4. Respond to the user (e.g., "Check your phone for MPesa prompt").
    # puts payment_params

    @payment = Mpesa.new(@phone_number, @chosen_subscription.name, @chosen_subscription.price, @chosen_subscription.id, @client_mac, @client_ip, @link_login)
    puts @payment.values
    @push = @payment.push

    if @push [:success]
      transaction = PaymentTransaction.create!(
      subscription_id: @chosen_subscription.id,
      phone_number: @phone_number,
      amount: @chosen_subscription.price,
      client_mac: @client_mac,
      client_ip: @client_ip,
      link_login: @link_login,
      status: :pending,
      subscription_name: @chosen_subscription.name,
      mpesa_checkout_request_id: @push[:checkout_request_id],
      mpesa_merchant_request_id: @push[:merchant_request_id]
      )
      flash[:notice] = @push[:message] || "M-Pesa payment initiated. Please approve the prompt on your phone."
      # Redirect to a "waiting for payment" page, or back to login with a message
      redirect_to hotspot_waiting_path(transaction_id: transaction.id)
    else
      flash[:alert] = @push[:message] || "Failed to initiate M-Pesa payment. Please try again."
      @subscriptions = Subscription.all.order(:price) # Re-fetch for re-render
      render :new, status: :unprocessable_entity
    end
  end

  def waiting
    @transaction = PaymentTransaction.find(params[:transaction_id])
    unless @transaction
      flash[:alert] = "Invalid payment transaction."
      redirect_to hotspot_new_path
    end
    # Render a page that tells user to wait for payment confirmation
    # You might use JavaScript here to poll your server for payment status
    # or rely purely on the M-Pesa callback.
    # # Check status. If successful, prepare for redirect
    if @transaction.successful? && @transaction.username.present?
      # record which form was used for user
      field_test_converted("subscription_form")
      # If payment and provisioning are done, redirect immediately
      # This might happen if the callback was super fast or on a refresh
      UpdatePaymentTransactionPostAuthStatusJob.set(wait: 12.seconds).perform_later(@transaction.id)
      Rails.logger.info "Enqueued UpdatePaymentTransactionPostAuthStatusJob for #{ @transaction.id } with 12-seconds delay."
      # Redirect user to the hotspot authentication page
      # Pass the generated username/password to MikroTik's login URL
      redirect_to build_mikrotik_login_url(@transaction), allow_other_host: true, status: :see_other
      # redirect_to initiate_login_url(transaction_id: @transaction.id)
    end
  end

  def initiate_login
    @transaction = PaymentTransaction.find(params[:transaction_id])
    username = @transaction.username # Or retrieve from session/current_user

    # Assuming the password generation and radcheck/radusergroup insertion
    # happens BEFORE this action, or in a background job that completes quickly.
    # If it happens here, ensure it's completed before rendering.

    @username = username
    # You might also want to pass other info to the view, like hotspot URL
    @hotspot_login_url = @transaction.link_login.split("?").first # Replace with your MikroTik Hotspot login URL

    # Render a view that contains the button
    render "initiate_login"
  end

  def payment_status
    @transaction = PaymentTransaction.find_by(id: params[:transaction_id])

    if @transaction && @transaction.successful? && @transaction.username.present?
      # If payment is successful, send a Turbo Stream redirect
      # This will replace the content of 'redirection_target' with a script that redirects
      # puts build_mikrotik_login_url(@transaction)
      # render turbo_stream: turbo_stream.replace("redirection_target", partial: "hotspot/redirect_script", locals: { url: build_mikrotik_login_url(@transaction) })

      # Instead of rendering a partial with JS for external redirect,
      # render a Turbo Stream action that triggers a full page visit to the 'waiting' action.
      # render turbo_stream: turbo_stream.action(:turbo_visit, url: hotspot_waiting_path(transaction_id: @transaction.id))
      render turbo_stream: turbo_stream.replace("redirection_target", partial: "hotspot/redirect_script", locals: { url: hotspot_waiting_path(transaction_id: @transaction.id) })


      # Or, if you want the whole page to redirect directly, you can use:
      # redirect_to build_mikrotik_login_url(@transaction), status: :see_other # or :found, :temporary_redirect
    elsif @transaction && @transaction.failed?
      render turbo_stream: turbo_stream.replace("redirection_target", partial: "hotspot/redirect_script",
        locals: { url: hotspot_new_path(flash_alert: @transaction.mpesa_error_message) }
      )

    else
      # Still pending or failed, render an empty frame or just status text
      render turbo_stream: turbo_stream.update("payment_status", "<p class='text-blue-500'>Still pending please wait...</p>")
    end
  end


  private

  def build_mikrotik_login_url(transaction)
    # MikroTik's login URL (e.g., http://192.168.88.1/login)
    link_login_base = transaction.link_login.split("?").first # Get base URL if it had extra params
    puts "the redirection link is:: #{link_login_base}"
    puts Radprofile::GetPassword.new(transaction.username).call

    # Construct the final login URL with username/password
    # This is highly dependent on your MikroTik's Hotspot login setup.
    # It might be `login?username=...&password=...` or `login?mk_username=...`
    # Common is to POST to it, but you can sometimes GET with params for auto-login.
    # For auto-login from your app, this is common:
    "#{link_login_base}?username=#{URI.encode_www_form_component(transaction.username)}&password=#{URI.encode_www_form_component(Radprofile::GetPassword.new(transaction.username).call)}&dst=#{URI.encode_www_form_component(transaction.link_login.split('dst=')[1])}" # Pass original destination back
    ### &dst=#{URI.encode_www_form_component(transaction.link_login.split('dst=')[1])} the dst removed on the redirecting

    # If using /login?chap-id=... /login?chap-challenge=...
    # you might need to auto-submit a form via JS, or direct user to log in manually.
    # The simplest is if MikroTik accepts username/password directly in query params for auto-login.
  end

  def build_mikrotik_gift_login_url(username, password, link_login)
    link_login_base = link_login.split("?").first

    puts "the redirection link is:: #{link_login_base}"
    puts Radprofile::GetPassword.new(username).call
    "#{link_login_base}?username=#{URI.encode_www_form_component(username)}&password=#{URI.encode_www_form_component(Radprofile::GetPassword.new(username).call)}&dst=#{URI.encode_www_form_component(link_login.split('dst=')[1])}"
  end

  def active_session_for_mac(mac_address)
    PaymentTransaction
      .where(post_auth_status: "success", client_mac: mac_address)
      .where("expected_stop_time > ?", Time.current)
      .order(expected_stop_time: :desc)
      .first
  end

  def hotspot_params
    params.require(:hotspot).permit(:subscription_id, :phone_number)
  end
end
