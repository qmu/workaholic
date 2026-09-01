---
created_at: 2026-08-29T12:21:04+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: run-the-loop-s-own-proofs-on-every-turn
merge_policy:
verification_handoff: 
---

# Name the drill verdict beside a mission close

## Overview

Name the drill verdict beside a mission close, as evidence, and **gate nothing**. The
archive gate closes a mission `achieved` on arithmetic — every ticket archived, the
acceptance fully checked, the queue empty — and says nothing about whether the mechanism
that mission shipped still works. The run report names the verdict of the drill belonging
to the mission it just closed. **No close, merge or claim reads it**: the arithmetic proof
is unchanged, `close.sh` stays the only writer of an end state, and a mission whose drill
is failing still closes.

## Policies

- `workaholic:operation` / `policies/observability.md` — evidence beside a decision, not a condition on it
- `workaholic:implementation` / `policies/error-handling.md` — an unreadable verdict is named, never rendered as green

## Key Files

- `plugins/workaholic/skills/drive/scripts/archive.sh` — the gate that calls
  `close.sh <slug> achieved` on its own arithmetic; where the verdict is read and reported
- `plugins/workaholic/skills/mission/scripts/close.sh` — the single writer of an end state,
  untouched by this
- `plugins/workaholic/skills/drive/SKILL.md` — §7's run report contract, which gains the line
- `plugins/workaholic/CLAUDE.md` — the archive-gate paragraph, updated in the same change

## Implementation Steps

1. At the archive gate, after the close (or its refusal) is decided, resolve the closing
   mission's drill through ticket 5's mapping — inverted: mission slug → drill.
2. Read that drill's verdict from the last completed run, composing the same reader
   ticket 6 uses; never a second derivation, and never by running the drill inline.
3. Name it in the archive output and in the run report: the drill, its verdict, and the run
   it came from. A mission with no drill is `no_drill` and a verdict that could not be read
   is `drill_unreadable:<reason>` — both named, neither rendered as a pass.
4. Prove the close is **byte-identical** either way: the same missions close, with the same
   proof, in the same order, whatever the verdict says. The reading is added to the report
   and to nothing else.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A mission closed by the archive gate has its drill's verdict named in the archive output
  and the run report.
- A mission with no drill, and one whose verdict could not be read, are each named by their
  own word rather than reading as green.
- The close itself is unchanged: a failing drill neither blocks nor delays it, and
  `close.sh` remains the only writer of an end state.

**Verification method** — the commands/tests/probes that prove them:

- An archive run over a fixture whose closing mission's drill is failing, proving the
  mission still closes and the verdict is named.
- The same fixture with the drill passing, diffed to prove only the reported verdict
  differs.
- A fixture whose mission maps to no drill, proving `no_drill`.

**Gate** — what must pass before approval:

- The close-path diff across a failing and a passing verdict is empty apart from the report
  line, and both named non-verdicts appear as stated.

## Considerations

- The temptation is to hold the close when the drill is red. It is refused by name: the
  archive gate's proof is *is the acceptance complete*, not *is the work good*, and adding
  a second condition would make an unattended close depend on a reading that is designed to
  become false when re-run.
- If the verdict read costs a network call, it must not turn a landed archive into a
  failure — the read is best-effort and its degradation is reported, exactly as the base
  health read already is.

## Final Report

Development completed as planned.

`drive/scripts/archive.sh` reads the closing mission's drill verdict **after** the close (or
its refusal) is decided, and names it in the archive output. The mapping is ticket 5's,
inverted — `drill-register.sh mission <slug>` — and the verdict comes from ticket 6's
reader, `read-drill-verdicts.sh --drill <name>`, composed rather than re-derived and never
by running the drill inline.

Four words, none of which reads as green when it is not: **`not failing on the base at
<tip>`**, **`is FAILING on the base at <tip>; the close is unchanged`**, **`no_drill`** (the
mission shipped none, or the name is not in the register — a fact, not a degradation), and
**`drill_unreadable:<reason>`**.

**It gates nothing.** The reading sits after the close and changes no branch of it: the same
missions close, with the same proof, in the same order, whatever the verdict says. Holding a
close whose drill is red is refused by name — this gate's proof is *is the acceptance
complete*, not *is the work good*, and a second condition would make an unattended close
depend on a reading designed to become false when re-run. `close.sh` remains the only writer
of an end state and is untouched.

The read is **best-effort**: it costs one REST call and every failure path degrades to a
named word, so a call that fails can never turn a landed archive into a failure — the
discipline the base-health read already carries.

### Discovered Insights

- **Insight**: The register is a repository-level document, so a plugin script reading it
  must treat its absence as ordinary rather than exceptional. `archive.sh` ships to
  repositories with no drill set at all, where the correct answer is `no_drill` and the
  correct behaviour is to say so once and carry on.
  **Context**: The general shape for a plugin script that composes a repository's own
  convention: the absence of the convention is a named answer, never an error, and never a
  reason to change what the script was already doing.
