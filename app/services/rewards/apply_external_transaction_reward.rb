module Rewards
  class ApplyExternalTransactionReward
    SUPPORTED_EVENT_TYPES = %w[credit_purchase renewal].freeze

    def self.call(webhook_event:, event_type:)
      payload = webhook_event.payload
      normalized_event_type = event_type.to_s
      raise ArgumentError, "unsupported event_type=#{normalized_event_type}" unless SUPPORTED_EVENT_TYPES.include?(normalized_event_type)

      referral = Rewards::ResolveReferral.call(payload: payload)
      reward_cents = Rewards::ResolveRewardAmount.call(payload: payload)
      transaction_id = payload["transaction_id"].to_s.strip.presence

      reward_txn = RewardTransaction.create!(
        referral: referral,
        user: referral.referrer_user,
        source_event: webhook_event,
        event_type: normalized_event_type,
        external_transaction_id: transaction_id,
        idempotency_fingerprint: "#{normalized_event_type}:event:#{webhook_event.id}",
        reward_cents: reward_cents,
        gross_cents: 0,
        status: :available,
        available_at: Time.current,
        metadata: {
          reward_source: normalized_event_type,
          referred_user_email: payload["referred_user_email"].to_s.strip.presence
        }
      )

      Ledger::PostEntry.call(
        user: referral.referrer_user,
        entry_type: :credit,
        account_type: :available_balance,
        amount_cents: reward_cents,
        reference: reward_txn
      )

      referral.update!(status: :qualified) if referral.registered?
      reward_txn
    end
  end
end
