module Rewards
  class ApplySubscriptionReward
    def self.call(webhook_event:)
      payload = webhook_event.payload
      app = webhook_event.app

      referral = Referral.find_by!(app: app, external_user_id: payload.fetch("external_user_id"))
      rule = app.reward_rules.enabled.active.find_by!(event_type: :subscription)

      amount_cents = payload.fetch("amount").to_i
      reward_cents = Rewards::CalculateReward.call(rule: rule, amount_cents: amount_cents)
      transaction_id = payload.fetch("transaction_id")

      reward_txn = RewardTransaction.create!(
        app: app,
        referral: referral,
        user: referral.referrer_user,
        source_event: webhook_event,
        event_type: :subscription,
        external_transaction_id: transaction_id,
        idempotency_fingerprint: "subscription:#{app.id}:#{transaction_id}",
        reward_cents: reward_cents,
        gross_cents: amount_cents,
        status: :available,
        available_at: Time.current,
        metadata: { rule_id: rule.id }
      )

      Ledger::PostEntry.call(
        app: app,
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

