---
created_at: 2026-09-10T13:07:21+09:00
author: a@qmu.jp
assignees: 
depends_on:
feedback: 20260908123552-slack-bot, 20260908123606-honor-repository-declared-qfs-slack-bindings-before-connector-fallback
merge_policy:
verification_handoff: 
---

# Say that an authorization refusal never falls back

## Overview

`CLAUDE.md`'s typed-fallback paragraph names four classes as the ones an operation may leave
the preferred route on — `qfs_unavailable` (availability), `qfs_operation_unavailable` /
`qfs_map_unverified` (capability), `qfs_preview_refused` (authorization), `qfs_preview_failed`
(reachability) — and then says *every other failure keeps the operation where it was declared*.
The natural reading is that all four permit a fallback. **One of them does not.**

`perform.sh`'s `qfs_fallback_class()` maps `qfs_preview_refused` to **`none`**, and both
consumers refuse to leave the route on it: the read path returns the result unchanged
(`read_fallback_class` → `none`) and the write path skips the fallback block entirely. So an
authorization refusal stays a refusal, which is the same doctrine this repository already
states for a refused merge — *an authorization denial stays a refusal, and no alternate
spelling, parent delegation or second account is used to get past it*
(`branching/scripts/refusal-capability.sh`'s `not_permitted`).

The behaviour is right and deliberate; the prose is what disagrees with it. A reader
implementing a new adapter from `CLAUDE.md` would let an authorization refusal fall through to
the connector — which is precisely the failure the typed-fallback rule exists to prevent, since
the connector would then carry traffic a provider had refused the declared route permission for.

Measured 2026-09-10 while driving
`20260908124152-resolve-qfs-slack-first-and-type-every-connector-fallback`:
`plugins/workaholic/skills/transport/scripts/perform.sh:78` reads `qfs_preview_refused) echo
none ;;`, while `CLAUDE.md`'s *An operation leaves the preferred route only on a TYPED failure*
paragraph lists it among the four. The suite pins the behaviour (`P3 a preview that answers
ok:false is a refusal, not an acceptance` asserts `reason == "qfs_preview_refused"` with no
fallback) and pins nothing about the sentence.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `CLAUDE.md` — the *An operation leaves the preferred route only on a TYPED failure* paragraph
  under *The Slack binding is declared by the repository, not by its environment*.
- `plugins/workaholic/skills/transport/scripts/perform.sh` — `qfs_fallback_class()` (the one
  derivation), `read_fallback_class()`, and the two call sites that read `none`.
- `plugins/workaholic/skills/transport/SKILL.md` — check whether the skill's own text carries
  the same grouping and correct it in the same change if it does.

## Implementation Steps

1. Read `qfs_fallback_class()` and both consumers, and confirm the current classes each word
   maps to rather than restating this ticket's reading.
2. Correct the `CLAUDE.md` sentence so the authorization class is named as a typed failure that
   **does not** permit a fallback, distinguishing *typed* from *fallback-permitting*. Keep the
   four words and their parentheticals; do not rename a class or move a token.
3. Carry the same correction into any other surface that repeats the grouping, in the same
   commit (`transport/SKILL.md`, the reference tree).
4. Consider whether the suite should pin the distinction the way it already pins the report
   wording, so prose and code cannot drift again. A pinned sentence is the smaller change; a
   new script is not warranted.

## Considerations

The behaviour must not move. This is a documentation repair, not a change to which classes
fall back — widening `qfs_preview_refused` into a fallback-permitting class would contradict
the repository's own `not_permitted` doctrine and would route around a provider's refusal.

The mirrored policy pages under `skills/<pillar>/policies/` are upstream hard copies and are
not edited for this.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `CLAUDE.md` states that an authorization refusal (`qfs_preview_refused`) is a typed failure
  that keeps the operation on the declared route, so the four named classes are no longer read
  as four fallback-permitting ones.
- `perform.sh` is byte-identical: no class is remapped and no consumer is widened.

**Verification method** — the commands/tests/probes that prove them:

- `git diff` shows no change under `plugins/workaholic/skills/transport/scripts/`.
- `node scripts/test-workflow-scripts.mjs` and
  `node --test scripts/tests/agentic-loop/*.test.mjs` both report 0 failed.

**Gate** — what must pass before approval:

- A reader implementing a new adapter from `CLAUDE.md` alone would refuse, not fall back, on an
  authorization refusal.
