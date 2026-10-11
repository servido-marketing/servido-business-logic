---
id: tasks-sp-panel-active-gigs-scheduled-completed-tabs
domain: tasks
title: SP panel active-gigs view MUST split into Scheduled and Completed tabs with counts
status: active
applies_to: [web]
tags: [tasks, provider, sp-panel, gig, task-list, tabs, completed, scheduled]
supersedes: []
created: 2026-10-11
updated: 2026-10-11
---
## Rule
The SP panel "Active tasks" (fi "Aktiiviset tehtävät") view MUST show two tabs, in this order:
1. Scheduled (fi `Aikataulutetut (N)`): every gig that is NOT completed (no `completionTime`).
2. Completed (fi `Valmistuneet (N)`): every gig that is completed (`completionTime` set, status "Valmistunut").

`N` is the number of gigs in that tab. A completed gig MUST NOT appear under the Scheduled tab and
MUST be reachable under the Completed tab. The Scheduled tab is selected by default. Tab labels
are exactly as above (no extra words).

## Rationale
Completed gigs were listed mixed in with upcoming ones (unfinished first, finished after), so a
provider with many recent completions had upcoming gigs pushed out of view.

## Implementation
- Client-side split only; no backend callable, schema field or query change. `completionTime`
  is derived from `workDoneAt` and is already populated on `ProviderTask`.
- The existing 30-day completed window (`orders-sp-panel-hide-old-completed-gigs`) still applies:
  the Completed tab and its count only include gigs completed within the last 30 days.
- "Scheduled" deliberately includes not-yet-planned gigs (planned time empty) so the existing
  "Plan" action stays reachable; it is the complement of Completed, not "plannedTime != null".
- Counts are totals for the tab (not reduced by the search box); search/sort apply within the
  selected tab. Empty tab shows the existing empty tip.
- Tab labels use new l10n keys with a count placeholder; the existing shared keys `scheduled`
  ("Aikataulutettu") and `completed` ("Valmistunut"/"Valmiit") MUST NOT be repurposed.

## Verification
Given an SP with 2 non-completed gigs and 2 gigs completed within 30 days, the Active tasks view
shows tabs `Aikataulutetut (2)` and `Valmistuneet (2)`; the first tab lists only the 2
non-completed gigs (no "Valmistunut" badge); tapping the second lists the 2 completed gigs and
opening one navigates to its details.
