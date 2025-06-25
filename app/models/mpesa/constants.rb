module Mpesa::Constants
  extend ActiveSupport::Concern
  def initialize(phone_number, account_name, amount, subscription_id, client_mac, client_ip, link_login)
    @CallBackURL = Rails.configuration.mpesa[:callback_url]
    puts amount

    @paybill =  Rails.configuration.mpesa[:short_code]
    @api_key = Rails.configuration.mpesa[:api_key]
    @consumer_secret = Rails.configuration.mpesa[:consumer_secret]
    @consumer_key = Rails.configuration.mpesa[:consumer_key]
    @amount = amount.truncate()
    @phone = phone_number.tap { |k| k[0] = "254" }
    @order = account_name
    @client_mac = client_mac
    @client_ip = client_ip
    @link_login = link_login
    @subscription_id = subscription_id
  end
end
