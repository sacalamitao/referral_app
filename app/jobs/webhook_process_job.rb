class WebhookProcessJob < ApplicationJob
  queue_as :critical

  # Retry only with explicit backoff supported by current ActiveJob version.
  retry_on StandardError, attempts: 10, wait: ->(executions) { [ (2**executions), 300 ].min }

  # Deterministic contract/validation failures should not retry.
  discard_on ActiveRecord::RecordInvalid
  discard_on Rewards::ResolveReferral::ReferralCodeNotFoundError
  discard_on Rewards::ResolveReferral::ReferralOwnershipMismatchError

  def perform(webhook_event_id)
    webhook_event = WebhookEvent.find(webhook_event_id)
    WebhookEvents::Process.call(webhook_event: webhook_event)
  end
end
