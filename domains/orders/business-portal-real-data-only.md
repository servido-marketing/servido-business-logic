---
id: orders-business-portal-real-data-only
domain: orders
title: Business portal screens MUST show only figures backed by real order and property data
status: active
applies_to: [web]
tags: [orders, business-customer, portal, panel, reports, dashboard, properties, invoices, messages, help, company]
supersedes: []
created: 2026-10-17
updated: 2026-10-19
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
- The timing card has an optional date and a preferred time of day. Empty date is as soon as
  possible; a set date is the requested day. Time of day is a single choice: Any time (default),
  Morning, Afternoon, Evening, or Exact time (exact time requires a date and is not offered
  without one). Labels show the product's buckets (morning 8-12, afternoon 12-17, evening 17-21).
  The schedule sent per property order: no date + Any time = `FlexibleSchedule` with no range
  and no day times; no date + a bucket = `FlexibleSchedule` with `dayTimes` = [that bucket]; date
  + Any time = `PickedSchedule` with that day and all three buckets; date + a bucket =
  `PickedSchedule` with that day and one `dayTime` slot; date + Exact time = `PickedSchedule`
  with one `exactTime` slot (`orders-booking-exact-time-selection`). The value lives only in the
  `TaskScheduled` event schedule written by `scheduleTask`; no field is added to the task
  document or the schedule schema. A from-to time window and a date range are not offered: a
  slot carries one `dayTime` or one `exactTime` and no end time, and `PreciseSchedule` is the
  whole-hour duration booking. The summary Timing row reads "{date or As soon as possible} .
  {time of day}" and omits the time-of-day part for Any time. The same schedule applies to
  every property order. Recurring is not offered.
- Order details (opened by selecting a row in Orders and jobs) is read-only, follows the Order detail
  design, and shows only what the `customer_tasks` projection carries: back link to Orders and jobs,
  service title and status pill, subtitle "Order {number} . {property name, address} . Ordered {date}",
  a three-step progress (Ordered at `createdAt`, Confirmed at the planned time, Completed at the
  completion time; only reached steps carry a date), Schedule (date and time of day from the requested
  schedule, expected duration of the service when it has one), Service (icon, name, description, chosen
  options and additional work), the customer's note (details text), assigned provider names, activity
  rows derived from order, planned and completion times, the customer's own feedback, and a pinned side
  column with status, key facts (when, property, provider) and price (service price, additional work
  with customer prices, total = the price shown in the Orders list). Sections with no data are omitted,
  not shown as placeholders. It MUST NOT show: provider reward or deductions, provider contact, rating,
  company or job count, customer contact data, who placed the order, access instructions, cost
  center or PO, VAT or incl.-VAT amounts, discount, invoice terms or an Invoiced step, an In progress
  step or "started" times, proof or before/after photos (task #618), guidelines, manager notes, a maps
  link, or any control that changes the order or opens chat (Message provider, Reschedule, Cancel). If
  the order is no longer in the customer's task list, the view shows an empty state with a way back.
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
orders with the same schedule and opens Orders and jobs. With no date and Morning selected,
the placed order's schedule is a `FlexibleSchedule` with `dayTimes` [morning] and the SP panel
shows Morning; with a date and Afternoon, it is a `PickedSchedule` with one afternoon slot;
Exact time is unavailable until a date is set.

Invoices always shows only "No invoices", whatever orders exist, with no KPI, table or Download. Users and permissions shows one row (the logged-in user, Owner, Active) and no invite or manage control. Messages for a business customer
with no assigned-provider orders shows an empty state and no support thread.

With one order opened from Orders and jobs, Order details shows no reward, provider contact, photo, edit, cancel, reschedule, message or pay control and no VAT, cost center, PO, access instructions or Invoiced step, and an order whose data has no details text, duration, additional work, planned or completion time or feedback omits those parts instead of showing placeholders.
