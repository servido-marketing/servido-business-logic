---
id: referral-share-earn-home-promotion
title: Share & Earn promoted on home page hero — replaces response-time badge
status: active
domain: referral
applies_to: [web]
tags: [referral, share, earn, hero, home, badge, promotion, ux]
created: "2026-07-03"
---

## Rule

The home page hero MUST NOT display a "response time" badge (e.g. "Vastaus 30 min" / "Response in 30 min"). That slot MUST instead display a "Share & earn" trust signal that links to a dedicated share & earn explanation page.

The share & earn trust signal MUST:
- Replace the response-time span in the hero's trust-signal row (the row next to the money-back guarantee link)
- Use the same visual weight as the money-back guarantee link (underlined, same font size)
- Link to `/<lang>/jaa-ja-ansaitse` (fi) / `/<lang>/share-and-earn` (en) — same page, language-routed
- Be translated in both `fi` and `en` i18n entries

The share & earn explanation page MUST:
- Explain the feature in plain language: share a personal link → friend gets 10 EUR off their first order → sharer earns 10 EUR credit toward their next order
- Be accessible at `/<lang>/jaa-ja-ansaitse` for Finnish and `/<lang>/share-and-earn` for English (both routes served by a single page under `[lang]/`)
- Include a clear CTA that sends the user to their account to get their referral link
- Be styled consistently with other informational pages (kotitalousvahennys pattern)

## Rationale

"Vastaus 30 min" promises a response time the product cannot always guarantee and adds no lasting value as a trust signal for marketing. Share & earn is a concrete, value-aligned signal: it tells visitors they can save money AND that other users trust Servido enough to recommend it. Promoting it in the hero increases referral program awareness and conversion, while removing a potentially misleading claim.

## Implementation

1. `src/i18n/hero.ts` — replace `responseTime` key value with "Jaa & ansaitse" (fi) / "Share & earn" (en); no key rename needed.
2. `src/components/home/HeroSection.astro` — change the response-time `<span>` to an `<a>` linking to `/<lang>/jaa-ja-ansaitse`; swap `ClockIcon` for a gift/share icon.
3. New page `src/pages/[lang]/jaa-ja-ansaitse.astro` — explanation page (fi + en via lang param). Route slug: `jaa-ja-ansaitse` for fi, the same for en (one route, two locales).
4. New page `src/pages/jaa-ja-ansaitse.astro` — redirect to `/<lang>/jaa-ja-ansaitse` (same pattern as `kotitalousvahennys.astro`).
5. Optional: add the page to the footer links alongside "kotitalousvähennys".

## Verification

- Home page hero: "Vastaus 30 min" / "Response in 30 min" is NOT visible.
- Home page hero: "Jaa & ansaitse" / "Share & earn" link IS visible in the same row as the money-back guarantee.
- Clicking the link navigates to the share & earn explanation page (200, correct lang).
- Explanation page: states the 10 EUR referral reward clearly in both fi and en.
- Explanation page: CTA links to the customer account section.
