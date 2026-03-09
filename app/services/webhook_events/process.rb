module WebhookEvents
  class Process
    EXTERNAL_TRANSACTION_EVENT_TYPES = %w[credit_purchase renewal].freeze

    def self.call(webhook_event:)
      ActiveRecord::Base.transaction do
        reward_txn = case webhook_event.event_type
        when "registration"
                        Rewards::ApplyRegistrationReward.call(webhook_event: webhook_event)
        when *EXTERNAL_TRANSACTION_EVENT_TYPES
                        Rewards::ApplyExternalTransactionReward.call(
                          webhook_event: webhook_event,
                          event_type: webhook_event.event_type
                        )
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
