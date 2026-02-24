class SystemConfig < ApplicationRecord
  encrypts :webhook_secret

  validates :webhook_secret, presence: true
  validates :timezone, presence: true
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
    self.active = true if active.nil?
  end

  def single_row_guard
    errors.add(:base, "only one system config is allowed") if self.class.exists?
  end
end
