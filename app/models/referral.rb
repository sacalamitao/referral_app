class Referral < ApplicationRecord
  enum :status, { registered: 0, qualified: 1, blocked: 2 }, default: :registered

  belongs_to :app
  belongs_to :referrer_user, class_name: "User", inverse_of: :referrals_as_referrer
  belongs_to :referral_code

  has_many :reward_transactions, dependent: :restrict_with_error

  validates :external_user_id, presence: true, uniqueness: { scope: :app_id }
  validates :referred_at, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      app_id
      created_at
      external_user_id
      id
      referred_at
      referrer_user_id
      referral_code_id
      status
      updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[app referral_code referrer_user reward_transactions]
  end
end
