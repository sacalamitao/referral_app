module Ledger
  class PostEntry
    def self.call(user:, entry_type:, account_type:, amount_cents:, reference:, occurred_at: Time.current, created_by: nil, metadata: {})
      LedgerEntry.create!(
        user: user,
        entry_type: entry_type,
        account_type: account_type,
        amount_cents: amount_cents,
        reference: reference,
        occurred_at: occurred_at,
        created_by: created_by,
        metadata: metadata
      )
    end
  end
end
