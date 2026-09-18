---
id: orders-referee-discount-price-display
domain: orders
title: Referee's discount banner MUST be paired with a discounted price everywhere the price header renders
status: active
applies_to: [web]
tags: [referral, referee, discount, price, booking, order, wizard, ui]
supersedes: []
created: 2026-07-07
updated: 2026-07-07
---
## Rule
Whenever the website shows the referral discount banner/label to a referee (a visitor who
arrived via a referral link, tracked by `sessionStorage.servido_ref`), every price header that
renders on the SAME page/flow MUST also show the discounted price — struck-through original
price + discounted price + the referral bonus label — using the same precedence as the booking
wizard: promo code discount (highest priority) > referral discount > credit-balance discount.
A referee MUST NOT see the discount banner/badge with no corresponding price reduction anywhere
on that page.

## Rationale
The discount banner is a promise of savings. If a price header on the same page ignores the
referral flag while another one (e.g. the pre-booking wizard) already applies it, the customer
sees a broken promise — banner present, full price shown — and loses trust in the checkout.
The order/task page (post task-creation, used for finishing payment) is a DIFFERENT component
from the pre-booking wizard, so a fix to one does not automatically fix the other; the rule
must apply to every price header component, not just the one it was authored against.

## Implementation
- `OrderWizard.tsx`'s price header (`priceLabel`/`priceCents` derived discount block, the one
  rendered in the step<5 summary bar) MUST read `sessionStorage.getItem('servido_ref')` the same
  way `RealBookingWizard.tsx` already does, and apply a referral discount using
  `applyPromoDiscount(priceCents, currency, { discount: { value: 1000, currency } })` when no
  promo code discount is active, mirroring the precedence chain already implemented in
  `RealBookingWizard.tsx` (`discounted ?? referralDiscounted ?? creditDiscounted`).
- When the referral discount is the active discount, show the `wizard.booking.referralBonus`
  label under the discounted price, exactly as `RealBookingWizard.tsx` already does.
- Do not change `RealBookingWizard.tsx`'s existing referral logic — it is already correct; this
  card closes the gap in `OrderWizard.tsx` only.
- No backend/schema change is required — `validateTask`'s referral-credit consumption
  (see `orders-referral-credits-consuming`) is unaffected; this rule is about the CLIENT-SIDE
  discount preview shown before payment, matching what the wizard already previews.

## Verification
On the order page (`/[lang]/order/[taskId]`), for a session with `servido_ref` set in
`sessionStorage` and no active promo code and zero credit balance: the price header MUST show
the original price struck through, a discounted price (original − 10 EUR, floored at 0), and the
`wizard.booking.referralBonus` label — matching what the pre-booking wizard (`/[lang]/varaa/[id]`)
already shows for the same session state.
