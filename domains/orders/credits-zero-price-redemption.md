---
id: orders-credits-zero-price-redemption
domain: orders
title: When credits cover the full booking price, validateTask consumes them and redeemTask bypasses payment
status: active
applies_to: [web, mobile, all]
tags: [orders, credits, referral, payment, redemption, zero-price, validateTask, redeemTask, gig]
supersedes: []
created: 2026-07-02
updated: 2026-07-02
---

## Rule

When `validateTask` computes that the customer's credit balance covers the full task price
(`creditsApplied >= priceToPay`), it MUST consume those credits immediately and return
`canRedeemWithCredits: true`. Clients receiving this flag MUST skip the Stripe payment flow
entirely, show a "covered by credits" UI, and call `redeemTask(taskId)` to finalize.

`redeemTask` is a complete bypass for the payment process. It appends a `TaskRedeemed` event —
a distinct event from `TaskPaymentRecorded` — which transitions the task to a redeemed/paid state
without involving Stripe. `TaskRedeemed` MUST NOT be confused with `TaskPaymentRecorded`; the
latter records actual money movement while `TaskRedeemed` records a credit-funded settlement.

Partial credits (credits < price) still route to Stripe as normal with the reduced price.
`redeemTask` MUST be called only for tasks where credits were fully consumed by `validateTask`.

## Rationale

Consuming credits in `validateTask` is authoritative and atomic — by the time the client gets
`canRedeemWithCredits: true`, the credits are already spent, preventing double-spend from
concurrent sessions. `redeemTask` then just records the final outcome. Using a dedicated
`TaskRedeemed` event keeps the event log semantically precise: payment events record money
movement, redemption events record credit settlement. This separation matters for accounting,
analytics, and future rule matching.

## Implementation

- **Backend (`validateTask.ts`):** After computing `creditsApplied`, if `creditsApplied >= postPromoPrice`:
  deduct credits from the customer's balance, return
  `{ success: true, customerTask, creditsApplied, canRedeemWithCredits: true }`.
- **Backend (new `redeemTask.ts`):** Accepts `{ taskId }`. Validates that the task was validated
  with full credit coverage (credits already consumed). Appends a `TaskRedeemed` event
  (new event type, bypasses payment). Returns `{ success: true }`.
- **New `task-redeemed-event.schema.json`** — event schema for `TaskRedeemed`, distinct from
  `TaskPaymentRecorded`. No `payment` field; records credit-funded settlement.
- **`validateTask` response schema** gains optional boolean field `canRedeemWithCredits`.
- **New `redeem-task-request.schema.json`** with required field `taskId: string`.
- **Mobile (`bond_checkout_bloc.dart`):** After `validateTask`, if `canRedeemWithCredits` is true,
  show a "covered by credits" screen with a Redeem button. On tap, call `redeemTask(taskId)`,
  then navigate to ContinueToOrderPlaced.
- **Website (`firebaseClient.ts finalizeBooking`):** After `validateTask`, if `canRedeemWithCredits`
  is true, skip `initializeOrderPayment`, show credits-cover UI with a "Redeem" button, and on
  confirm call `redeemTask(taskId)` before navigating to order-placed.

## Verification

- `validateTask` consumes credits from the customer's balance when credits >= full price.
- `validateTask` returns `canRedeemWithCredits: true` after consuming credits.
- After `redeemTask` is called, the task event log contains a `TaskRedeemed` event (NOT `TaskPaymentRecorded`).
- After `redeemTask` is called, the task is in a redeemed/paid state.
- A customer with partial credits (credits < price) is sent to Stripe with the reduced price.
- The Stripe payment flow is NOT invoked at any point when `canRedeemWithCredits` is true.
