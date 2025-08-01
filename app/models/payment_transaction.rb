class PaymentTransaction < ApplicationRecord
  belongs_to :subscription

  enum :status, { pending: "pending", successful: "successful", failed: "failed", cancelled: "cancelled" }

  validates :phone_number, :amount, :client_mac, :client_ip, :link_login, :status, :subscription_name, presence: true
  validates :mpesa_checkout_request_id, uniqueness: true, allow_nil: true

  # Encrypt password, or ensure it's handled securely
  # In a real app, you might use an attr_accessor for password and then generate digest only for storage
  def mpesa_error_message
    case mpesa_result_code
    when 1037
      "Your M-Pesa prompt timed out or your phone was unreachable. Please ensure your phone is online and try again."
    when 1025, 9999
      "A system error occurred during the M-Pesa push. Please try again in a few moments."
    when 1032
      "The M-Pesa payment was cancelled or timed out on your phone. Please try again and approve the prompt."
    when 1
      "Insufficient M-Pesa balance. Please deposit funds or use Fuliza if prompted, then try again."
    when 2001
      "Invalid M-Pesa PIN. Please ensure you enter the correct PIN when prompted."
    when 1019
      "The M-Pesa transaction expired before it could be processed. Please try again."
    when 1001
      "You have an ongoing M-Pesa transaction or USSD session. Please complete or close it, then try again in 2-3 minutes."
    when 0
      "Payment successful, awaiting authentication." # Should not trigger failed? but good for completeness
    else
      "An unexpected error occurred with your M-Pesa payment (Code: #{mpesa_result_code}). Please try again or contact support."
    end
  end
end
