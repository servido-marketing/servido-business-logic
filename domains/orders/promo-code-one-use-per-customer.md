---
id: orders-promo-code-one-use-per-customer
domain: orders
title: One-time promo codes are a separate kind with per-customer single-use enforcement
status: active
applies_to: [web]
tags: [promo, discount, coupon, booking, one-time, per-customer, applyPromoCode, checkPromoCode, kind]
supersedes: []
created: 2026-06-29
updated: 2026-06-29
---
## Rule
Promo codes MUST carry an optional `kind` field. When `kind` is `'one-time'`, the
code MUST NOT be applied more than once per customer account. Standard codes (no
`kind` field, or `kind: 'standard'`) have no per-customer usage restriction.

`applyPromoCode` MUST check `promoCode.kind === 'one-time'` and, if so, query
`customer_tasks` for any existing task owned by the caller that already has
`promoCode.code` matching the requested code. If found, it MUST throw
`HttpsError('already-exists', 'Promo code already used.')`.

`checkPromoCode` MUST apply the same kind-conditional lookup: when
`promoCode.kind === 'one-time'` and the requesting customer has already used the
code, it MUST return `{ valid: false }`.

## Rationale
Not all promo codes are intended as single-use. Separating them by kind lets the
manager create multi-use campaign codes alongside genuinely one-time codes without
changing the behavior of existing codes. Only codes explicitly marked `one-time`
enforce the per-customer guard.

## Implementation
- Add `kind?: 'standard' | 'one-time'` to the `promo-code` JSON Schema
  (`docs/schemas/promo-code.schema.json`). Field is optional; absence is equivalent
  to `'standard'`.
- In `applyPromoCode.ts`: after downloading the promo code doc, if
  `promoCode.kind === 'one-time'`, query `customer_tasks` for any doc belonging to
  the caller whose `promoCode.code` matches. Match → throw
  `HttpsError('already-exists', 'Promo code already used.')`.
- In `checkPromoCode.ts`: if the fetched promo code doc has `kind === 'one-time'`,
  perform the same `customer_tasks` lookup for the caller's uid. Match →
  return `{ valid: false }`.

## Verification
A code with `kind: 'one-time'`:
  - Applied twice by the same customer: second `applyPromoCode` call MUST fail;
    the second task MUST NOT have a `PromoCodeApplied` event.
  - `checkPromoCode` after first use MUST return `{ valid: false }` for that customer.
A code without `kind` (or `kind: 'standard'`):
  - Applied twice by the same customer: MUST succeed both times (no guard).
