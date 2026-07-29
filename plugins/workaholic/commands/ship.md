---
name: ship
description: Context-aware ship workflow - merge PR, deploy, and verify (with claim-worktree cleanup).
skills:
  - workaholic:drive
  - workaholic:ship
  - workaholic:branching
  - workaholic:write-release-note
---

# Ship

<!-- workaholic:policy-lens — opts this command into the always-on engineering-policy lens injected by hooks/policy-lens.sh (UserPromptSubmit). Keep this marker. -->

**Notice:** When user input contains `/ship` or `/ship-drive` - whether "run /ship", "do /ship", "ship it", or similar - they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

Context-aware ship workflow. Steps:

1. **Workspace Guard** (blocking) and **Ticket Guard** (informational, non-blocking) — follow `workaholic:ship` §3 and §4.
2. **Detect context**: `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/detect-context.sh`.
3. **Route by context** — every worktree under `.worktrees/` is a **claim worktree** now (`workaholic:drive`'s *Claims*: one unit ↔ one claim ↔ one branch ↔ one worktree ↔ one PR), so the routing question is only *which branch am I shipping*:
   - `work` — run `workaholic:ship`'s **Ship Flow** (§5) directly on the current branch. This is also the case inside a claim worktree, which is checked out on its own `work-*` branch: ship it where you stand.
   - `worktree` or `unknown` — the session is not on a shippable branch, so resolve one first: run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/list-worktrees.sh`, filter to `has_pr: true`, and ask the user which claim to ship via `AskUserQuestion` (prefix the `question` body with the `[<project label>]` from `gather/project-label.sh`). Then run the Ship Flow scoped to that worktree's branch, wrapping each command in `( cd <worktree_path> && … )`. With no shippable worktree, say so and stop — there is nothing to ship.

**Teardown rides the claim, and never happens from inside it.** After a successful merge the unit's claim is released by definition (its commits are on the base). Removing the worktree and deleting the remote claim branch is the **caller's** step, run from the **main checkout** — `branching/scripts/cleanup-mission-worktree.sh <unit-id>` then `git push origin --delete <claim-branch>` (`workaholic:drive` §6) — because git cannot remove the worktree you are standing in, and a merge that cleans up its own working directory cannot report its result. The cleaner refuses a dirty worktree and never discards uncommitted work; if it refuses, leave the claim alone and report it. A worktree that should persist for a further batch is reset instead, with `branching/scripts/reset-mission-worktree.sh <slug>`.

**Deployment confirmation is required, and the merge comes last.** `/ship` deploys and confirms in production **from the work branch before merging** the PR; the merge is the final step, gated on a passing confirmation (Ship Flow §5). It only completes a deployment when an established way to confirm it succeeded exists (a `.workaholic/deployments/` entry or a `CLAUDE.md` `## Verify` section). When none exists, the Ship Flow **halts pre-merge** (§1-4) and this command asks the user — via AskUserQuestion at this command/main-agent level — to provide a verification path / credentials, inspect production to establish one, author a `.workaholic/deployments/` entry, abort (aborting leaves `main` untouched), or — deliberately — **merge without production confirmation** (an explicit, recorded accepted-risk bypass for the cannot-confirm case only; never the default, never for a confirmation that ran and failed). A confirmation that actually ran and failed leaves the PR unmerged. All such user interaction happens here, not in the skill's leaf scripts.

**Branch-safety scan gate (pre-merge).** The Ship Flow also runs the `workaholic:release-scan` engine over the branch diff before deploy/merge (Ship Flow §5 step 2b). A `secret` finding is a **non-overridable** hard block — report it and stop, no bypass. A `size`/`leak` finding blocks but is overridable: this command issues the `AskUserQuestion` (with the `[<project label>]` prefix from `gather/project-label.sh`) offering fix-and-re-run or an explicit **recorded** accepted-risk override. All such prompts happen here, at the command level.

`workaholic:ship` is the worktree-independent essence — it operates on the current branch's PR and any agent can run it on its own. The claim/worktree lifecycle around it lives in `workaholic:drive`.
