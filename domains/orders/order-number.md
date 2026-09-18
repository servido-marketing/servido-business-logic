---
id: orders-order-number
domain: orders
title: Every gig is assigned an opaque 6-digit order code
status: active
applies_to: [web, mobile, all]
tags: [orders, order-number, reference, code, customer, panel, task]
supersedes: []
created: 2026-07-26
updated: 2026-07-26
---
## Rule

Every task/gig MUST be assigned an opaque, human-readable **order code** at creation time,
server-side. The code is a 6-digit numeric string (e.g. `482913`), NOT a sequential index — it
must not reveal creation order, position, or total volume of tasks. It is immutable once
assigned, globally unique across the whole platform, and MUST be displayed to the customer
(website + mobile) and in all provider/manager panels wherever the task is referenced.

## Rationale

Operators, customers, and support need a short reference they can read over phone/chat/email
instead of a long opaque Firestore document id. It must look and feel like an order code (a
random-looking 6-digit number), not a running counter — a sequential index would leak how many
tasks the platform has processed and when a given task was created relative to others, which the
operator explicitly does not want exposed.

## Implementation

- Generation: draw a random 6-digit numeric string (`000000`–`999999`, zero-padded, i.e.
  effectively a value drawn uniformly and rendered as fixed-width digits — NOT a counter, NOT a
  hash of a sequence, NOT derived from timestamp or document id in any decodable way). Reserve
  and check uniqueness via a Firestore registry doc per code (`orderCodes/{code}` created inside
  the SAME transaction that creates the `TaskCreated` event, guarded by the doc not existing).
  On collision (doc already exists), redraw and retry within the transaction — collisions are
  rare at this keyspace but the retry loop is required, not optional.
- The assigned string is stored once as `orderNumber` on `TaskCreatedEvent` (so it's derivable
  from replaying events) and is projected verbatim (no re-derivation) onto every read-projection
  a task appears in: `CustomerTask`, `ProviderTask`, `ServicesManagerTask`.
- Display format: the stored 6-digit string is split into two 3-digit groups joined by a dash
  and prefixed with `#`, e.g. stored `234456` displays as `#234-456`. This is a pure display-time
  transform (`orderNumber.substring(0,3) + '-' + orderNumber.substring(3,6)`) applied identically
  on every surface — the stored/transmitted value itself remains the plain 6-digit string, only
  rendering adds the dash. Existing tasks are NOT backfilled retroactively as part of this card —
  only newly created tasks after this ships get an `orderNumber`; older tasks show no order code
  badge.
- Customer-facing surfaces (website My Orders / task detail, mobile app task list / task detail)
  and manager/provider panels (task list rows, task detail header) all render the same
  `#XXX-XXX` badge next to the existing task name/date, sourced from `orderNumber` on their
  respective projection and dash-formatted at render time — never recomputed/re-derived
  client-side beyond this display split.

## Verification

- Creating many tasks yields `orderNumber` values that are 6-digit numeric strings with no
  detectable sequential/incremental relationship to creation order (i.e. NOT simply +1 each
  time), each globally unique (proven via a test that fires N concurrent `TaskCreated` writes
  and asserts N unique 6-digit codes come out, retrying on any simulated collision).
- `CustomerTask`, `ProviderTask`, and `ServicesManagerTask` docs for a newly created task all
  expose the identical `orderNumber` value.
- The customer-facing task list/detail (website + mobile) and the provider/manager panel task
  list/detail all render a `#XXX-XXX` dash-grouped badge (derived from the 6-digit
  `orderNumber`, e.g. `234456` → `#234-456`) for a task that has one, and render nothing
  (no crash, no `#undefined`) for a pre-existing task without one.
