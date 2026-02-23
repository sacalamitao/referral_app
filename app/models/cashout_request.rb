class CashoutRequest < ApplicationRecord
  enum :status, { requested: 0, approved: 1, declined: 2, paid: 3, cancelled: 4 }

  belongs_to :user
  belongs_to :reviewed_by_admin_user, class_name: "AdminUser", optional: true

  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validate :amount_not_greater_than_available_balance, on: :create

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      amount_cents
      created_at
      id
      paid_at
      payout_method
      payout_reference
      reviewed_at
      reviewed_by_admin_user_id
      status
      updated_at
      user_id
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[reviewed_by_admin_user user]
  end

  private

  def amount_not_greater_than_available_balance
    return if user.blank? || amount_cents.blank?
    return unless amount_cents > user.available_cents

    errors.add(:amount_cents, "exceeds available balance")
  end
end
