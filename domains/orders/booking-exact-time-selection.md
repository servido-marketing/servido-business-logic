---
id: orders-booking-exact-time-selection
domain: orders
title: Customer may pick an exact time OR a time-of-day range when booking
status: active
applies_to: [web, mobile, all]
tags: [orders, booking, scheduling, time-slot]
supersedes: []
created: 2026-07-06
updated: 2026-07-06
---
## Rule
When choosing a slot for a `PickedSchedule` booking, the customer MUST be able to choose
EITHER a time-of-day range (`morning`/`afternoon`/`evening` — the existing `dayTime` bucket)
OR an exact time (`HH:mm`, provider's local time) per date. Exactly one of the two MUST be
present per picked slot — never both, never neither. This mirrors the existing date pattern
where a customer can already pick a flexible range of dates OR an exact date.

## Rationale
Some customers know exactly when they want the provider to arrive (e.g. "16:30") and find
a 4-hour range too coarse; others are flexible and prefer picking a broad time-of-day bucket.
Offering both, the same way dates already offer flexible-range vs exact-date, removes friction
without forcing every customer through the coarser option.

## Implementation
- `PickedSchedule.slots[]` (`docs/schemas/picked-schedule.schema.json`) items gain a mutually
  exclusive choice: `dayTime` (existing enum) OR a new `exactTime` field, `HH:mm` 24h string,
  provider-local time. Enforced via `oneOf` at the slot level so a slot cannot carry both or
  neither.
- New reusable schema `docs/schemas/exact-time.schema.json` — a `type: string` with a strict
  `HH:mm` pattern (`^([01][0-9]|2[0-3]):[0-5][0-9]$`), analogous to `day-time.schema.json`.
- Client UX: the existing time-slot picker UI (that today only exposes morning/afternoon/
  evening chips, e.g. `TimeSlotSelector` / `ScheduleCell` in `apps/packages/ui`) gains a
  toggle — "Pick a range" (current chips) vs "Pick an exact time" (a time-of-day input/wheel) —
  mirroring the existing date picker's flexible-range-vs-exact-date toggle pattern used
  elsewhere in the booking flow.
- Backend: `scheduleTask` / booking derivation code that reads `slot.dayTime` must be
  updated to read either `slot.dayTime` or `slot.exactTime` and pass whichever is present
  straight through into the stored/derived schedule; do not attempt to convert one into the
  other (no auto-bucketing an exact time into a dayTime range).
- Display: anywhere a picked slot's time is rendered to a provider/manager/customer (schedule
  display widgets), show the exact `HH:mm` when `exactTime` is set, otherwise the localized
  dayTime label as today.
- UX presentation of the toggle: the two options MUST read as a natural customer question, not
  as an implementation mode switch. Do NOT label the choice with the technical field/mode names
  ("Range" / "Exact time") alone — phrase each option as a short first-person preference plus a
  one-line clarifying hint, e.g. "I'm flexible" (hint: "morning, afternoon or evening works") vs
  "I have a time in mind" (hint: "pick the exact time you'd like"). Apply this to both the web
  wizard (`ScheduleSelector.tsx` / `StepLocation.tsx`) toggle copy and its i18n strings
  (`timeModeRange`/`timeModeExact` and their hints) for every locale (`fi`, `en`). The visual
  toggle mechanism (two side-by-side buttons) is unchanged — only the copy/labels change.

## Verification
- A slot with `exactTime` set and no `dayTime` is accepted end-to-end (booked, stored,
  displayed as the exact time on all three projections' consuming UIs).
- A slot with `dayTime` set and no `exactTime` continues to work exactly as before (regression).
- A slot schema-validation call with BOTH `dayTime` and `exactTime`, or NEITHER, is rejected.
- UI: the picker exposes both a range mode and an exact-time mode and the user's choice is
  what gets sent in the booking request.
- Copy: neither toggle button's visible label is the bare word "Range" or "Exact time" — each
  reads as a natural preference statement with a clarifying hint line, in both `fi` and `en`.
