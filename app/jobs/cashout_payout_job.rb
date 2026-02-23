class CashoutPayoutJob < ApplicationJob
  queue_as :default

  def perform(cashout_request_id)
    cashout = CashoutRequest.find(cashout_request_id)
    result = Cashouts::MarkPaid.call(cashout_request: cashout)
    raise StandardError, result.error_message unless result.success?
  end
end
