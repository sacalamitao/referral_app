module Cashouts
  class MarkPaid
    def self.call(cashout_request:)
      return ServiceResult.success(cashout_request: cashout_request) if cashout_request.paid?
      return ServiceResult.failure(error_code: "invalid_state", error_message: "Cashout must be approved before payout") unless cashout_request.approved?

      app_id = LedgerEntry.where(reference: cashout_request).order(:id).pick(:app_id)
      app = App.find_by(id: app_id)
      return ServiceResult.failure(error_code: "missing_app_context", error_message: "Unable to resolve app context for cashout") if app.nil?

      ActiveRecord::Base.transaction do
        cashout_request.lock!
        return ServiceResult.success(cashout_request: cashout_request) if cashout_request.paid?

        Ledger::PostEntry.call(
          app: app,
          user: cashout_request.user,
          entry_type: :debit,
          account_type: :cashout,
          amount_cents: cashout_request.amount_cents,
          reference: cashout_request
        )

        cashout_request.update!(status: :paid, paid_at: Time.current)
        Balances::RecalculateUser.call(user: cashout_request.user)
      end

      ServiceResult.success(cashout_request: cashout_request)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(error_code: "invalid_cashout_request", error_message: e.record.errors.full_messages.to_sentence)
    end
  end
end
