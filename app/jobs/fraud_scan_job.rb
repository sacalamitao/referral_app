class FraudScanJob < ApplicationJob
  queue_as :low

  def perform(app_id)
    app = App.find(app_id)
    duplicates = app.referrals.group(:external_user_id).having("COUNT(*) > 1").count
    Rails.logger.warn("[fraud_scan] app_id=#{app.id} duplicate_external_users=#{duplicates.keys.size}") if duplicates.any?
  end
end

