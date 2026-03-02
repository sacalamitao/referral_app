class PaypalPayoutStatusSyncJob < ApplicationJob
  queue_as :default

  def perform(cashout_request_id, retry_count = 0)
    cashout_request = CashoutRequest.find(cashout_request_id)
    return unless cashout_request.payout_method == "paypal"
    return unless cashout_request.payout_processing?

    result = Cashouts::SyncPaypalPayoutStatus.call(cashout_request: cashout_request, retry_count: retry_count)
    raise StandardError, result.error_message unless result.success?
  end
end
