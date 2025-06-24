class Mpesa
  #the model without database to deal with Mpewsa payment ssytems that is:
  # STK push, status check, and even remitting out to other business
  # therefore the various parts will be broken to concers
  include Constants, Values
  require 'ostruct'
  require 'base64'
  require 'openssl'
  require 'httparty'

  #@token = Mpesa::Authorization.new(@api_key, @consumer_secret).call

  def push
    @token = Mpesa::Authorization.new(@consumer_key, @consumer_secret).call
    @response = Mpesa::StkPush.new().call(values, @token)
  end


end