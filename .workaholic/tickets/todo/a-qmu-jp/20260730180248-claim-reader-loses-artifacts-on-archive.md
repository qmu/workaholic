---
created_at: 2026-07-30T18:02:48+09:00
author: a@qmu.jp
type: bugfix
layer: [Domain, Infrastructure]
effort:
commit_hash:
category:
depends_on:
mission:
merge_policy: review
claim: work-20260730-191139
---

# The claim reader loses a batch unit's artifacts once its tickets are archived, so another runner can re-claim completed work

## Overview

The claim protocol's whole purpose is that two runners never pick the same work. It fails for a **batch** unit the moment that unit's tickets are archived, which is to say for the entire second half of every batch drive.

`lib/claims.sh`'s `claims_scan` derives a claim's artifacts by taking the paths the **`Claim` commit** touched and keeping those that *still carry* `claim: <branch>` **at the branch tip** (`plugins/workaholic/skills/drive/scripts/lib/claims.sh` ~L113-125). Its comment states the intended semantics: "a later commit that removes a stamp drops that artifact from the claim without any bookkeeping." That is right for a stamp removal. But `archive.sh` does not remove a stamp — it **renames** the file from `.workaholic/tickets/todo/<user>/X.md` to `.workaholic/tickets/archive/<branch>/X.md`, carrying the stamp along. The scan looks up the *old* path at the tip, finds nothing, and silently drops the artifact.

Observed live in this repository on 2026-07-30, immediately after a four-ticket batch was archived on its claim branch:

```
$ list-claims.sh
{"unit": "batch-20260730171124", "branch": "work-20260730-171125", "artifacts": [], ...}

$ plan-units.sh          # from a current main
backlog: [... 20260729183606-publish-tree-primitive.md,
              20260729183607-ticket-publishes-to-main.md,
              20260729183608-mission-publishes-to-main.md,
              20260729183609-drive-surveys-current-main.md]
```

All four tickets were reported as **claimable backlog while their claim was in flight**. The consequence is the double-pick the protocol exists to prevent: another runner (or a later tick of the 5-minute routine) claims them into a fresh `batch-<timestamp>` unit and re-implements work that is already done and already at a PR.

**The unit-id check does not save it.** `claim.sh` refuses a duplicate on two grounds — the unit id and the artifact overlap. A mission unit is protected by its id, because the id *is* the slug and a second runner claiming that mission mints the same id. A batch's id is minted from the clock at claim time, so a second claim of the same tickets gets a *different* id and only the artifact overlap can catch it — which is exactly the check that has gone empty.

## Policies

- `workaholic:implementation` / [domain-layer-separation.md](plugins/workaholic/skills/implementation/policies/domain-layer-separation.md) — the governing policy. One scan serves reader and writer (`lib/claims.sh`) precisely so they cannot disagree; the fix belongs in that single implementation and must not be papered over in `plan-units.sh` or `claim.sh` individually.
- `workaholic:implementation` / [infrastructure-as-code.md](plugins/workaholic/skills/implementation/policies/infrastructure-as-code.md) — coordination state stays derivable from git refs. The claim's artifact set must be recoverable from the branch as it exists now, not from a path that was true only at claim time.
- `workaholic:implementation` / [observability.md](plugins/workaholic/skills/implementation/policies/observability.md) — the failure is silent and looks healthy: `list-claims.sh` prints a well-formed claim with an empty array, and `plan-units.sh` offers the tickets with no `excluded` entry. A claim that has quietly stopped protecting its artifacts must be visible, not inferred.
- `workaholic:implementation` / [operational-planning.md](plugins/workaholic/skills/implementation/policies/operational-planning.md) — work the recovery backward from the concrete scenarios under Implementation Steps: mid-drive (some archived, some not), fully archived, a stamp genuinely removed, and a ticket deleted outright.
- `workaholic:implementation` / [coding-standards.md](plugins/workaholic/skills/implementation/policies/coding-standards.md) — POSIX `#!/bin/sh -eu` per [rules/shell.md](plugins/workaholic/rules/shell.md); the resolution stays inside the library, never inline in command markdown.

## Key Files

- [lib/claims.sh](plugins/workaholic/skills/drive/scripts/lib/claims.sh) — `claims_scan`'s artifact loop (~L113-125) and `claims_blob_field`. The single place the fix belongs.
- [claim.sh](plugins/workaholic/skills/drive/scripts/claim.sh) — the writer whose artifact-overlap refusal (~L114-124) is the check that silently stopped working.
- [plan-units.sh](plugins/workaholic/skills/drive/scripts/plan-units.sh) — `is_claimed_artifact`, the survey-side consumer of the same list.
- [list-claims.sh](plugins/workaholic/skills/drive/scripts/list-claims.sh) — the renderer; it needs no logic change, but its output is where the emptiness is first visible.
- [archive.sh](plugins/workaholic/skills/drive/scripts/archive.sh) — the mover. It is not the defect and should not grow claim bookkeeping, but it defines the rename the scan must survive.
- [drive/SKILL.md](plugins/workaholic/skills/drive/SKILL.md) — the *Claims* section states the model the scripts implement; whatever resolution is chosen is stated there once.
- [test-workflow-scripts.mjs](scripts/test-workflow-scripts.mjs) — `makeClaimFixture` and `testClaimProtocol` (~L7187) claim and then assert immediately, never archiving in between, which is precisely why no test caught this.

## Related History

- [20260728221802-add-claim-protocol-scripts.md](.workaholic/tickets/archive/work-20260728-221717/20260728221802-add-claim-protocol-scripts.md) - Built `claims.sh` / `claim.sh` / `list-claims.sh` and specified the reader as "artifacts whose branch-tip frontmatter carries `claim: <that branch>`" — a specification that reads correctly and is exactly what the archive rename breaks
- [20260728221803-unify-drive-executor.md](.workaholic/tickets/archive/work-20260728-221717/20260728221803-unify-drive-executor.md) - Built `plan-units.sh`, which consumes the artifact list and is where the resulting false offer surfaces
- [20260729183609-drive-surveys-current-main.md](.workaholic/tickets/archive/work-20260730-171125/20260729183609-drive-surveys-current-main.md) - Made `/drive` survey a current `main`, which is what made this defect observable: before it, a stale checkout hid the false offer behind a different bug

## Implementation Steps

1. **Decide the resolution and record it in `drive/SKILL.md`'s *Claims* section.** Two candidates, and the choice is a real design call rather than a detail:
   - **Follow the rename** — resolve each claim-commit path to its current path at the tip (`git log --follow`, or a diff with rename detection between the claim commit and the tip), then read the stamp there. Keeps "the artifacts are the files the claim commit touched" true, and keeps a genuine stamp removal working.
   - **Scan the tip for stamps** — enumerate every `.workaholic/` file at the tip carrying `claim: <branch>`, ignoring what the claim commit touched. Simpler and rename-proof, but changes the model's definition of a claim's artifact set and costs a tree walk per unmerged branch.
   Record which was chosen and why; a later reader will ask.

2. **Report both the pre-archive and post-archive path.** Whatever resolution is chosen, the survey has to subtract the path that is *on `main`* — a ticket in `todo/` there — while the branch tip holds the archived path. The two are different strings, so the reader must emit both (or the consumers must compare on the ticket's basename, which is unique by timestamp). Pick one and state it; a fix that reports only the archived path leaves the false offer intact.

3. **Keep the genuine unstamp path working.** A later commit that really does remove a `claim:` stamp must still drop that artifact from the claim — that behaviour is deliberate and documented, and a rename-following fix must not swallow it.

4. **Handle the deletion case explicitly.** A ticket deleted outright on the branch (not renamed) has no current path. Decide whether it stays claimed or drops, and say so.

5. **Add the regression coverage the existing fixture cannot express.** `testClaimProtocol` claims and asserts immediately. Extend `makeClaimFixture` usage with a case that claims a batch, **archives its tickets on the claim branch**, pushes, and then asserts from the *other* clone that (a) `list-claims.sh` still reports the unit's artifacts, (b) `plan-units.sh` still excludes those tickets with reason `claimed`, and (c) a second `claim.sh batch` over the same tickets is still refused `already_claimed`. Add the mid-drive case too: one ticket archived, one still in `todo/`.

6. **Verify the mission unit is genuinely unaffected before asserting so.** A mission's `mission.md` is not moved by `archive.sh`, so its stamp should survive at the same path — confirm that with a test rather than reasoning, since the unit-id check would mask an artifact-list regression there.

## Quality Gate

**Acceptance criteria**

- A batch unit whose tickets have been archived on its claim branch is still reported by `list-claims.sh` with a **non-empty** `artifacts` list. This is the criterion the ticket exists for.
- `plan-units.sh`, run from a **current** `main` in a different clone, does **not** offer those tickets as backlog, and reports each in `excluded[]` with reason `claimed`.
- A second `claim.sh batch` over any of those same tickets is refused `already_claimed`, naming the holding branch — the double-pick is impossible again.
- The mid-drive case holds: with one of two tickets archived, both are still reported as the unit's artifacts and both stay out of the offer.
- A commit that genuinely **removes** a `claim:` stamp still drops that artifact from the claim, unchanged.
- A ticket **deleted** on the claim branch behaves per the ruling recorded in step 4, and that behaviour is asserted.
- A **mission** unit's artifact list is unaffected, asserted rather than assumed.
- `claim.sh` and `plan-units.sh` still read the one shared scan — neither grows its own artifact resolution (`grep -c claims_scan` unchanged in both).
- Offline behaviour is unchanged: the reader still degrades (`fetched: false`, last-known refs) and the writer still fails loudly. No false "unclaimed" is produced in either mode.
- Every new script line is POSIX `#!/bin/sh -eu` and `hooks/posix-lint.sh` reports `conforming: true`.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green, extended with the archived-batch, mid-drive, genuine-unstamp, deletion, and mission cases described in implementation steps 5–6, each asserted **from the clone that did not do the writing** (the existing fixture's discipline).
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs` clean with no residual `outputs/` diff (`drive` ships in `outputs/workflows`).
- `bash plugins/workaholic/hooks/posix-lint.sh` conforming; `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.
- A live check against **this** repository, read-only: with PR #108's claim still in flight, `list-claims.sh` reports its four artifacts and `plan-units.sh` excludes them — the exact observation in the Overview, inverted.

**Gate**

- The full `## Local Verification` command set from [CLAUDE.md](CLAUDE.md) passes.
- The archived-batch case is covered by a **named** test. This defect is specifically one the existing fixture design cannot express (it never archives), so an untested fix does not close it.
- The resolution chosen in implementation step 1 is recorded in `drive/SKILL.md`'s *Claims* section with its reason, not only in the code.

**Decided** (recorded rather than asked; override at review time):

- `Decided:` the fix belongs in **`lib/claims.sh` alone**. The single-scan rule exists so the reader and the writer cannot disagree; a patch in `plan-units.sh` or `claim.sh` would create exactly the divergence the library was extracted to prevent.
- `Decided:` `archive.sh` is **not** modified. Making the mover maintain claim bookkeeping would spread coordination state across two seams, and the claim's truth is supposed to live in git — the reader's job is to read it correctly, including across a rename.
- `Decided:` this is a **bugfix**, not a hardening task. It is a live correctness hole in the mechanism that prevents duplicated work, reproduced in this repository's own survey output, and it should be driven ahead of feature work on the same subsystem.

## Considerations

- **Every batch drive to date has passed through this window.** The unit was protected between claim and first archive, and unprotected from then until merge — which is most of a drive's wall-clock. That no duplicate has been observed is a property of there having been one runner, not of the protocol; the 5-minute routine plus a second machine is exactly the configuration that would surface it.
- **`git log --follow` is single-path and can be slow.** If rename-following is the chosen resolution, prefer a single `git diff --find-renames` between the claim commit and the tip over a per-file `--follow`, and measure it against a branch with a large archive: the scan runs on every survey, i.e. every five minutes.
- **The basename shortcut is tempting and nearly right.** Ticket filenames are timestamp-prefixed and unique, so comparing basenames would fix the survey without any rename detection. It is worth considering explicitly rather than dismissing — but it silently stops working for any artifact type whose basename is not unique (`mission.md` is the obvious one), so if it is chosen it must be scoped to tickets and said so.
- **This interacts with staleness reporting.** A claim whose artifacts have gone empty currently looks like a claim over nothing, which is indistinguishable from a `Claim` commit that stamped nothing (`claims.sh` already tolerates that case). After the fix, an empty artifact list becomes a genuinely anomalous state worth surfacing rather than rendering as `[]`.
