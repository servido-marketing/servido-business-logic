---
id: orders-sp-service-application
domain: orders
title: Providers apply to global services; manager approves/rejects the application before the assignment takes effect
status: active
applies_to: [web]
tags: [orders, provider, services, application, assignment, manager, providers_with_services]
supersedes: []
created: 2026-09-24
updated: 2026-10-10
---
## Rule
A provider (SP) sees the SAME list of global services the manager sees in the manager
services module (`BondServices` / `ServicesSection`), but read-only: no name/price/description/
photo/etc. editing, no delete, no assign-providers action. The only action a provider has per
service is **Apply**. Applying does NOT connect the provider to the service immediately — it
creates a **pending application** that a manager must separately accept or reject in a dedicated
manager-panel module (Applications). Only once accepted does the existing
`providers_with_services` connection (the same collection `assignProvider`'s UI already reads/
writes via `providersByService`/`updateProvidersToServiceAssignment`) get created.

- A provider can be in exactly one of three states per service: **not applied** (Apply button
  shown), **applied / pending** (status label "Applied", button disabled/hidden), **active**
  (status label "Active" — already connected in `providers_with_services`, no Apply control at
  all since the provider already offers that service).
- Applying MUST NOT create a `providers_with_services` row directly — it creates a
  `service_applications/{id}` document with `{service, provider, status: 'pending', createdAt}`.
  The connection is only made when a manager accepts.
- A provider may not submit a second pending application for a service they already have a
  pending application for, nor for a service they are already active on.
- The manager-panel Applications module lists all `pending` applications (service + applicant
  provider identity) with Accept / Reject actions.
  - Accept: creates the `providers_with_services` row for that (provider, service) pair (reuse
    the exact same write `updateProvidersToServiceAssignment` already does for one added pair)
    and marks the application `status: 'accepted'`.
  - Reject: marks the application `status: 'rejected'`, does not touch `providers_with_services`.
  - Once resolved (accepted/rejected) an application leaves the pending list; a rejected
    provider MAY apply again later (rejection does not permanently block re-application).

- **Finnish copy**: the Apply button reads **"Hae"** (the status label for the pending state is
  "Haettu", already in use; "Aktiivinen" for active). The provider-application button MUST NOT
  reuse the promo-code "Käytä" ("use/redeem"), which means redeeming something, not requesting to
  join a service. The two UIs use separate l10n keys (`applyToService` vs. promo `apply`).

## Rationale
Manager-curated service assignment (already the case via `assignProvider`'s provider-picker)
should also be reachable from the provider's side as a self-service request, without letting
providers unilaterally attach themselves to services — the manager keeps the final say, matching
the existing trust model where only a manager can create a `providers_with_services` link.

## Implementation
- New Firestore collection `service_applications` (fields: `service: string` (service id),
  `provider: string` (provider id), `status: 'pending' | 'accepted' | 'rejected'`,
  `createdAt: number`, `resolvedAt: number | null`).
- New callables (guarded, in `cf/functions/src/`):
  - `applyToService(request: { service: string })` — `guard.provide`, resolves `provider =
    request.auth.uid`, rejects if a pending application or active `providers_with_services` row
    already exists for that pair, else creates the `service_applications` doc.
  - `resolveServiceApplication(request: { applicationId: string, accept: boolean })` —
    `guard.manage`; on `accept: true` writes the `providers_with_services` row (mirroring
    `updateProvidersToServiceAssignment`'s add-one-pair shape) and sets `status: 'accepted'`; on
    `accept: false` sets `status: 'rejected'`. Both set `resolvedAt`.
- `docs/schemas/service-application.schema.json`: the `service_applications` doc shape above.
- `docs/transaction-schemas/apply-to-service-request.schema.json`: `{ service: string }`.
- `docs/transaction-schemas/resolve-service-application-request.schema.json`:
  `{ applicationId: string, accept: boolean }`.
- Provider-panel: new read-only services module (mirrors `BondServices`/`ServicesSection` but
  `isReadOnly: true`, `canAdd: false`, no delete/edit/assign-providers accessory) with a status
  column (`Applied` / `Active`, computed from whether the provider has an active
  `providers_with_services` row for that service, or a pending `service_applications` row) and
  an Apply button (hidden once `Applied` or `Active`) wired to `applyToService`.
- Manager-panel: new Applications module (sibling to the existing `services`/`services_visibility`
  bond modules) listing pending `service_applications`, each row showing the service + applicant
  provider identity, with Accept/Reject buttons wired to `resolveServiceApplication`.

## Verification
- A provider who has never applied to a service sees an Apply button and no status label; in the
  Finnish locale the button text is "Hae" and never "Käytä"; the promo-code apply button still
  reads "Käytä".
- Clicking Apply creates a `pending` `service_applications` doc, does NOT create a
  `providers_with_services` row, and the provider's list now shows "Applied" (no Apply button).
- The provider CANNOT edit/delete/preview details of any service in this module — only status +
  Apply are visible/interactive.
- The manager's new Applications module shows the pending application; clicking Accept creates
  the `providers_with_services` row for that (provider, service) pair and removes it from the
  pending list; the provider's list now shows "Active" for that service.
- Clicking Reject instead removes it from the pending list without creating a
  `providers_with_services` row; the provider's list reverts to showing the Apply button again.
- A provider with an existing pending application, or already `Active` on a service, cannot
  submit another `applyToService` call for that same service (rejected server-side).
