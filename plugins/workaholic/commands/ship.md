---
name: ship
description: Context-aware ship workflow - draft the deployment plan and merge the PR; deploying is a separate, instructed act (with claim-worktree cleanup).
skills:
  - workaholic:drive
  - workaholic:ship
  - workaholic:branching
  - workaholic:write-release-note
---

# Ship

<!-- workaholic:policy-lens — keep: hooks/policy-lens.sh matches this marker. -->

Run the preloaded `workaholic:ship` skill end to end — the guards (§3, §4), then the **Ship Flow** (§5), with every `AskUserQuestion` issued here at the command/main-agent level. **The flow deploys nothing**: it drafts the Release Note's `## Deployment Plan` and merges. Deploying is §5-D, and it runs only when the developer's invocation instructs it for a named target — never a subcommand, never the first word of an argument. This command's own job is resolving *which branch is being shipped*: run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/detect-context.sh`; on `work` (including inside a claim worktree, which sits on its own `work-*` branch) run the Ship Flow on the current branch where you stand; on `worktree`/`unknown`, run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/list-worktrees.sh`, filter to `has_pr: true`, ask once (project-label-prefixed) which claim to ship, and run the Ship Flow scoped to that worktree's branch (`( cd <worktree_path> && … )`); with no shippable worktree, say so and stop. Post-merge claim teardown is the caller's step from the main checkout, per `workaholic:drive` §6 and the skill's §0.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
