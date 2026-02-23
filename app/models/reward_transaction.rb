class RewardTransaction < ApplicationRecord
  enum :event_type, { registration: 0, subscription: 1 }
  enum :status, { pending: 0, available: 1, reversed: 2 }

  belongs_to :app
  belongs_to :referral
  belongs_to :user
  belongs_to :source_event, class_name: "WebhookEvent", optional: true, inverse_of: :reward_transactions

  has_many :ledger_entries, as: :reference, dependent: :restrict_with_error

  validates :idempotency_fingerprint, presence: true, uniqueness: true
  validates :reward_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :gross_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      app_id
      available_at
      created_at
      event_type
      external_transaction_id
      gross_cents
      id
      idempotency_fingerprint
      referral_id
      reward_cents
      source_event_id
      status
      updated_at
      user_id
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[app ledger_entries referral source_event user]
  end
end
