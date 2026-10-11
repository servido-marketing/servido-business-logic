---
id: tasks-provider-gig-pool-card-actions
domain: tasks
title: SP panel gig pool cards show Ota keikka and Näytä tiedot buttons, no status badge
status: active
applies_to: [sp-panel]
tags: [tasks, sp-panel, gig-pool, ui-copy, take-gig]
supersedes: []
created: 2026-10-11
updated: 2026-10-11
---
## Rule

Applies to gig cards in the SP panel jobs pool (`JobsPool` rendered via `CommonTasksListPartial` -> `CommonTaskRow` in poolCard mode).

MUST NOT: render the green "Tarjolla oleva tehtävä" status badge (`pickTask` copy) on a jobs pool card.

MUST: render two visible buttons on each jobs pool card: primary "Ota keikka" (`spTakeGig`) and secondary "Näytä tiedot" (`viewDetails`). Each has a touch target of at least 44 px in both height and width.

MUST: "Ota keikka" opens the take-gig dialog directly, with the same dialog, agreements interception and submit behaviour as the former dropdown item. "Näytä tiedot" opens the gig details exactly as tapping the card does today.

MUST NOT: render the chevron dropdown button on a jobs pool card. "Näytä tiedot" replaces it.

MUST NOT: leave any popup, menu, dialog or overlay open, or re-appearing, on the pool after a gig was taken and the SP returns to the pool. Remaining cards keep their buttons uncovered and working.

MUST NOT: change the worker offered-gigs list (accept/decline menu), manager panel, active-gigs list, or gig details screen. They keep current badge and chevron behaviour.

## Rationale

The pool is a decision list: the SP either takes the gig or looks closer. A hidden dropdown plus a badge repeating the action costs a tap and space. A leftover popup after taking a gig blocks the next gig.

## Implementation

Jobs pool only, on both desktop and mobile card layouts. Buttons are not shown while the card data is loading. Worker offered-gigs lists share poolCard mode and MUST keep their dropdown.

## Verification

Jobs pool with 2 gigs: no card contains the text "Tarjolla oleva tehtävä" and no chevron icon; each card has "Ota keikka" and "Näytä tiedot" buttons at least 44 px in both dimensions. Tapping "Ota keikka" shows the dialog titled "Ota keikka" without opening any menu. After taking one gig and returning to the pool, one card remains, its two buttons are hittable, and no popup route or overlay is on the navigator stack.
