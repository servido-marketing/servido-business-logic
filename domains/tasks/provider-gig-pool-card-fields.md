---
id: tasks-provider-gig-pool-card-fields
title: SP panel gig pool cards hide customer-unassigned and Varattu rows
domain: tasks
status: active
applies_to: [sp-panel]
supersedes: []
tags: [tasks, sp-panel, gig-pool, ui-copy]
created: 2026-10-11
---

# SP panel gig pool cards: fields hidden

## Rule

Applies to gig cards in the SP panel gig pool (jobs pool and worker offered-gigs lists, rendered via `CommonTasksListPartial` -> `CommonTaskRow` in poolCard mode).

MUST NOT: render "Asiakas ei määritetty" (customer not specified) or any replacement text when the customer name is absent. If a customer name exists, it renders as before.

MUST NOT: render the `Varattu <time>` (booked) row.

MUST: keep the existing schedule display (the requested time) exactly as before. No new requested-time row.

MUST NOT: add a duration row (out of scope, separate task).

MUST NOT: change the manager panel, web admin, recurring-gigs, or sales-analytics screens. They keep `customerNotAssigned`, `booked`, and `salesAnalyticsBooked` as they are.

Active-gigs `Varattu` removal is covered by task #16, not this one.
