module Balances
  class RecalculateUser
    def self.call(user:)
      pending = user.ledger_entries.where(account_type: :pending_balance, entry_type: :credit).sum(:amount_cents) -
                user.ledger_entries.where(account_type: :pending_balance, entry_type: :debit).sum(:amount_cents)

      available = user.ledger_entries.where(account_type: :available_balance, entry_type: :credit).sum(:amount_cents) -
                  user.ledger_entries.where(account_type: :available_balance, entry_type: :debit).sum(:amount_cents)

      total_earned = user.reward_transactions.where.not(status: :reversed).sum(:reward_cents)

      user.update!(
        pending_cents: [ pending, 0 ].max,
        available_cents: [ available, 0 ].max,
        total_earned_cents: [ total_earned, 0 ].max
      )
    end
  end
end

