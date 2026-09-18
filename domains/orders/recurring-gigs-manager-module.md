---
id: orders-recurring-gigs-manager-module
domain: orders
title: Manager panel MUST expose recurring gigs as a dedicated "Recurring gigs" navigation module
status: active
applies_to: [web]
tags: [orders, recurrence, booking, manager, panel, series, ux]
supersedes: []
created: 2026-09-08
updated: 2026-09-08
---
## Rule
The manager_panel (web app) MUST have a separate top-level navigation module named
"Recurring gigs" that lists every recurring booking (series) owned by the company's
customers, and lets the manager drill into one series to see all its visit occurrences,
next-visit info, and per-series status — mirroring the customer-facing series view
(`servido-website` `SeriesDetail.tsx` at `/tilaukset/sarja/[recurringBookingId]`). This
is a NEW module, not a filter/tab bolted onto the existing Active Tasks list.

## Rationale
Recurring bookings currently only surface to the manager as individual flat task rows
mixed into Active/Completed/Unpaid lists (`manager_tasks_list.dart`), with no way to see
a series as a whole (progress, next occurrence, autopay state). Customers already have
this via `SeriesDetail.tsx`. Managers need the same visibility to answer customer
questions about a series without hunting through occurrence tasks individually.

## Implementation
- Web app (`apps/apps/web`): add `ManagerNavigationItem.recurringGigs` to
  `manager_panel/model/model.dart`'s nav enum, a new
  `manager_panel/bond/recurring_gigs/` module (bloc + view) following the existing
  `not_commited_tasks` / `completed_tasks` module shape, wired into
  `ManagerHome`'s switch (icon: `Icons.repeat` / `FontAwesomeIcons.rotate`, label via
  a new `recurringGigsTitle` l10n key).
- List screen: one row per `recurring_bookings` doc belonging to the company's
  customers — service name, customer name, progress (done/total visits), next
  occurrence date, status pill. Tapping a row opens a detail screen showing all
  occurrence tasks in the series (reuse `manager_tasks_list.dart` row rendering for
  the occurrence list) plus the series-level header info (recurrence summary, end
  condition, autopay state) — same information shape as the customer `SeriesDetail`
  header/visit-list, not the same code (different tech stack, React vs Flutter).
- Backend: reading `recurring_bookings` + resolving each series' occurrence tasks
  requires the manager-facing task projection to carry `recurringBookingId`
  (`docs/schemas/services-manager-task.schema.json`) the same way the customer
  projection already does (`customerTask.d.ts` `recurringBookingId`), so a manager
  task row can be grouped by series client-side. No new callable is required if the
  existing manager task list/read already returns full task docs — the coder task
  will confirm and add a dedicated read path only if the existing one insufficiently
  supports grouping by `recurringBookingId`.

## Verification
Manager panel main nav shows a "Recurring gigs" item (own icon+label, not nested
under Active Tasks) whose list shows one row per distinct `recurringBookingId`
among the company's tasks; opening a row shows all occurrence tasks of that series
plus next-occurrence and progress info, matching the customer series view's
information set.
