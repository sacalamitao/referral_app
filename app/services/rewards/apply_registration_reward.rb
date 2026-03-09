module Rewards
  class ApplyRegistrationReward
    def self.call(webhook_event:)
      payload = webhook_event.payload
      reward_cents = Rewards::ResolveRewardAmount.call(payload: payload)
      referred_user_email = payload.fetch("referred_user_email").to_s.strip.downcase
      referral = Rewards::ResolveReferral.call(payload: payload)

      available_at = Time.current

      reward_txn = RewardTransaction.create!(
        referral: referral,
        user: referral.referrer_user,
        source_event: webhook_event,
        event_type: :registration,
        idempotency_fingerprint: "registration:#{referral.id}",
        reward_cents: reward_cents,
        gross_cents: 0,
        status: :available,
        available_at: available_at,
        metadata: {
          reward_source: "registration",
          referred_user_email: referred_user_email
        }
      )

      Ledger::PostEntry.call(
        user: referral.referrer_user,
        entry_type: :credit,
        account_type: :available_balance,
        amount_cents: reward_cents,
        reference: reward_txn
      )

      reward_txn
    end
  end
end
