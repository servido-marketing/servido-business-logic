---
id: orders-referral-credits-consuming
domain: orders
title: Referral credits are consumed during validateTask, after promo discounts, via a credits ledger
status: active
applies_to: [all]
tags: [referral, credits, discount, validateTask, ledger, share-and-earn, promo, booking]
supersedes: []
created: 2026-07-01
updated: 2026-07-01
---
## Rule
When a customer calls `validateTask`, the backend MUST check their referral credit balance
and, if positive, apply a credit discount to the task price. Credits MUST be applied AFTER
any promo code discount — i.e. the credit deduction is calculated on the post-promo price.

Every credit movement (earned or spent) MUST be recorded in a top-level Firestore collection
`credits_ledger`. Each ledger entry contains:
- `customerId` — the customer whose balance changes
- `price` — integer EUR cents (positive = earned, negative = consumed)
- `event` — one of two kinds:
  - `claimed`: credits earned by the referrer after referee's first successful payment;
    MUST include `taskId` of the referrer's triggering task
  - `consumed`: credits deducted at validateTask time;
    MUST include `taskId` of the referee's (payer's) task

The customer's running credit balance is derived from summing all their `credits_ledger` entries,
NOT stored as a denormalized field (no `referralCredits` field on the customer doc is used for
balance purposes — ledger is the source of truth).

A `ReferralCreditAppliedEvent` MUST be appended to the task's event log when credits are consumed.

## Rationale
- Applying credits after promos ensures promos are fully honored first; credits top up the discount.
- A ledger collection gives an auditable history of every credit movement, enabling refunds and
  disputes to be resolved without reconstructing state from task events.
- Separating claimed vs consumed events with taskId references makes the link between referrer
  reward and referee booking explicit for operations/support.

## Implementation
- `validateTask` callable: after completing existing validation, read all `credits_ledger` docs
  for the current user. Sum prices → `balanceCents`. If `balanceCents > 0`, compute the
  post-promo price from the task, cap the credit deduction at `min(balanceCents, postPromoPrice)`,
  write a `consumed` ledger entry with the task's `taskId`, append a `ReferralCreditAppliedEvent`
  to the task, and return `creditsApplied: amountCents` in the response.
- On `stripeWebHook` payment success (the referral grant path): write a `claimed` ledger entry for
  the referrer with `taskId` of the referrer's task when `ReferralCreditGranted` fires.
- `credits_ledger` collection rules: server-side only (clients MUST NOT write directly).
- The `validateTask` response schema MUST include `creditsApplied?: number` (EUR cents).
- The `ReferralCreditAppliedEvent` schema already exists in docs/schemas.

## Verification
After `validateTask` for a customer with a positive credit balance:
- A `credits_ledger` document with `event.kind === 'consumed'` and the correct `taskId` MUST exist.
- A `ReferralCreditAppliedEvent` MUST appear in the task's event log.
- The `validateTask` response MUST contain `creditsApplied > 0`.
- The credit amount applied MUST NOT exceed the post-promo task price.
After a referee's first successful payment (referral grant path):
- A `credits_ledger` document with `event.kind === 'claimed'` and the referrer's `taskId` MUST exist.
