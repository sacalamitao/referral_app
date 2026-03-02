module Payments
  module Paypal
    class FetchBalance
      def self.call(system_config: SystemConfig.current)
        new(system_config: system_config).call
      end

      def initialize(system_config:)
        @client = Client.new(system_config: system_config)
      end

      def call
        token_result = client.access_token
        return token_result unless token_result.success?

        result = client.get(path: "/v1/reporting/balances", token: token_result.data.fetch(:token))
        return result unless result.success?

        payload = result.data.fetch(:payload, {})
        raw_balances = payload.is_a?(Hash) ? payload.fetch("balances", []) : []
        balances = Array(raw_balances).select { |item| item.is_a?(Hash) }

        usd_balance = balances.find do |item|
          currency = item["currency"]
          currency.is_a?(Hash) && currency["currency_code"].to_s == "USD"
        end

        return ServiceResult.failure(error_code: "paypal_balance_unavailable", error_message: "PayPal USD balance is unavailable") if usd_balance.blank?

        primary = usd_balance["primary"]
        available_value = primary.is_a?(Hash) ? primary["value"].to_f : 0.0
        available_cents = (available_value * 100).round

        ServiceResult.success(
          available_cents: available_cents,
          currency: "USD",
          raw_balance: usd_balance
        )
      end

      private

      attr_reader :client
    end
  end
end
