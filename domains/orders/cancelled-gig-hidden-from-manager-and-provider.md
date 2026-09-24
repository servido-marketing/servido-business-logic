---
id: orders-cancelled-gig-hidden-from-manager-and-provider
domain: orders
title: A cancelled gig must disappear from manager and provider (SP) panel task lists
status: active
applies_to: [web, mobile, all]
supersedes: []
created: 2026-09-24
updated: 2026-09-24
tags: [orders, cancel, manager, provider, visibility, panel]
---
## Rule
Once a task is cancelled (`isCancelled == true`, set by the `TaskCanceled` event via
`deriveManagerState`/`deriveProviderState`/`deriveCustomerState` in `stateDeriver.ts`),
it MUST NOT appear as an active/visible task in ANY panel list — manager panel, provider
(SP) panel, or customer preview — regardless of the task's `state` field. Cancellation
does not change `state`; `state` and `isCancelled` are independent fields and both must
gate visibility everywhere a task list is queried or filtered.

## Rationale
`TaskCanceled` only ever sets `isCancelled = true` in every deriver — it never
transitions `state` (no `cancelled` value exists in `ServicesManagerTaskState` /
`ProviderTaskState`). Every list query that filters solely on
`state != 'archived'` (manager: `manager_tasks`/`workerTasks`/`unpaidManagerTasks`;
provider: `providerTasks`/`companyUnassignedProviderTasks`/`offeredProviderTasks`) is
blind to cancellation and keeps showing the cancelled gig as if it were still active.
The customer-side `TaskPreviewMapping.make` already special-cases this correctly
(`if (backTask.isCancelled ?? false) return null;`) — manager/provider paths lack the
equivalent guard.

## Implementation
Firestore does not support a compound `!=`-on-two-fields query cheaply here, so filter
`isCancelled` client-side, mirroring `TaskPreviewMapping.make`'s existing pattern:
- `apps/apps/web/lib/model/repos.dart`: in `_managerTasks`'s `makeEntity` (and any
  other `ManagerTask`/`ProviderTask` `makeEntity` callback not already routed through
  it — `providerTasks`, `companyUnassignedProviderTasks`, `offeredProviderTasks`), add
  `if (task.isCancelled ?? false) return null;` right alongside the existing
  `state == ARCHIVED → null` guard, before mapping `toFront()`.
- Confirm `ManagerTask`/`ProviderTask` front entities and their `toFront()` mappers
  already carry `isCancelled` from the back model (`transaction_types.dart` shows both
  have it) — no new schema field needed, this is a query-filter fix only.

## Verification
Proof shows: (a) cancelling a booked/paid/planned gig (any pre-cancel `state`) removes
it from the manager panel's task list and the assigned provider's (SP) panel task list
within one snapshot update; (b) the same cancelled gig is absent from
`companyUnassignedProviderTasks` (pool) and `offeredProviderTasks` (offer inbox) if it
was in either; (c) a NON-cancelled task in the same `state` remains visible (no
over-filtering); (d) customer preview continues hiding it too (regression check on the
existing `TaskPreviewMapping` guard).
