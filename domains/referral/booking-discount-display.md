---
id: referral-booking-discount-display
domain: referral
title: Referral discount MUST be shown in the booking wizard payment step
status: active
applies_to: [web]
tags: [referral, share, discount, booking, wizard, website, ux, payment]
supersedes: []
created: 2026-07-02
updated: 2026-07-02
---

## Rule

When a visitor arrives via a referral link (`servido_ref` in sessionStorage) OR when a
logged-in user has a positive `referralCredits` balance, the booking wizard's price
summary MUST display the referral discount line — the same way promo code discounts are
rendered: original price struck through + discounted price displayed + discount label.

The discount amount shown is always exactly 10 EUR (1000 cents) — the fixed referral
credit grant — regardless of the customer's actual Firestore balance (which the anonymous
booking user does not have yet).

The referral discount line MUST NOT be shown simultaneously with a promo code discount.
If a promo code is active, the promo line takes precedence and the referral line is hidden
(the credits will still be applied server-side at payment, but showing two discount lines
would be confusing and one is already a non-trivial UX). If the customer removes the promo
code, the referral line reappears.

## Rationale

The referral credit (10 EUR) is already applied automatically at payment by the backend
(`handleReferralCreditsOnPayment` in `stripeWebHook.ts`). The customer is not informed
of this reduction during booking — they see the full price at the wizard's payment step.
This is a conversion risk: a user expects to see the discount they were promised by the
badge, and not seeing it at checkout may cause abandonment or confusion.

The referral-landing-badge rule already shows the discount on arrival. This rule closes
the funnel by confirming the discount in the booking wizard.

## Implementation

Both `OrderWizard.tsx` (the `/tilaukset/[taskId]` flow) and `RealBookingWizard.tsx`
(the `/varaa/[id]` flow) show a price summary at the payment step.

1. Add a `referralDiscount: boolean` field to `BookingState` in both wizards, defaulting
   to `false`.

2. On wizard mount (or on reach of the payment step), check:
   a. `sessionStorage.getItem('servido_ref')` is non-empty — referral session active.
   b. OR `fetchCustomerReferralCredits()` returns a value > 0 (for returning users
      with accumulated credits).
   Set `referralDiscount: true` in state when either condition holds.

3. In the price summary UI (the same block that renders promo discount):
   - When `state.referralDiscount && !state.promoDiscount`: render the referral discount
     line. Display the formatted discounted price (original minus 1000 cents) and a label
     "-€10 referral discount" (fi: "-10 € suositteluetu").
   - When both `referralDiscount` and `promoDiscount` are truthy: show only the promo
     discount line (promo wins visually; referral credits are still applied server-side).
   - When neither: show the full price with no discount line.

4. Reuse the existing `applyPromoDiscount` utility's logic to compute the discounted price
   (subtract 1000 cents from the configured price, floor at 100 cents).

## Verification

- Visiting `/varaa/[id]` with `?ref=TESTCODE` in the URL (so sessionStorage is set) and
  proceeding to the payment step MUST show the discounted price (original struck through)
  and the "-€10 referral discount" label.
- Applying a promo code while referral discount is active: promo line shows, referral line
  disappears.
- Removing the promo code: referral line reappears.
- Without `servido_ref` in sessionStorage and `referralCredits` is null/0: no discount
  line shown (no regression on normal flow).
- The discount line appears in BOTH wizard flows (`OrderWizard` and `RealBookingWizard`).
