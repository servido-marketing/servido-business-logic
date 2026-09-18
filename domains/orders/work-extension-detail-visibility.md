---
id: orders-work-extension-detail-visibility
domain: orders
title: Customers can see all work extensions in task detail regardless of payment state
status: active
applies_to: [website]
tags: [orders, work-extension, additional-work, detail, visibility, website]
created: 2026-07-01
updated: 2026-07-01
supersedes: []
---

## Rule

The website's task detail page MUST display ALL work extensions associated with a task,
regardless of the extension's payment status (`requested`, `acccepted`, `paymentPending`,
`paymentFailed`, `paid`, `rejected`) and regardless of the task's overall state.

A customer who has already paid for a work extension MUST still be able to see the extension
and its details (name, price, status) in their task detail view. Hiding extensions after
payment removes the customer's record of what they paid for.

Existing behavior (payment button + unpaid extension list shown only when
`statusKey === 'unpaidExtension'`) is preserved; this rule ADDS display of paid/rejected
extensions so the full history is always visible.

## Rationale

The customer has no other surface (mobile or website) where they can review what work extensions
were performed on their task after payment is complete. Without this, extensions are visible
only while unpaid, then disappear after the payment succeeds — losing a key part of the task
history the customer needs for their records.

## Implementation

Website (`servido-website/src/components/account/TaskDetail.tsx`):
- Move the `additionalWorks` section to render whenever `task.additionalWorks` has any entries,
  regardless of `statusKey`.
- Show ALL works, labelled with their status (e.g. "Paid", "Pending", "Rejected").
- Show the payment button (existing behavior) only when `statusKey === 'unpaidExtension'`
  and `paymentExtensionLink` exists (unchanged).

No backend, schema, or mobile changes required.

## Verification

- A customer whose work extension is in status `paid` sees the extension details in the task
  detail page.
- A customer with `requested`/`paymentPending` extensions also sees the details (no regression).
- The payment button appears only when `statusKey === 'unpaidExtension'` and
  `paymentExtensionLink` is set.
- A task with no `additionalWorks` shows no extension section.
