---
id: auth-default-mode-by-context
domain: auth/common
title: Default auth form mode depends on entry context — register standalone, login when embedded in an owned-resource flow
status: active
applies_to: [web]
tags: [auth, login, signup, register, default, context, task-preview, embedded]
supersedes: []
created: 2026-07-04
updated: 2026-07-04
---
## Rule

The login/register form's default (initially-shown) mode MUST depend on where it is
mounted:
- On the standalone `/login` page (a visitor arriving with no other context), the
  default mode MUST be **register**.
- When the form is embedded inline inside a flow that is about accessing a specific
  already-existing owned resource (e.g. the public task-preview login prompt on
  `/tilaukset/[taskId]` and `/order/[taskId]`), the default mode MUST be **login** —
  the visitor almost certainly already has an account tied to that task.

The visitor can always switch modes manually via the existing toggle; this rule only
governs the initial default.

## Rationale

Standalone `/login` is typically reached by a new visitor exploring the product —
register-first matches the growth/acquisition funnel. But a task-detail link is
emailed to an existing customer after they already booked a task, so they almost
certainly have an account — defaulting to register there added friction and produced
confusing "email already in use" register errors for returning customers.

## Implementation

- `LoginForm` (`src/components/account/LoginForm.tsx`) accepts an optional
  `initialMode?: 'register' | 'login'` prop, defaulting to `'register'` when omitted,
  used to seed the `authMode` state.
- The standalone `src/pages/[lang]/login.astro` renders `<LoginForm lang={lang} />`
  with no `initialMode` override — keeps the register default.
- `TaskPreviewCard.tsx` (the inline login prompt used by both `/tilaukset/[taskId]`
  and `/order/[taskId]`) renders `<LoginForm lang={lang} onLoggedIn={onLoggedIn} initialMode="login" />`.
- Social-login ordering (`auth-social-login-ordering`) is unaffected by this rule and
  still applies to both modes.

## Verification

1. Visiting `/login` directly with no prior context shows the register form by default
   (register title/subtitle, register submit copy).
2. Visiting an existing task's `/tilaukset/[taskId]` (or `/order/[taskId]`) while
   unauthenticated shows the inline login prompt defaulted to LOGIN (login title/
   subtitle, login submit copy) — not register.
3. The mode toggle still switches between register and login on both surfaces.
