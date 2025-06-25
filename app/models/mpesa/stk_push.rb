class Mpesa::StkPush
  # API_URL = 'https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest'
  # URI = "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest"
  URI = Rails.configuration.mpesa[:api_url]


  def call(values, token)
    response = request(:post, token, values)
    parsed_body = JSON.parse(response.read_body)
    puts parsed_body
    puts "this is the responce code #{parsed_body["ResponseCode"]}"

    if parsed_body["ResponseCode"] == "0"

      { success: true, message: parsed_body["ResponseDescription"], checkout_request_id: parsed_body["CheckoutRequestID"], merchant_request_id: parsed_body["MerchantRequestID"] }
    else
      { success: false, message: parsed_body["ResponseDescription"] || "Failed to initiate payment." }

    end
    rescue StandardError => e
    Rails.logger.error "M-Pesa STK Push error: #{e.message}"
    { success: false, message: "An error occurred during payment initiation." }
  end




  private

  def request(method, token, values)
    HTTParty.send(
      method,
      "#{URI}",
      headers: headers(token),
      body: values.to_json
    )
  end



  def headers(token)
    {
      "Authorization" => "Bearer #{token}",
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }
  end
end
