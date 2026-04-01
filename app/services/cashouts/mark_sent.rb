module Cashouts
  class MarkSent
    def self.call(cashout_request:, actor: nil)
      return ServiceResult.success(cashout_request: cashout_request) if cashout_request.sent?
      return ServiceResult.failure(error_code: "invalid_state", error_message: "Cashout must be approved before marking as sent") unless cashout_request.approved?

      ActiveRecord::Base.transaction do
        cashout_request.lock!
        return ServiceResult.success(cashout_request: cashout_request) if cashout_request.sent?

        Ledger::PostEntry.call(
          user: cashout_request.user,
          entry_type: :debit,
          account_type: :cashout,
          amount_cents: cashout_request.amount_cents,
          reference: cashout_request,
          created_by: actor,
          metadata: { payout_provider: "manual", payout_method: cashout_request.payout_method }
        )

        cashout_request.update!(
          status: :sent,
          payout_sent_at: Time.current,
          paid_at: nil,
          payout_failed_at: nil,
          payout_last_error_code: nil,
          payout_last_error_message: nil
        )

        Balances::RecalculateUser.call(user: cashout_request.user)
      end

      ServiceResult.success(cashout_request: cashout_request)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(error_code: "invalid_cashout_request", error_message: e.record.errors.full_messages.to_sentence)
    end
  end
end
