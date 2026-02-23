module Rewards
  class ReleasePending
    def self.call(reward_transaction:)
      return unless reward_transaction.pending?
      return if reward_transaction.available_at.blank? || reward_transaction.available_at > Time.current

      ActiveRecord::Base.transaction do
        Ledger::PostEntry.call(
          app: reward_transaction.app,
          user: reward_transaction.user,
          entry_type: :debit,
          account_type: :pending_balance,
          amount_cents: reward_transaction.reward_cents,
          reference: reward_transaction
        )

        Ledger::PostEntry.call(
          app: reward_transaction.app,
          user: reward_transaction.user,
          entry_type: :credit,
          account_type: :available_balance,
          amount_cents: reward_transaction.reward_cents,
          reference: reward_transaction
        )

        reward_transaction.update!(status: :available)
        Balances::RecalculateUser.call(user: reward_transaction.user)
      end
    end
  end
end

