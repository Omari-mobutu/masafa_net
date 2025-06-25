class PaymentJob < ApplicationJob
  queue_as :default

  def perform(payment)
    # Do something later
    payment_payload = JSON.parse(payment.data, symbolize_names: true)
    Rails.logger.info "M-Pesa Callback Received: #{payment_payload.inspect}"


    result_code = payment_payload.dig(:Body, :stkCallback, :ResultCode)
    checkout_request_id = payment_payload.dig(:Body, :stkCallback, :CheckoutRequestID)

    @transaction = PaymentTransaction.find_by(mpesa_checkout_request_id: checkout_request_id)
    # return unless transaction.present?
    unless @transaction
      Rails.logger.warn "M-Pesa Callback: Transaction not found for CheckoutRequestID: #{checkout_request_id}"
      return
    end


    if result_code == 0 # Payment Successful
      @transaction.successful! # Update status to successful
      @transaction.update!(payment_details: payment_payload)

      # --- CRITICAL: Create RADIUS User & Provision Access ---
      subscription_plan = @transaction.subscription.freeradius_group_name
      generated_username = "user_#{SecureRandom.alphanumeric(8).downcase}"
      generated_password = SecureRandom.base64(12) # Strong random password
      puts generated_password
      puts subscription_plan

      if Radprofile::CreateUser.call(
         generated_username,
         generated_password, # Pass plain for hashing in service
        subscription_plan
      )
        @transaction.update!(username: generated_username, password_digest: Digest::SHA256.hexdigest(generated_password))# Store a simple hash for internal record

        Rails.logger.info "RADIUS user #{generated_username} created for transaction #{@transaction.id}."

        # No direct redirection from callback, this just confirms to M-Pesa
        # render json: { "ResultCode" => 0, "ResultDesc" => "Success" }, status: :ok

        # This is where you might trigger a "login completion" for the client.
        # This is asynchronous. The client on the `hotspot/waiting` page
        # might need to poll your server or be redirected.
        # More advanced: Push notification via WebSockets or long polling
        # to the client on the waiting page to trigger the auto-login.
        # For a simple flow, the client just re-submits the form or clicks a button.
      else
        @transaction.update!(status: :failed)
        Rails.logger.error "Failed to create RADIUS user for transaction #{@transaction.id}. Check logs."
        # render json: { "ResultCode" => 1, "ResultDesc" => "Internal error" }, status: :ok
      end
    else # Payment Failed or Cancelled
      @transaction.update!(status: :failed, payment_details: payment_payload)
      Rails.logger.warn "M-Pesa Callback: Payment failed/cancelled for CheckoutRequestID: #{checkout_request_id}. ResultCode: #{result_code}"

    end

    rescue JSON::ParserError => e
    Rails.logger.error "M-Pesa Callback: Invalid JSON payload: #{e.message}"
    # render json: { "ResultCode" => 1, "ResultDesc" => "Invalid payload" }, status: :bad_request

    rescue StandardError => e
      Rails.logger.error "M-Pesa Callback unexpected error: #{e.message}"
    # render json: { "ResultCode" => 1, "ResultDesc" => "Server error" }, status: :internal_server_error
  end
end
