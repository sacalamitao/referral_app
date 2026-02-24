class WebhookEvent < ApplicationRecord
  enum :event_type, { registration: 0, subscription: 1 }
  enum :status, { received: 0, validated: 1, processed: 2, failed: 3 }

  has_many :reward_transactions, foreign_key: :source_event_id, inverse_of: :source_event, dependent: :restrict_with_error

  validates :idempotency_key_raw, presence: true, uniqueness: true
  validates :request_signature, :payload, :received_at, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      attempt_count
      created_at
      error_code
      error_message
      event_type
      id
      idempotency_key_raw
      processed_at
      received_at
      status
      updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[reward_transactions]
  end
end
