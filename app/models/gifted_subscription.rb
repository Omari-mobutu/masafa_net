class GiftedSubscription < ApplicationRecord
  # A regex for MAC address format (e.g., 00:11:22:33:44:55)
  MAC_ADDRESS_REGEX = /\A([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}\z/

  # Validations to ensure all necessary data is present and correctly formatted
  validates :mac_address, presence: true, format: { with: MAC_ADDRESS_REGEX, message: "must be in a valid format (e.g., 00:11:22:33:44:55)" }
  validates :package_name, presence: true
  validates :username, presence: true, uniqueness: true # Username should be unique
  validates :password, presence: true

  # The `redeemed_at` field from before still serves its purpose
  # to ensure a gift is only used once.
end
