module Mpesa::Values
  extend ActiveSupport::Concern

  def values
    {
        "BusinessShortCode": "#{@paybill}",
        "Password": password,
        "Timestamp": timestamp.to_s,
        "TransactionType": "CustomerPayBillOnline",
        "Amount": "#{@amount}",
        "PartyA": "#{@phone}",
        "PartyB": "#{@paybill}",
        "PhoneNumber": "#{@phone}",
        "CallBackURL": "#{@CallBackURL}",
        "AccountReference": "#{@order}",
        "TransactionDesc": "Payment of internet subscription #{@order} to masafa technologies"
      }
  end

  def timestamp
    Time.now.strftime("%Y%m%d%H%M%S").to_i
  end


  def password
    Base64.strict_encode64("#{@paybill}#{@api_key}#{timestamp}")
  end
end
