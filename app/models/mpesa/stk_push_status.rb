class Mpesa::StkPushStatus
  API_URL = Rails.configuration.mpesa[:api_query_url]

  def initialize(api_key,consumer_key, consumer_secret, checkout_request_id, short_code)
    @api_key= api_key
    @pass_key = consumer_key
    @consumer_secret= consumer_secret
    @checkout_request_id = checkout_request_id
    @paybill = short_code
    @token = Mpesa::Authorization.new(@api_key, @consumer_secret).call
  end

  def call


    puts "the happens to be the log #{@token}"

    response = request(:post)
    puts values.to_json
    puts headers.to_json
    parsed_body = JSON.parse(response.read_body)
    puts parsed_body

    if parsed_body.key?("errorCode")
      error = OpenStruct.new(
        error_code: parsed_body["errorCode"],
        error_message: parsed_body["errorMessage"],
        request_id: parsed_body["requestId"]
      )
      OpenStruct.new(result: nil, error: error)
    else
      result = OpenStruct.new(
        merchant_request_id: parsed_body["MerchantRequestID"],
        checkout_request_id: parsed_body["CheckoutRequestID"],
        response_code: parsed_body["ResponseCode"],
        response_description: parsed_body["ResponseDescription"],
        result_desc: parsed_body["ResultDesc"],
        result_code: parsed_body["ResultCode"]
      )
      OpenStruct.new(result: result, error: nil)
    end
  rescue JSON::ParserError => error
    OpenStruct.new(result: nil, error: error)
  end

  private

  def request(method)
    HTTParty.send(
      method,
      "#{API_URL}",
      headers: headers,
      body: values.to_json
    )
  end

  def timestamp
      Time.now.strftime('%Y%m%d%H%M%S').to_i
  end


  def values
      {
        "BusinessShortCode": "#{@paybill}",
        "Password": password,
        "Timestamp": timestamp.to_s,
        "CheckoutRequestID": "#{@checkout_request_id}",
      }
  end
  def headers
    {
      "Authorization" => "Bearer #{@token}",
      "Content-Type" => "application/json",
      "Accept" => "application/json",
    }
  end



  def password
    #@timestamp = timestamp
    Base64.strict_encode64("#{@paybill}#{@pass_key}#{timestamp}")
  end

end