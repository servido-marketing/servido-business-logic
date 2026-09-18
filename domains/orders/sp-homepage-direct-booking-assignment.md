---
id: orders-sp-homepage-direct-booking-assignment
domain: orders
title: Booking from a provider's public /tekijat page pre-assigns that provider at booking time
status: active
applies_to: [web]
tags: [orders, booking, provider, assignment, tekijat, sp-homepage, marketplace, bookMarketplaceService]
supersedes: []
created: 2026-09-10
updated: 2026-09-10
---
## Rule
Booking a service from a provider's public `/tekijat/[id]` page uses the SAME booking flow as
the normal marketplace flow (`bookMarketplaceService` → `scheduleTask` → `validateTask` →
`initializeOrderPayment`), with exactly one difference: the task MUST be assigned to that
provider immediately at booking time, instead of entering the unassigned pool.

- `bookMarketplaceService` accepts an optional `preferredProviderId` field on its request.
- When present, after the initial `TaskBookedFromMarketplaceService` event is appended, the
  backend appends a provider-assignment event for that provider using the SAME offer-vs-direct
  gate `assignProvider` already applies: a company worker gets `TaskOffered` (must accept), a
  non-company provider gets `ProviderAssigned` directly. This keeps company-worker consent
  semantics identical to the manager-assignment path — the customer picking a specific provider
  does not bypass that provider's own accept step.
- If `preferredProviderId` does not resolve to an existing `providers/{id}` doc, the request
  fails the same way an invalid `serviceId` would (no task created) — never silently falls back
  to unassigned pool.
- No other step of the booking flow changes: price, schedule, recurrence, payment, validation
  are identical to booking the same service without a preferred provider.

## Rationale
Customers can already discover a specific provider via `/tekijat/[id]` and see their live
availability. Booking without landing that customer with the SAME provider defeats the purpose
of a provider-specific page — the customer chose the person, not just the service.

## Implementation
- `docs/transaction-schemas/book-marketplace-service-request.schema.json`: add optional
  `preferredProviderId: string`.
- `cf/functions/src/bookMarketplaceService.ts`: after `appendEventToTask` for the booking event,
  if `request.data.preferredProviderId` is set, resolve the provider doc and append the
  assignment event via the same gate logic `assignProvider.ts`'s `assignProviderToOccurrence`
  uses (share/extract that helper rather than duplicating the company-vs-direct branch).
- Website `/tekijat/[id].astro` "Book this slot" button (`#b-go`) calls `bookMarketplaceService`
  via the existing `customerHotline`-routed `callable()` wrapper, passing
  `preferredProviderId: provider.id` alongside `serviceId`, then continues the existing
  `scheduleTask → validateTask → initializeOrderPayment` sequence unchanged.

## Verification
- Booking a service from `/tekijat/[id]` for a non-company provider results in a task whose
  `provider_tasks/{id}` (or `manager_tasks/{id}.providers`) shows that exact provider assigned
  immediately after booking, before payment.
- Booking the same service from the normal marketplace page (no `preferredProviderId`) still
  results in an unassigned/pooled task, unchanged from current behavior.
- Booking from a COMPANY worker's `/tekijat/[id]` page results in `TaskOffered` to that worker,
  not an immediate `ProviderAssigned` — matching `assignProvider`'s existing company gate.
