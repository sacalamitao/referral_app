require "net/http"
require "json"
require "base64"

module Payments
  module Paypal
    class Client
      DEFAULT_TIMEOUT_SECONDS = 12

      def initialize(system_config: SystemConfig.current)
        @system_config = system_config
      end

      def configured?
        system_config.present? && system_config.paypal_configured?
      end

      def access_token
        return ServiceResult.failure(error_code: "paypal_not_configured", error_message: "PayPal credentials are not configured") unless configured?

        uri = URI.parse("#{system_config.paypal_base_url}/v1/oauth2/token")
        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "Basic #{basic_auth_token}"
        request["Content-Type"] = "application/x-www-form-urlencoded"
        request.body = "grant_type=client_credentials"

        response = perform_request(uri, request)
        return response unless response.success?

        payload = response.data.fetch(:payload)
        token = payload["access_token"].to_s
        return ServiceResult.failure(error_code: "paypal_auth_failed", error_message: "PayPal access token missing") if token.blank?

        ServiceResult.success(token: token)
      end

      def get(path:, token:)
        return ServiceResult.failure(error_code: "paypal_not_configured", error_message: "PayPal credentials are not configured") unless configured?

        uri = URI.parse("#{system_config.paypal_base_url}#{path}")
        request = Net::HTTP::Get.new(uri)
        request["Authorization"] = "Bearer #{token}"
        request["Content-Type"] = "application/json"

        perform_request(uri, request)
      end

      def post(path:, token:, body:)
        return ServiceResult.failure(error_code: "paypal_not_configured", error_message: "PayPal credentials are not configured") unless configured?

        uri = URI.parse("#{system_config.paypal_base_url}#{path}")
        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "Bearer #{token}"
        request["Content-Type"] = "application/json"
        request.body = body.to_json

        perform_request(uri, request)
      end

      private

      attr_reader :system_config

      def basic_auth_token
        Base64.strict_encode64("#{system_config.paypal_client_id}:#{system_config.paypal_client_secret}")
      end

      def perform_request(uri, request)
        response = Net::HTTP.start(
          uri.host,
          uri.port,
          use_ssl: uri.scheme == "https",
          read_timeout: DEFAULT_TIMEOUT_SECONDS,
          open_timeout: DEFAULT_TIMEOUT_SECONDS
        ) do |http|
          http.request(request)
        end

        payload = response.body.present? ? JSON.parse(response.body) : {}
        code = response.code.to_i

        if code.between?(200, 299)
          ServiceResult.success(payload: payload, status_code: code)
        else
          ServiceResult.failure(
            error_code: "paypal_request_failed",
            error_message: payload["message"].presence || "PayPal request failed",
            http_status: :bad_gateway,
            data: { payload: payload, status_code: code }
          )
        end
      rescue JSON::ParserError
        ServiceResult.failure(error_code: "paypal_invalid_response", error_message: "PayPal returned an invalid JSON response", http_status: :bad_gateway)
      rescue StandardError => e
        ServiceResult.failure(error_code: "paypal_connection_error", error_message: e.message, http_status: :bad_gateway)
      end
    end
  end
end
