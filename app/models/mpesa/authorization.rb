class Mpesa::Authorization
  URI = Rails.configuration.mpesa[:authorization_url]


    def initialize(consumer_key, consumer_secret)
      @consumer_key = consumer_key
      @consumer_secret = consumer_secret

    end

    def call
      Rails.cache.fetch([self, :call], expires_in: 3566.seconds) do
        response = request(:get)
        #response = http.request(request)
        parsed_body = response.body
        token = JSON.parse(parsed_body)['access_token']
      end

    end

    private

    def request(method)
      HTTParty.send(
        method,
        "#{URI}",
        headers: headers
        )
    end

    def headers
      encode = credentials(@consumer_key, @consumer_secret)
      {
        "Authorization" => "Basic #{encode}",
        "Content-Type" => "application/json",
        "Accept" => "application/json",
      }
    end

    def credentials(consumer_key, consumer_secret)
      Base64.strict_encode64("#{consumer_key}:#{consumer_secret}")
    end


  end