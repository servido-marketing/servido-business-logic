---
id: orders-sp-panel-hide-old-completed-gigs
domain: orders
title: SP panel MUST hide completed gigs older than 30 days
status: active
applies_to: [web]
tags: [orders, provider, panel, gig, task-list, completed, history, workdone, retention]
supersedes: []
created: 2026-08-10
updated: 2026-08-10
---
## Rule
The provider (SP) panel's task/gig list MUST NOT show a gig whose completion time
(`completionTime`, derived from `workDoneAt`) is more than 30 days in the past. Gigs
completed within the last 30 days remain visible in the finished/completed section as today.
The 30-day window is a rolling cutoff evaluated at load/render time, not a one-time archive.

## Rationale
The SP task list accumulates every gig a provider has ever completed with no cutoff, making
the "finished" section grow unbounded and pushing genuinely recent/actionable items further
down. A 30-day rolling window keeps the list relevant without deleting or archiving the
underlying data — older gigs remain fully accessible via order history / search, only the
default panel list view is trimmed.

## Implementation
- Client-side filter, no new backend callable or schema field: `completionTime` already exists
  on `ProviderTask`/`ManagerTask` front-end entities (derived from `workDoneAt` in
  `mapping.dart`), so the cutoff is computed at read time from `DateTime.now()`.
- In `apps/apps/web/lib/model/repos.dart`, the `providerTasks` repo's `process` callback
  currently partitions into `finished`/`unfinished`. Add a rolling-cutoff filter to the
  `finished` branch: `finished.where((t) => t.completionTime!.isAfter(DateTime.now().subtract(Duration(days: 30))))`.
  Unfinished (active) tasks are never filtered by this rule.
- Do not touch the underlying Firestore query (`provider_tasks` collection where/orderBy) —
  this is a display-layer cutoff, not a data-retention change. No documents are deleted,
  archived, or mutated.
- Same pattern applies to any other provider/worker-facing completed-task list that reuses
  this repo or the same `process`-style finished/unfinished split (e.g.
  `bond_worker_tasks_list_bloc.dart` consumes the same `providerTasks`-shaped repo — confirm at
  implementation time whether it shares this repo instance or has its own query, and mirror the
  fix if it has an independent one).

## Verification
Given a provider with one completed gig `workDoneAt` = 31 days ago and one completed gig
`workDoneAt` = 5 days ago, the SP panel's completed/finished gig list shows only the 5-day-old
gig — the 31-day-old gig is absent. Active (non-completed) gigs are unaffected regardless of age.
