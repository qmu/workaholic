# Ship Flow — step-by-step detail

`SKILL.md` §5 is the flow's index; this file is the full per-step contract. Script
envelopes are [`scripts.md`](scripts.md). **The flow deploys nothing**: its outcome is a
drafted `## Deployment Plan` in the Release Note and a merged PR. Deploying is the
separate, instructed path (§5-D below), and the production evidence for what has landed
on the base is the `release/*` window's confirmation (`SKILL.md` §6).

## Deployment contract formats

A `.workaholic/deployments/<target>.md` entry:

```markdown
---
title: ...
environment: production
confirmation_method: browser   # browser | server-batch | db-query | api-probe | other
url: ...                       # optional, non-secret locator
deploy_model: deploy-on-merge  # optional; otherwise read from the body's own wording
paths: [app/, lib/]            # optional; the subtree this target ships (see below)
---
## Procedure
Step-by-step deployment instructions for the agent to execute.
## Confirmation
The exact, executable way to confirm the deploy succeeded in production.
```

Or, in `CLAUDE.md`:

```markdown
## Deploy
Step-by-step deployment instructions for the agent to execute.

## Verify
Health checks, smoke tests, and expected outcomes.
```

`paths` is how a repository with several targets makes "what is waiting to deploy"
answerable per target. When a target declares none, the consolidation gives it the whole
unreleased range and reports `attribution: whole_range` — honest with one target,
visibly weak with several, and never silently assumed either way.

A target follows one of two **deploy models** — *deploy-from-branch* (deploy + confirm
from the branch, then merge) or *deploy-on-merge* (the merge is the deployment;
confirmation splits into a pre-merge readiness proof and a post-merge promotion check).
The `.workaholic/deployments/README.md` "Deploy models" section spells out both with
copyable examples; a deploy-on-merge target should label its `## Confirmation` pre-merge
vs post-merge. A docs/config-only project legitimately may have a trivial confirmation
("the merge to `main` is the deployment; confirm the commit is on `main`") — that still
must be stated, not left absent.

## The steps

1. **Pre-check**: `bash ../ship/scripts/pre-check.sh "<branch>"`.
   If `found` is `false`: inform the user "No PR found for this branch. Run `/report`
   first." and stop. If `merged` is `true`: the PR is already on `main` and this
   flow has nothing further to land — warn, then proceed only to the drafting phase and
   the release publish for the already-merged commit. Capture `pr_number` and `url`.

2. **Catch up with `main`** (mandatory — before the plan is drafted, so the plan
   describes the reconciled branch):
   `bash ../ship/scripts/catchup-main.sh "<base-branch>"`, and
   apply the version-collision guard: confirm the branch's target version is greater
   than `main`'s current version and not an already-published tag; if not (which a
   mechanical catch-up conflict on the manifests reveals), re-bump to the next free
   version as part of reconciliation. On `caught_up:false`, branch on `conflict_class`:
   **`mechanical`** — reconcile it yourself as routine ship hygiene (merge
   `origin/main`, resolve the version/lockstep manifests plus any `append_only_files` by
   keeping both sides, re-bump past the collision, regenerate `outputs/`, re-run the
   project's checks), no user prompt; **`content`** — halt and ask the user;
   `conflict:false, reason:"merge_failed"` is neither — fix the working tree and re-run.
   Never present reconciliation itself as an optional choice.

2b. **Branch-safety scan gate** (PRE-MERGE, blocks the merge exactly like the §1-4 gate
   — the branch staying open is the rollback):

   ```bash
   bash ../release-scan/scripts/scan-branch-safety.sh | bash ../release-scan/scripts/gate-decision.sh
   ```

   On `decision: "pass"`, proceed. On `decision: "block"`, run the scan again on its own
   for the `findings[]` (file:line + rule; secret values redacted), present them, and
   act by severity:
   - **`overridable: false`** (a `secret`/`hard` finding) — a non-overridable hard
     block: report and **stop**. The developer must remove the credential from the diff
     and re-run; there is no bypass. NEVER offer a confirm-through that could leave a
     secret in the merged PR.
   - **`overridable: true`** (only `size`/`leak`) — ask via the agent's selection prompt (command
     level) to either **fix the diff and re-run** (remove the bloat / the leaked term,
     or scope the `.workaholic/leak-denylist` entry for a false positive), or **accept
     the risk and override**. On override, record it so the decision stays auditable —
     `bash ../ship/scripts/record-evidence.sh "<branch>" "release-scan" "override" "<findings overridden: rules + files>" "bypassed"`
     — then continue. Re-run the scan after any fix.

3. **Draft the deployment plan** (PRE-MERGE; this step replaced the deploy step on
   2026-08-13): run `read-deployments.sh` and `find-claude-md.sh`.
   - **No confirmation method** (`has_confirmation` false AND no `## Verify`): HALT and
     apply the §1-4 hard gate — provide a path/credentials, inspect production, author a
     `.workaholic/deployments/` entry, abort, or the deliberate accepted-risk bypass
     (record via the step-4 bypass path, then merge). Aborting leaves `main` untouched.
     The gate is unchanged by the role change: a plan whose verification line reads
     "none declared" is exactly the aspirational plan this phase exists to prevent.
   - **Confirmation method exists**: run the capability check
     (`check-confirmation-capability.sh`) for each target's `confirmation_method` and
     report `capable: false` with its `missing`/`hint` — the plan names a check that
     could not run *here*, which the reader needs to know and which no longer blocks
     anything, because nothing is being deployed. Advisory, as before.
   - Generate the release note (`write-release-note` against
     `.workaholic/stories/<branch>.md`, passing the PR `url`), then draft the plan into
     it:

     ```bash
     bash ../ship/scripts/draft-deploy-plan.sh "<note-path>" [<base>]
     ```

     Report `targets` and `changed`. On `ok: false` (`base_unresolvable`, `no_note`)
     **report the reason and skip** — the note is left untouched, and a plan that was
     half-written would be worse than one that was not written at all. The section
     carries no clock, so a re-run against an unchanged base is byte-identical and
     `changed` is `false`.

4. **Commit the merge artifacts** (PRE-MERGE):
   - **Bypass path only** (the developer chose the §1-4 accepted-risk override): record
     the bypass —
     `bash ../ship/scripts/record-evidence.sh "<branch>" "none" "none (accepted-risk bypass)" "<short note: production state unverified; merge-without-confirmation accepted by developer>" "bypassed" "<note-path>"`.
     On `no_story`, still surface the bypass in the PR body and the step-8 summary.
   - Commit the note and the story so they ride into the merge:
     `bash ../ship/scripts/commit-release-note.sh "<branch>"`
     (commit the story update alongside — the script commits only the note). **A failed
     push stops the ship here, pre-merge** (`fatal: "release_note_not_on_remote"`; only
     `no_remote` is soft): resolve the named `push_error`, push, re-run.
   - Update the PR body so reviewers see the plan before merge:
     `bash ../report/scripts/create-or-update.sh "<branch>" "<title>"`.

5. **Merge PR**:
   `bash ../ship/scripts/merge-pr.sh "<pr-number>" [<base-branch>]`.
   On failure, inform the user and stop. Read `commit_hash_source` before using
   `commit_hash` in step 6; report `checked_out`/`checkout_reason` rather than treating
   a refused post-merge checkout as an error (see [`scripts.md`](scripts.md)). **The
   merge is not a deployment** and authorizes none.

6. **Publish GitHub Release** (post-merge, gated on a successful merge):
   `bash ../ship/scripts/publish-release.sh "<branch>" "<merge-commit>" "<tag>" "<notes-file>"`.
   It defers to an existing release-publishing CI workflow (`reason:"ci_publishes"`) —
   do nothing then. **Refuse to tag when step 5 reported `on_base: false` or
   `commit_hash_source: "branch_head"`**: a tag on the branch head builds the release
   from a tree that never existed on the base. Derive `<tag>` from the project version
   when present, else the next semver after `gh release view`/the latest tag; suffix for
   an additional release on the same branch. When CI is absent and a release will be
   created interactively, confirm via the agent's selection prompt first. Report `published`/`reason`.

7. **Extract deferred concerns** (post-merge):
   `bash ../ship/scripts/extract-deferred-concerns.sh "<branch>" "<pr-number>" "<pr-url>" [<base-branch>]`.
   Pass the base explicitly; report `extracted`, **`pushed`** (on false, say local
   `main` is ahead and a `git push` is outstanding, naming `push_error`), and
   **`destination`** (a count without a destination does not say whether the records
   became visible on the base).

8. **Summarize**: catch-up result, branch-safety scan result (pass, or the blocking
   findings — and any recorded accepted-risk override), **the drafted plan** (targets
   covered, `changed`, or the reported reason it was skipped, and any target whose
   declared method is not capable here), the unresolved-gate outcome if ship halted or —
   distinctly — merged WITHOUT a declared confirmation method with the recorded bypass
   evidence, PR merge status (number, URL), release-note status, GitHub Release status,
   and the deferred concern extraction count with its `destination`, plus
   `checked_out`/`checkout_reason` when the base was not checked out.

## §5-D. The instructed deployment

A separate invocation on the developer's instruction, naming a target, after they have
read the drafted plan. Unattended callers never reach it (`SKILL.md` §0). It is not a
subcommand and not a first word of an argument — `/ship` keeps one behaviour.

- **D1. Deploy**: run `check-confirmation-capability.sh` (advisory), display the named
  target's `## Procedure` / `## Deploy`, confirm via the agent's selection prompt (§1-3), execute.
- **D2. Confirm**: execute that target's `## Confirmation` / `## Verify`, branching on
  `confirmation_method`: `browser` — open the recorded `url` and check the documented
  signal; `server-batch` — run the documented command (credentials transient, never
  persisted); `db-query` — run the documented query and compare; `api-probe` — probe the
  recorded `endpoint`; `other` / `## Verify` — follow the documented steps. **A failing
  result is a failed deployment and is not overridable**: record it as `fail` and
  promote nothing.
- **D3. Record** the attempt into both destinations with one call:

  ```bash
  bash ../ship/scripts/record-evidence.sh \
    "<branch>" "<target>" "<method>" "<non-secret result>" "<status>" "<note-path>"
  ```

  `<status>` is `pass`, `fail`, `not_run` (the declared method cannot execute in this
  environment — deliberately distinct from `fail`), or `bypassed`. The note's
  `## Deployment Verification` is **append-only**: a second attempt adds a block and
  never rewrites the first, matching the rule that a failed confirmation deletes
  nothing. The secret guard runs before either destination is touched.
