# Referral Management SaaS Architecture (Rails 7)

## 1) High-Level Architecture

```text
3rd-Party Apps
  -> POST /api/v1/webhooks/events (API key + HMAC signature)
  -> Rails API Controllers (thin)
  -> Service Objects (orchestration + business rules)
  -> Sidekiq Jobs (async processing / retries)
  -> PostgreSQL (source of truth)
  -> Redis (queues + rate-limit counters + locks)

Admin Users
  -> ActiveAdmin
  -> User/App/Reward/Cashout/Webhook oversight
```

## 2) Multi-Tenant Design

- Tenant boundary: `apps` table.
- External identity uniqueness is app-scoped: unique `(app_id, external_user_id)`.
- Referral relationships and rewards are app-scoped.
- Per-app reward rules support flat and percentage reward modes.

## 3) Core Entities

- `User`: platform referrer account.
- `App`: third-party client credentials and status.
- `ReferralCode`: unique referral code per user.
- `Referral`: app-scoped referred external user.
- `RewardRule`: app-scoped rules by event type.
- `RewardTransaction`: immutable reward record.
- `LedgerEntry`: accounting source-of-truth rows.
- `CashoutRequest`: payout lifecycle.
- `WebhookEvent`: inbound event journal.
- `IdempotencyKey`: dedupe and replay protection.

## 4) Security Controls

- API key authentication via hashed key lookup.
- HMAC SHA256 webhook signature verification with secure compare.
- Idempotency uniqueness constraint `(app_id, key)`.
- Replay prevention using request timestamp window.
- Strong params + event payload validation.
- Filter sensitive parameters from logs.

## 5) Event Processing Flow

1. Authenticate app via API key.
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
- Per-app throttling to isolate noisy tenants.

## 9) SaaS Monetization

- Free: low event quota, basic rules.
- Growth: higher quota, richer reports.
- Pro: advanced rules, fraud controls.
- Enterprise: SSO/SAML, dedicated workers, SLA.

