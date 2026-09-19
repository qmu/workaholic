---
created_at: 2026-09-20T01:47:51+09:00
author: a@qmu.jp
assignees: []
depends_on:
mission:
merge_policy:
verification_handoff:
feedback: [https://github.com/qmu/workaholic/issues/1248]
claim: work-20260920-020459
---

# Declare the outcome token a loop-finish line carries

## Overview

`/moderate`'s `propose-yield` step — added 2026-09-19 by PR #1239 so that *a zero-proposal tick is a finding, not an outcome* — cannot read the log it was built to read, and answers `degraded` instead of ever raising its finding.

**Measured, tick `20260919-133646`** (`.workaholic/moderations/2026-09-19.md:134`):

```
- `propose-yield`: degraded — a propose tick's recorded outcome is outside this
  step's declared token set; no yield was judged
```

**Reproduced here, 2026-09-20**, by running the step unchanged against this checkout: `{"step": "propose-yield", "status": "degraded", "reason": "outcome_unclassified", "summary": "…", "needs_agent": [], "event": ""}`. The step is doing exactly what its header says it should — *one entry this step could not read is enough to make “every tick originated nothing” a claim it has not established* — so the defect is not in the step. It is in what the writers put on the line.

**Three distinct causes, each established by reading the tree.**

**1. Two writers, two incompatible shapes.** `runtime/scripts/coordinator.sh:71-73` writes the summary as structured JSON — `jq -c '{executed:.result.executed,outcome:.result.outcome,reason:.result.reason}'`. `work/scripts/codex-loop.sh:1168` and `:1181` write **prose** — `"${_rw_role} finished (${_rw_outcome})"` and `"${_rw_role} not executed ${_rw_seen} times (${_rw_outcome}); held to its ordinary cadence"`. Counted across this checkout's whole log: **74** `loop-finish-*` lines, **53** JSON-shaped and **21** prose-shaped, some of the prose in Japanese (`- \`loop-finish-propose\`: ok — propose と specificate が完了しました。work_waiting のため新規提案はなく、inbox は空でした。`). On the Codex path `_rw_outcome` is `ok` for any successful run whatever it originated, so that arm is *structurally* unable to answer the step's question.

**2. The `outcome` token is composed by the run and declared nowhere.** `commands/infinite-development.md:485` asks a tick to report *each completed worker's `executed`, `outcome`, and `reason`* and names no vocabulary; a tree walk found no declaration of the set anywhere. The step's own header concedes this — *the outcome string is composed by the run, so a substring test is the honest instrument* — and then has to enumerate the tokens a second time, on the reader's side, where it can only ever be a guess about what writers will produce. The six propose finishes in the current window, read through `log-read.sh --owner loop --step-prefix loop-finish-propose`:

| classified | `outcome` as written |
| --- | --- |
| `nothing` | `propose:proposed_0:past_target_date / specificate:proposed_6:formation_turn_closed` |
| `nothing` | `propose:no_evolutionary_move / specificate:proposed_mission_merged` |
| **`unclassified`** | `completed` |
| `originated` | `ticket_published` |
| `originated` | `ticket_published` |
| **`unclassified`** | `published_and_merged` |

Two of six unclassified is enough to make the step `degraded`, and the two words responsible — `completed`, `published_and_merged` — are ordinary things a run would write.

**3. The classifier reads the whole line and takes the first arm that matches — and both readings are wrong on live data.** The `jq` program at `step-propose-yield.sh:124-133` tests `.summary` **as one string**, which includes the free-text `reason` field; a reason sentence containing `ticket_published` would classify the entry. More seriously, its `if`/`elif` order decides a composite outcome silently. **Both rows classified `nothing` above are misclassifications**: the first contains `proposed_6` and the second contains `proposed_mission` — each an *originated* token in the step's own set — and each lost to a `nothing` token earlier in the `if` chain. Those are ticks where propose originated nothing but specificate ingested a mission and six tickets. So the step's `nothing` count is not merely unread; it is wrong in the direction that would make it raise a false finding once the `unclassified` entries clear.

**The direction of the repair.** Declare the vocabulary once, on the writer's side, and make both writers emit the same shape; then let the reader read a **field**, not a line.

- One declaration of the terminal-outcome tokens, readable by both writers and by every reader, in the same style this repository uses for other closed sets.
- `codex-loop.sh`'s two prose calls emit the same `{executed, outcome, reason}` object `coordinator.sh` does, so one log has one shape.
- `step-propose-yield.sh` parses the summary as JSON and tests **`.outcome`** alone, never the reason; a summary that is not JSON is `unclassified` by name, which is the correct reading for the 21 prose lines already on disk.
- Composite outcomes (`propose:… / specificate:…`) are a real and common form, so the reading is per-segment with a stated precedence — an entry where **any** segment originated is `originated`, since the step's question is whether the routine produced anything.

**The migration needs no mover, and that is a finding rather than an omission.** `moderate/scripts/log-append.sh` is the one writer, is append-only and **never prunes**; `.workaholic/moderations/` is git-ignored and stays in the checkout that wrote it. Nothing may rewrite the 21 prose lines already there. It does not need to: the step's window is *the newest two day files*, so the old shape ages out on its own within two UTC days of the writers changing. The change must therefore be verified against **legacy rows** — a log fixture holding both shapes, including the prose ones the new reader rejects — and not against a fresh log (`rules/general.md`, *A tightened constraint over persisted data is verified against legacy rows*).

**Not in scope.** Building the missing `propose-open`/`propose-close` writer (a documented pair no script writes — ticket `20260919141500`, the operator's call). Widening `step-blocked-tick.sh`, which the step's header refuses by name. Letting the step originate anything: it reports and asks, and `rules/workaholic.md`, *What May Originate a Mission*, permits only a human's ask or a human-authored strategy.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions (all code work)
- `workaholic:implementation` / `policies/command-scripts.md` — the change spans three POSIX `sh` scripts
- `workaholic:implementation` / `policies/type-driven-design.md` — a closed token set declared once at the writer, rather than guessed at each reader
- `workaholic:implementation` / `policies/objective-documentation.md` — the log line is a machine-consumed record; its shape is a contract, not prose
- `workaholic:implementation` / `policies/observability.md` — `degraded` with a named reason is correct behaviour; the defect is that the condition never clears
- `workaholic:implementation` / `policies/test.md` — the new reader is exercised against a legacy fixture carrying both shapes

## Key Files

- `plugins/workaholic/skills/runtime/scripts/coordinator.sh` - lines 66-75: the finish seam, writing `{executed, outcome, reason}` as the summary; the JSON-shaped writer
- `plugins/workaholic/skills/work/scripts/codex-loop.sh` - lines 1168 and 1181: the two prose `loop-finish-<role>` writes, and the header at line 1140 stating the `loop-attempt` / `loop-finish` split
- `plugins/workaholic/skills/moderate/scripts/step-propose-yield.sh` - lines 30-40 (the token set in the header), lines 124-133 (the `jq` classifier that reads the whole summary), lines 144-147 (the `outcome_unclassified` emit)
- `plugins/workaholic/skills/moderate/scripts/log-read.sh` - the one reader; `--owner` derivation at line 159. Not expected to change
- `plugins/workaholic/skills/moderate/scripts/log-append.sh` - the one writer, append-only, never prunes. Not expected to change
- `plugins/workaholic/skills/moderate/reference/workflow.md` - §34, lines 3877-3890: the step's documented contract
- `plugins/workaholic/commands/infinite-development.md` - line 485: the report contract that asks for `executed` / `outcome` / `reason` and names no vocabulary
- `scripts/test-workflow-scripts.mjs` - lines 23920-23965: the existing `propose-yield` fixture, where the legacy-row assertions belong
- `plugins/workaholic/rules/workaholic.md` - line 177: the `moderations/` definition, including the two-producer statement; update it if the shape statement changes

## Related History

The step and its `unclassified` arm are two weeks old; the log's two-writer shape predates it, which is why the step has never once produced its finding.

- [20260919141500-keep-the-moderation-planner-readable-at-the-35th-step.md](.workaholic/tickets/archive/work-20260919-195549/20260919141500-keep-the-moderation-planner-readable-at-the-35th-step.md) - recorded that `/propose`'s documented `propose-open` / `propose-close` writer does not exist, leaving `--owner propose` reading zero entries — the reason `propose-yield` reads the coordinator's `loop-finish-propose` lines instead

## Implementation Steps

1. **Reproduce and localize first.** Run `sh plugins/workaholic/skills/moderate/scripts/step-propose-yield.sh --tick <id> --root .` and confirm `degraded` / `outcome_unclassified`. Then run `log-read.sh --root . --since <the earlier of the newest two day files> --owner loop --step-prefix loop-finish-propose` and reproduce the six-row classification table in the Overview, including the two misclassified composite rows. Do not proceed on this ticket's table — re-derive it, since the window moves daily.
2. Establish the full writer set by walking the tree for `loop-finish-` in command position, not by trusting this ticket's two. Name any third writer found.
3. Decide and record where the token set is declared so that both writers and every reader compose it rather than spelling it. State in the declaration's header why it is a closed set and what an unrecognised token means.
4. Make `codex-loop.sh:1168` and `:1181` emit the same structured summary `coordinator.sh` does. `_rw_outcome` on the success arm is `ok`, which carries no yield information; establish what that arm can honestly say and say that, rather than inventing a token it did not measure.
5. Rewrite `step-propose-yield.sh`'s classifier to parse the summary as JSON and read `.outcome` only. A non-JSON summary is `unclassified` by name. Segment a composite outcome on its separator and apply a stated precedence: any segment that originated makes the entry `originated`.
6. Keep every existing refusal of that step intact — `no_log_reader`, `no_log_area`, `log_unreadable`, `survey_unreadable`, and `outcome_unclassified` itself. The step must still be able to reach `degraded`; what changes is that ordinary traffic no longer forces it.
7. Extend the fixture at `scripts/test-workflow-scripts.mjs:23920` with a **legacy log** carrying both shapes — the 21-line prose form included — and assert the reader's behaviour on each.
8. Update `moderate/reference/workflow.md` §34, `step-propose-yield.sh`'s header token table, and `rules/workaholic.md`'s `moderations/` entry in the same change.

## Quality Gate

**Acceptance criteria**

- Run against this checkout's live log, `step-propose-yield.sh` answers something other than `outcome_unclassified` — `ok`, or `blocked` with a populated `needs_agent`, depending on what the window holds that day.
- A composite outcome containing both a `nothing` token and an `originated` token classifies as `originated`. Asserted directly on the two rows named in the Overview.
- A `reason` field containing an originated token does not change the classification of an entry whose `outcome` says nothing was originated.
- A prose-shaped legacy summary is `unclassified` by name and still makes the step `degraded` — the rejection is explicit, never a silent `nothing`.
- `codex-loop.sh` and `coordinator.sh` write a summary of the same shape; a fixture asserts the two are readable by one reader.
- No token is renamed and no existing refusal word of the step is removed.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` is green, with the extended `propose-yield` fixture of Step 7 covering each criterion above, including the **legacy** prose rows. Run it with `TMPDIR` pointed at local disk.
- `sh plugins/workaholic/skills/moderate/scripts/step-propose-yield.sh --tick <id> --root .` on this checkout, before and after, quoted in the branch story.
- `sh scripts/e2e/loop-drill.sh verify-all --kind hermetic` green, since the drills cover the tick log's readers.
- `bash plugins/workaholic/hooks/posix-lint.sh` conforming for all three edited scripts.

**Gate**

- The suite and the hermetic drills green, posix-lint conforming, and the before/after step output quoted in the branch story.
- The legacy fixture is named explicitly in the story — a fresh-log pass is not evidence for this change (`rules/general.md`).

## Considerations

- The step is correct as written and must not be softened into answering `ok` on an entry it could not read; its header states why in full, and the whole value of the step is that an unread entry holds the finding (`plugins/workaholic/skills/moderate/scripts/step-propose-yield.sh` lines 42-46).
- The misclassification in cause 3 is the more dangerous of the two defects, because it is **silent**: once the `unclassified` entries age out, the step would raise `originated_nothing` against a window in which specificate had ingested a mission and six tickets (`plugins/workaholic/skills/moderate/scripts/step-propose-yield.sh` lines 124-133).
- The `.workaholic/moderations/` log is git-ignored and stays only in the checkout that wrote it, so a developer's checkout and a loop clone hold different logs and the step's answer differs between them. That is by design (`rules/workaholic.md` line 177) and is not a defect this ticket touches, but it means the before/after evidence must name which checkout it was read in.
- `log-append.sh` is idempotent per `(tick, step)` and never prunes, so nothing in this change may rewrite a line. Verified in its header; re-confirm before editing (`plugins/workaholic/skills/moderate/scripts/log-append.sh`).
- `outputs/workflows/` carries a generated copy of these skills; regenerate with `node scripts/build-plugins/build.mjs` in the same change or `Outputs Freshness` fails the merge.
