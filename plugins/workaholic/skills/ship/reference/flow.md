# Ship Flow — step-by-step detail

`SKILL.md` §5 is the flow's index; this file is the full per-step contract. Script
envelopes are [`scripts.md`](scripts.md). Merge is the LAST step, gated on a passing
production confirmation — if confirmation fails, the branch simply is not merged, and
that is the rollback.

## Deployment contract formats

A `.workaholic/deployments/<target>.md` entry:

```markdown
---
title: ...
environment: production
confirmation_method: browser   # browser | server-batch | db-query | api-probe | other
url: ...                       # optional, non-secret locator
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

A target follows one of two **deploy models** — *deploy-from-branch* (deploy + confirm
from the branch, then merge) or *deploy-on-merge* (the merge is the deployment;
confirmation splits into a pre-merge readiness proof and a post-merge promotion check).
The `.workaholic/deployments/README.md` "Deploy models" section spells out both with
copyable examples; a deploy-on-merge target should label its `## Confirmation` pre-merge
vs post-merge. A docs/config-only project legitimately may have a trivial confirmation
("the merge to `main` is the deployment; confirm the commit is on `main`") — that still
must be stated, not left absent.

## The steps

1. **Pre-check**: `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/pre-check.sh "<branch>"`.
   If `found` is `false`: inform the user "No PR found for this branch. Run `/report`
   first." and stop. If `merged` is `true`: the PR is already on `main` and this
   confirmation-before-merge flow cannot re-gate it — warn, then proceed only to
   deploy/confirm/release for the already-merged commit. Capture `pr_number` and `url`.

2. **Catch up with `main`** (mandatory — before any deploy):
   `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/catchup-main.sh "<base-branch>"`, and
   apply the version-collision guard: confirm the branch's target version is greater
   than `main`'s current version and not an already-published tag; if not (which a
   mechanical catch-up conflict on the manifests reveals), re-bump to the next free
   version as part of reconciliation. On `caught_up:false`, branch on `conflict_class`:
   **`mechanical`** — reconcile it yourself as routine ship hygiene (merge
   `origin/main`, resolve the version/lockstep manifests plus any `append_only_files` by
   keeping both sides, re-bump past the collision, regenerate `outputs/`, re-run the
   pre-merge proof), no user prompt; **`content`** — halt and ask the user;
   `conflict:false, reason:"merge_failed"` is neither — fix the working tree and re-run.
   Never present reconciliation itself as an optional choice.

2b. **Branch-safety scan gate** (PRE-MERGE, blocks the merge exactly like the §1-4 gate
   — the branch staying open is the rollback):

   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/release-scan/scripts/scan-branch-safety.sh | bash ${CLAUDE_PLUGIN_ROOT}/skills/release-scan/scripts/gate-decision.sh
   ```

   On `decision: "pass"`, proceed. On `decision: "block"`, run the scan again on its own
   for the `findings[]` (file:line + rule; secret values redacted), present them, and
   act by severity:
   - **`overridable: false`** (a `secret`/`hard` finding) — a non-overridable hard
     block: report and **stop**. The developer must remove the credential from the diff
     and re-run; there is no bypass. NEVER offer a confirm-through that could leave a
     secret in the merged PR.
   - **`overridable: true`** (only `size`/`leak`) — ask via `AskUserQuestion` (command
     level) to either **fix the diff and re-run** (remove the bloat / the leaked term,
     or scope the `.workaholic/leak-denylist` entry for a false positive), or **accept
     the risk and override**. On override, record it so the decision stays auditable —
     `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/record-evidence.sh "<branch>" "release-scan" "override" "<findings overridden: rules + files>" "bypassed"`
     — then continue. Re-run the scan after any fix.

3. **Deploy** (gated on a confirmation method — §1-4; PRE-MERGE): run
   `read-deployments.sh` and `find-claude-md.sh`.
   - **No confirmation method** (`has_confirmation` false AND no `## Verify`): HALT and
     apply the §1-4 hard gate — provide a path/credentials, inspect production, author a
     `.workaholic/deployments/` entry, abort, or the deliberate accepted-risk bypass
     (record via the step-5 bypass path, then merge). Aborting leaves `main` untouched.
   - **Confirmation method exists**: run the capability check
     (`check-confirmation-capability.sh`) for the target's `confirmation_method`; if
     `capable` is false, warn with `missing`/`hint` — the method cannot run in this
     environment (e.g. `browser` in headless CI) and will force the post-deploy halt;
     steer toward a headless-executable method or an interactive ship. Advisory only.
     Then take the deploy procedure from the matching `## Procedure` (preferred) or
     `## Deploy`, display it, confirm via AskUserQuestion (§1-3), and execute. For a
     **deploy-on-merge** project the pre-merge "deploy + confirm" is the
     branch/staging-level readiness proof (build/verify/test green, version correct);
     the merge promotes and step 7 publishes/confirms the release. Capture the target's
     `confirmation_method` and `## Confirmation` / `## Verify` for step 4.

4. **Confirm in production** (execute the confirmation, PRE-MERGE), branching on
   `confirmation_method`: `browser` — open the recorded `url` and check the documented
   signal; `server-batch` — run the documented command (credentials transient, never
   persisted); `db-query` — run the documented query and compare; `api-probe` — probe
   the recorded `endpoint`; `other` / `## Verify` — follow the documented steps.
   **A confirmation that runs and returns a failing result is a failed ship — do NOT
   merge, and it is NOT bypassable.** Report it prominently, leave the PR open, stop.
   (Distinct from *cannot execute at all* — a cannot-confirm case, which falls back to
   the §1-4 accepted-risk bypass option, not a force-merge.)

5. **Record evidence and prepare merge artifacts** (PRE-MERGE):
   - Append the proof: `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/record-evidence.sh "<branch>" "<target>" "<method>" "<non-secret result>" "pass"`.
   - **Bypass path only** (the developer chose the §1-4 accepted-risk override): record
     the bypass instead —
     `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/record-evidence.sh "<branch>" "none" "none (accepted-risk bypass)" "<short note: production state unverified; merge-without-confirmation accepted by developer>" "bypassed"`.
     On `no_story`, still surface the bypass in the PR body and the step-9 summary.
   - Generate the release note: run `workaholic:write-release-note` against
     `.workaholic/stories/<branch>.md`, passing the PR `url`.
   - Commit both so they ride into the merge:
     `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/commit-release-note.sh "<branch>"`
     (commit the story update alongside — the script commits only the note). **A failed
     push stops the ship here, pre-merge** (`fatal: "release_note_not_on_remote"`; only
     `no_remote` is soft): resolve the named `push_error`, push, re-run.
   - Update the PR body so reviewers see the proof before merge:
     `bash ${CLAUDE_PLUGIN_ROOT}/skills/report/scripts/create-or-update.sh "<branch>" "<title>"`.

6. **Merge PR** (LAST — only after a passing confirmation):
   `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/merge-pr.sh "<pr-number>" [<base-branch>]`.
   On failure, inform the user and stop. Read `commit_hash_source` before using
   `commit_hash` in step 7; report `checked_out`/`checkout_reason` rather than treating
   a refused post-merge checkout as an error (see [`scripts.md`](scripts.md)).

7. **Publish GitHub Release** (post-merge, gated on a successful merge):
   `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/publish-release.sh "<branch>" "<merge-commit>" "<tag>" "<notes-file>"`.
   It defers to an existing release-publishing CI workflow (`reason:"ci_publishes"`) —
   do nothing then. **Refuse to tag when step 6 reported `on_base: false` or
   `commit_hash_source: "branch_head"`**: a tag on the branch head builds the release
   from a tree that never existed on the base. Derive `<tag>` from the project version
   when present, else the next semver after `gh release view`/the latest tag; suffix for
   an additional release on the same branch. When CI is absent and a release will be
   created interactively, confirm via AskUserQuestion first. Report `published`/`reason`.

8. **Extract deferred concerns** (post-merge):
   `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/extract-deferred-concerns.sh "<branch>" "<pr-number>" "<pr-url>" [<base-branch>]`.
   Pass the base explicitly; report `extracted`, **`pushed`** (on false, say local
   `main` is ahead and a `git push` is outstanding, naming `push_error`), and
   **`destination`** (a count without a destination does not say whether the records
   became visible on the base).

9. **Summarize**: catch-up result, branch-safety scan result (pass, or the blocking
   findings — and any recorded accepted-risk override), deployment status, confirmation
   result (method + pass/fail with the recorded evidence, the unresolved-gate outcome if
   ship halted, or — distinctly — merged WITHOUT production confirmation with the
   recorded bypass evidence), PR merge status (number, URL — merged only after
   confirmation passed), release-note status, GitHub Release status, and the deferred
   concern extraction count with its `destination`, plus `checked_out`/`checkout_reason`
   when the base was not checked out.
