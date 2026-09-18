---
id: cms-service-promo-text
domain: cms
title: Website service promo line is a dedicated manager-edited promoText property, distinct from description
status: active
applies_to: [web]
tags: [cms, services, website, promo, promotext, manager, copy]
supersedes: []
created: 2026-06-24
updated: 2026-06-24
---
## Rule
The short promo line shown for a service on the public website (e.g. "Crystal clear
windows by verified cleaners" — the line currently hardcoded as `description` in the
website's `services.json`) MUST be sourced from a dedicated, manager-edited
`ServiceProperties.promoText` property. `promoText` is a NEW localized (fi/en) field on
the service, edited through the existing service form and persisted by the existing
`updateService` / `updateLocalService` callable. It is SEPARATE from
`ServiceProperties.description` (the long service description) and MUST NOT reuse or
overload it — the two fields serve different purposes and may differ in wording.

## Rationale
- The website was built detached from the core system, so the field it calls
  `description` is really the promo line. The core system's `description` is the long
  service description; conflating them couples two distinct concepts and forces the
  manager to choose one wording for both surfaces.
- A first-class `promoText` field gives the manager direct control of the website promo
  line, edited in the same service form as every other service property, with no second
  editor and no separate override doc/collection.
- Read path follows the established CMS model (a build script pulls Firebase and composes
  the static `services.json` — no per-visitor runtime request), exactly like the existing
  placement (`surfaces`) overlay.

## Implementation
- `promoText` is added to `docs/schemas/service-properties.schema.json` as an optional
  localized-text field; types are regenerated for both backend (`npm run generate:types`)
  and Flutter (`docs/export-flutter-transaction-types.sh`).
- Manager panel service form gains a `promoText` `LocalizedFormEntryBloc` field
  (`web_ui` `ServiceFormBloc`), a corresponding `MpFormEntry` section in the form view,
  draft load/build wiring (`service_draft_bloc.dart`), and fi/en labels — modeled on the
  existing optional `helpText` field.
- Build-time overlay only: `servido-website/scripts/generate-services.mjs` fetches each
  service's live `properties.promoText` (fi + en) from the `services` collection (keyed by
  the slug→serviceId map in `real-service-ids.ts`) and writes it onto the website service's
  promo line (the `description` field in `services.json`) when a non-empty value exists.
- Fallback is load-bearing: a service with no DB id, an unreachable DB, or an empty/blank
  `promoText` keeps the existing authored copy in `services.json` — a missing value MUST
  NEVER blank the promo line. `--no-fetch` leaves the promo line untouched.

## Verification
After a manager sets a service's `promoText` and the CMS generator runs against that env,
the regenerated `services.json` MUST carry the manager-edited fi/en promo text for that
service, and a service with no DB `promoText` MUST retain its prior authored copy (the
generator never blanks a promo line). A `--no-fetch` regen MUST leave every service's promo
line byte-identical. The manager-set `promoText` MUST round-trip through the service form
(save then reopen shows the saved value) and MUST NOT alter the separate `description`.
