---
id: orders-business-portal-real-data-only
domain: orders
title: Business portal screens MUST show only figures backed by real order and property data
status: active
applies_to: [web]
tags: [orders, business-customer, portal, panel, reports, dashboard, properties, invoices, messages, help, company]
supersedes: []
created: 2026-10-17
updated: 2026-10-18
---
## Rule
Every number, column and filter in the Business portal (dashboard, orders and jobs, properties,
reports, order a service) MUST be computed from data the business customer already owns:
their `customer_tasks` projection, their `customers/{uid}.houses` and the public `services`
catalogue. A designed element with no backing field (invoicing, cost center, approvals, proof
photos, exports, scheduled reports, multi-user permissions beyond the single Owner row, PO number, access instructions) MUST be left out until the backend
exists; it MUST NOT be rendered with placeholder, zero or invented values.

## Rationale
The design shows a mature B2B product; shipping fake KPIs to a paying company is worse than
omitting them.

## Implementation
- Cancelled tasks are not exposed by the customer task mapping, so they are not listed.
- Task to property linking is by matching the task address to a house address (tasks carry no
  house id). Unmatched tasks show the address only.
- Order numbers use the existing 6-digit display rule (`orders-order-number`).
- Order a service places real orders: for the selected service and each selected property it
  calls `bookMarketplaceService` then `scheduleTask` (one order per property), with no payment
  step; orders stay unpaid until payment is initiated (payment and credit redemption are a
  follow-up). Success shows a success toast and navigates to Orders and jobs.
- The timing card has an optional date and an optional time (time requires a date). No date and
  time is a flexible schedule; date only is the picked day with morning, afternoon or evening
  slots; date and time is the exact time slot. The same schedule applies to every property order.
- Invoices has no backend (no invoice entity) and shows only a title and an empty card "No invoices". It MUST NOT show KPIs, a table, receipts, paid/unpaid status, Pay or Download controls, and MUST NOT use `paidAt` or `getCustomerReceipt`.
- Messages are the existing per-order chat between the customer and the assigned SP
  (`communication/{taskId}`, send by `sendTaskMessage`, read marker by `markTaskChatReadCustomer`).
  Threads exist only for orders with an assigned provider. There is no support inbox or
  property-manager thread, so none MAY be shown; "Read" is shown only when `providerLastReadAt`
  is at or after the message time.
- Help is static localized copy. The FAQ MUST describe only behavior the product has (one order
  per property, per-order chat, Company details); it MUST NOT promise monthly
  invoicing, billing groups, colleague invitations or automatic rescheduling. Support contact is a
  `mailto:` link to the Servido customer-service address; no search, no account manager.
- Company details shows only fields that can be stored: company name, business ID, VAT number,
  street address, postal code, city, billing email (`business_customers/{uid}`, written by
  `updateBusinessCompany`) and the primary contact name, phone, email (`customers/{uid}.contact`,
  written by `updateProfile`). Industry, billing reference, payment terms, invoicing cycle and
  e-invoice address MUST NOT be shown.
- Users and permissions shows exactly one row: the logged-in user (name and email from
  `customers/{uid}.contact`, company name from `business_customers`) with role Owner and status
  Active. It has no team backend, so it MUST NOT show an invite button, add/remove/edit actions,
  other roles (and no explainer for them; only the Owner description) or any other user.
- Every sidebar item has a screen; a titled empty page is used only for items that have no data.

## Verification
With a business customer who has no houses and no tasks, every list shows an empty state, every
KPI shows 0 or is absent, and no screen contains a cost center, PO number, access instructions, invoice
amount, proof-photo or export control. Selecting 2 properties and pressing Place order creates 2
orders with the same schedule and opens Orders and jobs.

Invoices always shows only "No invoices", whatever orders exist, with no KPI, table or Download. Users and permissions shows one row (the logged-in user, Owner, Active) and no invite or manage control. Messages for a business customer
with no assigned-provider orders shows an empty state and no support thread.
