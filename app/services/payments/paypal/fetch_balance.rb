module Payments
  module Paypal
    class FetchBalance
      def self.call(system_config: SystemConfig.current)
        new(system_config: system_config).call
      end

      def initialize(system_config:)
        @client = Client.new(system_config: system_config)
        @currency_code = system_config&.paypal_payout_currency.to_s.presence || "CAD"
      end

      def call
        token_result = client.access_token
        return token_result unless token_result.success?

        result = client.get(path: "/v1/reporting/balances", token: token_result.data.fetch(:token))
        return result unless result.success?

        payload = result.data.fetch(:payload, {})
        raw_balances = payload.is_a?(Hash) ? payload.fetch("balances", []) : []
        balances = Array(raw_balances).select { |item| item.is_a?(Hash) }

        target_balance = balances.find do |item|
          currency = item["currency"]
          currency.is_a?(Hash) && currency["currency_code"].to_s == currency_code
        end

        return ServiceResult.failure(error_code: "paypal_balance_unavailable", error_message: "PayPal #{currency_code} balance is unavailable") if target_balance.blank?

        primary = target_balance["primary"]
        available_value = primary.is_a?(Hash) ? primary["value"].to_f : 0.0
        available_cents = (available_value * 100).round

        ServiceResult.success(
          available_cents: available_cents,
          currency: currency_code,
          raw_balance: target_balance
        )
      end

      private

      attr_reader :client, :currency_code
    end
  end
end
