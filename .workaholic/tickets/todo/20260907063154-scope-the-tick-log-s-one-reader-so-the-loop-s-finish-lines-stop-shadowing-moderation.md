---
created_at: 2026-09-07T06:31:54+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260907062639-separate-the-loop-s-finish-records-from-the-moderation-log-rather-than-patching-each-reader.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
merge_policy:
verification_handoff: 
---

# Scope the tick log's one reader so the loop's finish lines stop shadowing moderation


## Overview

`/infinite-development` records each subagent finish with `log-append.sh --step loop-finish-<name>`
under the **coordinator's** tick id, into `.workaholic/moderations/<UTC-day>.md` — the file
`/moderate` writes its own steps into. Each such write opens a `## <tick-id>` section carrying no
moderation rows. `/propose` does the same with `propose-open` / `propose-close`.

Two readers of that file are already known to break on the mixing, and the ask is to repair the
**cause** rather than each reader. This ticket does that at `log-read.sh`, the log's one reader:
it gains a derived **section owner** and a default that answers only moderation entries, so every
reader that composes it is repaired without being touched, and every future reader inherits the
repair instead of the trap.

**The reporter's causal chain does not survive a read of the code, and the defect it names is real
with a different symptom.** The ask attributes the renderer's `no_rows` verdict to the baseline.
`render-tick-post.sh` emits `no_rows` from `${TMP}/now` — **this tick's own rows, taken from the run
JSON on stdin** — at a point *before* the baseline is selected at all, so a rowless baseline cannot
produce it. What the mixing actually does is measured below: it makes the change diff read
**every eventful step as changed**, and it makes `blocked-tick` report a coordinator section as a
healthy moderate tick. Both are worse than the reported symptom, because both are silent.

## Measured, 2026-09-07, on this repository

**The log.** `.workaholic/moderations/2026-09-06.md`: **84** `loop-finish-*` lines, **0**
`human-checkin-post` lines. Sections `20260906-204212` and `20260906-210558` each hold exactly one
`loop-finish-*` line and nothing else. The coordinator turns every five minutes and `/moderate`
every thirty, so a coordinator-only section is the ordinary previous section, not an edge case.

**Reader 1 — the change baseline** (`render-tick-post.sh`). `PREV` is the newest tick carrying a
`human-checkin-post` line, falling back to the newest tick before this one *whatever step it
carries*. With no posting tick in the window — the measured state — the fallback lands on a
coordinator section, `${TMP}/prev` comes back empty, and every step whose row supplies an `event`
compares against an empty `was` and is counted as changed. Reproduced hermetically, identical run
JSON, one row carrying an event whose summary is **unchanged** from the previous moderate tick:

| Previous section in the fixture | `previous_tick` | `change_count` |
| --- | --- | --- |
| `loop-finish-implement` only (mixed log) | `20260904-135000` | **1** — spurious |
| the previous moderate tick (clean log) | `20260904-130000` | **0** — correct |

That is the diff no longer suppressing an unchanged answer, which is the one property the change
diff exists to guarantee (`📦 Release Preparation` was retired for restating an unchanged answer).

**Reader 2 — `blocked-tick`** (`step-blocked-tick.sh`), not named in the ask and broken the same
way. Its subject is `[.entries[].tick] | unique | reverse | .[1]` — **any** tick — so it takes a
coordinator section as "the tick before last". For such a section `opened` is 0, which takes the
first branch and emits `the tick before last opened and closed; N step(s) recorded`. The step whose
whole job is to notice the tick stopping reports a **false healthy reading**, and the live log shows
it doing exactly that: `blocked-tick: ok — the tick before last opened and closed; 1 step(s)
recorded`, where the section it read holds one `loop-finish-implement` line.

**Reader 3 — the cadence gate** (`commands/infinite-development.md` §2, the bare `--latest-tick`)
is the same cause and is already ticketed as `20260907031134`, queued and not yet driven. This
ticket must not duplicate that repair; see Considerations.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a run says what it did and what it could not read

## Key Files

- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — **the one reader, and the one file
  this repair belongs in.** It already composes every filter with `--latest-tick`; the owner is a
  filter of the same kind.
- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — the change baseline; expected
  to need **no edit**, because it composes `log-read.sh` with no owner and inherits the default.
  Read it to confirm that, and to confirm `no_rows` keeps its current meaning.
- `plugins/workaholic/skills/moderate/scripts/step-blocked-tick.sh` — the second broken reader.
  Its moderate arm inherits the default; its **propose arm deliberately reads `propose-open` /
  `propose-close`** and must keep seeing them — this is the one reader that wants two owners.
- `plugins/workaholic/skills/moderate/scripts/log-append.sh` — **the one writer, and it is not
  touched**: the owner is derived from the step id every line already carries, so the existing
  append-only history is covered without a migration.
- `plugins/workaholic/commands/infinite-development.md` — §2's three cadence reads
  (`--step-prefix loop-finish-<name> --latest-tick`, and the bare `moderate` read); the ceiling a
  routine-fired session executes.
- `plugins/workaholic/skills/work/SKILL.md` — states the same cadence generically; keep it in step.
- `plugins/workaholic/skills/work/scripts/codex-loop.sh` — reads `loop-attempt-<role>` and
  `loop-finish-<name>`; **must keep reading them** or the Codex clock loses its cadence and its
  worker outcomes.
- `plugins/workaholic/skills/moderate/scripts/{condition-age,question-state,filed-records,ask-question,answer-outcome,step-question-answers,step-thread-reconcile,step-doc-drift,step-inbound-sweep,step-open-log,step-stuck-prs,step-unanswered-asks,step-human-checkin}.sh`
  — the other consumers. Each keys on a moderation step id already, so the default should be a
  no-op for them; prove that rather than assume it.
- `scripts/test-workflow-scripts.mjs` — pins the reader's behaviour; the suite currently has no row
  on the owner because it did not exist.
- `scripts/e2e/loop-drill.sh` — carries `verify-blocked-tick`; the natural home for the drill
  assertion.
- `docs/loop-drill-runbook.md` §9 — the drill register; a new or changed drill needs its row.

## Implementation Steps

1. **Reproduce both failures before changing anything.** Build a hermetic fixture root holding
   `.workaholic/moderations/<day>.md` with, in this order, a moderate tick section carrying one
   eventful step, and then a section carrying one `loop-finish-implement` line and nothing else.
   - Pipe a run JSON whose row repeats that step's summary **unchanged** into
     `render-tick-post.sh --tick <later> --root <fixture>` and record `previous_tick` and
     `change_count`. Delete the `loop-finish` section and record them again. The two readings must
     differ — that difference is the defect, and it is the assertion step 6 pins.
   - Run `step-blocked-tick.sh` against the same fixture and record its summary. It must currently
     describe the coordinator section as a moderate tick that opened and closed.
   Record both readings in the branch story. Do not proceed on the ask's `no_rows` account: it is a
   hypothesis this step falsifies or confirms, and the code says it is false.

2. **Derive the owner in `log-read.sh`, from the step id, over a closed named table.** No new field,
   no new file, no stored value: the step id is already on every line the log has ever carried, so
   history is classified by construction.
   - `loop-finish-*`, `loop-attempt-*` → `loop` (the coordinator's, written under the coordinator's
     own tick id)
   - `propose-*` → `propose` (`/propose`'s own opening and closing lines)
   - everything else → `moderate`
   Keep the table short, named and in one place, with the reason each prefix is on it. An
   unrecognised step id is `moderate` — the existing behaviour, so nothing already written moves.

3. **Add `--owner <moderate|loop|propose|all>`, defaulting to `moderate`.** It composes with every
   existing filter exactly as `--step-prefix` does, `--latest-tick` included; the classification is
   **per entry**, never per section, so a section that ever mixes two owners degrades to the right
   answer per line rather than to a guess about the section. Document the default and its
   consequence in the script header: *a caller that names no owner is asking about moderation.*

4. **Opt the loop's own readers in, by name.** Each of these reads another owner deliberately and
   must be changed in the same commit as step 3, or the cadence breaks between commits:
   - `commands/infinite-development.md` §2 and `skills/work/SKILL.md` — the `loop-finish-<name>`
     cadence reads take `--owner loop`.
   - `skills/work/scripts/codex-loop.sh` — the `loop-attempt-<role>` and `loop-finish-<name>` reads
     take `--owner loop`.
   - `step-blocked-tick.sh`'s **propose arm** takes `--owner propose`; its moderate arm takes the
     default and is otherwise untouched.
   Do **not** change `infinite-development.md`'s bare `moderate` cadence read here — that is ticket
   `20260907031134`'s repair and is queued; note in the branch story that the default now also
   covers it, and leave the ticket to land its own filtered read.

5. **Confirm every other consumer is unaffected.** For each script in Key Files that composes
   `log-read.sh` with no owner, state in the branch story whether the default changes its answer
   and why. The expected answer is *no change, it already keys on a moderation step id*; a consumer
   where that is not true is a finding to report, not a thing to silently adjust.

6. **Pin it.** Add suite rows in `scripts/test-workflow-scripts.mjs`:
   (a) `log-read.sh` with no owner returns no `loop-finish-*` entry from a mixed fixture;
   (b) `--owner loop` returns exactly those, and `--latest-tick` composes with it;
   (c) `render-tick-post.sh`'s `previous_tick` skips a coordinator-only section, and its
   `change_count` is 0 for an unchanged summary across a mixed log — the step 1 reproduction,
   inverted;
   (d) `step-blocked-tick.sh` does not describe a coordinator-only section as a moderate tick.
   Extend `verify-blocked-tick` in `scripts/e2e/loop-drill.sh` with a breaker row written against
   the **behaviour** (a coordinator-only section must not be read as a moderate tick), and update
   its row in `docs/loop-drill-runbook.md` §9.

7. **Update the documentation in the same change** — `CLAUDE.md`'s `.workaholic/` runtime
   conventions (the `moderations/` paragraph), `plugins/workaholic/skills/moderate/SKILL.md` and
   `reference/workflow.md` where the log's readers are described, and
   `plugins/workaholic/rules/workaholic.md` if it names the log's shape. Say what the default is and
   why, once, and cite it from the other surfaces rather than restating it.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `log-read.sh` with no `--owner` returns no `loop-finish-*` or `loop-attempt-*` entry from a log
  that carries them, and `--owner loop` returns exactly those; both compose with `--latest-tick`.
- `render-tick-post.sh`'s `previous_tick` is the newest **moderate** tick before this one, and its
  `change_count` is 0 when every step's summary is unchanged, on a log whose previous section holds
  only a `loop-finish-*` line.
- `step-blocked-tick.sh` never describes a coordinator-only section as a moderate tick that opened
  and closed, and its propose arm still reads `propose-open` / `propose-close`.
- The loop's cadence reads still find `loop-finish-<name>` and `loop-attempt-<role>`:
  `infinite-development.md`, `work/SKILL.md` and `codex-loop.sh` each name `--owner loop`.
- `log-append.sh` is byte-identical, no line is pruned, no file is migrated, no second store and no
  cursor is added.
- Every affected document is updated in the same commit.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the four new rows in step 6 pass.
- `sh scripts/e2e/loop-drill.sh verify-blocked-tick` — passes, and fails with the breaker applied.
- `sh scripts/e2e/loop-drill.sh verify-all` — no drill regresses.
- The step 1 reproduction re-run: the mixed and clean fixtures now give the **same**
  `change_count`, and `previous_tick` names the moderate tick in both.
- `git diff --stat` shows `log-append.sh` unchanged and no file under `.workaholic/moderations/`
  touched.

**Gate** — what must pass before approval:

- The suite, the drill set, and the reproduction above, with the before/after readings recorded in
  the branch story.

## Considerations

- **Why the reader and not the writer.** The ask prefers giving the finish records their own
  namespace and permits either a separate day file or *a marker the moderation readers filter on*.
  This takes the second sub-form: the marker already exists — it is the step id — so the separation
  costs one derivation in one reader, no second store, no migration, and it classifies the 84 lines
  already on disk by construction. A separate day file would need `log-append.sh` to learn a
  destination, would leave every line already written in the wrong file, and would give the area a
  second file shape for `layout-doctor.sh` and the OKF floor to know about. Both satisfy *fix the
  cause*; this one is reversible in a single file.
- **The reported symptom is a hypothesis, and the code contradicts it.** `no_rows` is emitted from
  the run's own rows before the baseline is read. Something else produced the `no_rows` recorded at
  tick `20260906-211606` — most likely a run whose JSON reached the renderer without rows — and that
  is **not** in this ticket's scope. If step 1 reproduces `no_rows` from a rowless baseline, the
  reading above is wrong and the ticket should be re-scoped rather than forced; report it either
  way.
- **`propose-open` / `propose-close` are the reason the owner is a small set rather than a
  boolean.** `blocked-tick` reads them deliberately, so *not moderate* is not one class. A boolean
  would have silently broken the propose arm, which is the exact failure mode this ticket exists to
  stop repeating.
- **The default is a behaviour change for every existing caller**, and that is the point — but it
  is also the risk. Step 5 exists so that each caller's change (or non-change) is stated rather than
  assumed.
- **Overlap with ticket `20260907031134`.** That ticket points the `moderate` cadence gate at
  `--step-prefix loop-finish-moderate`. This ticket makes the bare read safe as well. The two are
  compatible and neither is redundant: a filtered read is the right shape for a cadence gate
  regardless, and this default is what protects the readers nobody has thought about yet. Whichever
  lands second must not revert the other.
- **Non-goals, from the ask.** Do not stop the tick recording its finishes; the cadence depends on
  them and they are correct where they are. Do not prune existing lines: the log is append-only, and
  a machine deleting lines it dislikes is a worse failure than the one it would cure.
