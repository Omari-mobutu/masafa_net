
# app/services/concerns/mpesa_utils.rb
module MpesaUtils
  extend ActiveSupport::Concern

  class_methods do
    def generate_timestamp
      Time.now.strftime("%Y%m%d%H%M%S").to_i
    end


    # Utility method for phone number formatting if needed
    def format_phone_number(phone_number)
      phone_number.sub(/\A0/, "254") # Converts 07... or 01... to 2547... or 2541...
    end
  end
end
