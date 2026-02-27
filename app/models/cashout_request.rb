class CashoutRequest < ApplicationRecord
  enum :status, {
    requested: 0,
    approved: 1,
    declined: 2,
    paid: 3,
    cancelled: 4,
    payout_processing: 5,
    payout_failed: 6
  }

  enum :payout_provider, { paypal: "paypal" }, prefix: true

  belongs_to :user
  belongs_to :reviewed_by_admin_user, class_name: "AdminUser", optional: true

  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :payout_method, presence: true
  validates :payout_reference, presence: true
  validates :payout_attempts, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :payout_method, inclusion: { in: %w[gcash bank paypal] }
  validate :amount_not_greater_than_available_balance, on: :create
  validate :paypal_reference_must_be_email

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      amount_cents
      created_at
      id
      paid_at
      payout_attempts
      payout_failed_at
      payout_last_error_code
      payout_last_error_message
      payout_provider
      payout_provider_response
      payout_sent_at
      payout_method
      payout_reference
      paypal_payout_batch_id
      paypal_payout_item_id
      paypal_payout_status
      paypal_sender_batch_id
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

  def paypal_reference_must_be_email
    return unless payout_method.to_s == "paypal"
    return if payout_reference.to_s.match?(URI::MailTo::EMAIL_REGEXP)

    errors.add(:payout_reference, "must be a valid PayPal email")
  end
end
