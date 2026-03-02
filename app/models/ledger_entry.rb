class LedgerEntry < ApplicationRecord
  enum :entry_type, { credit: 0, debit: 1 }
  enum :account_type, {
    pending_balance: 0,
    available_balance: 1,
    cashout: 2,
    adjustment: 3,
    reversal: 4
  }

  belongs_to :user
  belongs_to :reference, polymorphic: true, optional: true
  belongs_to :created_by, polymorphic: true, optional: true

  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :occurred_at, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      account_type
      amount_cents
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
    %w[created_by reference user]
  end

  def reward_transaction_reference
    reference if reference.is_a?(RewardTransaction)
  end

  def reward_source
    reward_transaction_reference&.event_type&.to_s
  end

  def referred_user_email
    reward_transaction_reference&.metadata&.dig("referred_user_email")&.to_s&.strip&.presence
  end
end
