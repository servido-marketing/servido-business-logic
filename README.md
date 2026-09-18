# Servido Business Logic (`bl`)

Single source of truth for **product domain rules** that bind every Servido app — web,
mobile, and future surfaces. Not code, not agent how-tos: the *what must always be true*
of the product. Tooling-agnostic on purpose, so any worker (Hermes coder, Codex, a human)
can pull rules and act on them.

## Why this exists
Business rules outlive code and tooling. "Social logins always appear before email" should
not live in one app's commit history — it must travel to the next app you build months later.
This repo is that durable, versioned, reviewable catalog.

## Structure
```
bl/
  README.md                 # this protocol
  INDEX.md                  # GENERATED — human-readable catalog (grep this)
  index.json                # GENERATED — machine-readable catalog (pull this)
  templates/rule-card.md    # the card schema
  scripts/
    new-card.sh <domain> <slug>   # scaffold a card
    reindex.sh                    # rebuild INDEX.md + index.json from frontmatter
    lint.sh                       # validate all cards
  domains/
    auth/common/ auth/web/ auth/mobile/
    payments/ orders/ ...         # one .md card per rule
```

## The rule card
One rule = one markdown file with YAML frontmatter. See `templates/rule-card.md`.
Key frontmatter: `id` (stable forever), `domain`, `status` (active|superseded|deprecated),
`applies_to`, `tags`. Body: **Rule / Rationale / Implementation / Verification**.

The `## Verification` line is special: it's phrased as an assertion a proof spec can check,
so a pulled rule becomes a permanent regression check in the consuming app.

## Worker protocol

### PULL — at the start of any task touching a domain
1. `git pull`
2. Grep `INDEX.md` (or read `index.json`) for the task's domain and tags.
3. Read every matched card. **Every `status: active` card is a binding constraint** — honor
   it in BOTH the implementation and the proof spec.
4. If a rule has a `## Verification` line, encode that assertion into the proof spec so it
   becomes a regression check in this app too.

### PUSH — when a task establishes or changes a rule
1. `scripts/new-card.sh <domain> <slug>` to scaffold (or edit an existing card).
2. Fill Rule / Rationale / Implementation / Verification.
3. If it replaces an older rule: set the old card's `status: superseded` and list its id in
   the new card's `supersedes:`.
4. `scripts/reindex.sh` then `scripts/lint.sh` (must pass).
5. Commit on a branch and **open a PR** — business rules ride the same review gate as code.

## Conventions
- `id` is immutable. Never reuse or repurpose an id.
- Deprecate, don't delete: flip `status`, keep history.
- Keep cards app-agnostic; note per-surface differences under `applies_to` / Implementation.
- Run `reindex.sh` before every commit that adds/edits a card — never hand-edit INDEX.md/index.json.
