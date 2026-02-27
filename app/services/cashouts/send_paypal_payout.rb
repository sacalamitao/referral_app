module Cashouts
  class SendPaypalPayout
    def self.call(cashout_request:, actor: nil)
      new(cashout_request: cashout_request, actor: actor).call
    end

    def initialize(cashout_request:, actor:)
      @cashout_request = cashout_request
      @actor = actor
      @system_config = SystemConfig.current
      @paypal_client = Payments::Paypal::Client.new(system_config: @system_config)
    end

    def call
      return ServiceResult.failure(error_code: "invalid_payout_method", error_message: "Cashout is not configured for PayPal payout") unless cashout_request.payout_method == "paypal"
      return ServiceResult.failure(error_code: "invalid_state", error_message: "Cashout must be approved before payout") unless cashout_request.approved? || cashout_request.payout_failed?

      token_result = paypal_client.access_token
      return fail_cashout!(token_result) unless token_result.success?

      payout_result = send_payout(token: token_result.data.fetch(:token))
      return fail_cashout!(payout_result) unless payout_result.success?

      apply_paid_state!(payout_result.data.fetch(:payload))
      ServiceResult.success(cashout_request: cashout_request)
    end

    private

    attr_reader :cashout_request, :actor, :paypal_client, :system_config

    def send_payout(token:)
      sender_batch_id = "cashout-#{cashout_request.id}-#{Time.current.to_i}-#{SecureRandom.hex(4)}"
      amount = format("%.2f", cashout_request.amount_cents.to_f / 100)

      body = {
        sender_batch_header: {
          sender_batch_id: sender_batch_id,
          email_subject: "You have received a payout"
        },
        items: [
          {
            recipient_type: "EMAIL",
            amount: {
              value: amount,
              currency: system_config.paypal_payout_currency
            },
            receiver: cashout_request.payout_reference,
            note: "Referral payout",
            sender_item_id: "cashout-#{cashout_request.id}"
          }
        ]
      }

      cashout_request.update!(
        status: :payout_processing,
        payout_provider: :paypal,
        payout_attempts: cashout_request.payout_attempts + 1,
        paypal_sender_batch_id: sender_batch_id,
        payout_last_error_code: nil,
        payout_last_error_message: nil,
        payout_failed_at: nil
      )

      paypal_client.post(path: "/v1/payments/payouts", token: token, body: body)
    end

    def apply_paid_state!(payload)
      ActiveRecord::Base.transaction do
        cashout_request.lock!

        Ledger::PostEntry.call(
          user: cashout_request.user,
          entry_type: :debit,
          account_type: :cashout,
          amount_cents: cashout_request.amount_cents,
          reference: cashout_request,
          created_by: actor,
          metadata: { payout_provider: "paypal" }
        )

        cashout_request.update!(
          status: :paid,
          paid_at: Time.current,
          payout_sent_at: Time.current,
          paypal_payout_batch_id: payload.dig("batch_header", "payout_batch_id"),
          paypal_payout_status: payload.dig("batch_header", "batch_status"),
          payout_provider_response: payload
        )

        Balances::RecalculateUser.call(user: cashout_request.user)
      end
    end

    def fail_cashout!(result)
      cashout_request.update!(
        status: :payout_failed,
        payout_failed_at: Time.current,
        payout_last_error_code: result.error_code,
        payout_last_error_message: result.error_message,
        payout_provider_response: result.data[:payload].presence || {}
      )

      ServiceResult.failure(
        error_code: result.error_code,
        error_message: result.error_message,
        http_status: result.http_status,
        data: { cashout_request: cashout_request }
      )
    end
  end
end
