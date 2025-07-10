# app/controllers/hotspot_controller.rb
class HotspotController < ApplicationController
  # Assume this is the landing page after MikroTik redirect
  # e.g., accessible via /hotspot/login or root_path
  def new
    # Capture params from MikroTik
    @client_mac = params[:mac] || session[:client_mac]
    @client_ip = params[:ip] || session[:client_ip]
    @link_login = params[:"link-login"] || session[:link_login] # Essential for final redirect back to MikroTik


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



    # Fetch available subscriptions from your Rails DB
    @subscriptions = Subscription.all.order(:price)

    # Render the view where the user chooses a subscription and enters phone number
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
      # If payment and provisioning are done, redirect immediately
      # This might happen if the callback was super fast or on a refresh
      # Pass the generated username/password to MikroTik's login URL
      redirect_to build_mikrotik_login_url(@transaction), allow_other_host: true, status: :see_other
      nil
    end
  end

  # def payment_status
  #  @transaction = PaymentTransaction.find_by(id: params[:transaction_id])

  #  if @transaction && @transaction.successful? && @transaction.username.present?
  # If payment is successful, send a Turbo Stream redirect
  # This will replace the content of 'redirection_target' with a script that redirects
  #    render turbo_stream: turbo_stream.replace("redirection_target", partial: "hotspot/redirect_script", locals: { url: #build_mikrotik_login_url(@transaction) })

  #     puts build_mikrotik_login_url(@transaction)
  # Or, if you want the whole page to redirect directly, you can use:
  # redirect_to build_mikrotik_login_url(@transaction), status: :see_other # or :found, :temporary_redirect
  #  else
  # Still pending or failed, render an empty frame or just status text
  #    render turbo_stream: turbo_stream.update("payment_status", "<p class='text-blue-500'>Still pending ayee...</p>")
  #  end
  # end

  def payment_status
    @transaction = PaymentTransaction.find_by(id: params[:transaction_id])

    # Initialize default values for the JSON response
    status = "pending"
    message = "Please check your phone for the M-Pesa prompt and approve the payment."
    is_redirect_ready = false
    redirect_url = nil

    if @transaction
      if @transaction.successful? && @transaction.username.present?
        status = "completed"
        message = "Payment successful! Internet access granted. Redirecting you now..."
        is_redirect_ready = true

        # IMPORTANT: Build the Mikrotik login URL here.
        # This is the URL that the *client's browser* will be redirected to
        # after your Rails app confirms payment.
        # Ensure build_mikrotik_login_url(@transaction) returns a full, absolute URL.
        # For a Mikrotik hotspot, this would typically be the router's login URL
        # with username/password, or a simple success page.
        # As discussed, consider where you *really* want the user to end up.
        # If your 'dst' logic in Mikrotik is good, sometimes a simple success page
        # from your Rails app is enough, and Mikrotik handles the final 'dst' redirect.
        # But if your app needs to drive the post-payment login, this URL is key.

        # Example assuming build_mikrotik_login_url provides the correct path:
        redirect_url = build_mikrotik_login_url(@transaction)

        # Log the URL for debugging purposes (optional)
        puts "Redirect URL generated: #{redirect_url}"

      elsif @transaction.failed?
        status = "failed"
        message = "Payment failed. Please try again."
        # You might add logic here to provide a link back to the payment initiation page
      else
        # Still pending or other non-successful status
        status = "pending"
        message = "Waiting for M-Pesa confirmation please enter you mpesa PIN..."
      end
    else
      # Transaction not found
      status = "error"
      message = "Transaction not found. Please contact support."
    end


    respond_to do |format|
      format.json {
        render json: {
          status: status,
          message: message,
          is_redirect_ready: is_redirect_ready,
          redirect_url: redirect_url
        }
      }
      # REMOVE or comment out any 'format.turbo_stream' blocks for this action
      # format.turbo_stream { ... (your old turbo stream logic) ... }
    end
end


  private

  def build_mikrotik_login_url(transaction)
    # MikroTik's login URL (e.g., http://192.168.88.1/login)
    link_login_base = transaction.link_login.split("?").first # Get base URL if it had extra params
    puts "the lick to redirect #{link_login_base}"
    puts Radprofile::GetPassword.new(transaction.username).call

    # Construct the final login URL with username/password
    # This is highly dependent on your MikroTik's Hotspot login setup.
    # It might be `login?username=...&password=...` or `login?mk_username=...`
    # Common is to POST to it, but you can sometimes GET with params for auto-login.
    # For auto-login from your app, this is common:
    "#{link_login_base}?username=#{URI.encode_www_form_component(transaction.username)}&password=#{URI.encode_www_form_component(Radprofile::GetPassword.new(transaction.username).call)}" # Pass original destination back
    ### &dst=#{URI.encode_www_form_component(transaction.link_login.split('dst=')[1])} the dst removed on the redirecting link

    # If using /login?chap-id=... /login?chap-challenge=...
    # you might need to auto-submit a form via JS, or direct user to log in manually.
    # The simplest is if MikroTik accepts username/password directly in query params for auto-login.
  end

  def hotspot_params
    params.require(:hotspot).permit(:subscription_id, :phone_number)
  end
end
