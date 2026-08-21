---
name: story
description: Context-aware branch story + PR creation for the current branch or claim worktree.
skills:
  - workaholic:story
---

# Story

<!-- workaholic:policy-lens — keep: hooks/policy-lens.sh matches this marker. -->

Run the preloaded `workaholic:story` skill's **Run Workflow** section end to end (Workspace Guard, Detect Context, Route by Context). This command (main agent) runs the Write Story orchestration directly and spawns its workers as `general-purpose` subagents per the skill — there is no story-writer subagent.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
