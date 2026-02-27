class SystemConfig < ApplicationRecord
  encrypts :webhook_secret
  encrypts :paypal_client_id
  encrypts :paypal_client_secret

  validates :webhook_secret, presence: true
  validates :timezone, presence: true
  validates :paypal_mode, inclusion: { in: %w[sandbox live] }
  validates :paypal_payout_currency, presence: true
  validate :single_row_guard, on: :create

  before_validation :ensure_defaults, on: :create

  scope :active, -> { where(active: true) }

  def self.current
    first
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      active
      config
      created_at
      id
      paypal_client_id
      paypal_client_secret
      paypal_mode
      paypal_payout_currency
      timezone
      updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  private

  def ensure_defaults
    self.webhook_secret ||= SecureRandom.hex(32)
    self.timezone ||= "UTC"
    self.paypal_mode ||= "sandbox"
    self.paypal_payout_currency ||= "USD"
    self.active = true if active.nil?
  end

  def paypal_base_url
    paypal_mode == "live" ? "https://api-m.paypal.com" : "https://api-m.sandbox.paypal.com"
  end

  def paypal_configured?
    paypal_client_id.present? && paypal_client_secret.present?
  end

  def single_row_guard
    errors.add(:base, "only one system config is allowed") if self.class.exists?
  end
end
