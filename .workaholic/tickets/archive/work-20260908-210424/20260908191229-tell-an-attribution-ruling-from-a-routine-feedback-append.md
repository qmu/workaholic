---
created_at: 2026-09-08T19:12:29+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-loop-grow-a-mission-without-handing-it-back-to-a-person
merge_policy:
verification_handoff: 
---

# Tell an attribution ruling from a routine feedback append

## Overview

`branching/scripts/lib/publication-refusal.sh` classifies a publication as `ruling_touching`
when a mission that already existed on the base (`M`) has its `feedback:` line moved. The aim is
right — an attribution ruling written by `carry-attribution.sh` is the operator's to make — but
two acts move that line and their diffs are shaped alike: the ruling, and `/specificate`
appending a ref while it extends an existing mission. The second is caught by the first's test,
so the loop is punished for exactly the behaviour the operator asks for: minting a new mission
sails through, growing an existing one halts. Measured 2026-09-08: PR #1097 and #1094 held five
hours and conflicted; PR #1112, minting, landed in four minutes.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/branching/scripts/lib/publication-refusal.sh` — the one rule. Its
  ruling arm is a per-line test, which is why any publication carrying such a line inherits the
  word regardless of what else it carries.
- `plugins/workaholic/skills/strategy/scripts/carry-attribution.sh` — what a ruling actually
  writes, and therefore the shape the narrowed rule must still catch.
- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` — the seam's adapter
  (`refusal_stream`) and its call site; it already hands the rule every changed file.
- `plugins/workaholic/skills/branching/scripts/list-operator-facing-pulls.sh` — the reader's
  adapter, the second reading of the one rule; it must stay a reading, not a copy.
- `plugins/workaholic/skills/branching/scripts/list-stranded-publications.sh` — the third
  consumer, whose term 3 excludes whatever this rule names.
- `scripts/test-workflow-scripts.mjs` — the rows that source the rule and feed it normalised
  streams directly.
- `scripts/e2e/loop-drill.sh` — the drill that sources the same rule.

## Implementation Steps

1. **Reproduce before changing anything.** Source the rule and feed it two normalised streams:
   a ruling (one `M` line on an existing mission with the `feedback:` line moved, and nothing
   else), and a `/specificate` extension (the same `M` line, plus added ticket files, an added
   feedback record and regenerated indexes). Record that both answer `ruling_touching`.
2. **Localize.** The ruling arm sets its flag from a single matching line and the `END` block
   never asks what else the stream held, so the classification is per-line where the question is
   per-publication.
3. **Derive the distinguishing term from what a ruling writes**, by reading
   `carry-attribution.sh` — it appends the strategy's existing refs to one mission and writes
   nothing else. State in the rule's header exactly which paths a ruling touches and which it
   cannot, so the term is derived rather than guessed.
4. **Narrow the ruling arm** so it fires only when the mission modification is the whole of the
   publication (beside the indexes the write regenerates). One `awk` pass over the same
   normalised stream: no new field, no new input, no adapter change, and the
   `.claude/git-identities` arm untouched.
5. **Keep the two invariants the header names**: strategy outranks ruling, and an unparseable
   line contributes nothing — a publication we could not classify must not become the operator's
   by accident.
6. **Err toward the operator on a mixed publication.** The ask rules that the rule's aim need not
   be loosened, so a publication carrying a ruling *and* other work stays `ruling_touching`.
   Write that choice and its cost into the header.
7. **Pin both directions in the suite**, feeding the rule directly as the existing rows do: a
   ruling still answers `ruling_touching`; a `/specificate` extension answers empty. Assert both
   adapters still source the one rule.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A `carry-attribution.sh`-shaped stream still answers `ruling_touching`.
- A `/specificate` extension stream — the same modified mission plus added artifacts — answers
  the empty word.
- `strategy_touching` still outranks, and `.claude/git-identities` still answers
  `ruling_touching` on its own.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`

**Gate** — what must pass before approval:

- The rule stays one `awk` pass over the existing normalised stream; neither adapter changes.

## Considerations

- The rule is read by three consumers; narrowing it widens `list-stranded-publications.sh`'s
  candidate set for free. That is intended and is the second half of the ask.
- The generated-index exception must be stated by path, not inferred: a ruling's write
  regenerates the OKF indexes, so those paths cannot be treated as "other work".

## Final Report

Development completed, and the outcome is not the one this ticket predicted: **the base landed
the rule while this branch was driving it**, through the publication refactor that introduced
`branching/scripts/publication-shape.sh` and `prepare-publication.sh`. This branch's own
narrowing — an added-artifact term computed inside `publication_refusal_word` — collided with it
head-on and was **resolved in favour of the base's**, which is the stricter and better rule.

What the base's rule does: the mission arm reads a **fourth field** on the normalised stream,
and `publication-shape.sh` sets it to `extension` only when the modification removes nothing but
the `feedback:` line, adds refs without dropping any, has an **added feedback record for every
new ref**, and carries an **added ticket naming that same mission**. Four conjoined proofs where
this branch had tested one (*was anything added at all*), so a hand-made publication that
carried a ruling beside an unrelated added file — the residue this branch's own header had to
state as a cost — is not an extension there at all.

What this branch contributes is what the base landed without: **rule-level coverage of that
fourth field**. `publication-shape.sh` computes the term and `publish-tree-pr.sh`'s end-to-end
row exercises the pair, but nothing fed the rule directly, so a rule that ignored the field
would have passed every existing row. Five rows now pin it: a ruling regenerating the OKF
indexes is still the operator's, an `extension` stream is ordinary routine work, a stream
carrying **no fourth field at all** is still the operator's (the safe direction, and what a
caller predating the field depends on), and neither the identity-mapping arm nor
`strategy_touching` can be bought back by an `extension`.

### Discovered Insights

- **Insight**: The `extension` term is one `awk` comparison against a field a **different**
  script computes, so the two halves can be individually correct and jointly wrong — and the
  end-to-end row cannot see it, because it exercises both halves at once.
  **Context**: This is why the direct-stream rows are worth their weight beside an integration
  row. A rule dropping `&& $4 != "extension"` still passes every adapter-driven row that does
  not happen to be an extension.
- **Insight**: An absent fourth field must read as *not an extension*, and that is load-bearing
  rather than incidental: `list-stranded-publications.sh` and `list-operator-facing-pulls.sh`
  both feed the rule through the same adapter today, but any caller that ever built a
  three-field stream by hand would otherwise have its publications silently released to
  auto-merge.
  **Context**: The row asserting it is the one that fails if somebody later reverses the
  comparison to `$4 == "ruling"`.
- **Insight**: The collision itself is the loop's own measured behaviour: this mission's claim
  lapsed, the base drove the same three tickets through another route, and the survey still
  offered the unit as `heartbeat_lapsed` because `superseded` is derived from **archived
  tickets**, not from the work being present on the base. The tickets were never archived, so
  no verdict could see it.
  **Context**: Worth remembering before adding a *the base already did this* test — that is a
  reading about behaviour, and `CLAUDE.md`'s planning section refuses exactly that shape.
