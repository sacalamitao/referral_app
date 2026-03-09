module Rewards
  class ApplyRegistrationReward
    def self.call(webhook_event:)
      payload = webhook_event.payload
      reward_cents = Rewards::ResolveRewardAmount.call(payload: payload)

      referral_code = ReferralCode.find_by(code: payload["referral_code"].to_s.upcase, active: true)
      raise ActiveRecord::RecordInvalid, Referral.new.tap { |r| r.errors.add(:referral_code, "is invalid") } if referral_code.blank?

      referral = Referral.create!(
        referrer_user: referral_code.user,
        referral_code: referral_code,
        external_user_id: payload.fetch("external_user_id"),
        referred_at: Time.current,
        status: :registered,
        metadata: payload.except("event_type")
      )

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

      reward_txn
    end
  end
end
