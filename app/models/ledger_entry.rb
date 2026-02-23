class LedgerEntry < ApplicationRecord
  enum :entry_type, { credit: 0, debit: 1 }
  enum :account_type, {
    pending_balance: 0,
    available_balance: 1,
    cashout: 2,
    adjustment: 3,
    reversal: 4
  }

  belongs_to :app
  belongs_to :user
  belongs_to :reference, polymorphic: true, optional: true
  belongs_to :created_by, polymorphic: true, optional: true

  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :occurred_at, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      account_type
      amount_cents
      app_id
      created_at
      created_by_id
      created_by_type
      entry_type
      id
      occurred_at
      reference_id
      reference_type
      updated_at
      user_id
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[app created_by reference user]
  end
end
