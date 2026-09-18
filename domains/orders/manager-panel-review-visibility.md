---
id: orders-manager-panel-review-visibility
domain: orders
title: Manager panel MUST surface customer review (feedback) on the gig list and gig details
status: active
applies_to: [web]
tags: [orders, review, feedback, customerFeedback, manager, panel, task-list, task-details]
supersedes: []
created: 2026-08-09
updated: 2026-08-09
---
## Rule

When a customer has left a review (`customerFeedback` with a non-null `stars` and/or `comment`)
on a task, the services-manager panel MUST:

1. Show a small review indicator icon (star icon) on that task's row in the gig list, ONLY when
   `customerFeedback` is present (stars set or comment set). No icon when no feedback exists.
2. Display the full review (star rating + comment, if present) in the gig details view, in its
   own labelled section. If no review exists yet, the section is omitted entirely (no empty
   placeholder).

This uses the existing `customerFeedback` field already projected onto `ServicesManagerTask` /
the manager `Task` entity (see `CooperationFeedback` — `stars`/`comment`) — no new backend
callable, event, or schema is required; the field is already populated by the existing
`addFeedback` callable via `FeedbackAdded` events. This is a pure manager-panel display feature.

## Rationale

Managers currently have no way to see customer feedback without manually inspecting each task's
Firestore document. Surfacing it directly in the panel lets managers spot dissatisfied customers
at a glance from the list (icon) and read the full review without extra clicks (details).

## Implementation

- Data source: `ManagerTask.customerFeedback` (type `CooperationFeedback?`, fields `stars: int?`,
  `comment: String?`), already mapped end-to-end (CF `addFeedback` → `FeedbackAdded` event →
  `ServicesManagerTask.customerFeedback` projection → `mapping.dart`
  `CooperationFeedbackMappingB.toFront()` → `ManagerTask.customerFeedback`).
- "Has review" predicate: `customerFeedback != null && (customerFeedback.stars != null ||
  (customerFeedback.comment?.isNotEmpty ?? false))`.
- Gig list (`ManagerTasksList` / `CommonTasksListPartial` accessories row in
  `apps/apps/web/lib/flows/manager_panel/bond/not_commited_tasks/view/manager_tasks_list.dart`
  and any other manager task list surface): add a small star icon accessory, visible only when
  the has-review predicate is true. No numeric rating in the list — icon only, to keep the row
  compact.
- Gig details (`BondManagerTaskDetails` / `ManagerTaskPreview`
  under `apps/apps/web/lib/flows/manager_panel/bond/bond_manager_task_details/`): add a
  "Customer review" section showing the star rating (read-only star row, reuse existing rating
  display widget if one exists) and the comment text, rendered only when the has-review
  predicate is true.
- No provider-feedback exposure here — this card is customer→manager review visibility only.
  `providerFeedback` is out of scope.

## Verification

- A task with `customerFeedback.stars` set (with or without a comment) shows a star icon on its
  row in the manager gig list.
- A task with no `customerFeedback` (or one with both `stars` and `comment` empty/null) shows NO
  icon on its list row.
- Opening gig details for a task with `customerFeedback` shows a "Customer review" section with
  the correct star count and comment text.
- Opening gig details for a task with no `customerFeedback` shows no review section at all (no
  empty state).
