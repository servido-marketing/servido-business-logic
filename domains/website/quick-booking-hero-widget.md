---
id: website-quick-booking-hero-widget
domain: website
title: Homepage hero shows a desktop-only quick-booking card instead of plain hero art
status: active
applies_to: [web]
tags: [website, hero, booking, homepage]
supersedes: []
created: 2026-09-25
updated: 2026-09-25
---
## Rule
On desktop (`lg:` breakpoint and up), the homepage hero section MUST display a compact
"quick booking" card in place of the floating service-card visual, letting a visitor pick a
service + postal code and jump straight into the booking wizard with that selection
pre-applied. On mobile/tablet the hero MUST keep its current layout (search bar + floating
service card grid) unchanged — the quick-booking card is desktop-only.

## Rationale
Mirrors a competitor pattern the operator specifically asked to replicate (see
`slack-imgs.png`): a compact right-column card that shortcuts straight to "pick a time" and
reduces the number of clicks between landing on the homepage and reaching the wizard, without
adding a new form step or new backend contract. Mobile is excluded because the vertical card
doesn't fit above the fold on small screens and the existing search+grid pattern already
serves that surface well.

## Implementation
- New client island `QuickBookingCard.tsx` renders in the desktop-only column of
  `HeroSection.astro` (`hidden lg:block`, replacing the existing floating-card block at that
  breakpoint only — the mobile grid block stays untouched).
- **Real next-available-slot backend (revised per operator 2026-09-25):** a new
  `customerHotline`-routed callable `getHomepageNextAvailableSlot` (no request params) computes:
  1. Take all real providers known to the site — the `tekijat-generated.json` catalog (the
     existing static export of real Firestore provider profiles used site-wide for `/tekijat/*`,
     keyed by provider Firebase UID). This is "all SPs from the homepage" in the sense the
     homepage's real-provider surface (`/tekijat`) draws from — no new provider data source.
  2. For each provider, take all of that provider's services (`generated.services[]`, already
     present per-provider in the same file — id/name/price).
  3. For each provider, fetch their weekly availability the SAME way
     `getProviderWeeklyAvailability` already does (refactor its per-provider day/slot
     computation out of that file into a shared helper, e.g.
     `computeProviderAvailabilityDays(db, providerId, weeks)`, and call it from both callables —
     no duplicated iso-week/slot math). Availability is per-provider (a provider's slots apply
     across all their services), so the "first available slot" is really "first available
     provider-day-slot, not sooner than 4h from now."
  4. Compute `now + 4h` in UTC. Walk each provider's `days[].slots[]` in chronological order,
     skip any slot whose start instant (`date` + `startHour:startMinute`, provider-local
     Europe/Helsinki) is before that cutoff, and take the single globally-earliest qualifying
     slot across ALL providers. Return `{ success: true, slot: { providerId, providerName,
     serviceId, serviceName, date, startHour, startMinute } | null }` — `null` when no provider
     has any qualifying slot in the scanned window (reuse `getProviderWeeklyAvailability`'s
     `MAX_WEEKS`/8-week horizon).
  5. `serviceId`/`serviceName` for the returned slot: since availability is per-provider not
     per-service, pick the provider's FIRST listed service (`generated.services[0]`) as the
     representative service for the CTA target — do not invent per-service availability that
     doesn't exist in the data model.
  - New docs contracts: `docs/transaction-schemas/get-homepage-next-available-slot-response.schema.json`
    (no request schema needed — no params). No new Firestore writes, read-only aggregation over
    existing `providers_weekly_availability` docs for the providers in `tekijat-generated.json`.
  - **Single round-trip (per operator 2026-09-25):** the callable itself performs the fan-out —
    it loops all providers/services server-side inside one function invocation and returns only
    the single globally-earliest winning slot. The client makes exactly ONE call
    (`getHomepageNextAvailableSlot`) on mount; it never calls per-provider/per-service availability
    endpoints individually to compute this line.
- Fields, top to bottom:
  1. A "next available" line — now REAL: rendered from `getHomepageNextAvailableSlot`'s result,
     fetched client-side on mount (loading skeleton → formatted `DD.MM. HH:mm` local Finnish
     time; falls back to static teaser copy if `slot` is `null` or the call errors — no console
     error surfaced to the user in that case).
  2. Service picker — a `<select>` sourced from the SAME `services-json` marketing catalog
     already used by `HeroSearch`/`ServiceCard` (`servicesForSurface('hero')` or the full
     `services` list, filtered to non-hidden) — this stays the marketing catalog for the
     dropdown; the "next available" line is a separate, factual real-data signal above it, not
     tied 1:1 to the dropdown's current selection (no live re-query on dropdown change — that
     would require a new per-service/per-provider endpoint out of scope for this simple pass).
  3. Postal code text input (numeric, FI 5-digit), client-validated only (non-empty, 5 digits) —
     no coverage-area lookup call from this widget; the wizard itself already validates/derives
     coverage further down the funnel.
  4. Two static trust bullets (reuse copy patterns already present in the hero: "maksa vasta
     työn jälkeen" style / kotitalousvähennys) — reuse existing i18n strings, do not invent new
     policy claims.
  5. Primary CTA button ("Valitse aika" / en: "Pick a time") — on click, navigates to
     `/${lang}/palvelut/${selectedService.slug}?zip=${postalCode}` (the existing real-service
     product page route, using the user's DROPDOWN selection, not the fetched slot's provider —
     the fetched slot is informational only). Do NOT invent a new checkout/booking endpoint or
     bypass the existing service→wizard funnel.
- Card visual style: white rounded-2xl card, shadow-xl, matches the site's existing card
  tokens (same `border`, `shadow-lg`/`shadow-xl`, `rounded-2xl` used elsewhere in
  `HeroSection.astro`/`ServiceCard`), NOT the mockup screenshot's own literal colors — map to
  `var(--primary)`/`var(--foreground)`/`var(--muted-foreground)` tokens.

## Verification
- Desktop (`lg:` and up) homepage hero right column shows the quick-booking card (real "next
  available" line + service select + postal code input + CTA) instead of the floating
  service-card visual.
- Mobile/tablet (below `lg:`) homepage hero is visually unchanged — still search bar + 2-col
  service card grid, no quick-booking card present.
- `getHomepageNextAvailableSlot` returns a slot whose computed start instant is >= (call time +
  4h) — never a sooner slot, never a slot from a provider with zero remaining capacity that day.
- With all providers' availability docs empty/missing, the callable returns `slot: null` and the
  card falls back to static teaser copy — no thrown error, no broken UI.
- Selecting a service + entering a 5-digit postal code + clicking the CTA navigates to that
  service's real page (`/${lang}/palvelut/${slug}?zip=...`) — no console errors, no new
  network calls to an undefined endpoint.
- CTA is disabled (or no-ops) when no service is selected.
