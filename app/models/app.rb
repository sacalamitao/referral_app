class App < ApplicationRecord
  encrypts :webhook_secret

  enum :status, { active: 0, inactive: 1 }, default: :active

  attr_reader :raw_api_key

  has_many :referrals, dependent: :restrict_with_error
  has_many :referral_codes, through: :referrals
  has_many :reward_rules, dependent: :destroy
  has_many :reward_transactions, dependent: :restrict_with_error
  has_many :ledger_entries, dependent: :restrict_with_error
  has_many :webhook_events, dependent: :restrict_with_error
  has_many :idempotency_keys, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :api_key_digest, presence: true, uniqueness: true
  validates :webhook_secret, presence: true
  validates :timezone, presence: true

  before_validation :ensure_api_key_digest!, on: :create
  before_validation :ensure_webhook_secret!, on: :create

  def rotate_api_key!
    raw = SecureRandom.hex(24)
    @raw_api_key = raw
    update!(api_key_digest: self.class.digest_api_key(raw))
    raw
  end

  def self.digest_api_key(raw)
    Digest::SHA256.hexdigest(raw.to_s)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      created_at
      id
      name
      status
      timezone
      updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[
      idempotency_keys
      ledger_entries
      referral_codes
      referrals
      reward_rules
      reward_transactions
      webhook_events
    ]
  end

  private

  def ensure_api_key_digest!
    return if api_key_digest.present?

    @raw_api_key = SecureRandom.hex(24)
    self.api_key_digest = self.class.digest_api_key(@raw_api_key)
  end

  def ensure_webhook_secret!
    self.webhook_secret ||= SecureRandom.hex(32)
  end
end
