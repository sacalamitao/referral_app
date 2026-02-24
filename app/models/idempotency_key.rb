class IdempotencyKey < ApplicationRecord
  validates :key, :request_hash, :first_seen_at, :expires_at, presence: true
  validates :key, uniqueness: true

  scope :active, -> { where("expires_at > ?", Time.current) }
end
