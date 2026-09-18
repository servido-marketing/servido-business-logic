---
id: website-i18n-full-coverage-booking-wizard
domain: website
title: Booking wizard UI text MUST come from i18n dictionaries, never hardcoded English
status: active                  # active | superseded | deprecated
applies_to: [web]                # which surfaces this binds; use [all] if universal
tags: [i18n, translation, booking, wizard, website, localization, hardcoded]
supersedes: []
created: 2026-07-09
updated: 2026-07-09
---
## Rule
Every user-facing string rendered inside the website booking wizard (`servido-website/src/components/booking/**`) MUST be sourced from the `wizardTranslations` dictionary (`src/i18n/wizard.ts`) via `useTranslation()`/`t(...)`, for every supported locale (currently `fi`, `en`). No component may contain a literal English (or any single-language) string, derived label, or `Date`-locale-dependent value (e.g. `Intl`/`toLocaleDateString` weekday names, ordinal suffixes) that isn't run through the active locale's dictionary.

## Rationale
`RecurrenceSection.tsx` rendered "Every Wednesday", "Repeat", "Starts", "Ends", weekday initials, and ordinal-day labels as raw English literals and JS-computed weekday/ordinal strings, so Finnish (and any other) visitors saw English mid-wizard. This breaks trust and conversion on a booking flow the operator otherwise fully localizes. The fix must be systemic (a rule + dictionary keys), not a one-off patch, because new wizard sections keep getting added and this class of bug (hardcoded literal, or a computed value based on `Date`/`Intl` APIs that default to English) recurs easily.

## Implementation
- Add all missing keys to BOTH `fi` and `en` blocks of `wizardTranslations.recurrence` in `src/i18n/wizard.ts` (weekday names, "Every {weekday}" template, ordinal-of-month template, "None"/"Other…" pill labels, "Repeat"/"Repeat every"/"Repeat on"/"Starts"/"Ends"/"Never"/"On"/"After"/"occurrences"/"Day"/"of the month"/frequency unit labels "week"/"2 weeks"/"month"/"Time of day").
- Weekday names and ordinal suffixes must NOT be computed via hardcoded English arrays (`WEEKDAY_NAMES`, the `ordinal()` function) — replace with locale-driven lookups: an array of 7 translation keys per locale for weekday names, and a locale-aware ordinal/date formatter (or a translated template swapping in the raw day number when the target locale has no ordinal concept, e.g. Finnish "5. päivä" not "5th day").
- `RecurrenceSection.tsx` must call `t('wizard.recurrence.<key>')` (or equivalent nested accessor already used elsewhere in the file for `wizard.morning` etc.) for every string currently hardcoded — the `WEEK_DAYS` single-letter array (`S/M/T/W/T/F/S`) is also locale-specific and must translate per locale.
- Grep the whole `servido-website/src/components/booking/**` tree (not just RecurrenceSection) for other literal English strings not passed through `t(...)` before considering the fix complete — the task explicitly calls for finding ALL hardcoded English in this area, not just the one reported string.

## Verification
Load the website booking wizard's recurrence step with the site locale set to `fi`: every visible string (pill labels including the dynamic "Every <weekday>" pill, "Repeat"/"Repeat every"/"Repeat on"/"Starts"/"Ends" labels, weekday abbreviation buttons, frequency unit labels, "occurrences"/"Day"/"of the month") renders in Finnish, with zero remaining English literals. Confirm via `grep -n` over `RecurrenceSection.tsx` (and sibling booking components) that there are no bare string literals left in JSX/label positions — every rendered string traces to a `t('wizard...')` call.
