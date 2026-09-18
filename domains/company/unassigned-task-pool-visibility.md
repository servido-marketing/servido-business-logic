---
id: company-unassigned-task-pool-visibility
domain: company
title: An unassigned company task (no providers assigned) MUST be visible to every worker of that company, not just the assignee
status: active
applies_to: [web, mobile, all]
tags: [company, worker, task, pool, visibility, assignment, isInPool]
supersedes: []
created: 2026-09-02
updated: 2026-09-02
---
## Rule
A company task with zero assigned providers (`providers.length < (requiredProviderCount ?? 1)`,
i.e. `isInPool == true`, per `tasks-multi-sp-gig-slots`) MUST be visible in the task list of
EVERY worker belonging to that company — not only workers explicitly present in `providers`.
Once a worker (or enough workers to fill `requiredProviderCount`) is assigned via
`assignProvider`, the task drops out of the company-wide pool and is visible only to the
assigned worker(s), exactly as today's single-provider gig.

## Rationale
Company managers create tasks without assigning a worker inline (`tasks-multi-sp-gig-slots`
removed `workerId`/`assistantWorkerIds` from `issueCompanyTask`). Today the worker panel's task
list only queries `providers array-contains me`, so an unassigned task is invisible to every
worker until a manager separately calls `assignProvider` — with no way for a worker to see or
volunteer for open work, and no visible symptom to the manager (the gig just silently
disappears from every worker's view). Company crews need the same self-service pickup pattern
marketplace/local providers already have via the jobs pool.

## Implementation
- **Query**: the worker panel's task list (`BondWorkerTasksListBloc` /
  `apps/web/lib/model/repos.dart`'s `providerTasks`) MUST be the union of two queries scoped to
  the worker's company subcollection (`companies/{companyId}/provider_tasks`):
  1. `providers array-contains <workerId>` (tasks already assigned to me) — existing query.
  2. `isInPool == true` (every unassigned/under-slotted company task) — new query, NOT filtered
     by provider id; every worker in the company sees the same open pool.
  Merge + de-duplicate by task id (a task can theoretically satisfy both once partially staffed
  with `requiredProviderCount > 1`).
- **Backend**: no change needed — `isInPool` is already derived correctly per
  `tasks-multi-sp-gig-slots` (`task.providers.length < (task.requiredProviderCount ?? 1)`).
  This card is purely about the missing client-side query.
- **Assignment**: a worker MAY self-assign from the pool (mirroring `pickTaskAsProvider` for
  marketplace/local) OR a manager may call `assignProvider` — either path appends to
  `providers` and the task drops out of every other worker's pool view once
  `providers.length >= requiredProviderCount`.
- **Visual distinction**: pool tasks (not yet assigned to me) SHOULD be visually distinguished
  from tasks already assigned to me in the worker's list (e.g. a badge or separate section),
  matching the existing jobs-pool pattern for marketplace/local providers.

## Verification
- A company manager creates a task with no assignee (`providers: []`). Every worker belonging
  to that company sees the task in their task list, not only a designated assignee.
- Once a worker is assigned via `assignProvider` (bringing `providers.length >=
  requiredProviderCount`), the task disappears from every OTHER worker's pool view and remains
  visible only to the assigned worker(s).
- A `requiredProviderCount > 1` task with some but not all slots filled stays visible in every
  unassigned worker's pool view until fully staffed.
- Refreshing the page after assignment does not resurrect the task in a non-assigned worker's
  list (no stale client-side cache masking the query result).
