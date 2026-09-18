---
id: orders-mobilepay-phone-prefill
domain: orders
title: MobilePay checkout must prefill customer's known phone number
status: active
applies_to: [web]
tags: [orders, payments, payment-link, mobilepay, phone, checkout, conversion, ux]
supersedes: []
created: 2026-07-06
updated: 2026-07-06
---
## Rule
When a customer reaches the payment step of ANY booking flow (conversion, marketplace,
local-service, gig, work-extension) and the payment page is presented with MobilePay as an
available/selected method, and the customer's phone number is already known server-side
(`contactPhone` on the customer/manager task, collected during booking details), the MobilePay
payment element MUST be prefilled with that phone number. The customer may still edit it before
confirming; this only governs the initial value.

## Rationale
The customer already typed their phone number once, earlier in the same booking flow (contact
details step), to let Servido reach them. Asking them to retype it a second time at the MobilePay
step is friction with a known answer — operator-reported UX gap. Prefilling removes a redundant,
error-prone re-entry without touching payment logic.

## Implementation
- `paymentLink` is generated server-side by `makePaymentVerificationLink` in
  `cf/functions/src/bookConversion.ts` and consumed by every booking flow via
  `deriveManagerState` (see `orders-payment-link-all-booking-flows`). Extend
  `makePaymentVerificationLink` with an optional `contactPhone?: string` parameter; when present,
  append it to the generated link as `&contact_phone=<encodeURIComponent(contactPhone)>`.
- Every call site that already has the customer's phone in scope at manager-task derivation time
  (`RegisterConversion`, `GigIntiatedAsProvider`, `TaskBookedFromMarketplaceService`,
  `TaskBookedFromLocalService` branches in `cf/functions/src/utils/stateDeriver.ts`) passes
  `contactPhone` through to `makePaymentVerificationLink`. Read it from the customer/manager task
  projection field that already stores it (existing `contactPhone` field — no new field needed).
- The static payment page `apps/apps/mobile/web/conversion-pay.html` reads `contact_phone` from
  its query params (alongside the existing `task_id`/`pk`/etc. params already read via
  `params.get(...)`) and, when non-empty, passes it into every Stripe Elements group that mounts
  a `mobilepay` payment method (the main `paymentMethodOrder` mount AND the simple-payment
  accordion's single-method mount) as
  `defaultValues: { billingDetails: { phone: contactPhone } }` — Stripe's supported mechanism for
  prefilling a Payment Element's collected billing details. Wallet-only mounts (Apple Pay /
  Google Pay Express Checkout) are unaffected; this only touches `mobilepay`-capable Payment
  Element mounts.
- No new schema, no new event, no migration. `contactPhone` already exists on the manager task
  projection (`docs/transaction-schemas/schemas/services-manager-task.schema.json` — see below);
  only the link-building + query-param plumbing + client prefill are new.

## Verification
1. Booking through any of the four flows with a contact phone number entered, then opening the
   resulting `paymentLink`, shows the MobilePay Payment Element's phone field pre-filled with
   that same number (not empty).
2. If no `contactPhone` was collected (e.g. flow skips contact step), the payment page renders
   with an empty phone field exactly as before — no error, no placeholder garbage.
3. The prefilled value remains editable; submitting a payment after editing it uses the edited
   value (prefill does not lock the field).
