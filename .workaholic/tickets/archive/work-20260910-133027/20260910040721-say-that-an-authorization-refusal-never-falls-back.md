---
created_at: 2026-09-10T13:07:21+09:00
status: done
author: a@qmu.jp
assignees: 
depends_on:
feedback: 20260908123552-slack-bot, 20260908123606-honor-repository-declared-qfs-slack-bindings-before-connector-fallback
merge_policy:
verification_handoff: 
claim: work-20260910-133027
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

## Final Report

Development completed as planned. The defect was exactly as the ticket read it, and the repair is
prose plus a pin; the mechanism is byte-identical.

**Step 1 — the code was read rather than restated.** `qfs_fallback_class()`
(`perform.sh:75-83`) maps `qfs_unavailable` → `availability`, `qfs_operation_unavailable` /
`qfs_map_unverified` → `capability`, `qfs_preview_failed` → `reachability`, and
`qfs_preview_refused` → **`none`** (`*` → `none` behind them). Both consumers stay put on it: the
read path at `perform.sh:159` returns the adapter's result unchanged the moment
`read_fallback_class` — which composes `qfs_fallback_class` and only adds
`qfs_connector_failure` → `reachability` — answers `none`; the write path at `perform.sh:308`
guards its whole fallback block on `!= none`, so an authorization refusal never enters it. The
ticket's reading was accurate in both directions.

**Step 2 — `CLAUDE.md` now distinguishes typed from fallback-permitting.** The four words and
their parentheticals are kept, no class is renamed and no token moved; what is added after the
list is that exactly one of the four does not permit a fallback, which one, what the code does
(`qfs_fallback_class()` maps it to `none`; the read path returns the refusal unchanged, the write
path skips the block), and why — *an authorization denial stays a refusal*, on
`branching/scripts/refusal-capability.sh`'s `not_permitted` doctrine, which the paragraph now
cites rather than re-derives. It closes with the failure mode in the ticket's own terms: a reader
implementing a new adapter from that paragraph must refuse, never fall through to the connector,
which would carry traffic a provider had refused the declared route permission for.

**Step 3 — no other surface repeats the grouping.** `plugins/workaholic/skills/transport/SKILL.md`
already reads correctly: its typed-fallback paragraph lists three classes and then states
separately that *`qfs_preview_refused` preserves the refusal and never changes route to escape an
authorization decision*. A tree-wide search for the word found no other prose carrying the
four-way grouping; the `outputs/` copies are generated from scripts that are unchanged, and
`node scripts/build-plugins/build.mjs` produced no diff.

**Step 4 — the distinction is pinned, so the two cannot drift again.** A new suite row, *an
authorization refusal is typed and never falls back*, asserts both halves against each other: the
code by its mapping (`qfs_preview_refused) echo none`, read with comments stripped so a sentence
about the class cannot stand in for the mapping, plus that `read_fallback_class` composes the one
derivation rather than carrying a second rule), and the prose by the distinction it must draw. The
prose half checks meaning-bearing phrases rather than a whole wrapped sentence, because the
paragraph may legitimately be rewrapped and the rule is the distinction, not the line breaks. This
is the pinned-sentence shape the ticket named as the smaller change; no new script was added.

**Acceptance.** `git diff` over `plugins/workaholic/skills/transport/scripts/` is **empty** — no
class remapped, no consumer widened. `node scripts/test-workflow-scripts.mjs` reports **7130
passed, 0 failed** (7125 before, plus the five assertions of the new row) and
`node --test scripts/tests/agentic-loop/*.test.mjs` reports **124 pass, 0 fail**, including `P3 a
preview that answers ok:false is a refusal, not an acceptance`, which pins the behaviour this
change deliberately did not touch. `build-plugins/verify.mjs`, `validate-metadata.mjs` and
`layout-doctor.sh` (`conforming: true`) are green.

**One ticket minted.** `perform.sh`'s write path carries a comment naming *capability,
authorization, availability* as the classes a write may leave the route on, immediately above the
guard that excludes authorization — the same disagreement, one layer down, in the file a reader
would check to settle the question. This ticket's own Quality Gate requires that file byte-identical,
so it could not be repaired here:
`20260910143000-name-the-write-path-s-fallback-classes-as-the-code-maps-them.md`, carrying this
ticket's own `feedback:` refs.
