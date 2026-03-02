module Cashouts
  class SyncPaypalPayoutStatus
    TERMINAL_SUCCESS_BATCH_STATUSES = %w[SUCCESS].freeze
    TERMINAL_FAILED_BATCH_STATUSES = %w[DENIED CANCELED FAILED BLOCKED RETURNED REVERSED].freeze
    RETRYABLE_BATCH_STATUSES = %w[PENDING PROCESSING NEW].freeze

    def self.call(cashout_request:, actor: nil, retry_count: 0)
      new(cashout_request: cashout_request, actor: actor, retry_count: retry_count).call
    end

    def initialize(cashout_request:, actor:, retry_count:)
      @cashout_request = cashout_request
      @actor = actor
      @retry_count = retry_count.to_i
      @paypal_client = Payments::Paypal::Client.new(system_config: SystemConfig.current)
    end

    def call
      return ServiceResult.success(cashout_request: cashout_request) if cashout_request.paid? || cashout_request.cancelled?
      return ServiceResult.failure(error_code: "invalid_state", error_message: "Cashout is not in a syncable PayPal state") unless cashout_request.payout_processing?
      return ServiceResult.failure(error_code: "missing_paypal_batch_id", error_message: "PayPal batch id is missing") if cashout_request.paypal_payout_batch_id.blank?

      token_result = paypal_client.access_token
      return token_result unless token_result.success?

      fetch_result = paypal_client.get(path: "/v1/payments/payouts/#{cashout_request.paypal_payout_batch_id}", token: token_result.data.fetch(:token))
      return fetch_result unless fetch_result.success?

      payload = fetch_result.data.fetch(:payload)
      batch_status = payload.dig("batch_header", "batch_status").to_s

      persist_sync_snapshot!(payload: payload, batch_status: batch_status)

      if TERMINAL_SUCCESS_BATCH_STATUSES.include?(batch_status)
        settle_paid!(payload: payload, batch_status: batch_status)
      elsif TERMINAL_FAILED_BATCH_STATUSES.include?(batch_status)
        mark_failed!(payload: payload, batch_status: batch_status)
      elsif RETRYABLE_BATCH_STATUSES.include?(batch_status)
        schedule_retry_if_needed
      end

      ServiceResult.success(cashout_request: cashout_request.reload)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(error_code: "invalid_cashout_request", error_message: e.record.errors.full_messages.to_sentence)
    end

    private

    MAX_SYNC_RETRIES = 20

    attr_reader :cashout_request, :actor, :retry_count, :paypal_client

    def persist_sync_snapshot!(payload:, batch_status:)
      cashout_request.update!(
        paypal_payout_status: batch_status,
        paypal_payout_item_id: payload.dig("items", 0, "payout_item_id") || cashout_request.paypal_payout_item_id,
        payout_provider_response: payload
      )
    end

    def settle_paid!(payload:, batch_status:)
      ActiveRecord::Base.transaction do
        cashout_request.lock!
        return if cashout_request.paid?

        Ledger::PostEntry.call(
          user: cashout_request.user,
          entry_type: :debit,
          account_type: :cashout,
          amount_cents: cashout_request.amount_cents,
          reference: cashout_request,
          created_by: actor,
          metadata: { payout_provider: "paypal", paypal_batch_status: batch_status }
        )

        cashout_request.update!(
          status: :paid,
          paid_at: Time.current,
          payout_failed_at: nil,
          payout_last_error_code: nil,
          payout_last_error_message: nil,
          paypal_payout_status: batch_status,
          paypal_payout_item_id: payload.dig("items", 0, "payout_item_id") || cashout_request.paypal_payout_item_id,
          payout_provider_response: payload
        )

        Balances::RecalculateUser.call(user: cashout_request.user)
      end
    end

    def mark_failed!(payload:, batch_status:)
      cashout_request.update!(
        status: :payout_failed,
        payout_failed_at: Time.current,
        payout_last_error_code: "paypal_batch_#{batch_status.downcase}",
        payout_last_error_message: payload.dig("batch_header", "time_completed").present? ? "PayPal payout ended with #{batch_status}" : "PayPal payout failed with #{batch_status}",
        paypal_payout_status: batch_status,
        paypal_payout_item_id: payload.dig("items", 0, "payout_item_id") || cashout_request.paypal_payout_item_id,
        payout_provider_response: payload
      )
    end

    def schedule_retry_if_needed
      return if retry_count >= MAX_SYNC_RETRIES

      delay_minutes = [ retry_count + 1, 15 ].min
      PaypalPayoutStatusSyncJob.set(wait: delay_minutes.minutes).perform_later(cashout_request.id, retry_count + 1)
    end
  end
end
