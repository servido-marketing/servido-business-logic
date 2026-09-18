---
id: orders-website-task-details-credits-applied
domain: orders
title: Task details display the amount of referral/gift credits applied to the booking
status: active
applies_to: [web]
tags: [orders, credits, credits_ledger, display, task-details, website, referral, redemption]
supersedes: []
created: 2026-08-06
updated: 2026-08-06
---

## Rule

The customer-facing task-details page on the website MUST show, when non-zero, the amount of
credits that were applied to the booking's price. This is a read-only display field — it does
not change the checkout/redemption flow defined in `orders-credits-zero-price-redemption` or
`orders-referral-credits-consuming`.

The value shown is the SAME amount recorded by the `ReferralCreditApplied` event appended during
`validateTask` (`amountCents`, capped at the post-promo price) — not re-derived or re-computed on
the client. When the task has no `ReferralCreditApplied` event, the field is omitted entirely
(no "0.00 €" line).

## Rationale

Credits are already the authoritative accounting mechanism (`credits_ledger`, see
`payments-manager-credit-gift` and `orders-referral-credits-consuming`); customers currently see
the price they paid but have no visibility into how much of it was covered by credits, which is
confusing when a promo/referral discount already appears separately. Surfacing the existing
`ReferralCreditApplied.amountCents` value (already computed and stored) is a read model addition,
not a new accounting decision.

## Implementation

- **Backend (`stateDeriver.ts`):** the `ReferralCreditApplied` event handler currently returns
  without touching `task` (both `deriveCustomerState` and its provider/manager-projection
  siblings). It MUST instead set `task.creditsApplied = event.amountCents` on the projected
  `CustomerTask` (accumulate with `+=` if the event can fire more than once per task; otherwise a
  plain assignment is correct — confirm against `validateTask.ts`'s call sites before choosing).
- **`docs/schemas/customer-task.schema.json`:** new optional integer property `creditsApplied`
  (EUR cents, minimum 0) — "Total referral/gift credits applied to this task's price, mirrors the
  ReferralCreditApplied event(s). Absent or 0 means no credits were applied."
- **Website (`firebaseClient.ts` `CustomerTaskDoc`):** add `creditsApplied?: number` mirroring the
  schema.
- **Website (`taskFormat.ts`):** new `taskCreditsAppliedLabel(task): string | null` — returns a
  formatted currency string (same `formatPrice`/locale convention as `taskPriceLabel`) when
  `task.creditsApplied` is a positive number, else `null`.
- **Website (`TaskDetail.tsx`):** render a new `Field` row (creditsAppliedLabel translation key)
  positioned after the existing price/schedule fields, using the new label helper — omitted
  entirely when the label is `null` (the existing `Field` component already no-ops on falsy
  `value`).
- **i18n:** add `account.detail.creditsAppliedLabel` (fi + en) translation keys.

## Verification

- A task with a `ReferralCreditApplied` event of `amountCents: 1000` shows a "Credits applied:
  10,00 €" (or localized equivalent) row on its task-details page.
- A task with NO `ReferralCreditApplied` event shows no credits row at all (not "0,00 €").
- The displayed amount exactly matches the event's `amountCents`, not a client recomputation.
- `taskCreditsAppliedLabel` returns `null` for `creditsApplied` of `0` or `undefined`.
