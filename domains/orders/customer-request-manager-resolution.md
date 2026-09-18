---
id: orders-customer-request-manager-resolution
domain: orders
title: Manager panel must list and resolve customer reschedule/cancel requests
status: active
applies_to: [web]
tags: [orders, reschedule, cancel, manager-panel, task-details]
supersedes: []
created: 2026-07-07
updated: 2026-07-07
---
## Rule
A pending `rescheduleRequest` or `cancelRequest` on a task (see `services-manager-task`
schema) MUST surface as a row in a dedicated "Customer Requests" module in the manager
panel until a manager resolves it. A manager MUST be able to mark a request `applied` or
`declined` from that module, and resolution MUST go through a callable
(`resolveCustomerRequest`) — never a direct Firestore write.

## Rationale
Reschedule/cancel requests submitted inside the 48h-before-planned deadline are stored
(not auto-applied) specifically so a manager makes the call. Today those requests exist on
the task document but have no dedicated worklist — managers can only find them by opening
individual task details, so pending requests go unnoticed. A list view with direct
navigation into task details closes that gap without duplicating task-detail actions.

## Implementation
- New manager-panel module lists every task with a `rescheduleRequest.status == 'pending'`
  or `cancelRequest.status == 'pending'`.
- Each row shows: the gig cell (existing task/gig list-cell widget, reused — not
  reimplemented) next to a request-summary cell (request type, requested schedule or
  reason, requestedAt).
- Clicking the row navigates to the existing task details screen (same navigation as any
  other task list in the panel) — no new detail UI; the manager acts using existing
  task-details controls plus the new resolve action.
- Resolving (`applied` or `declined`) calls the new `resolveCustomerRequest` callable
  (taskId, requestType: `reschedule`|`cancel`, resolution: `applied`|`declined`). The
  callable is the ONLY place that transitions `rescheduleRequest.status` /
  `cancelRequest.status` away from `pending` — clients never write these fields directly.
- Once resolved, the row drops out of the pending list (status no longer `pending`).

## Verification
- A task with a pending `rescheduleRequest` or `cancelRequest` appears in the Customer
  Requests module, showing gig cell + request details together.
- Clicking a row navigates to that task's details screen.
- Invoking `resolveCustomerRequest` with `resolution: 'applied'` or `'declined'` flips the
  request's `status` off `pending` and the row disappears from the module's pending list.
- No client code path sets `rescheduleRequest.status`/`cancelRequest.status` directly;
  only the callable does.
