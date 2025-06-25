# app/services/concerns/mpesa_auth.rb
module  MpesaAuth
  extend ActiveSupport::Concern # Use ActiveSupport::Concern for mixins in classes

  # Cache the auth token for 3500 seconds (slightly less than 3600 to be safe)
  AUTH_TOKEN_CACHE_KEY = "mpesa_auth_token".freeze
  AUTH_TOKEN_EXPIRY = 3500.seconds # Cache for almost an hour

  class_methods do
    def auth_token
      Rails.cache.fetch(AUTH_TOKEN_CACHE_KEY, expires_in: AUTH_TOKEN_EXPIRY) do
        generate_auth_token_from_api
      end
    rescue StandardError => e
      Rails.logger.error "Failed to retrieve/generate Mpesa auth token: #{e.message}"
      nil # Or raise a specific error
    end

    private

    def generate_auth_token_from_api
      uri = Rails.configuration.mpesa[:authorization_url]
      consumer_secret = Rails.configuration.mpesa[:consumer_secret]
      consumer_key = Rails.configuration.mpesa[:consumer_key]
      encode = Base64.strict_encode64("#{consumer_key}:#{consumer_secret}")
      headers = { "Authorization" => "Basic #{encode}", "Content-Type" => "application/json", "Accept" => "application/json" }
      response = HTTParty.send(:get, "#{uri}", headers: headers)

      parsed_response = JSON.parse(response.body)

      if response.is_a?(HTTParty::Response) && parsed_response["access_token"].present?
        Rails.logger.info "Mpesa auth token generated and cached."
        parsed_response["access_token"]
      else
        Rails.logger.error "Failed to generate Mpesa auth token: #{parsed_response['errorMessage'] || response.body}"
        raise "Mpesa auth token generation failed" # Raise to prevent caching nil
      end
    rescue JSON::ParserError, HTTParty::ResponseError => e
      Rails.logger.error "Mpesa auth token API communication error: #{e.message}"
      raise "Mpesa auth token API communication error: #{e.message}"
    end
  end

  # Instance methods (if any authentication-related logic is needed at instance level)
  included do
    def generate_password
      paybill =  Rails.configuration.mpesa[:short_code]
      api_key = Rails.configuration.mpesa[:api_key]
      timestamp = MpesaUtils.generate_timestamp # Use the utility module for timestamp

      Base64.strict_encode64("#{paybill}#{api_key}#{timestamp}")
    end
  end
end
