---
id: company-worker-default-availability-24h
domain: company
title: Default worker availability is 24h/7d, not a 9-5 weekday plan
status: active
applies_to: [web, mobile, all]
tags: [company, worker, availability, weekly-plan, invite, onboarding, default]
supersedes: []
created: 2026-07-13
updated: 2026-07-13
---
## Rule
When a company invites a new worker (and whenever a worker's `weeklyPlan` is
otherwise unset/missing), the DEFAULT availability MUST be full-time: every
day of the week (monday–sunday), each with a single slot from 00:00 to 24:00.
A company manager MAY still narrow this down afterward via the worker
availability edit form — this rule only fixes the starting point, not a
restriction on what a worker/manager can configure.

## Rationale
The previous default (Mon–Fri 09:00–17:00) understated a brand-new worker's
real capacity before anyone has bothered to configure a plan, which silently
lowered `CompanyWorkerAssociated.availability` and could bias task assignment
away from workers who are actually available around the clock. Defaulting to
24/7 avoids this false-negative until a manager makes a deliberate choice to
narrow it.

## Implementation
- `apps/packages/model/lib/src/entities/weekly_plan.dart` already ships a
  `RobotWeeklyPlan.make()` extension with exactly this 24h/7d shape (all 7
  days, 00:00–24:00 slots) — reuse it (rename to a neutral name such as
  `DefaultWeeklyPlan24h` or repoint the existing `DefaultWeeklyPlan.make()` to
  this shape) rather than hand-rolling a second copy.
- Every call site that seeds a fresh worker's availability before a manager
  edits it (invite-worker flow, any other "new worker" seed, and any
  fallback in `_computeAvailability`/`CompanyWorkerAssociated.availability`
  that substitutes a default when `weeklyPlan` is null) must use the 24/7
  default. Do not special-case web vs mobile — same product rule everywhere.
- No backend schema change is required: `WeeklyWorkPlan`/`DailyPlan`/`TimeSlot`
  already support a 00:00–24:00 slot on every day (see
  `docs/schemas/weekly-work-plan.schema.json`, `TimeOfDay.hour` max 23 — note
  `end.hour: 24` is used today by `RobotWeeklyPlan`, so keep that same
  encoding for consistency, don't invent a different end-of-day sentinel).

## Verification
A brand-new worker (freshly invited, before any manager edit) has a
`weeklyPlan` covering all 7 days with a single 00:00–24:00 slot each, and
`CompanyWorkerAssociated.availability` reflects full-week capacity for that
worker until a manager narrows it.
