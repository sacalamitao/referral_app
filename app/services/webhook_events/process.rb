module WebhookEvents
  class Process
    def self.call(webhook_event:)
      ActiveRecord::Base.transaction do
        reward_txn = case webhook_event.event_type
                     when "registration"
                       Rewards::ApplyRegistrationReward.call(webhook_event: webhook_event)
                     when "subscription"
                       Rewards::ApplySubscriptionReward.call(webhook_event: webhook_event)
                     else
                       raise ArgumentError, "unsupported event_type=#{webhook_event.event_type}"
                     end

        Balances::RecalculateUser.call(user: reward_txn.user)
        webhook_event.update!(status: :processed, processed_at: Time.current)
      end
    rescue StandardError => e
      webhook_event.update!(
        status: :failed,
        error_code: e.class.name,
        error_message: e.message,
        attempt_count: webhook_event.attempt_count + 1
      )
      raise
    end
  end
end

