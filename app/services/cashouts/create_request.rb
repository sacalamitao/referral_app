module Cashouts
  class CreateRequest
    SUPPORTED_PAYOUT_METHODS = %w[gcash bank].freeze

    def self.call(user:, amount_cents:, payout_method:, payout_reference:)
      amount = amount_cents.to_i
      method = payout_method.to_s.downcase.strip
      reference = payout_reference.to_s.strip

      return ServiceResult.failure(error_code: "invalid_amount", error_message: "Amount must be greater than 0") if amount <= 0
      return ServiceResult.failure(error_code: "insufficient_balance", error_message: "Amount exceeds available balance") if amount > user.available_cents
      return ServiceResult.failure(error_code: "invalid_payout_method", error_message: "Unsupported payout method") unless SUPPORTED_PAYOUT_METHODS.include?(method)
      return ServiceResult.failure(error_code: "missing_payout_reference", error_message: "Payout reference is required") if reference.blank?

      cashout_request = nil
      insufficient_balance = false

      ActiveRecord::Base.transaction do
        user.lock!
        if amount > user.available_cents
          insufficient_balance = true
          raise ActiveRecord::Rollback
        end

        cashout_request = CashoutRequest.create!(
          user: user,
          amount_cents: amount,
          status: :requested,
          payout_method: method,
          payout_reference: reference
        )

        Ledger::PostEntry.call(
          user: user,
          entry_type: :debit,
          account_type: :available_balance,
          amount_cents: amount,
          reference: cashout_request
        )

        Ledger::PostEntry.call(
          user: user,
          entry_type: :credit,
          account_type: :cashout,
          amount_cents: amount,
          reference: cashout_request
        )

        Balances::RecalculateUser.call(user: user)
      end

      return ServiceResult.failure(error_code: "insufficient_balance", error_message: "Amount exceeds available balance") if insufficient_balance
      return ServiceResult.failure(error_code: "insufficient_balance", error_message: "Amount exceeds available balance") if cashout_request.blank?

      ServiceResult.success(cashout_request: cashout_request)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(error_code: "invalid_cashout_request", error_message: e.record.errors.full_messages.to_sentence)
    end
  end
end
