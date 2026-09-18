---
id: orders-recurrence-monthday-start-prefill
domain: orders
title: Monthly recurrence start date must prefill the chosen day-of-month in the correct next month
status: active                  # active | superseded | deprecated
applies_to: [web, mobile, all]  # which surfaces this binds; use [all] if universal
tags: [orders, recurrence, booking, scheduling]
supersedes: []
created: 2026-07-06
updated: 2026-07-06
---
## Rule
When a customer picks the "Every Nth of month" quick recurrence mode, the prefilled
`recurrenceStartDate` MUST be the next calendar occurrence of that day-of-month, computed
in the customer's local calendar — i.e. if today's day-of-month has already passed in the
current month (or equals today), the prefilled date MUST roll to the SAME day-of-month in
the NEXT month, not silently keep the current month with the wrong day, and MUST NOT ever
produce a date in a month that has already started when the target day has already occurred.

## Rationale
Reported bug: picking "Every 5th of month" prefilled `08.05.2026` when the correct next
occurrence was `08.06.2026` — the client and server were constructing the target date with
different month/day semantics (likely a UTC/local date construction mismatch, since
`new Date(year, month, day).toISOString()` shifts by timezone offset near midnight, and can
silently roll the DATE portion into the wrong month/day when the local time is close to a
month boundary or during DST changes). Customers who trust the prefilled date without
double-checking end up booking the wrong first occurrence.

## Implementation
- The "next occurrence of day-of-month" MUST be computed and formatted entirely in local
  calendar terms — build `YYYY-MM-DD` from local year/month/day directly (no `toISOString()`
  round-trip, which reinterprets the local `Date` object as UTC and can shift the date by one
  day depending on the browser's timezone offset).
- Rule for "day N of month": if `N > today's day-of-month`, OR (`N === today's day-of-month`)
  the target date is THIS month; if `N <= today's day-of-month` and the target would already be
  in the past today, the target date is NEXT month, same day N (clamped to the next month's
  last day if N exceeds it, e.g. day 31 in a 30-day month becomes the last day).
- Applies to the website's `RecurrenceSection` "Every Nth of month" pill (`applyQuick('monthday')`
  → `nextMonthDay(day)`) and to the numeric "Day" input inside the monthly recurrence section
  (`monthDay` state) — both paths that set `recurrenceStartDate` for `recurrenceFrequency ===
  'monthly'` must reuse the same corrected date-math helper, not two separate implementations.
- Mobile / any other surface implementing the same "recurring monthly, pick day-of-month" quick
  action must use the equivalent local-calendar-safe date math.

## Verification
- Given "today" = 2026-05-08 (an 8th-of-month) and the customer selects "Every 8th of month",
  the prefilled `recurrenceStartDate` MUST equal 2026-06-08 (next month), NOT 2026-05-08.
- Given "today" = 2026-05-01 and the customer selects "Every 5th of month" (day 5, still ahead
  of today in the current month), the prefilled `recurrenceStartDate` MUST equal 2026-05-05
  (this month), NOT next month.
- Given "today" = 2026-01-31 and the customer selects "Every 31st of month", and the next month
  (February) has only 28/29 days, the prefilled date MUST clamp to the last day of that month
  (e.g. 2026-02-28), not overflow into March.
- Changing the numeric "Day" input after a quick-pill selection recomputes `recurrenceStartDate`
  via the same corrected logic (no stale/mismatched date left over from the pill).
