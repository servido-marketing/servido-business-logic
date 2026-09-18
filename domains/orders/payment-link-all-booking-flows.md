---
id: orders-payment-link-all-booking-flows
domain: orders
title: Manager task projection includes paymentLink for all booking flows
status: active
applies_to: [all]
supersedes: []
created: 2026-06-26
updated: 2026-06-26
tags: [orders, payments, payment-link, manager, booking, marketplace, local-service, conversion, gig]
---

## Rule

Every booking flow that creates a manager task MUST set `paymentLink`, `paymentVerificationLink`, and `paymentExtensionLink` on the manager projection during state derivation.

The affected initial event kinds are: `RegisterConversion`, `GigIntiatedAsProvider`, `TaskBookedFromMarketplaceService`, and `TaskBookedFromLocalService`.

## Rationale

The manager panel relies on `paymentLink` to give the manager a direct link to collect payment from the customer. If any booking flow omits this field in `deriveManagerState`, the manager sees no payment link for those tasks — silently. Conversion and provider-gig flows already set the field; marketplace and local-service bookings were missing it.

## Implementation

In `cf/functions/src/utils/stateDeriver.ts`, function `deriveManagerState`:

- `TaskBookedFromMarketplaceService` branch: add `task.paymentVerificationLink`, `task.paymentLink`, and `task.paymentExtensionLink` using `makePaymentVerificationLink(taskId, ...)` — identical to the pattern in `RegisterConversion` and `GigIntiatedAsProvider`.
- `TaskBookedFromLocalService` branch: same three assignments.

No new events, no schema changes, no migrations needed.

## Verification

For a task created via `bookMarketplaceService`, the manager task projection must have a non-null `paymentLink` value after state derivation.
