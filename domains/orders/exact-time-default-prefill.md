---
id: orders-exact-time-default-prefill
domain: orders
title: Exact-time scheduling input must default to next full hour
status: active                  # active | superseded | deprecated
applies_to: [web]
tags: [scheduling, exact-time, booking, ux]
supersedes: []
created: 2026-07-06
updated: 2026-07-06
---
## Rule
When a customer switches a schedule slot's time mode to "exact time", the exact-time input
MUST NOT render empty. It MUST prefill with the next full hour from the current moment,
formatted as `HH:mm` (24h), matching the `exact-time` schema pattern. The customer may still
edit/clear it afterward; this only governs the initial value shown on switching into exact mode.

## Rationale
An empty time input on mode-switch reads as broken/confusing (operator-reported). A sensible
default (next full hour) removes a dead-end interaction and nudges toward a valid, schema-
compliant value without forcing a chip/preset choice.

## Implementation
- Compute "next full hour from now": if minutes/seconds/ms > 0, round up to the next hour;
  if already exactly on the hour, keep that hour. Format as zero-padded `HH:mm`, wrapping
  `23:00` -> next day `00:00` conceptually (only the HH:mm value is shown; date is unaffected).
- Apply this default at the moment `timeMode` transitions to `'exact'` (i.e. where the slot
  update currently sets `exactTime: ''` on mode switch), not on every render — do not stomp a
  value the customer already typed.
- Web (`servido-website`): `ScheduleSelector.tsx` is where the mode switch sets
  `{ timeMode: opt.key, exactTime: '' }` (currently hardcoded empty) — this is the exact site to
  change; use the next-full-hour default there instead of `''`.
- No schema change: `exact-time.schema.json` pattern (`HH:mm`, 24h) already accepts this value
  unmodified.

## Verification
Switching a schedule slot to exact-time mode shows a non-empty time input pre-filled with the
next full hour (e.g. switching at 14:22 shows "15:00"; switching exactly at 14:00 shows "14:00").
Switching away and back does not carry over a stale prior exact time (fresh default each time),
and an already-user-edited value is not overwritten on unrelated re-renders.
