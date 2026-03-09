class WebhookProcessJob < ApplicationJob
  queue_as :critical

  # Retry only with explicit backoff supported by current ActiveJob version.
  retry_on StandardError, attempts: 10, wait: ->(executions) { [ (2**executions), 300 ].min }

  # Deterministic validation failures (e.g., duplicate external_user_id) should not retry.
  discard_on ActiveRecord::RecordInvalid

  def perform(webhook_event_id)
    webhook_event = WebhookEvent.find(webhook_event_id)
    WebhookEvents::Process.call(webhook_event: webhook_event)
  end
end
