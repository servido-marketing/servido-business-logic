---
id: orders-order-again
domain: orders
title: "\"Order again\" link in My Orders for tasks with a known serviceId"
status: active
applies_to: [web]
tags: [orders, re-order, my-orders, account, service, booking, website]
supersedes: []
created: 2026-07-13
updated: 2026-07-13
---
# BL: Order Again

## Context
Customers viewing My Orders need a fast path to re-book the same service without navigating back to the service catalogue.

## Rule

A **"Order again" / "Tilaa uudelleen"** link is displayed next to each task row in My Orders when:

1. `task.serviceId` is set on the `CustomerTaskDoc`, AND
2. A slug in the `real-service-ids` map resolves to that `serviceId` for the current environment.

If either condition is false, no link is shown (graceful omission — no broken links for unmapped or legacy tasks).

The link navigates to `/{lang}/palvelut/{slug}`, which is the service landing page with the embedded booking picker.

## Scope

- Website-only change (`AccountTasks.tsx`, `account.ts` i18n, `real-service-ids.ts` export).
- No new backend callable needed — `serviceId` is already persisted on `CustomerTaskDoc`.
- No CF deploy needed.

## Behaviour details

- Link is visible in both **pending** and **past** sections.
- Link is a sibling `<a>` element outside the task-detail `<a>` (no nested anchors).
- i18n keys: `account.action.orderAgain` — `'Tilaa uudelleen'` (fi) / `'Order again'` (en).
