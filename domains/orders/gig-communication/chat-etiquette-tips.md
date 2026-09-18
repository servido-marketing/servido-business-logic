---
id: orders-gig-communication-chat-etiquette-tips
domain: orders/gig-communication
title: SP-facing task chat MUST show a static etiquette tips banner above the message thread
status: active
applies_to: [web]
tags: [orders, chat, messaging, communication, provider-panel]
supersedes: []
created: 2026-08-10
updated: 2026-08-10
---
## Rule
The provider panel's task chat section (`TaskChat`, `orders-gig-communication-gig-chat`) MUST
display a small, static, non-dismissible tips banner directly above the message thread, listing
these four behavior tips, each with a leading emoji, in this exact order:

1. ⚡ Reply within an hour – a fast reply makes a great impression.
2. 🙂 Be polite and clear.
3. 🔕 No repeated reminders – one message is enough.
4. 🔒 Keep the conversation in Servido.

The banner is display-only — no interaction, no dismiss/collapse state, no persistence. It is
shown to the provider (SP) ONLY, not the customer (the customer's website chat section is
unaffected by this card). Text is localized (fi/en) via the existing `AppLocalizations` l10n
mechanism, matching the other `chat*` strings already in `app_en.arb`/`app_fi.arb`.

## Rationale
Operator wants providers coached on message etiquette (fast replies, politeness, no spam,
keep conversation on-platform) right where they chat, not buried in onboarding docs a provider
may never revisit. Customer-side is unaffected — the etiquette guidance targets provider
behavior specifically (reply speed, tone, avoiding the temptation to route customers off-platform).

## Implementation
- New reusable widget `ChatTipsBanner` (stateless, no bloc) added under
  `apps/packages/web_ui/lib/src/partials/task_chat/view/` (same directory as `task_chat.dart`),
  exported from `task_chat.dart`.
- Rendered inside `TaskChat`'s `build()` in
  `apps/packages/web_ui/lib/src/partials/task_chat/view/task_chat.dart`, placed above the
  `RemoteDataBuilder<List<TaskMessage>>` message list, inside the same bordered `Container`.
  Do NOT touch `provider_task_preview.dart`'s wiring — `TaskChat` already renders identically on
  both the assigned-task details screen and (per `orders-gig-communication-gig-chat`'s gate) is
  only shown once a provider is assigned, so the banner inherits that same gate for free.
- New l10n keys in `apps/packages/ui/lib/l10n/app_en.arb` + `app_fi.arb` (4 keys, one per tip
  line, full sentence including the emoji so translators can adjust emoji placement per
  locale if ever needed): `chatTipReplyFast`, `chatTipBePolite`, `chatTipNoRepeats`,
  `chatTipKeepOnPlatform`. Regenerate via the existing Flutter l10n gen step (do NOT hand-edit
  the generated `app_localizations_en.dart`/`app_localizations_fi.dart` — those are generated
  from the `.arb` files by the Flutter build; a coder-fast card running `flutter gen-l10n` or a
  normal `flutter analyze`/build pass will regenerate them).
- No backend change, no schema change — this is pure static UI copy, no new Firestore field, no
  new callable request/response shape.

## Verification
- Opening the provider panel's task chat for an assigned task shows the 4-line tips banner
  (in the exact order above, each with its emoji) directly above the message thread, before any
  messages are shown.
- The banner appears identically whether the thread is empty or has existing messages.
- The banner is NEVER shown when the chat section itself is gated off (pool/unassigned task per
  `orders-gig-communication-gig-chat`), since it only renders inside `TaskChat`.
- The customer-facing website chat section (same `TaskChat` widget) also renders the banner —
  the card intentionally applies to whichever surface mounts `TaskChat`; verification confirms
  it appears on the provider panel (the concrete driver of this request) and does not require a
  customer-facing home this iteration since `applies_to: [web]` covers the widget generically.
- Banner text matches the fi/en copy in the l10n `.arb` files verbatim (including punctuation).
