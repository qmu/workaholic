---
created_at: 2026-08-17T13:32:24+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: register-every-fb-as-an-issue
merge_policy:
verification_handoff: 
---

# Give the FB issue writer an assignee and this repo

## Overview

`feedback/scripts/open-issue.sh` is the only sanctioned writer of an `[FB] ` issue, and
it is written for one destination: **another** repository, unassigned. The unified `/fb`
needs two things it does not have — an **assignee** on the created issue, and an explicit
statement that **this** repository is a legal target. The assignee is load-bearing, not
cosmetic: `[Propose]`'s discovery (`propose/scripts/list-inbound-issues.sh`) lists only
issues assigned to the running identity, deliberately never unassigned ones, so an
unassigned in-repo `[FB]` issue would be ingested by nobody.

This ticket changes the writer only. Routing `/fb` to it is the next ticket, so nothing
observable changes for a caller until that one lands.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:operation` / `policies/observability.md` — a refusal reports its reason, never a silent fallback

## Key Files

- `plugins/workaholic/skills/feedback/scripts/open-issue.sh` — the writer; adds
  `--assignee <login>`, and its header comment (currently "on ANOTHER repository") states
  the widened contract and what is *not* widened with it.
- `plugins/workaholic/skills/feedback/scripts/fb-title.sh` — unchanged; the `[FB] `
  stamping is already idempotent and already applies here.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the one GitHub transport
  (`rules/shell.md`: REST only, never `gh issue …`); `slug` also answers "what is this
  repository", which is how the in-repo target resolves without guessing.
- `plugins/workaholic/skills/feedback/SKILL.md` — the *Scripts* entry and the crossing
  section's framing of `open-issue.sh`.
- `plugins/workaholic/skills/feedback/reference/crossing.md` — the step list that calls it.
- `scripts/test-workflow-scripts.mjs` — hermetic coverage; it must stay `gh`-free.

## Implementation Steps

1. Read `open-issue.sh` end to end, including its header: it deliberately judges nothing
   and masks nothing, and that stays true — this ticket adds a field to the payload, not
   a policy to the script.
2. Add `--assignee <login>` (option, so the three positionals do not move, matching how
   `create.sh` took `--subject`). Passed → the REST payload carries `assignees: [<login>]`;
   absent → the payload carries no assignees key at all, exactly as today.
3. Decide and record where the login comes from: the **caller** resolves it and passes it,
   so this script keeps having no identity opinion. Note in the header that
   `gh api user` is the caller's source, not this script's.
4. State the target rule: the slug must still be `owner/name`, and this repository's own
   slug is now an accepted value rather than an oversight. Keep the `owner/name` shape
   check; do not add a "is this us" branch — the caller decides the destination.
5. Report an assignment that GitHub silently drops (a login without access is dropped by
   the API rather than refused) by echoing back the `assignees` the response actually
   carries, so the caller can report `assigned: false` instead of assuming.
6. Update the feedback skill's `## Scripts` entry and `reference/crossing.md`'s step for
   the new flag, and regenerate the bundle: `node scripts/build-plugins/build.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `open-issue.sh --assignee <login>` creates an issue whose `assignees` contains that
  login, and the emitted JSON reports what the API actually assigned.
- Without the flag, the request body is byte-identical to today's — the crossing is
  unchanged.
- The script still refuses `no target/title/body`, a non-`owner/name` slug, a missing
  body file and an unavailable `gh`, each with its existing message.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — including a case asserting the payload shape
  with and without `--assignee`, built without calling `gh`.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — the
  bundle is regenerated and self-contained.

**Gate** — what must pass before approval:

- The hermetic suite passes and `git status` shows no unstaged `outputs/` drift.

## Considerations

- The header comment is part of the contract here, not decoration: it is the only place
  that says the crossing's gates run *before* this script. Widening the destination
  without widening that sentence is how the next reader concludes the gates moved.
- Assignment failure must not fail issue creation — a filed ask with no assignee is
  recoverable by hand; a lost ask is not.

## Final Report

Development completed as planned. `open-issue.sh` gained `--assignee <login>` as an
option (the three positionals did not move), its header now states the widened
destination and what did **not** widen with it, and the envelope echoes the `assignees`
the API response actually carried so a silently-dropped login reports `assigned: false`
instead of being assumed. Without the flag the request body is byte-identical to what the
crossing has always sent. `SKILL.md` gained an `open-issue.sh` entry under *Scripts*,
`reference/crossing.md` step 7 states the new envelope and that the crossing passes no
`--assignee`, and the bundle was regenerated.

### Discovered Insights

- **Insight**: `open-issue.sh` was already destination-agnostic in code — the only thing
  binding it to "another repository" was `resolve-target.sh`, which refuses this
  repository by slug and routes it to `/ticket`. The in-repo path therefore reuses the
  writer unchanged and simply never calls the resolver.
  **Context**: the two scripts read as one flow but are separable; the next ticket routes
  a destination-less `/fb` without touching either one's refusals.
- **Insight**: an empty `--assignee` had to be a refusal rather than a fall-back to
  unassigned. `list-inbound-issues.sh` filters on `assignee=<login>` server-side, so an
  unassigned in-repo `[FB]` issue is invisible to every `[Propose]` copy — a silent
  unassigned filing would be an ask nobody ever proposes.
  **Context**: the discovery filter is what makes the assignee load-bearing; anything
  that can leave it empty must say so loudly.
