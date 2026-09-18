---
created_at: 2026-09-18T16:45:52+09:00
author: a@qmu.jp
assignees: []
depends_on:
mission:
merge_policy:
verification_handoff:
claim: work-20260918-165448
---

# Refuse an unread scan in land-unit.sh

## Overview

PR #1206 (`fc5b42b94`, ticket `20260918150931`) repaired `release-scan/scripts/gate-decision.sh`
so that an unread scan **refuses** instead of passing. **That repair does not reach
`drive/scripts/land-unit.sh`, because that script never calls the gate.** It carries its own copy
of the tier reading, inline, with the same failure mode the repair removed — and here the copy is
not even mitigated by the gate, since the gate is not in the path at all.

`plugins/workaholic/skills/drive/scripts/land-unit.sh` lines 192-213:

```sh
scan_out=$( ( cd "$worktree_path" && sh "${SCRIPT_DIR}/../../release-scan/scripts/scan-branch-safety.sh" "origin/${base}" ) )
scan_verdict="pass"
scan_findings=0
case "$scan_out" in
    *'"verdict": "block"'*)
        scan_findings=$(printf '%s' "$scan_out" | grep -o '"category":' | wc -l | tr -d ' ')
        case "$scan_out" in
            *'"severity":"hard"'*) refuse "secret_finding" … ;;
        esac
        if [ "$override_scan" != true ]; then refuse "scan_block" … ; fi
        scan_verdict="overridden"
        ;;
esac
```

The `case` has no `*)` arm. **Anything the two literal patterns do not match leaves
`scan_verdict="pass"` and `scan_findings=0`, and the unit is pushed onto the base ref** — the one
push in this plugin whose destination *is* `main`. *Read nothing* and *read and found nothing*
produce byte-identical output, which is exactly the conflation #1206 removed one layer up.
`release-scan/SKILL.md:41` already records the gap in one sentence: *"`publish-tree-pr.sh` and
`land-unit.sh` also read the scan JSON without this gate."*

**Measured**, in this checkout at `fc5b42b94`, by running lines 193-213 verbatim under
`/bin/sh` (bash 5.2) with the scan swapped for a stub:

| The scan | land-unit.sh does |
| -------- | ----------------- |
| exits 0, emits nothing | **lands**, `scan_verdict=pass`, `scan_findings=0` |
| emits `{"verdict":"block","findings":[{"category":"secret","severity":"hard"}]}` — one byte of spacing away from today's producer | **lands**, `scan_verdict=pass`, `scan_findings=0` |
| exits non-zero (its own documented `could not resolve a base ref` refusal) | **aborts**: `set -eu` kills the script at the assignment, exit 1, **no JSON at all** |
| emits today's real block | refuses `scan_block (1)` — correct |

Three things follow, and each is part of what must change.

**The silent land is reachable, and not only through drift.** `sh <file>` on a file that exists
and produces no stdout exits 0 — an empty or truncated `scan-branch-safety.sh`, a stub, a bundle
whose closure carried the path but not the content. The two sibling consumers contemplate exactly
this: both `catch-up-claim.sh:467` and `prepare-publication.sh` guard with `[ -f "$SCAN" ]` before
reading, and both carry `[ -n "$gate" ] || … scan_unreadable`. `land-unit.sh` has neither.

**The two patterns are pinned to two different spellings of one producer's output** —
`"verdict": "block"` *with* the space and `"severity":"hard"` *without* — a coupling nothing
declares and nothing tests. It holds today (`scan-branch-safety.sh:259` prints the verdict with a
space, `:251` prints each finding without), and if either spelling ever moves the gate fails
**open**. This is the same text-grep fragility `gate-decision.sh` was rewritten to remove, still
live one script over.

**The crash is not "nothing happened" either.** The abort lands after §3 has already merged
`origin/<base>` into the unit's worktree, and it produces none of the eleven refusal words
`routing.md:428-437` enumerates — the caller gets no parseable object at all. (Whether an
assignment whose value comes from a command substitution trips `set -e` is a shell-dependent
corner; bash honours it, which is itself a reason to read the status explicitly rather than lean
on it.)

**The two mitigations, stated accurately and not overstated.**

- **A scan that *ran* is handled correctly today.** A `hard` finding refuses `secret_finding`
  non-overridably; any other `block` refuses `scan_block` unless `--override-scan`. The over-count
  direction that bit `gate-decision.sh` is **not** reachable here: `scan-branch-safety.sh:75`
  escapes `"` in every string value, so a `"category":` or `"severity":"hard"` inside an
  `evidence` string cannot match either grep. **The defect is one-directional** — it is confined
  to a scan that did not run or did not speak.
- **This route is `--developer-present` only**, so a person is at the keyboard. **Presence is not
  detection.** The near miss #1206 recorded is precisely that a permissive default produces *no
  signal at all* and arrives with a plausible explanation already attached: there, `total: 0` sat
  beside a printed finding and the ready reading — *the `override` tier is neither `hard` nor
  `confirm`* — was immediately available; the run stopped only because somebody opened the script
  header. Here the equivalent output is `"scan_verdict": "pass", "scan_findings": 0`, which a
  developer has no reason to question and which becomes the durable record of a branch that was
  never judged. A human in the room does not read a field that says the right thing.

**Where this came from**: a sibling runner reported it as a `moderate` concern in PR #1206's story,
and ticket `20260918150931`'s own Considerations names it out of scope with the instruction to
record it rather than widen that change. `publish-tree-pr.sh:429` — the other script that reads
the scan raw — already falls through to `merge_reason="scan_unreadable"` on an unmatched shape and
is safe. **`land-unit.sh` is the one remaining copy.**

## Policies

The standard engineering policies (synced from qmu.co.jp into the `workaholic` policy skills) that
govern this ticket. The implementing session MUST read each linked hard copy before writing code
and keep every change defensible against its Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh`; this script is `#!/bin/sh -eu` with an explicit `set -eu` and must stay so (`rules/shell.md`)
- `workaholic:implementation` / `policies/command-scripts.md` — a script's input contract is part of its interface, and a gate that cannot say whether it read anything has no contract at all
- `workaholic:implementation` / `policies/type-driven-design.md` — *landed on an unjudged branch* must be unreachable by construction, not merely untested for; a `case` with no default arm is the representable invalid state
- `workaholic:implementation` / `policies/test.md` — the change is script-internal, so the hermetic suite is the whole verification surface
- `workaholic:operation` / `policies/ci-cd.md` — this is the last gate before a write to the base ref of the delivery path

## Key Files

- `plugins/workaholic/skills/drive/scripts/land-unit.sh` - the defect; lines 192-213 are the whole of it. Also lines 39-43 (the *GATES APPLY UNCHANGED* header paragraph), lines 66-73 (the output contract and the refusal list), and line 267 (the success `printf`)
- `plugins/workaholic/skills/release-scan/scripts/gate-decision.sh` - the one derivation of the tier policy, to be composed rather than re-derived; its header states the contract, the six reason words and the `< file` recovery
- `plugins/workaholic/skills/release-scan/scripts/scan-branch-safety.sh` - the producer; `:251` emits each finding, `:259` the verdict, `:75` the `json_escape` that makes the over-count direction unreachable, `:49` the non-zero base-ref refusal
- `plugins/workaholic/skills/drive/scripts/catch-up-claim.sh` - lines 467-488: the reference implementation of the ordered refusal arm, the `[ -f "$SCAN" ]` guard and the `[ -n "$gate" ]` check. Copy its shape, not its `[ -f ]` *skip* (see Implementation Steps 3)
- `plugins/workaholic/skills/branching/scripts/prepare-publication.sh` - lines 236-256: the same arm in the publication path, refusing by word
- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` - line 429: the `*)` fallthrough `land-unit.sh` lacks
- `plugins/workaholic/skills/drive/reference/routing.md` - lines 411-437: *The third route*, including `scan_verdict: "overridden"` and the refusal enumeration both of which this change touches
- `plugins/workaholic/skills/drive/SKILL.md` - §6 line 204: the one-line statement of the third route
- `plugins/workaholic/skills/release-scan/SKILL.md` - line 41 counts the gate's consumers and names `land-unit.sh` as reading the scan without it; line 39 is the 2026-08-21 record of why one-copy-of-the-tier exists
- `scripts/test-workflow-scripts.mjs` - `testLandUnit` (`T` at line 16905; the `scan_verdict` assertion at 16954) is the row to **widen**; `testGateRefusalReachesConsumers` (line 6622) is the reusable plugin-tree-copy stubbing technique
- `scripts/e2e/loop-drill.sh` - line 6694 names `land-unit.sh` only in the `base_health_gates_nothing` list; that row must stay green

## Related History

The tier reading has now been repaired three times, each time because a consumer read a shape
instead of a severity — and each time the repair was made in the one derivation rather than in the
copies. This ticket removes the last copy that was left standing.

- [20260918150931-refuse-an-unread-scan-instead-of-passing-it.md](.workaholic/tickets/archive/work-20260918-152022/20260918150931-refuse-an-unread-scan-instead-of-passing-it.md) - the immediate predecessor (PR #1206): the same defect in `gate-decision.sh`, its measurement, the `refuse` word and the ordered `case` arm this ticket reuses. Its Considerations name `land-unit.sh` as out of scope
- [20260805033616-drive-land-unit-now.md](.workaholic/tickets/archive/work-20260804-195932/20260805033616-drive-land-unit-now.md) - the ticket that created this script and its gate paragraph
- [20260803213000-audit-the-gates-for-shape-dependent-green.md](.workaholic/tickets/archive/work-20260804-113856/20260803213000-audit-the-gates-for-shape-dependent-green.md) - the generalization: *does a gate's verdict track a real quality failure, or a shape the tooling expects?* This is one more instance of that class
- [20260902042630-let-the-tick-merge-what-it-resolved.md](.workaholic/tickets/archive/work-20260902-093741/20260902042630-let-the-tick-merge-what-it-resolved.md) - added the gate read to `catch-up-claim.sh`, the consumer whose arm ordering is the model here
- [20260714103350-wire-release-scan-report-ship.md](.workaholic/tickets/archive/work-20260714-000543/20260714103350-wire-release-scan-report-ship.md) - the original wiring of the scan into `/story` (warn) and `/ship` (block)

## Implementation Steps

1. **Reproduce the three shapes first**, before changing anything, and keep the outputs
   (`workaholic:discover`, *Diagnosis-First Rule* — a ticket reporting a failure of an existing
   mechanism starts by reproducing it). The cheapest faithful reproduction is a copy of the plugin
   tree with `skills/release-scan/scripts/scan-branch-safety.sh` replaced by a stub, driven through
   the existing `makeClaimFixture` — the same technique `testGateRefusalReachesConsumers`
   (`scripts/test-workflow-scripts.mjs:6622`) uses to reach a consumer's `$GATE`, and for the same
   reason: each script resolves its neighbours relative to its own directory, so a copy is the only
   way a stub reaches them. The three stubs: `exit 0` with no output; a `block` verdict spelled
   `{"verdict":"block",…}` without the space; `exit 1` with a message on stderr. The first two must
   land before the change and must not after it; the third must abort before and refuse after.

2. **Route the reading through `gate-decision.sh`.** Replace the inline `case` with the composition
   the two sibling consumers already use:

   ```sh
   gate="$( ( cd "$worktree_path" && sh "$SCAN" "origin/${base}" 2>/dev/null || printf '' ) | sh "$GATE" 2>/dev/null || printf '')"
   ```

   **Decided: compose the gate rather than keep an inline reading with a parseable-object check.**
   Both close the reachable hole, and the gate wins on every other term. The tier policy has one
   home by design — `gate-decision.sh`'s own header: *"the point of this script has always been
   that the tier policy lives in one place"*, and `release-scan/SKILL.md:39` records what the
   second copy cost the last time there was one. Composing also inherits the structural `jq`
   counting (so the two spelling dependencies disappear rather than being re-pinned), the six
   reason words, and every future repair to the tier for free; an inline check would re-pin
   `land-unit.sh` to the producer's text shape, which is half the defect. **The cost, stated**:
   `land-unit.sh` acquires `jq` as a transitive dependency where it has none today. That is the
   correct direction — an absent or broken `jq` answers `jq_unavailable`, which this ticket turns
   into a refusal rather than the silent pass it would be under an inline text read — and `jq` is
   already unconditional in the surrounding seams (`plan-units.sh`, `catch-up-claim.sh`,
   `claim-mergeability.sh`).

3. **Refuse when there is nothing to read, by the existing word.** Three guards, all of them
   refusals and none of them a skip:

   - `[ -f "$SCAN" ] && [ -f "$GATE" ]` — **absent scripts refuse `scan_unreadable`**, they do not
     skip the gate. This is the one place `catch-up-claim.sh`'s shape must **not** be copied
     verbatim: there the guard wraps the whole block and an absent scan proceeds, which is
     defensible for a catch-up whose next act is a pull-request merge behind branch protection,
     and is not defensible before a fast-forward push onto the base ref.
   - the scan's own exit status — capture it explicitly (`if ! scan_out=$( … ); then refuse …`, or
     the `|| printf ''` form above) so a non-zero scan becomes a **reported refusal** instead of a
     `set -e` abort with no JSON. Name the status in `detail`.
   - `[ -n "$gate" ] || refuse "scan_unreadable" …` — the gate itself could not run.

   **Decided: the refusal word is `scan_unreadable`**, not a new one. It already means *no reading
   was made* in `catch-up-claim.sh` (`not_attempted: scan_unreadable`), in
   `prepare-publication.sh` (`refuse scan_unreadable`) and in `publish-tree-pr.sh`
   (`merge_reason="scan_unreadable"`). `land-unit.sh` has its own `refuse()` (line 106), which
   prints `{"landed": false, "unit", "reason", "detail"}` and exits 0 — the new word goes there,
   with the gate's `reason` quoted into `detail` so the caller learns *which way* the reading
   failed without re-running anything.

4. **Order the refusal arm above every other arm, and above the override.** The `case` over the
   gate's output, in this order:

   ```sh
   case "$gate" in
       *'"decision": "refuse"'*)  refuse "scan_unreadable" "<the gate's reason>" ;;
       *'"decision": "pass"'*)    ;;                       # scan_verdict stays "pass"
       *'"overridable": false'*)  refuse "secret_finding" … ;;
       *'"decision": "block"'*)   … ;;                     # scan_block unless --override-scan
       *)                         refuse "scan_unreadable" "unrecognised gate output" ;;
   esac
   ```

   **Decided: `--override-scan` may not rule past an unread scan**, and the ordering is how that is
   enforced rather than a second condition. An override is **a developer's ruling about findings**;
   a refusal means there are no findings to rule on, so there is nothing for the ruling to be
   about. The flag's own header text already says as much — *"`size`/`leak` findings are the tier a
   developer may override interactively"* (lines 41-43) — and a flag that could also wave through
   *the gate did not run* would be the only bypass of a reading in the plugin. The same argument
   `catch-up-claim.sh:472-479` records for its own arm applies verbatim: a refusal's `overridable`
   and `override_only` are `null`, so it would reach the `*)` fallthrough anyway — but that safety
   is **incidental**, and a later change setting `overridable: false` "for safety" on a refusal
   would silently re-route it into `secret_finding`, reporting a credential nobody found. The arm
   makes the behaviour a property of the word.

   **A `*)` default arm is mandatory**, and it refuses. The absence of one is the defect.

5. **Keep everything a scan that *ran* does byte-identical.** `overridable: false` (a `hard`
   finding) refuses `secret_finding`, non-overridable. Any other `block` refuses `scan_block`
   unless `--override-scan`, and with it sets `scan_verdict="overridden"`. **Non-goal, stated:
   do not adopt `/drive`'s `review`-route rule that `override_only: true` proceeds without a
   ruling.** That would widen what lands on the base ref without a developer saying so, which is a
   different decision from this one and is not this ticket's to make. Take `scan_findings` from the
   gate's `total` and delete the `grep -o '"category":' | wc -l` count — the gate reads it
   structurally and the grep is the second half of the same fragility.

6. **`scan_verdict` gains no third value, and this is deliberate.** It stays `"pass" | "overridden"`
   and it appears **only in the success object** (line 267), which a refusal never reaches —
   `refuse()` exits before it, emitting `{"landed": false, …}` with no `scan_verdict` field at all.
   A third value would be a state that can only mean *and the unit landed anyway*, which is the
   outcome this ticket removes. **Its consumers, enumerated — there are three, and no script is
   among them:**

   - `scripts/test-workflow-scripts.mjs:16954` asserts `v: "pass"` on the happy path. **It must
     keep asserting exactly that**, unchanged: it is the proof that a scan which ran still behaves
     as it did.
   - `plugins/workaholic/skills/drive/reference/routing.md:434` — prose: *"refuse unless
     `--override-scan` is passed, reported as `scan_verdict: "overridden"`."* Unchanged; the
     sentence beside it, *"Remaining refusals are facts: `not_claimed`, …"*, gains
     `scan_unreadable` and states that an unread scan refuses and that `--override-scan` cannot
     rule past one.
   - `plugins/workaholic/skills/drive/scripts/land-unit.sh:68` — the script's own header output
     block, and line 72-73's refusal list, which gains `scan_unreadable`.

   Nothing parses the field, nothing gates on it, and no caller of `land-unit.sh` exists in the
   tree at all (`commands/drive.md:14` and `commands/implement.md:37` both state that neither entry
   point calls it) — so the enumeration is complete and no consumer migration is needed.

7. **Update the documentation in the same change** (`CLAUDE.md`, *Update the docs in the same
   change*): the script's header (the gate paragraph at lines 39-43, the output contract at 66-73);
   `skills/drive/reference/routing.md`'s *The third route*; `skills/release-scan/SKILL.md:41`,
   whose sentence *"`publish-tree-pr.sh` and `land-unit.sh` also read the scan JSON without this
   gate"* becomes true of `publish-tree-pr.sh` alone. Nothing under `skills/` that this change
   touches is excluded from the bundle, so run `build.mjs` and check `outputs/` for a diff.

8. **Widen the suite**, per the Quality Gate below.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- **A scan that emits nothing on exit 0 does not land the unit.** `land-unit.sh <unit>
  --developer-present` against a stubbed `scan-branch-safety.sh` that exits 0 with no output
  answers `{"landed": false, "reason": "scan_unreadable"}`, the branch tip is **not** on the base
  ref, the worktree is still present and the remote claim branch still exists.
- **A scan that exits non-zero does not land the unit and does not abort.** The same call against a
  stub that writes to stderr and exits 1 answers `landed: false`, `reason: "scan_unreadable"`,
  **exit status 0**, with the failure named in `detail` — not an empty stdout and not exit 1.
- **A gate that answers `decision: "refuse"` does not land the unit**, whatever the reason word
  (drive it with a stubbed `gate-decision.sh`, the technique at
  `scripts/test-workflow-scripts.mjs:6622`), and `detail` carries that reason.
- **`--override-scan` cannot rule past an unread scan**: every case above answers
  `reason: "scan_unreadable"` when `--override-scan` is also passed, and nothing is pushed.
- **`--override-scan` cannot rule past a `hard` finding**: unchanged, still `secret_finding`.
- **A scan that ran keeps its present behaviour byte-for-byte**, on all three inputs:
  a **clean** branch lands with `scan_verdict: "pass"` and `scan_findings: 0`; a **`hard`** finding
  refuses `secret_finding` with and without `--override-scan`; an **override-tier** (`size`) block
  refuses `scan_block` without the flag and lands with `scan_verdict: "overridden"` and a non-zero
  `scan_findings` with it. `scan_findings` equals the gate's `total`.
- **No `case` over the scan or gate output is left without a default arm**, and no reading of the
  scan's JSON by text pattern survives in this script.
- The refusal leaves the repository intact: `origin/main` is at the same SHA as before the call,
  the claim branch's remote ref is unchanged, the worktree is not removed and `sync-main.sh` was
  not run.
- `land-unit.sh` stays POSIX `sh` (`#!/bin/sh -eu` plus the explicit `set -eu`), and any embedded
  `jq` compiles under the suite's *every embedded jq program compiles* row.
- `headless_context` and `no_developer_instruction` still refuse **before** anything is read or
  fetched, in that order, and `headless_context` still outranks every flag.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green. **Widen `testLandUnit`
  (`scripts/test-workflow-scripts.mjs:16905`) rather than replacing it** — every one of its present
  assertions is behaviour this change must preserve, including the `scan_verdict: "pass"` happy
  path at line 16954, the two human-gate refusals, the moved-base retry, the teardown and the
  claimable-immediately acceptance criterion. Add to it, or to a sibling row beside it, one case
  per acceptance criterion above, driven through a **copy of the plugin tree** with
  `scan-branch-safety.sh` (and, for the gate-refusal case, `gate-decision.sh`) stubbed — the
  technique `testGateRefusalReachesConsumers` (line 6622) already establishes, and the only way a
  stub reaches a script that resolves its neighbours by `SCRIPT_DIR`.
- **The discriminating assertion in each new case is that nothing landed** — `git rev-parse
  refs/heads/main` in the origin is byte-identical before and after — not merely that the reported
  word changed. Before this change the same inputs answered `{"landed": true, "scan_verdict":
  "pass"}` and the push happened.
- `scripts/test-workflow-scripts.mjs:37399` (*exactly three scripts reach the catch-up*) and
  `:37406` (`land-unit.sh` is refused headless) stay green **unchanged** — this change adds no
  `catchup-main.sh` caller and moves no human gate.
- `sh scripts/e2e/loop-drill.sh verify-all` is green, and the `base_health_gates_nothing` row
  (`scripts/e2e/loop-drill.sh:6694`) stays `true` — routing through `gate-decision.sh` reaches
  neither `read-base-checks.sh` nor `attribute-base-red.sh`, so no base-health gate is created.
  **No new drill is needed**: the drill proves seam vocabulary offline, and every shape here is
  hermetic and already at home in the suite.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` clean, with
  `git status` showing no unexpected `outputs/` diff.
- The three reproduced shapes re-run by hand after the change, pasted into the branch story so the
  before/after is on the record.

**Gate** — what must pass before approval:

- The hermetic suite, the drill's classified set and the build/verify pair are all green, and the
  documentation of step 7 landed in the same change.
- Decided: the hermetic suite is the whole verification surface — the change is script-internal
  with no network or runtime surface, and the stub technique reproduces every shape offline, so a
  live land would prove nothing extra and would write to the base ref to prove it (developer may
  override at /drive).
- Decided: `land-unit.sh`'s block-tier behaviour is preserved exactly rather than aligned with
  `/drive`'s `review` route — widening what lands without a ruling is a separate decision
  (developer may override at /drive).
- Decided: no third `scan_verdict` value; the refusal is carried by `reason`, and the three prose
  and test consumers are updated in the same change (developer may override at /drive).

## Considerations

- **The `[ -f "$SCAN" ]` guard in `catch-up-claim.sh` is a skip, not a refusal**
  (`plugins/workaholic/skills/drive/scripts/catch-up-claim.sh` line 467): with the scan or gate
  absent, the whole gate block is bypassed and the delivery proceeds. It is a weaker reading than
  this ticket gives `land-unit.sh`, and in an installed or bundled plugin both files are always
  present beside it, so it is not known to be reachable. **Out of scope** — record whatever is
  found in the branch story's Concerns rather than widening this change, exactly as #1206 did for
  this ticket.
- **`publish-tree-pr.sh` reads the scan raw too**
  (`plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` line 429) and is **safe**: its
  `case` has a `*)` arm answering `merge_reason="scan_unreadable"`. It is the proof that the
  fallthrough arm is the load-bearing part; leave it alone.
- **The refusal is a newly reachable state for a developer standing in the session.** Where the
  scan genuinely cannot run — a shallow clone, a missing `origin/<base>` ref, an absent `jq` —
  what was a silent land becomes a visible stop with a named remedy (re-run the scan, or fix the
  environment). That is the intended direction; the earlier behaviour was a landed base with no
  record that anything had been judged.
- **`scan_findings` changes meaning slightly.** Today it counts `"category":` occurrences; after
  step 5 it is the gate's structural `total`. These agree on every output today's producer emits,
  and the new one is correct where they would differ. It is reported to a human and parsed by
  nothing (`plugins/workaholic/skills/drive/scripts/land-unit.sh` line 268).
- **`category` stays in the scan's output.** The gate no longer counts on it, but `/story` and
  `publish-tree-pr.sh` read it (`plugins/workaholic/skills/release-scan/scripts/scan-branch-safety.sh`
  line 251). Do not remove it while removing this script's dependence on it.
- **The `set -e` corner is shell-dependent.** The measured abort on a non-zero scan was observed
  under bash 5.2 as `/bin/sh`; POSIX leaves some latitude in how an assignment whose value comes
  from a command substitution interacts with `set -e`, and the plugin's scripts are written to run
  under `sh` generally (`rules/shell.md`). Reading the status explicitly (step 3) makes the
  behaviour the same under every shell instead of relying on that corner.
