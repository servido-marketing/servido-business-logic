---
id: tasks-provider-photos-at-completion
domain: tasks
title: SP panel offers photo upload only in the gig-completion step
status: active
applies_to: [web]
tags: [tasks, gig, photo, upload, provider, panel, completion, media]
supersedes: []
created: 2026-10-11
updated: 2026-10-11
---
## Rule
In the SP panel, photo upload (max 6 photos, label "Lataa kuvia") is offered ONLY in
the gig-completion step — the "Complete task" modal. It MUST NOT appear in the gig
detail view or in the gig pool view.

- Photos still go through the existing `addTaskMedia` callable and land in the
  `providerMedia` projection field (see `tasks-task-worker-attachments`).
- Photos already uploaded stay visible, read-only, on the gig detail view (no upload
  control, no delete control there).
- Upload in the completion modal is optional and MUST NOT block completion: the SP can
  complete the task with zero photos.
- The manager panel keeps its own upload control; its complete modal does NOT show
  upload.

## Rationale
- Photos are evidence of finished work, so the natural moment to collect them is at
  completion; offering upload in detail/pool views adds clutter and invites uploads
  before the work is done.
- Keeping it optional avoids blocking SPs who have no photos to give.

## Implementation
- No backend or schema change: same `addTaskMedia` callable, `TaskMediaAdded` event
  and `providerMedia` field; the 6-photo cap and "Lataa kuvia" label are client-side UI.
- SP panel (web): move the upload control from the gig detail view into the
  "Complete task" modal; keep rendering existing `providerMedia` photos as a read-only
  grid on the detail view; ensure the pool view has no upload control.
- Manager panel: leave its upload control as is; do not add upload to its complete modal.
- Related: `tasks-task-worker-attachments`.

## Verification
- SP panel: gig detail and pool views show no "Lataa kuvia" control.
- SP panel: "Complete task" modal shows "Lataa kuvia", rejects a 7th photo, and
  completion succeeds with 0 photos.
- Photos uploaded in the modal are persisted via `addTaskMedia` into `providerMedia`
  and appear read-only on the detail view afterwards.
- Manager panel still has its upload; its complete modal shows none.
