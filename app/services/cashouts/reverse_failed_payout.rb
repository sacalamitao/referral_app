module Cashouts
  class ReverseFailedPayout
    def self.call(cashout_request:, actor: nil)
      new(cashout_request: cashout_request, actor: actor).call
    end

    def initialize(cashout_request:, actor:)
      @cashout_request = cashout_request
      @actor = actor
    end

    def call
      return ServiceResult.failure(error_code: "invalid_state", error_message: "Only payout_failed cashouts can be reversed") unless cashout_request.payout_failed?

      ActiveRecord::Base.transaction do
        cashout_request.lock!
        return ServiceResult.failure(error_code: "invalid_state", error_message: "Only payout_failed cashouts can be reversed") unless cashout_request.payout_failed?

        Ledger::PostEntry.call(
          user: cashout_request.user,
          entry_type: :debit,
          account_type: :cashout,
          amount_cents: cashout_request.amount_cents,
          reference: cashout_request,
          created_by: actor,
          metadata: { reversal_reason: "paypal_payout_failed" }
        )

        Ledger::PostEntry.call(
          user: cashout_request.user,
          entry_type: :credit,
          account_type: :available_balance,
          amount_cents: cashout_request.amount_cents,
          reference: cashout_request,
          created_by: actor,
          metadata: { reversal_reason: "paypal_payout_failed" }
        )

        cashout_request.update!(status: :cancelled)
        Balances::RecalculateUser.call(user: cashout_request.user)
      end

      ServiceResult.success(cashout_request: cashout_request)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(error_code: "invalid_cashout_request", error_message: e.record.errors.full_messages.to_sentence)
    end

    private

    attr_reader :cashout_request, :actor
  end
end
