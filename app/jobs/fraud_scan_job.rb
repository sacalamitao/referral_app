class FraudScanJob < ApplicationJob
  queue_as :low

  def perform
    duplicates = Referral.group(:external_user_id).having("COUNT(*) > 1").count
    Rails.logger.warn("[fraud_scan] duplicate_external_users=#{duplicates.keys.size}") if duplicates.any?
  end
end
