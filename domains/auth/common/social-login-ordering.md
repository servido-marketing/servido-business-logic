---
id: auth-social-login-ordering
domain: auth/common
title: Social logins always appear before email login
status: active
applies_to: [web, mobile, all]
tags: [auth, login, signup, ui-order, social, google, apple, phone]
supersedes: []
created: 2026-06-14
updated: 2026-06-14
---
## Rule
On every authentication surface (login AND signup), social login options MUST render
**before** the email/password form. Email/password is always the last option.

## Rationale
- Higher conversion: social auth is one tap vs. typing credentials.
- Parity with the Servido mobile app, where social is already primary.
- Reduces password fatigue and support load from forgotten passwords.

## Implementation
- Order, top to bottom: **Google → Apple → Phone (OTP)** → divider ("or") → email/password form.
- Applies to BOTH the login surface and the signup surface.
- The divider visually separates the social cluster from the email form.
- If a provider is unavailable on a given surface, keep the relative order of the rest.

## Verification
Proof screenshot of the login (and signup) surface MUST show the social buttons
positioned above the email input field, with email/password last.
