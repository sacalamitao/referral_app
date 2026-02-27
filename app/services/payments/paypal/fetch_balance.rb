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

        balances = result.data.fetch(:payload).fetch("balances", [])
        usd_balance = balances.find { |item| item.dig("currency", "currency_code") == "USD" }
        return ServiceResult.failure(error_code: "paypal_balance_unavailable", error_message: "PayPal USD balance is unavailable") if usd_balance.blank?

        available_value = usd_balance.dig("primary", "value").to_f
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
