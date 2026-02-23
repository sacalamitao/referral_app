class WebhookProcessJob < ApplicationJob
  queue_as :critical

  retry_on StandardError, attempts: 10, wait: :exponentially_longer

  def perform(webhook_event_id)
    webhook_event = WebhookEvent.find(webhook_event_id)
    WebhookEvents::Process.call(webhook_event: webhook_event)
  end
end

