# app/controllers/hotspot_controller.rb
class HotspotController < ApplicationController
  # Assume this is the landing page after MikroTik redirect
  # e.g., accessible via /hotspot/login or root_path
  def new
    # Capture params from MikroTik
    @client_mac = params[:mac]
    @client_ip = params[:ip]
    @link_login = params[:"link-login"] # Essential for final redirect back to MikroTik

    # Basic validation for essential params
    unless @client_mac.present? && @client_ip.present? && @link_login.present?
      flash[:alert] = "Missing essential client information. Please try connecting again."
      # Render an error page or redirect to a general info page
      return render plain: "Error: Missing client data", status: :bad_request
    end

    # Generate or retrieve JWT for this "session"
    # This token carries the client_mac, client_ip, link_login
    # (or a session_id that can retrieve them from your DB if you prefer server-side state)
    @auth_token = generate_auth_token(@client_mac, @client_ip, @link_login)

    cookies[:auth_token] = {
          value: @auth_token,
          httponly: true,
          secure: Rails.env.production?, # Use true in production!
          expires: 30.minutes.from_now
          # samesite: 'Lax' # Consider adding SameSite for CSRF protection
        }

    puts @auth_token

    # Fetch available subscriptions from your Rails DB
    @subscriptions = Subscription.all.order(:price)

    # Render the view where the user chooses a subscription and enters phone number
  end

  # This action handles the form submission where the user selects a subscription
  # and provides their phone number.
  def choose_subscription
    # Validate auth_token from params or cookie (securely)
    puts params[:auth_token]
    token_data = decode_auth_token(cookies[:auth_token])
    puts "this is the token data #{token_data}"
    unless token_data && token_data[:mac] == hotspot_params[:mac] # Basic check
      flash[:alert] = "Invalid session. Please try again."
      return redirect_to hotspot_new_path # Redirect back to start
    end

    @chosen_subscription = Subscription.find_by(id: hotspot_params[:subscription_id])
    @phone_number = hotspot_params[:phone_number]
    @client_mac = token_data[:mac] # From token
    @client_ip = token_data[:ip]   # From token
    @link_login = token_data[:link_login] # From token

    unless @chosen_subscription && @phone_number.present?
      flash[:alert] = "Please select a subscription and enter your phone number."
      # Re-render the login page with errors, or redirect back
      @subscriptions = Subscription.all.order(:price)
      return render :login, status: :unprocessable_entity
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
      flash[:notice] = payment_service_response[:message] || "M-Pesa payment initiated. Please approve the prompt on your phone."
      # Redirect to a "waiting for payment" page, or back to login with a message
      redirect_to hotspot_waiting_path(transaction_id: @push[:transaction_id])
    else
      flash[:alert] = payment_service_response[:message] || "Failed to initiate M-Pesa payment. Please try again."
      @subscriptions = Subscription.all.order(:price) # Re-fetch for re-render
      render :login, status: :unprocessable_entity
    end
  end

  def waiting
    @transaction = PaymentTransaction.find_by(id: params[:transaction_id])
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
    params.permit(:mac, :ip, :"link-login", :auth_token, :subscription_id, :phone_number)
  end

  def generate_auth_token(mac, ip, link_login)
    payload = { mac: mac, ip: ip, link_login: link_login, exp: 30.minutes.from_now.to_i }
    JWT.encode(payload, Rails.application.credentials.jwt_secret_key, "HS256")
  end

  def decode_auth_token(token)
    secret_key = Rails.application.credentials.jwt_secret_keys
    JWT.decode(token, secret_key, true, algorithm: "HS256")
    # JWT.decode(token, Rails.application.credentials.jwt_secret_key, true, algorithm: "HS256")[0].with_indifferent_access
  rescue JWT::DecodeError
    nil
  end

  def clear_tenant_token
    cookies.delete(:auth_token)
  end
end
