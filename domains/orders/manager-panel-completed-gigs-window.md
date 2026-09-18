---
id: orders-manager-panel-completed-gigs-window
domain: orders
title: Manager panel completed-gigs list uses a 30-day rolling window, not 7 days
status: active
applies_to: [web]
tags: [orders, manager, panel, gig, task-list, completed, workdone, retention]
supersedes: []
created: 2026-08-11
updated: 2026-08-11
---
## Rule
The manager panel's "Completed gigs" tab MUST show completed gigs whose `workDoneAt` falls
within the last 30 days (1 month), not the last 7 days. The window is a rolling cutoff
evaluated at load/render time, not a one-time archive. Older completed gigs remain fully
accessible via order history / search — only the default panel list view is trimmed.

## Rationale
The previous 7-day cutoff was too aggressive for managers, who need visibility into a full
month of completed work (billing/reconciliation cadence, monthly reviews). This mirrors the
existing SP-panel rule (`orders-sp-panel-hide-old-completed-gigs`, 30-day window) so both
panels use a consistent retention window for their completed/finished gig lists.

## Implementation
- Client-side query change only, no new backend callable or schema field.
- In `apps/apps/web/lib/model/repos.dart`, the `completedManagerTasks` repo's Firestore query
  currently filters `workDoneAt` greater than `DateTime.now().subtract(Duration(days: 7))`.
  Change `Duration(days: 7)` to `Duration(days: 30)`.
- Do not touch anything else in the query (collection, field name, comparison operator).

## Verification
Given a manager with one completed gig `workDoneAt` = 29 days ago and one completed gig
`workDoneAt` = 31 days ago, the manager panel's "Completed gigs" tab shows only the 29-day-old
gig — the 31-day-old gig is absent. Active (non-completed) gigs are unaffected regardless of age.
