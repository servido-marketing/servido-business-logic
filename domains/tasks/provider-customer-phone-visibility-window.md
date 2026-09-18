---
id: tasks-provider-customer-phone-visibility-window
domain: tasks
title: Provider (SP) task view obscures customer phone number outside the gig window
status: active
applies_to: [mobile, web]
tags: [tasks, provider, panel, phone, privacy, ui]
supersedes: []
created: 2026-08-06
updated: 2026-08-06
---
## Rule
On the provider (SP) task detail view, the customer phone number is displayed
in full only while now is within [plannedAt-24h, plannedAt+12h] of the task's
planned gig time. Outside that window (or when plannedAt is unset), the UI
shows a masked/obscured form of the number (e.g. partially redacted digits)
instead of the plain number. This is a UI-level deterrent only — the backend
continues to send the real phone number to the provider client as it does
today; no schema, callable, or projection changes.

## Rationale
Operator wants friction against providers contacting customers well outside
the gig window, without the cost/complexity of a backend-enforced visibility
gate. A UI-side mask is enough of a deterrent for now.

## Implementation
- Client-side only, on the SP task detail screen wherever
  `customer.phoneNumber` (ProviderPovCustomer) is rendered.
- Compute the window client-side from the task's `plannedAt` timestamp
  already present on the ProviderTask; no new data needed.
- When outside window: render a masked string (e.g. last 2-3 digits visible,
  rest replaced with a mask character) instead of the raw number; no tap-to-
  call / tap-to-copy action on the masked form.
- When inside window: render as today (full number, tappable).

## Verification
- SP viewing a task with plannedAt more than 24h away (past) or more than 12h
  away (future) sees a masked phone number, not the real one.
- SP viewing a task within [plannedAt-24h, plannedAt+12h] sees the full,
  tappable phone number exactly as before.
- SP viewing a task with no plannedAt sees the masked form (safe default).
