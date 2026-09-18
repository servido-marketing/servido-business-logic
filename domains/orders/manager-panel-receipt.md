---
id: orders-manager-panel-receipt
domain: orders
title: Manager panel task details exposes a download-receipt action reusing the customer receipt endpoint
status: active
applies_to: [web]
tags: [orders, receipt, manager, panel, pdf, download]
supersedes: []
created: 2026-07-09
updated: 2026-07-09
---
## Rule
The manager panel task details view MUST offer a "Download receipt" action for any task that
has a resolvable receipt (i.e. the same condition the customer app already uses to show its
"Print receipt" button: task has a resolvable main cost, product name, address, and buyer
identity). The action MUST NOT introduce a new receipt-generation code path — it downloads the
existing `getCustomerReceipt` HTTPS endpoint's PDF by `taskId`, the same PDF the customer already
gets. No new callable, schema, or PDF layout is introduced by this rule.

## Rationale
Managers routinely need the same receipt customers get (support requests, invoicing disputes,
manual bookkeeping) but currently have no in-panel way to retrieve it — they'd have to ask the
customer to forward theirs or hit the raw CF URL by hand. The receipt PDF layout and pricing
math are already correct and tested via `getCustomerReceipt` (see `cf/functions/src/getCustomerReceipt.ts`);
duplicating that logic client-side or server-side for the manager surface would fork the two
receipts and risk drift (VAT math, promo handling, extension line items). Reusing the same
public endpoint by `taskId` keeps exactly one receipt implementation for the whole product.

## Implementation
- Manager panel: `apps/apps/web/lib/flows/manager_panel/bond/bond_manager_task_details/` —
  add a "Download receipt" `AigButton` to `BondManagerTaskDetails`, visible when the loaded
  `ManagerTask` has enough data to resolve a receipt (mirror the mobile app's
  `canGetReceipt` gating condition — task must have a resolvable main cost/schedule price,
  a product name, an address, and buyer identity; do not show the button for tasks missing
  any of those, since the endpoint throws `incomplete receipt data` in that case).
- Trigger: open `getCustomerReceipt`'s URL (`?taskId=<id>`) in a new browser tab/window (the
  endpoint already sets `Content-Disposition: attachment`, so the browser downloads the PDF —
  no client-side PDF generation needed on the manager panel, unlike the mobile app which
  builds its own PDF from local data). The endpoint's base URL must come from the isolate's
  existing CF environment config (same pattern already used elsewhere in the web app for
  calling onRequest endpoints), not a hardcoded prod URL.
- No new Cloud Function, no new request/response schema — `getCustomerReceipt` already reads
  both `customer_tasks` and `manager_tasks` by `taskId` and needs no manager-specific auth
  change (it is a public `onRequest` endpoint keyed by `taskId`, same as today).

## Verification
Manager panel task details screen, for a task with a resolvable receipt (paid, priced, has
address + buyer identity), shows a "Download receipt" button; clicking it triggers a PDF
download from `getCustomerReceipt?taskId=<id>` and the response is a valid `application/pdf`
matching the same receipt the customer app produces for that task. For a task missing any
receipt precondition (e.g. no price resolved yet), the button MUST NOT be shown.
