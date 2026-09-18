---
created_at: 2026-09-18T15:09:31+09:00
author: a@qmu.jp
assignees: []
depends_on:
mission:
merge_policy:
verification_handoff:
---

# Refuse an unread scan instead of passing it

## Overview

`skills/release-scan/scripts/gate-decision.sh` is the one derivation of the release-safety
severity tier, read before every merge the loop performs. **Its failure mode is `pass`.** An
absent reading, a reading delivered by a route the script does not read, and a reading whose
shape has drifted are each indistinguishable from a clean scan, because `decision` is gated on a
text-grep count of `"category":` occurrences in the raw input and every failure drives that count
to zero.

Measured in this checkout at `2a85aff9e`, three shapes, each answering `decision: "pass"`:

1. **Empty stdin.** `printf '' | sh gate-decision.sh` →
   `{"decision": "pass", "overridable": true, "override_only": false, "hard": 0, "confirm": 0, "total": 0}`.
   No input at all reads exactly like a clean branch.
2. **A file path passed as an argument is ignored.** The script reads `input=$(cat 2>/dev/null || true)`
   and takes no positional argument, so `sh gate-decision.sh <scan.json>` reads stdin — nothing —
   and answers `pass` while the caller believes its file was judged. Confirmed with a file whose
   single finding is `{"category":"secret","severity":"hard",…}`: the answer was
   `{"decision": "pass", …, "total": 0}`.
3. **A finding carrying `severity` but no `category`.** `hard`/`confirm` are counted by grepping
   `"severity":[ ]*"hard"` / `"confirm"`, but `hard` is consulted only *inside* the `total > 0`
   branch, and `total` counts `"category":` alone. Piping
   `{"verdict":"block","findings":[{"severity":"hard","rule":"secret"}]}` yields the
   self-contradictory `{"hard": 1, …, "decision": "pass", "total": 0}` — the script reports a hard
   finding and passes it in the same object.

**The live risk, stated exactly.** `scan-branch-safety.sh` emits `"category":"…"` on every finding
(`skills/release-scan/scripts/scan-branch-safety.sh:251`), so a genuine `secret` finding today
produces `total >= 1`, `decision: "block"`, `overridable: false`. **There is no live bypass of a
real finding.** What is defective is that the gate cannot tell *no reading* from *a clean reading*
and resolves every such case toward `pass`. Two independent callers hit that in one session on
2026-09-18: one passed a file argument and got a false `total: 0` pass; one ran the scan from a
wrong path, piped the resulting empty output in, and got `decision: "pass"` from no input at all —
noticed only because the answer looked suspicious, not because the gate said anything.

**The permissive default ships with a ready-made rationalisation, and that is the real hazard.**
The near miss is recorded here because it is the strongest evidence this ticket has. The caller
passed the file positionally. The file was correct:

```
{"verdict":"block","findings":[{"rule":"too-large-commit","severity":"override","file":"d0f29157f","line":0,"detail":null}]}
```

The gate answered `{"decision":"pass","overridable":true,"override_only":false,"hard":0,"confirm":0,"total":0}`,
exit 0. It was noticed only because the same output block had already printed that file's
`findings` through `jq`, so *one finding* and *`total: 0`* sat side by side — and then **a plausible
explanation was immediately available**: *the `override` tier is neither `hard` nor `confirm`, so
of course it does not appear in `total`*. Under that reading the run came close to merging on
`decision: pass`; it stopped only because somebody read the script header and found the
`Usage: scan-branch-safety.sh … | gate-decision.sh` stdin contract. Piped correctly, the same file
answers `{"decision":"block","overridable":true,"override_only":true,"hard":0,"confirm":0,"total":1}`.
**The merge outcome is identical; the recorded justification is not** — a false pass would have left
a durable record saying the branch had zero findings when it had one. A silent wrong answer that
supplies its own excuse is worse than one that looks wrong, which is why this is a defect in the
gate and not a lesson for its callers.

Two facts follow from that, and both are part of what must change:

- **No field in the output says whether an input was read.** *Read nothing* and *read and found
  nothing* are byte-identical, exit 0 in both. The assumption that `scan-branch-safety.sh` always
  emits at least a `{"verdict":…}` object is embedded in the script in a way no caller can detect
  when it breaks.
- **Both entry doors land on the same false pass** — a positional argument, and a piped empty file
  — which is why this is the gate's finding rather than either caller's mistake. `CLAUDE.md` names
  the exact shape in the coordinator's own architecture rule: *"For agent-composed gated writes,
  read the gate in one tool call before constructing the merge, push or deletion in another; **exit
  zero is not a passing JSON gate.**"* The script hands its callers nothing to tell the difference
  with.

This is the repository's own doctrine pointed at one of its own gates. *An absence of a reading is
never a proof* (`skills/drive/reference/claims.md`), and `commands/infinite-development.md:26`
already states it to the coordinator that calls this script: *"Readability precedes counting. A
null, failed, malformed, inaccessible or incomplete read is unknown, never zero."* A gate that
answers `pass` on an unreadable input asserts a proof nobody made — the same shape PR #1200
(`d80c10a31`) repaired in `reconcile-questions.sh`, where a question was retired on the absence of
a negative reading rather than on a positive one.

The fix has four parts, all inside this one script plus one ordered `case` arm in each of its two
script consumers: **parse with `jq`**, **refuse an unread input by its own word**, **refuse a
positional argument**, and **derive `decision` from the severity counts** so a `pass` beside a
non-zero `hard`/`confirm` is unreachable by construction.

## Policies

The standard engineering policies (synced from qmu.co.jp into the `workaholic` policy skills) that
govern this ticket. The implementing session MUST read each linked hard copy before writing code
and keep every change defensible against its Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh` conventions; this script is `#!/bin/sh -eu` and must stay so (`rules/shell.md`)
- `workaholic:implementation` / `policies/command-scripts.md` — a script's argument and input contract is part of its interface; an ignored argument is a silent interface failure
- `workaholic:implementation` / `policies/type-driven-design.md` — the invalid state (`decision: "pass"` with `hard > 0`) must be unrepresentable by derivation, not merely untested for
- `workaholic:implementation` / `policies/test.md` — the gate's proof is one hermetic row per measured shape; the change is script-internal, so the suite is the whole verification surface
- `workaholic:operation` / `policies/ci-cd.md` — this is the pre-merge quality gate of the delivery path, read by `/ship`, `/drive`'s `review` route, the catch-up and the stranded-publication act

## Key Files

- `plugins/workaholic/skills/release-scan/scripts/gate-decision.sh` - the defect; lines 42-66 are the whole of it
- `plugins/workaholic/skills/release-scan/scripts/scan-branch-safety.sh` - the producer; line 251 emits each finding's `category`/`severity`, so the shapes above are drift, not today's output
- `plugins/workaholic/skills/release-scan/SKILL.md` - states the tier policy and counts the consumers ("three consumers now")
- `plugins/workaholic/skills/drive/scripts/catch-up-claim.sh` - consumer; lines 467-481 read the gate before its one REST merge
- `plugins/workaholic/skills/branching/scripts/prepare-publication.sh` - consumer; lines 236-250, behind `settle-stranded-publication.sh` and the operator catch-up
- `plugins/workaholic/skills/ship/reference/flow.md` - consumer contract §2b; instructs on `pass` and on `block` and on nothing else
- `plugins/workaholic/skills/ship/SKILL.md` - §2b's one-line statement of the same gate
- `plugins/workaholic/skills/drive/SKILL.md` - §6's `review` route: merge on `decision: pass` **or** `override_only: true`
- `plugins/workaholic/skills/drive/reference/routing.md` - the same route stated in full (§6 mechanics)
- `plugins/workaholic/commands/implement.md` - the agent-composed gate rule ("a zero process exit is not a passing JSON gate")
- `plugins/workaholic/commands/infinite-development.md` - the coordinator's copy of that rule, beside *readability precedes counting*
- `plugins/workaholic/skills/story/SKILL.md` - **not** a consumer of this script: `/story` reads finding severities off the scan itself (line 108). Do not "fix" it.
- `scripts/test-workflow-scripts.mjs` - `testReleaseScanGateDecision` (~line 6487) is the existing tier-policy row to widen
- `scripts/e2e/loop-drill.sh` - `cmd_verify_close`'s `close_scan_held` row (~line 4591) pipes JSON literals through the gate offline

## Related History

The tier reading has been repaired twice before, both times because a consumer read an absence or
a summary instead of the severity, and both times the repair was made in this one script rather
than in the consumers. The gate's *own* unread-input case was never covered.

- [20260918080734-retire-a-check-in-question-only-on-a-positive-reading.md](.workaholic/tickets/archive/work-20260918-081459/20260918080734-retire-a-check-in-question-only-on-a-positive-reading.md) - the identical shape one seam over: a state changed on the absence of a negative reading; PR #1200 made it require a positive one (nearest precedent)
- [20260902042630-let-the-tick-merge-what-it-resolved.md](.workaholic/tickets/archive/work-20260902-093741/20260902042630-let-the-tick-merge-what-it-resolved.md) - added the gate read in `catch-up-claim.sh` before its merge (consumer 1)
- [20260908191229-catch-a-held-publication-up-without-merging-it.md](.workaholic/tickets/archive/work-20260908-210424/20260908191229-catch-a-held-publication-up-without-merging-it.md) - the publication path's gate read (consumer 2)
- [20260827012039-drill-the-closing-seam-with-no-network.md](.workaholic/tickets/archive/work-20260827-021918/20260827012039-drill-the-closing-seam-with-no-network.md) - why the closing seam's tier reading is drilled offline with JSON literals (`close_scan_held`)
- [20260714103350-wire-release-scan-report-ship.md](.workaholic/tickets/archive/work-20260714-000543/20260714103350-wire-release-scan-report-ship.md) - the original wiring of the scan into `/story` (warn) and `/ship` (block)

## Implementation Steps

1. **Reproduce the three shapes first**, before changing anything, and keep the outputs: `printf '' | sh …/gate-decision.sh`;
   `sh …/gate-decision.sh <a file holding a hard finding> </dev/null`;
   `printf '%s' '{"verdict":"block","findings":[{"severity":"hard","rule":"secret"}]}' | sh …/gate-decision.sh`.
   Each must answer `decision: "pass"` before the change and must not after it. (A ticket reporting
   a failure of an existing mechanism starts by reproducing it — `workaholic:discover`.)

2. **Refuse a positional argument.** Any positional argument answers the refusal object below with
   `reason: "bad_argument"`, reads nothing, and exits 0. **Decided: refuse rather than accept a file
   path** — the script's contract is one stdin pipe and all five call sites pipe into it, so
   accepting a file would create a second input route and, with both supplied, an ambiguity about
   which one was judged; a gate with two input routes is exactly how a caller comes to believe it
   judged something it did not. The recovery is already available and costs the caller one
   character: `sh gate-decision.sh < scan.json`. Name that recovery in the script's header.

3. **Parse with `jq`, not by grepping JSON text.** `total` is `.findings | length`; `hard` /
   `confirm` / `override` are the counts of `.findings[] | select(.severity == …)`. This also
   removes a live miscount: the present `grep -oE '"category":'` counts that literal anywhere in
   the input, including inside a finding's `evidence` string. `jq` is a hard dependency of the
   surrounding seams already (`catch-up-claim.sh`, `plan-units.sh`, `discover-input.sh` all call it
   unconditionally), but this script is the gate, so a `jq` that is absent or that fails is
   `reason: "jq_unavailable"` — a refusal, never a pass. Write the program as a single
   single-quoted `jq` invocation in command position so `test-workflow-scripts.mjs`'s *every
   embedded jq program compiles* row can extract and compile it; do not build it by string
   interpolation, which that row cannot see.

4. **Refuse every unread or undecidable input by its own word**, as a third `decision` beside
   `pass` and `block`:

   ```
   {"decision": "refuse", "reason": "<word>", "overridable": null, "override_only": null,
    "hard": null, "confirm": null, "total": null}
   ```

   The closed reason set, five words plus `jq_unavailable`: **`no_scan_input`** (stdin empty or
   whitespace only), `unparseable_input` (not JSON), `not_a_scan_verdict` (JSON whose `.findings`
   is not an array), `finding_unclassified` (a `findings[]` element that is not an object, or whose
   `severity` is absent or outside the closed set `hard | confirm | override`), `bad_argument`,
   `jq_unavailable`. Exit 0 in every case — the repository's refusal convention, and a non-zero
   exit would be swallowed by the `|| printf ''` both script consumers already wrap the call in.

   **The load-bearing requirement is the one the runner that hit this proposed**: read **one
   parseable scan object from stdin**, and refuse when you cannot, instead of mapping `total: 0` to
   `pass` before confirming an input existed. That single check closes **both** doors on its own —
   a positional argument leaves stdin empty and therefore refuses as `no_scan_input` even with
   step 2 removed — and it is adopted as stated, including its word. The four other reasons are
   **diagnostic refinements over that one check, never the safety mechanism**: each names *why*
   there was no usable reading, which is what turns a refusal a caller can act on out of one they
   have to investigate. `bad_argument` earns its place by naming the mistake precisely — *your file
   was never read* — where `no_scan_input` would leave a caller holding a correct file and no
   explanation, which is exactly the position the near-miss caller was in.

   **Decided: a third word rather than resolving to `block`** — `block` means *findings were
   found*, and the consumers then read the severity counts to decide how hard to block. A `block`
   carrying `hard: 0, confirm: 0` satisfies the present `override_only` rule, which is a merge
   licence for `/drive`'s `review` route: the permissive answer again, wearing the blocking word.
   Forcing `overridable: false` instead would make `/ship` report *a credential is in this diff*
   and send a developer hunting a secret that does not exist. `refuse` says the one true thing —
   no reading was made — and leaves the remedy (re-run the scan correctly) where it belongs.

   **Decided: `null` counts, not `0`** — the repository's own convention for a walk that could not
   complete (`classify-residue.sh`, `publication-age.sh`, and `infinite-development.md`'s
   *readability precedes counting*): `0` reads as *counted, found none*, which is the very
   conflation this ticket removes. `overridable` and `override_only` are `null` for the same
   reason, and they are load-bearing here: a consumer that has not been updated must not be able
   to read a refusal as a licence. See step 6.

5. **Derive `decision` from the severity counts, never from `total` alone.** `block` when
   `hard + confirm + override > 0`; `pass` only when the walk completed and all three are zero.
   `overridable` stays keyed on `hard` alone and `override_only` stays *findings exist and every
   one is `override`* — neither tier rule moves, and the empty finding set stays `pass`, not
   `override_only`. Because the counts and `total` are now read off one parsed array, `decision:
   "pass"` beside a non-zero `hard` or `confirm` is unreachable by construction; add no runtime
   self-check for it (a guard for an unreachable state states that the derivation is not trusted)
   and assert it in the suite instead.

6. **Give each of the two script consumers one ordered `case` arm** — `catch-up-claim.sh:475`ff and
   `prepare-publication.sh:244`ff — placed **above** the existing arms:

   ```sh
   *'"decision": "refuse"'*) … scan_unreadable ;;
   ```

   mapping to the **existing** `scan_unreadable` word (`DELIVERY="not_attempted: scan_unreadable"`
   in the catch-up, `refuse scan_unreadable` in the publication path). **No new vocabulary**: that
   word already means *no reading was made*, which is precisely the refusal. The arm is required
   even though the null fields already route a refusal to the `*)` fallthrough, because relying on
   arm ordering against a field the refusal happens not to set is how a later change that sets
   `overridable: false` for safety would silently re-route the refusal into `scan_held:hard`.
   Both consumers keep `[ -n "$gate" ] || … scan_unreadable`, which now fires only when the script
   itself could not run.

7. **Update the three agent-level consumer contracts**, each of which currently instructs on `pass`
   and `block` and on nothing else, so an agent meeting a `refuse` has no instruction:
   - `skills/ship/reference/flow.md` §2b and `skills/ship/SKILL.md` §2b — a `decision: "refuse"` is
     a **stop whose remedy is to re-run the scan correctly** (name `reason`). It is neither a
     secret nor an override: never hunt a credential on it, and never record it through
     `record-evidence.sh … "bypassed"`, which asserts a risk a human accepted.
   - `skills/drive/SKILL.md` §6 and `skills/drive/reference/routing.md` — a refusal merges nothing:
     leave the pull request open, leave the claim standing, and report the unit's merge outcome as
     `merge_refused: scan_unreadable`, the same word the scripts use. The merge licence stays
     exactly `decision: pass` **or** `override_only: true`, and a `null` is neither.
   - `commands/implement.md` and `commands/infinite-development.md` — one clause on the existing
     gate rule: only `decision: "pass"` or `override_only: true` is a passing gate; every other
     answer, `refuse` included, is not.

8. **Update the documentation in the same change** (`CLAUDE.md`'s *Update the docs in the same
   change*): `skills/release-scan/SKILL.md`'s tier-policy section gains the third outcome and the
   reason set; `CLAUDE.md`'s *Release-safety scan* section gains one sentence that an unread scan
   refuses rather than passes; `gate-decision.sh`'s own header states the new contract, the usage
   line (`… | gate-decision.sh`, and `< file` for a file), and the measurement above. Keep the
   existing header's record of the 2026-08-21 `override_only` repair — it is why the script exists.

9. **Widen the suite and the drill**, per the Quality Gate below. Nothing here is generated, so no
   `build.mjs` run is required; run it anyway if any skill markdown under `skills/` changed, since
   `outputs/workflows` carries `release-scan`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `printf '' | sh gate-decision.sh` answers `decision: "refuse"`, `reason: "no_scan_input"`, and `total: null`.
- `sh gate-decision.sh <path> </dev/null` answers `decision: "refuse"`, `reason: "bad_argument"`, and reads neither the file nor stdin.
- **The near-miss shape, both ways round, in one case**: the file `{"verdict":"block","findings":[{"rule":"too-large-commit","severity":"override","file":"d0f29157f","line":0,"detail":null}]}` passed **positionally** refuses, and the same bytes **piped** answer `decision: "block"`, `override_only: true`, `total: 1`. No input shape answers `pass` with that content by either route.
- **`decision` alone tells *read nothing* from *read and found nothing*** — a refusal and a clean pass are never byte-identical, and no consumer has to compare counts to learn which it got.
- `printf '%s' '{"verdict":"block","findings":[{"severity":"hard","rule":"secret"}]}' | sh gate-decision.sh` answers a non-`pass` decision (`refuse`/`finding_unclassified` under the closed-set rule of step 4) and **never** `decision: "pass"` beside `hard: 1`.
- `printf 'not json' | sh gate-decision.sh` answers `reason: "unparseable_input"`; `{"verdict":"pass"}` with no `findings` key answers `reason: "not_a_scan_verdict"`.
- A normal `scan-branch-safety.sh` output is unchanged in every existing respect: a clean branch is `pass` with `total: 0` and `override_only: false`; a `secret` branch is `block` with `overridable: false`; a `size`-only branch is `block` with `override_only: true`; a `leak` beside a `size` is not `override_only`. The end-to-end `scan | gate-decision` row on a real secret branch stays a non-overridable block.
- **No input shape produces `decision: "pass"` while `hard` or `confirm` is non-zero**, and none produces `override_only: true` while `hard` or `confirm` is non-zero.
- A refusal never carries `overridable: false` or `override_only: true`; both are `null`.
- `catch-up-claim.sh` reports `delivery: "not_attempted: scan_unreadable"` and `prepare-publication.sh` refuses `scan_unreadable` when the gate refuses — neither reports `scan_held:hard`, and neither merges or pushes.
- `gate-decision.sh` stays POSIX `sh` (`#!/bin/sh -eu`), and its embedded `jq` program compiles under the suite's *every embedded jq program compiles* row.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green. **Widen the existing `testReleaseScanGateDecision` row rather than replacing it** — every one of its present assertions is a behaviour this change must preserve, and its comments carry the 2026-08-21 measurement. Add to it: one case per shape above (empty stdin, positional argument, `severity` without `category`, unparseable, missing `findings`), the two invariant assertions (no `pass` and no `override_only` beside a non-zero `hard`/`confirm`), and the assertion that a refusal's `overridable`/`override_only` are `null`.
- Two hermetic consumer rows, in the same suite, proving the ordered arm is reached: stub the gate (or feed a branch whose scan output is empty) and assert `catch-up-claim.sh`'s `delivery` is `not_attempted: scan_unreadable` and `prepare-publication.sh`'s `reason` is `scan_unreadable`, with no ref written and no merge attempted.
- `sh scripts/e2e/loop-drill.sh verify-all` is green, and `cmd_verify_close`'s `close_scan_held` row gains a third literal — an empty input — asserting the closing seam does not merge on it. The drill is the right home for that one because it is where the seam's vocabulary is proved offline; the shape-level cases stay in the hermetic suite.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` clean (`release-scan` ships into `outputs/workflows`), and `git status` shows no unexpected `outputs/` diff.
- The three measured shapes re-run by hand after the change, pasted into the branch story so the before/after is on the record.

**Gate** — what must pass before approval:

- The hermetic suite, the drill's classified set and the build/verify pair are all green, and the documentation of step 8 landed in the same change.
- Decided: no consumer is asked to key on the new word except through the ordered `case` arm and the prose of step 7 — every other consumer is safe because a refusal's `overridable` / `override_only` are `null`, so nothing that reads a boolean licence can read a refusal as one (developer may override at /drive).
- Decided: the hermetic suite is the whole verification surface, plus the one drill literal — the change is script-internal with no runtime or network surface, so a live run would prove nothing extra (developer may override at /drive).
- Decided: `verdict` is not cross-checked against the counts — the findings array is the source of truth and the producer's own summary word is not a second axis to disagree on (developer may override at /drive).

## Considerations

- **`category` becomes unused by the gate.** After step 3 the tier is read off `severity` alone, which is the correct axis (`category` is the rule family). Do not delete `category` from `scan-branch-safety.sh`'s output — `/story`, `publish-tree-pr.sh` and `land-unit.sh` all read it (`plugins/workaholic/skills/release-scan/scripts/scan-branch-safety.sh` line 251).
- **`/story` is not a consumer of this script**, though `skills/release-scan/SKILL.md` line 39 counts it among "three consumers". It reads finding severities directly off the scan (`plugins/workaholic/skills/story/SKILL.md` line 108). Correct that sentence if it is touched; do not add a gate call to `/story`, which warns rather than blocks.
- **`publish-tree-pr.sh` and `land-unit.sh` read the scan JSON without this gate** (`plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` line 395, `plugins/workaholic/skills/drive/scripts/land-unit.sh` line 193). They are out of this ticket's scope, but each is a place the same permissive reading could live; note whatever is found there in the branch story's Concerns rather than widening this change.
- **The refusal is a new reachable state for every caller**, including `/ship`, where the developer is present. If the scan genuinely cannot run in an environment (no base ref, a shallow clone), what was previously a silent `pass` becomes a visible stop. That is the intended direction, and `scan-branch-safety.sh` already refuses a missing base ref rather than defaulting (`scripts/test-workflow-scripts.mjs` line 13297), so the stop names a real condition.
- **Exit status stays 0 on a refusal** (`plugins/workaholic/skills/release-scan/scripts/gate-decision.sh`). Both script consumers wrap the call in `|| printf ''`, so a non-zero exit would erase the reason word and land them on the generic empty-output path — the refusal object is the only way the reason survives.
