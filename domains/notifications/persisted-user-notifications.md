---
id: notifications-persisted-user-notifications
domain: notifications
title: Every dispatched notification is persisted per-recipient and inspectable in worker/company-manager panels
status: active
applies_to: [all]
tags: [notifications, worker-panel, manager-panel, company-panel, inbox, panel]
supersedes: []
created: 2026-09-03
updated: 2026-09-03
---
## Rule
Every notification `notify()`/`notifyEvent()` dispatches (email, push, or sms — regardless of
whether that specific channel is actually enabled/sent for the event kind) MUST also write ONE
record to a per-user `user_notifications/{userId}/items/{notificationId}` subcollection for the
resolved recipient. This applies uniformly whenever the actor role is `provider` (worker_panel /
provider_panel) or `manager` (company_panel / manager_panel) — customer-facing surfaces are out of
scope for this card. The persisted record is written even when every channel is disabled/no-op for
that event kind (silent-channel rule from `notifications-management` still governs actual
delivery; persistence is independent of delivery). Workers (COMPANY role, worker_panel) and company
managers (COMPANY role, company_panel) MUST be able to open a Notifications module listing their own
persisted records, newest first, with read/unread state.

## Rationale
Channel delivery (email/push/sms) is transient and can silently no-op (missing config, missing
template, network failure) per `notifications-management`. Persisting a durable record independent
of delivery gives workers/managers an always-available in-app inbox to inspect what happened,
regardless of whether the configured channel actually reached them — critical for company workflows
where a worker/manager may miss an email/push and needs to audit assignment/status events later.

## Implementation
- New collection `user_notifications/{userId}/items/{notificationId}`, schema
  `docs/schemas/user-notification.schema.json`: `{id, eventKind: NotificationEventKind, actorRole:
  'provider'|'manager', title, content, data: Record<string,string>, read: boolean, createdAt}`.
  `title`/`content` mirror the same `data['Title']`/`data['Content']` values already threaded to the
  push sender in `notifyEvent()` — reuse that derivation, don't add a second templating path.
- `notifyEvent()` in `cf/functions/src/utils/notifications.ts` writes this record for every
  `actorEntries` entry whose `role` is `provider` or `manager`, unconditionally (before/independent
  of the per-channel `channels.*.enabled` checks) — one Firestore write per actor per event,
  alongside (not instead of) the existing channel dispatch logic.
  `docs/transaction-schemas/mark-notification-read-request.schema.json` — the only client mutation
  is marking read; nothing else writes this collection directly.
- Worker panel (worker_panel) and company manager panel (company_panel) each get a Notifications
  module: a list view reading `user_notifications/{currentUserId}/items` ordered by `createdAt`
  desc, unread-count badge in the side menu (consistent with the existing chat unread-badge pattern
  per `orders-gig-communication-sp-chat-hub`), and a tap-to-mark-read action calling
  `markNotificationRead(notificationId)`.

## Verification
Proof shows: (a) triggering any event kind whose actors include `provider` or `manager` (e.g.
`taskPlanned`, `companyTaskUpdated`, `workerJoinedCompany`) results in a new
`user_notifications/{userId}/items` doc for that actor even when the event kind has NO channel
config (nothing published) or all channels disabled; (b) the worker_panel Notifications module for
that userId lists the record with correct title/content and unread state; (c) the company_panel
Notifications module shows the same for a manager actor; (d) marking a notification read via
`markNotificationRead` persists `read: true` and updates the unread badge; (e) a user cannot read or
mark-read another user's `user_notifications` subcollection (Firestore rules + callable ownership
check).
