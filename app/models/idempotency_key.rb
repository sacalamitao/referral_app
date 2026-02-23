class IdempotencyKey < ApplicationRecord
  belongs_to :app

  validates :key, :request_hash, :first_seen_at, :expires_at, presence: true
  validates :key, uniqueness: { scope: :app_id }

  scope :active, -> { where("expires_at > ?", Time.current) }
end

