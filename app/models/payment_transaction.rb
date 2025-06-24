class PaymentTransaction < ApplicationRecord
  belongs_to :subscription

  enum :status, { pending: "pending", successful: "successful", failed: "failed", cancelled: "cancelled" }

  validates :phone_number, :amount, :client_mac, :client_ip, :link_login, :status, :subscription_name, presence: true
  validates :mpesa_checkout_request_id, uniqueness: true, allow_nil: true

  # Encrypt password, or ensure it's handled securely
  # In a real app, you might use an attr_accessor for password and then generate digest only for storage
end
