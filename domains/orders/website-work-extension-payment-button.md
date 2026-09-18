---
id: orders-website-work-extension-payment-button
domain: orders
title: Website task detail page must show a working pay-extension button when an extension is unpaid, and return the customer to the task page after payment
status: active
applies_to: [web]
tags: [orders, work-extension, additional-work, payment, website, navigation]
supersedes: []
created: 2026-07-07
updated: 2026-07-07
---
## Rule

On the website's task detail page (`/[lang]/tilaukset/[taskId]`), when a task's status is
`unpaidExtension` (per `orders-unpaid-work-extensions`) and `customer_tasks/{id}.paymentExtensionLink`
is present, a "Pay extension" button MUST be rendered and MUST navigate the customer to the
extension payment page. After the payment flow completes (success, failure, or the customer
navigates back), the customer MUST land back on the SAME task detail page
(`/[lang]/tilaukset/[taskId]`), not the orders list or an unrelated page.

## Rationale

The task detail page already lists the unpaid extension's price and status ("Extension pending
payment") but historically had no way to act on it, or the pay button existed without a correct
return path — leaving the customer stranded on the hosted Stripe page with no way back. A
customer who just paid (or abandoned payment) needs to immediately see the task's updated state,
not have to re-navigate from the orders list.

## Implementation

Website (`servido-website/src/components/account/TaskDetail.tsx`):
- The existing conditional render (`info.statusKey === 'unpaidExtension' && task.paymentExtensionLink`)
  is the gate — a button must always be shown when this condition is true (no version of the page
  should reach `unpaidExtension` status with no visible/actionable button).
- The link's `returnUrl` (or equivalent `return_url` query param honored by the hosted payment page,
  `conversion-pay.html`) MUST be set to the current task detail page's own absolute URL
  (`{origin}/{lang}/tilaukset/{taskId}`), so `window.parent.postMessage`/redirect completion lands
  back on this same task, in this same language.
- `paymentExtensionLink` is built server-side via `makePaymentVerificationLink` (`bookConversion.ts`)
  and currently does NOT accept/thread a `returnUrl`/`return_url` param the way
  `buildConversionPaymentLink` (client-side booking payment) does. Extend
  `makePaymentVerificationLink` to accept an optional `returnUrl` and append it as `&return_url=...`
  in the generated link (mirroring `contact_phone`'s optional-param pattern), and pass the task
  detail page's URL through from the website's read of `paymentExtensionLink` — OR, if computing the
  return URL server-side (in `stateDeriver.ts`, which doesn't know the site origin/lang), have the
  website compose its own return-aware link by appending `?return_url=...` client-side to whatever
  `paymentExtensionLink` bare value it received.

No backend schema change beyond what's already present (`customer_tasks.paymentExtensionLink`
already documented in `docs/schemas/customer-task.schema.json`).

## Verification

- On a task with `statusKey === 'unpaidExtension'`, the task detail page renders a visible
  "Pay extension" button, not just extension details with no action.
- Clicking the button navigates to a Stripe-hosted payment page (or opens it) whose return path
  points back at this same task's detail URL (`/{lang}/tilaukset/{taskId}`), not the generic
  orders list.
- After completing (or cancelling) payment on the hosted page, the customer ends up back on the
  same task's detail page.
- A task NOT in `unpaidExtension` status shows no pay-extension button (no regression to
  `orders-work-extension-detail-visibility`, which still shows extension details for all statuses).
