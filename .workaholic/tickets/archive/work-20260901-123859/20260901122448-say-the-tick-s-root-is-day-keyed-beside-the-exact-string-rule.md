---
created_at: 2026-09-01T12:24:48+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-tick-add-to-a-standing-thread-instead-of-restating-itself
merge_policy:
verification_handoff: 
---

# Say the tick's root is day-keyed beside the exact-string rule

## Overview

PROPOSED. `workaholic:notify` prohibits fuzzy matching by name — "never a similarity match,
never 'the most recent thread that looks related', never recency" — written after a 2026-08-05
misfire, and it also states that the tick's root is keyed `tick:<tick-id>`. Once the key is the
day, both sentences need to be true together and visibly so: the tick threads by an **exact
string it derives**, not by recency, so the prohibition is untouched rather than carved out.
This writes that down where the rule lives, so the next reader does not have to infer it.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/notify/SKILL.md` — the lookup's normative statement and the fuzzy-match prohibition.
- `plugins/workaholic/skills/notify/reference/notifications.md` — where the prohibition's history is recorded.
- `plugins/workaholic/skills/moderate/SKILL.md` and `CLAUDE.md` — the tick's own description of its posting.

## Implementation Steps

1. In `workaholic:notify`, state the tick's key as the **day** rather than the tick, beside
   the exact-string rule, and say in one sentence why that is not a recency match: the key is
   derived from the tick's own id, so the search is the same exact-string search it always
   was, and no thread is ever chosen for looking related.
2. Record in `reference/notifications.md` what changed and what did not — the 2026-08-05
   misfire and the prohibition it produced are untouched; what moved is one key's derivation.
   Name the measurement that moved it (14 roots, 12 with no questions).
3. Update `CLAUDE.md`'s `/moderate` section and `workaholic:moderate` so the day-keyed root and
   the delta reply are described where each is read. **In the same change** — an outdated
   document is a defect here, not a follow-up.
4. Check the generated bundle carries the same words (`node scripts/build-plugins/build.mjs`),
   since `outputs/` is committed and CI fails on drift.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `workaholic:notify` states the day key and why it is not recency, in the same place as the
  prohibition.
- No document still describes the root as keyed per tick.
- `outputs/` is regenerated and matches.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- A grep for `tick:<tick-id>` across `plugins/`, `docs/` and `CLAUDE.md` returning only
  historical passages that are explicitly dated.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` — the post-format drift rows still pass.

## Considerations

- The prohibition is **not** being loosened, and the wording should make that hard to
  misread later: a future reader looking for permission to match by recency must not find it
  here.
- The post shapes' tokens are byte-pinned against drift by `test-workflow-scripts.mjs`; a
  reworded shape must move both copies in the same commit or the suite fails.
