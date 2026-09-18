---
id: orders-promo-code-booking-flow
domain: orders
title: Promo codes are validated server-side via applyPromoCode after booking
status: active
applies_to: [web]
tags: [promo, discount, coupon, booking, website, applyPromoCode]
supersedes: []
created: 2026-06-26
updated: 2026-06-29
---
## Rule
A customer MAY enter a promo code during the booking flow. The code is submitted
server-side via the `applyPromoCode` callable AFTER the task is created and
scheduled. A failed or missing promo code MUST NOT block or fail the booking.

When a promo code is applied, the booking UI MUST display:
1. The promo code name (code string) alongside the discounted price.
2. The original price struck through next to the discounted price.

The order details page MUST also display the applied promo code name.

## Rationale
- The task is created before payment; applying the promo code post-booking
  lets the booking succeed even when a code is wrong, avoiding data loss.
- Validation is server-side only — client must never guess whether a code is valid.
- A non-fatal path (`promoFailed`) surfaces a UI warning without rolling back.
- Showing the promo code name in booking UI and order details confirms to the
  customer which code was applied and what discount they received.

## Implementation
- The website's `BookingStepLocation` component accepts a promo code string and
  stores it in wizard state. The `applyPromo` handler calls the `applyPromoCode`
  callable and updates state on success; on failure it shows an inline error and
  lets the customer remove/re-enter the code. The stored code is cleared on remove.
- `firebaseClient.ts` `finalizeBooking` and `finalizeOrderAgainBooking` BOTH call
  `applyPromoCode(taskId, code)` when a code is present. On `HttpsError` or
  non-success result, they set `promoFailed: true` on the result (non-fatal).
- An invalid / unknown code shows an inline validation error in the UI.
- The booking completes regardless of whether the promo code application succeeds.
- In the booking wizard header summary (step < 4), when `promoDiscount` is set,
  the promo code name (`state.promoCode`) MUST appear as a small badge/label
  alongside the price display.
- In `TaskDetail.tsx`, when `task.promoCode?.code` is present, it MUST be shown
  in the order details section alongside or below the price.

## Verification
A booking with a valid promo code MUST have a `PromoCodeApplied` event on the task.
A booking with an invalid code MUST still complete (task created, payment proceeds)
and `promoFailed` MUST be set on the booking result.
The booking UI header MUST show the promo code name when a discount is active.
The order details page MUST show the promo code name when `task.promoCode.code` exists.
