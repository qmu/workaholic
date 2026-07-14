---
name: ship
description: Context-aware ship workflow - merge PR, deploy, and verify (with worktree cleanup for trips).
skills:
  - workaholic:trip-protocol
  - workaholic:ship
  - workaholic:branching
  - workaholic:write-release-note
---

# Ship

<!-- workaholic:policy-lens — opts this command into the always-on engineering-policy lens injected by hooks/policy-lens.sh (UserPromptSubmit). Keep this marker. -->

**Notice:** When user input contains `/ship`, `/ship-drive`, or `/ship-trip` - whether "run /ship", "do /ship", "ship it", or similar - they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

Context-aware ship workflow. Steps:

1. **Workspace Guard** (blocking) and **Ticket Guard** (informational, non-blocking) — follow `workaholic:ship` §3 and §4.
2. **Detect context**: `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/detect-context.sh`.
3. **Route by context**:
   - `work` — run `workaholic:ship`'s **Ship Flow** (§5) directly on the current branch. No worktree handling.
   - `worktree` or `unknown` — follow `workaholic:trip-protocol`'s **Trip Ship → Context routing** (worktree selection / drive-vs-trip prompt), which wraps the `workaholic:ship` Ship Flow with worktree sync + cleanup.

**Deployment confirmation is required, and the merge comes last.** `/ship` deploys and confirms in production **from the work branch before merging** the PR; the merge is the final step, gated on a passing confirmation (Ship Flow §5). It only completes a deployment when an established way to confirm it succeeded exists (a `.workaholic/deployments/` entry or a `CLAUDE.md` `## Verify` section). When none exists, the Ship Flow **halts pre-merge** (§1-4) and this command asks the user — via AskUserQuestion at this command/main-agent level — to provide a verification path / credentials, inspect production to establish one, author a `.workaholic/deployments/` entry, abort (aborting leaves `main` untouched), or — deliberately — **merge without production confirmation** (an explicit, recorded accepted-risk bypass for the cannot-confirm case only; never the default, never for a confirmation that ran and failed). A confirmation that actually ran and failed leaves the PR unmerged. All such user interaction happens here, not in the skill's leaf scripts.

**Branch-safety scan gate (pre-merge).** The Ship Flow also runs the `workaholic:release-scan` engine over the branch diff before deploy/merge (Ship Flow §5 step 2b). A `secret` finding is a **non-overridable** hard block — report it and stop, no bypass. A `size`/`leak` finding blocks but is overridable: this command issues the `AskUserQuestion` (with the `[<project label>]` prefix from `gather/project-label.sh`) offering fix-and-re-run or an explicit **recorded** accepted-risk override. All such prompts happen here, at the command level.

`workaholic:ship` is the trip-independent essence (usable by any agent on its own); the worktree/trip lifecycle lives in `workaholic:trip-protocol` and is Claude-Code-only.
