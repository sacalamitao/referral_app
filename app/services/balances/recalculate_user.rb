module Balances
  class RecalculateUser
    def self.call(user:)
      pending = user.ledger_entries.where(account_type: :pending_balance, entry_type: :credit).sum(:amount_cents) -
                user.ledger_entries.where(account_type: :pending_balance, entry_type: :debit).sum(:amount_cents)

      available = user.ledger_entries.where(account_type: :available_balance, entry_type: :credit).sum(:amount_cents) -
                  user.ledger_entries.where(account_type: :available_balance, entry_type: :debit).sum(:amount_cents)

      total_earned = user.reward_transactions.where.not(status: :reversed).sum(:reward_cents)

      # Balance fields are denormalized/cached counters derived from ledger + reward tables.
      # Persist them without triggering profile validations (first_name/last_name/contact_number),
      # so webhook processing is not blocked by unrelated user-profile completeness.
      user.update_columns(
        pending_cents: [ pending, 0 ].max,
        available_cents: [ available, 0 ].max,
        total_earned_cents: [ total_earned, 0 ].max,
        updated_at: Time.current
      )
    end
  end
end
