class User < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :trackable

  enum :status, { active: 0, suspended: 1 }, default: :active

  has_many :referral_codes, dependent: :destroy
  has_one :active_referral_code, -> { where(active: true) }, class_name: "ReferralCode", inverse_of: :user
  has_many :referrals_as_referrer, class_name: "Referral", foreign_key: :referrer_user_id, inverse_of: :referrer_user, dependent: :restrict_with_error
  has_many :reward_transactions, dependent: :restrict_with_error
  has_many :ledger_entries, dependent: :restrict_with_error
  has_many :cashout_requests, dependent: :restrict_with_error

  validates :available_cents, :pending_cents, :total_earned_cents,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  after_create :ensure_active_referral_code!

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      available_cents
      created_at
      current_sign_in_at
      current_sign_in_ip
      email
      id
      last_sign_in_at
      last_sign_in_ip
      pending_cents
      sign_in_count
      status
      total_earned_cents
      updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[
      cashout_requests
      ledger_entries
      referral_codes
      referrals_as_referrer
      reward_transactions
    ]
  end

  private

  def ensure_active_referral_code!
    referral_codes.create!(active: true) unless active_referral_code
  end
end
