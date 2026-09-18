---
id: orders-customer-task-reschedule
domain: orders
title: Customer reschedule — free until planned, 48h self-service window, then manager-handled
status: active
applies_to: [web, mobile, all]
tags: [orders, reschedule, scheduling, task, booking, time-selection, planned, manager]
supersedes: []
created: 2026-06-24
updated: 2026-06-24
---
## Rule
A customer MAY request a new date/time for their own task. Whether it applies
immediately or becomes a manager-handled request depends on the gig's planned
time:

1. **Not yet planned** (task has no `plannedAt`; customerState before `planned`):
   the customer can reschedule freely and the new time applies immediately.
2. **Planned, with at least 48h of lead time** (now ≤ `plannedAt − 48h`): the
   customer can still reschedule self-service and the new time applies immediately.
3. **Planned, inside the 48h deadline** (now > `plannedAt − 48h`, including after
   the planned time): the customer MAY still submit a reschedule, but it MUST be
   stored as a pending **reschedule request** — it does NOT change the schedule.
   A manager handles that request manually.

Reschedule MUST NOT be offered for terminal/closed states (`workDone`, `accepted`,
`feedback`, `canceled`, `disputed`, `archived`).

## Rationale
- Before a gig is planned there is no committed provider time slot, so a new time
  is free to apply.
- Once planned, a provider has a committed slot; 48h is enough lead time for the
  system to re-plan automatically without operational cost.
- Inside 48h, moving a gig affects a provider who may already be en route or has
  blocked the slot — that trade-off needs a human (manager) decision, so the
  customer's intent is captured as a request rather than silently applied.
- Capturing (not rejecting) a late reschedule keeps the customer's intent visible
  to ops instead of forcing a cancel + rebook.

## Implementation
- The customer-facing surfaces compute a `rescheduleMode` from customerState +
  `plannedAt`:
  - `immediate` when not planned, or planned with `now ≤ plannedAt − 48h`;
  - `request` when planned and `now > plannedAt − 48h`;
  - `unavailable` for terminal/closed states.
- A single callable `requestReschedule(taskId, schedule)` (NOT a naive re-call of
  `scheduleTask`) decides the tier server-side:
  - `immediate` → applies the new schedule (re-plan for an already-planned task so
    the provider/manager projections stay consistent). Applying a new schedule MUST
    only update the date/time, never regress a committed customerState: the
    `TaskScheduled` fold advances to `scheduled` ONLY from a pre-payment state
    (`undefined`/`defined`/`scheduled`); for any committed state (`pendingPayment`,
    `paymentFailed`, `paid`, `planned`, …) it preserves the existing state and just
    swaps the schedule/address. Otherwise rescheduling a paid task would downgrade
    it and the customer would be asked to pay again.
  - `request` → appends a `TaskRescheduleRequested` event carrying the requested
    schedule + `requestedAt`; this sets a `rescheduleRequest` field on the manager
    projection and leaves customerState/schedule unchanged. The manager resolves it
    manually (apply or decline).
- The customer-side time-selection UI is the SAME component used at booking
  (flexible vs. specific date, flexible range, morning/afternoon/evening slots) —
  not a reimplementation. In `request` mode the UI tells the customer their request
  will be reviewed by a manager rather than promising an immediate change.
- The 48h boundary is computed against `plannedAt`; an unplanned task is always
  `immediate`.

## Verification
Proof shows: (a) for an unplanned task and a planned task with >48h lead time, the
reschedule control applies the new time immediately and the displayed schedule
updates; (b) for a planned task inside 48h, submitting a new time stores a
reschedule request (manager projection shows `rescheduleRequest`) WITHOUT changing
the customer's schedule, and the UI states a manager will handle it; (c) the
control is absent for terminal states.
