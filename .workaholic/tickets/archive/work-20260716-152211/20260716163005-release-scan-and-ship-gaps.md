---
created_at: 2026-07-16T16:30:05+09:00
author: a@qmu.jp
type: bugfix
layer: [Domain]
effort: 1h
commit_hash:
category: Changed
depends_on:
mission:
---

# Release-scan and ship carry four known gaps: untiered releasability, drifted secret rules, glob sprawl, and a silent push

## Overview

Promoted from four triaged deferred concerns (2026-07-16 triage-to-zero;
verdicts verified against source):

1. **`report-step-1-wording-predates-the`** — `/report` keys releasability off
   the binary `verdict == block`, so a lone *override-tier* size finding forces
   `releasable: false`; `release-scan/SKILL.md` states the same untiered rule.
2. **`record-evidence-sh-does-not-share`** — `record-evidence.sh` carries a
   drifted inline copy of the secret rules: it lacks the `([_-]…)?` suffix tail
   and `access[_-]?key` that `secret-patterns.sh` has, so the evidence guard
   misses `SECRET_KEY` / `aws_secret_access_key` shapes the branch scanner
   catches.
3. **`scan-allow-s-predicted-growth-has`** — `.workaholic/scan-allow` has grown
   the five predicted per-ticket globs; a scanner ticket that forgets its line
   hard-blocks its own `/ship` on the non-overridable tier.
4. **`commit-release-note-sh-s-push`** — the release-note push is best-effort
   (`push_and_report`, never fatal); a silent push failure ships a release
   without its note. The push-outcome test covers only success and no-remote,
   not a rejected push.

## Key Files

- `plugins/workaholic/skills/report/SKILL.md` (~685) and `plugins/workaholic/skills/release-scan/SKILL.md` (~37) — the untiered releasability wording
- `plugins/workaholic/skills/release-scan/scripts/lib/secret-patterns.sh` — the canonical `_SP_KEY` group and pass 1
- `plugins/workaholic/skills/ship/scripts/record-evidence.sh` (~37) — the drifted inline copy
- `.workaholic/scan-allow` — the five per-ticket globs
- `plugins/workaholic/skills/ship/scripts/commit-release-note.sh` (~41) — `push_and_report`
- `scripts/test-workflow-scripts.mjs` — `testReleaseScan*`, `testRecordEvidence`, `testCommitReleaseNotePush`

## Implementation Steps

1. Key `/report` releasability off finding severity: `hard`/`confirm` force `releasable: false`; `override` warns and records. Reconcile report/SKILL.md and release-scan/SKILL.md in the same change.
2. Extract the `_SP_KEY` group and pass-1 unmistakable-shape rules into a shared snippet both `secret-patterns.sh` and `record-evidence.sh` source; keep pass 2's value judgment out of the evidence guard (different material, different bar).
3. Adopt a fixed filename prefix for scanner tickets and collapse the five scan-allow globs into one prefix-scoped exemption (prefix-scoped, never `tickets/**`).
4. Make `commit-release-note.sh`'s push failure a pre-merge hard stop (nothing has landed yet, so the post-merge `|| true` reasoning does not apply); add a test asserting branch state after a rejected push.
5. Rebuild `outputs/` (report/ship/release-scan scripts are bundled).

## Policies

- `workaholic:operation` / `policies/ci-cd.md` — a shipment's safety rests on verifiable evidence; a silently unpushed release note and an evidence guard weaker than the branch scanner both break that chain.
- `workaholic:implementation` / `policies/objective-documentation.md` — the SKILL.md releasability wording must state the tiered behavior the scripts actually implement.

## Quality Gate

- A branch whose only finding is override-tier `size` reports `releasable: true` with a recorded warning; a `hard` or `confirm` finding still forces false.
- `record-evidence.sh` flags every shape `secret-patterns.sh` pass 1 + `_SP_KEY` flags (pinned by a shared-fixture test), with zero drift possible between the two callers.
- One prefix-scoped scan-allow line covers all scanner tickets; the five globs are gone.
- A rejected release-note push stops `/ship` pre-merge with the branch state intact, pinned by test.
- `node scripts/test-workflow-scripts.mjs` green; `build.mjs`/`verify.mjs` green after rebuild.

## Considerations

- Step 2 must not let the shared snippet drift into pass-2 territory: the evidence guard scans command *output*, where reference-shaped subtraction rules do not apply.

## Final Report

Development completed as planned. The shared snippet is `secret-patterns.sh` itself rather than a new file: pass 1 was factored into a named `secret_pass1_grep()` function and `record-evidence.sh` sources the library for that plus `_SP_KEY`, keeping its own key-name-only bar for generic assignments (pass 2 stays scanner-only, per the Consideration). The scan-allow collapse adopted the `scan-rule-` slug-prefix convention (documented in release-scan/SKILL.md's Allowlist section); the four archived legacy scanner tickets keep their names (immutable in practice), and the one icebox legacy ticket is exempted by exact path with a rename-on-promotion note. The push hard stop exempts `no_remote` deliberately — with nothing to push to there is no remote PR the note could miss, and local-only repos must keep working.

### Discovered Insights

- **Insight**: A POSIX script sourced by another script cannot locate its own file (no `BASH_SOURCE`), so a shared shell library must either be sourced by executables that know their own `dirname "$0"` or export everything through functions/variables defined at source time.
  **Context**: This is why the sharing runs record-evidence.sh → secret-patterns.sh (executable sources library) rather than secret-patterns.sh → a new common file.
- **Insight**: The live branch itself demonstrated fix 1 during development: this branch's scan reports exactly one override-tier finding (101 files > 100), which under the old binary rule would have marked the whole triage branch not releasable.
  **Context**: When /report runs on this branch, expect `releasable: true` with the size warning recorded — that is the new intended behavior, not a missed finding.
