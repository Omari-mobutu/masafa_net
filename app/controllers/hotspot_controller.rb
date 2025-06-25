# app/controllers/hotspot_controller.rb
class HotspotController < ApplicationController
  # Assume this is the landing page after MikroTik redirect
  # e.g., accessible via /hotspot/login or root_path
  def new
    # Capture params from MikroTik
    @client_mac = params[:mac]
    @client_ip = params[:ip]
    @link_login = params[:"link-login"] # Essential for final redirect back to MikroTik


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
  end


  private

  def hotspot_params
    params.require(:hotspot).permit(:subscription_id, :phone_number)
  end
end
