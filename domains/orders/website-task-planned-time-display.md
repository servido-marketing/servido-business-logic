---
id: orders-website-task-planned-time-display
domain: orders
title: Website shows the planned time once a task is planned
status: active
applies_to: [web]
tags: [orders, scheduling, task, planned, display, website, account]
supersedes: []
created: 2026-07-09
updated: 2026-07-09
---
## Rule
On the customer website (task detail, account task list, cart), once a task's
`state` is `planned` (or any state at/after `planned` in the customer task
lifecycle: `planned`, `picked`, `provider_accepted`, `workDone`, `accepted`,
`feedback`) AND the task has a `plannedAt` timestamp, the UI MUST display that
committed planned date/time instead of (or alongside, for detail views) the
originally requested schedule window (`taskScheduleLabel`).

Before a task is planned (`defined`, `scheduled`, `pendingPayment`,
`paymentFailed`, `paid` with no `plannedAt` yet), the UI keeps showing the
requested schedule as today — there is no committed time to show.

## Rationale
`plannedAt` already exists on `customer-task` (`docs/schemas/customer-task.schema.json`)
and is set by the backend once a provider/manager commits a concrete slot,
but the website never surfaced it — customers kept seeing only their
originally requested window even after a firm time was set, which reads as
stale/incorrect once the provider has actually locked in a time.

## Implementation
Add a `taskPlannedAtLabel(task, lang)` formatter alongside the existing
`taskFormat.ts` helpers, using `plannedAt` (Firestore Timestamp) formatted as
`DD.MM.YYYY · HH:mm` (locale-aware). Any component currently calling
`taskScheduleLabel` (`TaskDetail.tsx`, `AccountTasks.tsx`, `CartTasks.tsx`)
must prefer the planned-time label when `task.state` is `planned` or later
AND `plannedAt` is present, falling back to `taskScheduleLabel` otherwise.

## Verification
- Task with `state: 'defined'`/`'paid'` and no `plannedAt` → UI shows the
  requested schedule window (unchanged behavior).
- Task with `state: 'planned'` and `plannedAt` set → UI shows the planned
  date/time, not the original requested window.
- Task with `state: 'workDone'`/`'accepted'`/`'feedback'` (post-planned) and
  `plannedAt` set → UI still shows the planned date/time (not reverted to
  requested window).
- Task with `state: 'planned'` but `plannedAt` missing (defensive/edge case)
  → UI falls back to the requested schedule window, does not crash/blank.
