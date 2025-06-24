class PaymentCallback < ApplicationRecord
  enum :status, { pending: "pending", successful: "successful", failed: "failed", cancelled: "cancelled" }
end
