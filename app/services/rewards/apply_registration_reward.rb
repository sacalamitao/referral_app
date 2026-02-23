module Rewards
  class ApplyRegistrationReward
    def self.call(webhook_event:)
      payload = webhook_event.payload
      app = webhook_event.app

      referral_code = ReferralCode.find_by(code: payload["referral_code"].to_s.upcase, active: true)
      raise ActiveRecord::RecordInvalid, Referral.new.tap { |r| r.errors.add(:referral_code, "is invalid") } if referral_code.blank?

      referral = Referral.create!(
        app: app,
        referrer_user: referral_code.user,
        referral_code: referral_code,
        external_user_id: payload.fetch("external_user_id"),
        referred_at: Time.current,
        status: :registered,
        metadata: payload.except("event_type")
      )

      rule = app.reward_rules.enabled.active.find_by!(event_type: :registration)
      reward_cents = Rewards::CalculateReward.call(rule: rule)
      available_at = rule.pending_days.to_i.days.from_now
      pending_release = available_at > Time.current

      reward_txn = RewardTransaction.create!(
        app: app,
        referral: referral,
        user: referral.referrer_user,
        source_event: webhook_event,
        event_type: :registration,
        idempotency_fingerprint: "registration:#{app.id}:#{referral.id}",
        reward_cents: reward_cents,
        gross_cents: 0,
        status: pending_release ? :pending : :available,
        available_at: available_at,
        metadata: { rule_id: rule.id }
      )

      Ledger::PostEntry.call(
        app: app,
        user: referral.referrer_user,
        entry_type: :credit,
        account_type: pending_release ? :pending_balance : :available_balance,
        amount_cents: reward_cents,
        reference: reward_txn
      )

      RewardReleaseJob.set(wait_until: available_at).perform_later(reward_txn.id) if pending_release

      reward_txn
    end
  end
end
