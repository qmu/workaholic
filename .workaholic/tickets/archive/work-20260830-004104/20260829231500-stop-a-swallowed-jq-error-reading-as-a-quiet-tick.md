---
created_at: 2026-08-29T23:15:00+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-direction-s-lifecycle-a-declared-stage
merge_policy:
feedback: [20260829211659-make-the-strategy-lifecycle-staged.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
verification_handoff: 
---

# Stop a swallowed jq error reading as a quiet tick

## Overview

MINTED MID-RUN, from a defect this mission's own work reproduced rather than predicted.

`moderate/scripts/step-direction-health.sh` composes its subjects with

```sh
subjects=$(printf '%s' "$STATE" | jq -c '…' 2>/dev/null || echo '[]')
```

so a jq **compile** error — one apostrophe in a comment, a missing parenthesis around an
object value — is discarded and the step emits `[]`. Measured while shipping *Show a
direction's stage where directions are read*: the step reported

```
"status": "ok", "summary": "… 1 overdue, 0 expiring, 1 dormant …; 0 to ask", "needs_agent": []
```

A tick that found two directions needing a person, could not compile the expression that
would name them, and reported itself **healthy with nothing to ask**. That is precisely the
collapse this step's own header forbids everywhere else: *a read we could not make must never
render as a reading we made*.

The failure is invisible for two further reasons. `sh -n` passes — the shell parses fine, it
is the embedded jq that does not — and the fallback is **legitimate** for a *data* problem, so
it cannot simply be deleted.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a degraded read is named, never rendered as an answer
- `workaholic:implementation` / `policies/single-source-of-truth.md` — one derivation of "this step could not read"

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — the measured case;
  its `|| echo '[]'` and the `2>/dev/null` that hides the reason.
- `plugins/workaholic/skills/moderate/scripts/` — every sibling step using the same shape;
  the fix is worth nothing if it is applied to one script only.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the contract that a degraded
  step reports `degraded` **by name** rather than `ok` with an empty finding.
- `scripts/test-workflow-scripts.mjs` — where `every shipped shell script parses` was added in
  this mission; the jq analogue belongs beside it.

## Implementation Steps

1. **Reproduce first**, on a copy: break one embedded jq program (an apostrophe in a comment
   is enough) and confirm the step still reports `status: ok` with an empty `needs_agent`.
2. Survey which `moderate/scripts/step-*.sh` share the shape. Count them before deciding —
   the repair is worth doing once, in a form every one of them can adopt.
3. Distinguish the two cases the single fallback currently merges: a jq **compile** error
   (our own defect — the step cannot run at all) from a jq **runtime/data** result (an honest
   empty answer). Only the first may reach `degraded`.
4. Report the first as `degraded` with its own reason, so `run.sh` counts it and the tick log
   names it. A step that cannot compile its own reading has found nothing and must not say so
   in the vocabulary of a step that looked.
5. Consider a suite-level guard beside `every shipped shell script parses`: extract each
   embedded jq program and compile it (`jq -n '<program>'` or `jq --args`), so a compile error
   fails the suite rather than one hourly tick. State the limits — a program built by string
   interpolation may not be extractable, and those are named rather than skipped silently.
6. Do **not** simply drop `2>/dev/null`: the stderr of a legitimately degraded read is noise on
   an hourly unattended run, and the fix is to classify, not to shout.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A step whose embedded jq fails to compile reports `degraded` with a named reason, never `ok`.
- An honestly empty reading still reports `ok` with an empty finding, unchanged.
- Every step sharing the shape is covered, or the ones deliberately left are named with why.
- No step's questions, keys, caps or holds move.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-direction-health`
- A deliberate one-character break in one embedded program must fail the suite.

**Gate** — what must pass before approval:

- The suite passes on the unmodified tree and fails on the deliberate break above.

## Considerations

- The tempting minimal fix is to remove `|| echo '[]'` from the one measured script. That
  turns a swallowed error into an unhandled one for that script and leaves every sibling
  exactly as it was — the defect is the **shape**, not the file.
- `every shipped shell script parses` (added 2026-08-29) catches the shell half of this class
  and provably does not catch the jq half: the measured break passed `sh -n` and still
  produced an empty, healthy-looking tick.

## Final Report

Development completed as planned.

**Reproduced first, on a copy, exactly as step 1 asked.** One character removed from
`step-direction-health.sh`'s embedded program (a closing parenthesis in the `arrived`-hold
`select`): `sh -n` passed, and the step reported `"status": "ok"` with
`1 expiring … 1 to ask` while the expiring direction's own `direction-expiring:` question had
silently vanished — the `last_live` question fired in its place, because the guard that
suppresses it reads the very list the broken program was supposed to build. Byte-for-byte the
measured shape.

**The shape was counted before it was repaired** (step 2): 58 reachable
`jq … 2>/dev/null || …` call sites across 18 scripts under `skills/moderate/scripts/`, several
multi-line and most inside `$( … )` command substitutions. That count is why the repair is a
shadowing `jq` function in `lib/jq-guard.sh` sourced at one `.` line per script (30 scripts)
rather than 58 edited call sites — 58 chances to write the classification differently.

**The two cases are told apart by jq's own exit status** (step 3), measured rather than
assumed: `3` for a compile error, `5` for a runtime or input error, `1` for `-e` with a
null/false result. No new convention, and every existing fallback keeps its data behaviour
byte-for-byte.

**One derivation of "this step could not read"** (step 4): the guard records and decides
nothing; `run.sh` reads the record and reclassifies → `degraded` / `jq_compile_error`, beside
the `step_missing` / `step_error` / `no_output` / `bad_output` it already owned. `needs_agent`
is deliberately **not** zeroed the way `bad_output` zeroes it — a step's other readings may
have compiled fine, and dropping a question a person is owed to punish a defect elsewhere in
the same script trades one silence for another.

**The suite-level guard was built** (step 5), and it is the half that matters more: a compile
error now fails the commit that introduces it rather than one tick at 03:00. `every embedded
jq program compiles` finds each `jq` in **command position**, tokenizes its arguments as the
shell would, redeclares every `--arg`/`--argjson` name (an undefined `$name` is itself a
compile error, so omitting this would report the whole tree broken), and compiles the program
with `jq -n` against closed stdin. **491 programs compile on this tree; 14 are built by string
interpolation and are counted in the assertion's own name** rather than skipped silently.

**`2>/dev/null` was not dropped** (step 6). The guard captures and redirects nothing at all:
stdin, stdout, stderr, arguments and exit status pass through untouched, so the caller's own
redirection keeps deciding who sees jq's words, and the record carries the script name instead.

### Discovered Insights

- **Insight**: The two halves of this repair have different jobs, and the build-time half is
  the stronger one. The run-time guard can only say *this step's reading is worthless*; the
  suite row names the file, the line and jq's own message before a tick ever runs.
  **Context**: That split is why the run-time record deliberately carries no jq message — it
  would have meant capturing stderr per call and replaying it to preserve the caller's own
  `2>/dev/null`, buying at run time what the suite already gives for free at build time.

- **Insight**: A shell function named `jq` is inherited by `$( … )` substitutions and pipeline
  segments but is **not** exported to child processes, which is exactly the bound this repair
  wants: a script's guard covers that script's own embedded programs and nothing else. A step
  that shells out to a helper is covered because the helper sources the guard itself and
  inherits `WORKAHOLIC_JQ_COMPILE_ERRORS` through the environment.
  **Context**: It also means the guard can never leak into a program the tick did not write —
  `git`, `gh` and every other child are untouched.

- **Insight**: Two suite fixtures (`step-base-health.sh`, `step-unanswered-asks.sh`) copy a
  single step script into an empty directory to prove it degrades when its sibling *readers*
  are absent. Adding a mandatory `. lib/jq-guard.sh` broke both, because the copy no longer
  had its own preamble.
  **Context**: The fix was to carry `lib/` with the script rather than to make the source line
  tolerant — a `[ -f … ] &&` guard would have reintroduced, in the repair itself, exactly the
  silent-fallback shape the ticket exists to remove. `ask-question.sh` already hard-sources
  `lib/question-id.sh`, so a lib is not optional here and the fixtures were the thing that was
  wrong.

- **Insight**: Restricting the extractor to `jq` in **command position** cut false positives
  from 92 to 14 in one step — it is what keeps `command -v jq` and the word "jq" inside an
  ordinary message string (`"… (is jq present?)"`) out of a permanent gate.
  **Context**: A build-time gate that reports work it cannot really see is disabled within a
  week; the command-position rule is the cheapest thing that makes this one trustworthy.
