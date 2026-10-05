---
id: tasks-global-gig-single-sp-assignment
title: Global gigs accept exactly one SP; assignment replaces, not appends
domain: tasks
status: active
applies_to: [all]
supersedes: []
tags: [tasks, provider-assignment, global-gig, multi-sp]
created: 2026-10-05
---

# Global gigs accept exactly one SP; assignment replaces, not appends

## Rule

MUST: when a task is a **global gig** (a non-company gig — `task.companyService` /
`task.companyCustomerId` absent, i.e. not a multi-SP company job with a
`requiredProviderCount` slot pool), assigning a provider to it via `assignProvider`
MUST **replace** the task's single provider slot, not append to a list.

A global gig has exactly one provider seat for its lifetime. If a provider is already
assigned and a different provider is assigned afterward (e.g. a manager reassigns an
unavailable SP), the new assignment REPLACES the old one — `task.providers` must end up
as `[newProvider]`, never `[oldProvider, newProvider]`.

MUST NOT: apply the multi-SP append/accumulate behavior (`task.providers = [...(task.providers ?? []), event.provider]`,
dedup via `Set`/`filter`) to a global gig. That accumulation behavior is reserved for
company gigs where `requiredProviderCount > 1` and multiple SPs can legitimately hold
concurrent slots on the same task (see `tasks-multi-sp-gig-slots`, company multi-worker
jobs).

## Rationale

The multi-SP gig-slots feature (company tasks with `requiredProviderCount`) introduced
an accumulate-into-list `ProviderAssigned` reducer across all task projections
(customer/provider/manager). That reducer is correct for company tasks with multiple
worker slots, but it was never gated on "is this a company task" — so it silently
started applying to global (non-company, single-SP) gigs too. A global gig assigned to
provider A, then reassigned to provider B, ended up showing BOTH A and B as assigned
providers instead of only B — breaking the single-SP invariant global gigs have always
had.

## Implementation

- Discriminant: a task is a **global gig** when it has no `companyService` /
  `companyCustomerId` (i.e. wasn't created via `CompanyTaskIssued`/`CompanyTaskUpdated`)
  — equivalently, `requiredProviderCount` is unset/1 and the task's origin event is not a
  company-issued event (`GigIntiatedAsProvider`, `TaskBookedFromMarketplaceService`,
  `TaskBookedFromLocalService`, `RegisterConversion` initial events are all global-gig
  origins).
- In `cf/functions/src/utils/stateDeriver.ts`, every `ProviderAssigned` branch (customer
  task deriver, provider task deriver, manager task deriver — 3 occurrences) must branch
  on this discriminant:
  - Global gig: `task.providers = [event.provider]` (replace, not append). Also replace
    `task.providerNames` with `event.providerName ? [event.providerName] : []` rather
    than accumulating via `Set`.
  - Company/multi-SP gig (existing behavior, unchanged): keep the current
    append-and-dedup logic gated on `requiredProviderCount`/company origin.
- `cf/functions/src/assignProvider.ts`'s pre-checks (`taskData.providers?.includes(...)`,
  "Provider already assigned" guard) only need to reject re-assigning the SAME provider
  twice; reassigning to a DIFFERENT provider on a global gig is a legitimate replace and
  must not be blocked by those guards once the deriver is fixed.

## Verification

- Assigning provider A to a fresh global gig → `task.providers === ['A']` on all three
  projections (customer/provider/manager).
- Reassigning the same global gig from provider A to provider B → `task.providers ===
  ['B']` (A is gone, not `['A','B']`) on all three projections.
- A company multi-SP gig with `requiredProviderCount: 2` assigning provider A then
  provider B still ends with `task.providers === ['A','B']` (unchanged, regression
  guard for the existing multi-SP feature).
