class RewardRule < ApplicationRecord
  enum :event_type, { registration: 0, subscription: 1 }
  enum :reward_mode, { flat: 0, percentage: 1 }
  enum :recurrence_mode, { one_time: 0, recurring: 1 }

  belongs_to :app

  validates :event_type, :reward_mode, :recurrence_mode, presence: true
  validates :pending_days, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :amount_cents,
            numericality: { only_integer: true, greater_than: 0 },
            allow_nil: true
  validates :percentage_bps,
            numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 10_000 },
            allow_nil: true
  validate :reward_value_presence

  scope :enabled, -> { where(enabled: true) }
  scope :active, lambda {
    now = Time.current
    where("active_from IS NULL OR active_from <= ?", now)
      .where("active_to IS NULL OR active_to >= ?", now)
  }

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      active_from
      active_to
      amount_cents
      app_id
      created_at
      enabled
      event_type
      id
      pending_days
      percentage_bps
      recurrence_mode
      reward_mode
      updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[app]
  end

  private

  def reward_value_presence
    if flat? && amount_cents.blank?
      errors.add(:amount_cents, "must be present for flat reward mode")
    end

    if percentage? && percentage_bps.blank?
      errors.add(:percentage_bps, "must be present for percentage reward mode")
    end
  end
end
