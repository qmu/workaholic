---
created_at: 2026-08-10T16:41:56+00:00
author: noreply@anthropic.com
assignees:
depends_on:
mission:
merge_policy:
claim: work-20260810-170054
---

# Reconcile drive/reference/routing.md's stale review-route description

## Overview

While reconciling stale notification-shape references left behind by P10
(`20260809085953-reconcile-stale-notification-shape-references-post-p10.md`), an adjacent and
unrelated drift was found in the same file, out of that ticket's scope per the drive skill's
failure contract ("inside the current ticket's scope → implement it; outside it → write a ticket,
continue"): `plugins/workaholic/skills/drive/reference/routing.md`'s *Routing mechanics (§6)*
section still documents the **pre-auto-merge** review route —

```
- **`review` → stop at the PR.** The worktree and the claim **stay** — the unit is unfinished
  until its PR merges. ...
```

— while `plugins/workaholic/skills/drive/SKILL.md` §6 (and `CLAUDE.md`'s `/implement`
architecture paragraph) already documents the **current** model: mission
`auto-merge-propose-and-implement-prs-under-a-dev-release-branch-split` (2026-08-11) changed
`review` to **merge the PR immediately** once `/report` opens it and the branch-safety scan
passes, demoting only on a scan finding. The reference file (which `SKILL.md` links to as the
routing detail) directly contradicts the skill it is meant to elaborate.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/reference/routing.md` — the *Routing mechanics (§6)* section's `review` bullet
- `plugins/workaholic/skills/drive/SKILL.md` — §6, the current source of truth for the route
- `outputs/workflows/skills/drive/reference/routing.md` — generated mirror; fix via `node scripts/build-plugins/build.mjs`, never by hand

## Implementation Steps

1. Rewrite the `review` bullet in `routing.md`'s *Routing mechanics (§6)* to match `SKILL.md` §6: the PR merges immediately once opened and the branch-safety scan verdict is `pass` (`gh pr merge --merge`), tearing the claim down exactly as `auto` does; a scan finding is the one thing that leaves the PR open instead (unoverridable, no human present).
2. Grep `plugins/workaholic/` and `CLAUDE.md` for any other surviving "stop at the PR" / "unit is unfinished until its PR merges" description of the `review` route and reconcile each.
3. Regenerate `outputs/workflows` (`node scripts/build-plugins/build.mjs`) and run `verify.mjs` / `validate-metadata.mjs` / `test-workflow-scripts.mjs` / `layout-doctor.sh` per the repository's Local Verification list.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `drive/reference/routing.md` describes the `review` route as merging immediately (post-scan-pass), never as stopping at the PR pending a human merge.

**Verification method** — the commands/tests/probes that prove them:

- `grep -n "stop at the PR" plugins/workaholic/ -r` returns no hits describing the current `review` route (historical/decision-log mentions naming the retired behavior are fine).
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs && node scripts/test-workflow-scripts.mjs` all clean; `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.

**Gate** — what must pass before approval:

- The grep above is clean and the local verification suite passes before this ticket's PR is opened for review.

## Considerations

- Low severity, cosmetic doc drift — not blocking, hence minted rather than fixed opportunistically inside the notification-shape ticket per the drive skill's failure contract.
- Found while implementing `20260809085953-reconcile-stale-notification-shape-references-post-p10.md`.

## Final Report

Development completed as planned. Rewrote `drive/reference/routing.md`'s *Routing mechanics (§6)*
`review` bullet to match `drive/SKILL.md` §6, the current source of truth: the PR merges
immediately once opened and the branch-safety scan verdict is `pass`, tearing the claim down
exactly as `auto` does, with a scan finding the one thing that leaves it open. The re-grep (step 2)
surfaced a deeper, out-of-scope drift in the same sweep: `/ticket`'s and (per its own Key Files
note) potentially `/mission`'s creation-time `merge_policy` interrogation still frames `review` as
"a human must review the PR" — no longer true under the auto-merge mission, since both policies now
merge unattended and the real distinction is deploy-confirmation timing. Minted
`20260810170140-reconcile-ticket-creation-s-review-wording-with-auto-merge.md` for it rather than
fixing it here, since it touches a developer-facing decision prompt outside this ticket's stated
Key Files.

### Discovered Insights

- **Insight**: A skill's `reference/` file can drift out of sync with the `SKILL.md` it elaborates even when the `SKILL.md` itself was correctly updated — the two are separate files with no automated cross-check.
  **Context**: `drive/SKILL.md` §6 was already reconciled to the auto-merge mission's model, but `drive/reference/routing.md`, which `SKILL.md` links to for the same routing detail, was missed in that change and kept contradicting it. Worth a grep sweep across a skill's `reference/` directory whenever its `SKILL.md`'s routing/behavior sections change.
