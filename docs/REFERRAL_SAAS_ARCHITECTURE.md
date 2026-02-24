# Referral Management SaaS Architecture (Rails 7)

## 1) High-Level Architecture

```text
3rd-Party Apps
  -> POST /api/v1/webhooks/events (HMAC signature)
  -> Rails API Controllers (thin)
  -> Service Objects (orchestration + business rules)
  -> Sidekiq Jobs (async processing / retries)
  -> PostgreSQL (source of truth)
  -> Redis (queues + rate-limit counters + locks)

Admin Users
  -> ActiveAdmin
  -> User/SystemConfig/Reward/Cashout/Webhook oversight
```

## 2) Single-Tenant Design

- The platform uses one canonical `system_configs` row.
- Webhook intake and signing are controlled by singleton `system_configs.webhook_secret`.
- Referral and reward records are global to the single-tenant deployment.
- Reward rules are global by event type.

## 3) Core Entities

- `User`: platform referrer account.
- `SystemConfig`: singleton webhook/security configuration.
- `ReferralCode`: unique referral code per user.
- `Referral`: referred external user.
- `RewardRule`: rules by event type.
- `RewardTransaction`: immutable reward record.
- `LedgerEntry`: accounting source-of-truth rows.
- `CashoutRequest`: payout lifecycle.
- `WebhookEvent`: inbound event journal.
- `IdempotencyKey`: dedupe and replay protection.

## 4) Security Controls

- Singleton config resolution via `SystemConfig.current`.
- HMAC SHA256 webhook signature verification with secure compare.
- Idempotency uniqueness constraint `(key)`.
- Replay prevention using request timestamp window.
- Strong params + event payload validation.
- Filter sensitive parameters from logs.

## 5) Event Processing Flow

1. Resolve singleton system config.
2. Verify HMAC signature.
3. Validate timestamp freshness.
4. Persist `webhook_events` as received.
5. Reserve idempotency key.
6. Enqueue processing job.
7. Apply registration/subscription reward logic.
8. Create `reward_transactions` and `ledger_entries` atomically.
9. Mark webhook event status.

## 6) Ledger Rules

- Ledger is append-only.
- Reversals are compensating entries, never destructive updates.
- `users.available_cents`, `users.pending_cents`, and `users.total_earned_cents` are cached projections.

## 7) Background Jobs

- `WebhookProcessJob`: main event processor.
- `RewardReleaseJob`: pending -> available release.
- `CashoutPayoutJob`: payout integration hook.
- `FraudScanJob`: heuristic checks and anomaly flagging.

## 8) Scaling Notes

- Horizontal Rails + Sidekiq workers.
- Partition heavy append tables (`webhook_events`, `ledger_entries`) in future.
- Add read replicas for analytics/admin-heavy reads.
- Global webhook throttling for single-tenant ingress.

## 9) SaaS Monetization

- Free: low event quota, basic rules.
- Growth: higher quota, richer reports.
- Pro: advanced rules, fraud controls.
- Enterprise: SSO/SAML, dedicated workers, SLA.
