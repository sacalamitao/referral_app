module Rewards
  class ApplySubscriptionReward
    def self.call(webhook_event:)
      payload = webhook_event.payload

      referral = Referral.find_by!(external_user_id: payload.fetch("external_user_id"))
      reward_cents = Rewards::ResolveRewardAmount.call(payload: payload)
      transaction_id = payload.fetch("transaction_id")

      reward_txn = RewardTransaction.create!(
        referral: referral,
        user: referral.referrer_user,
        source_event: webhook_event,
        event_type: :subscription,
        external_transaction_id: transaction_id,
        idempotency_fingerprint: "subscription:#{transaction_id}",
        reward_cents: reward_cents,
        gross_cents: 0,
        status: :available,
        available_at: Time.current,
        metadata: {
          reward_source: "subscription",
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
