---
name: catch
description: By-developer catch-up report over a recent window (commits, tickets, stories, mission progress), then follow-up Q&A.
skills:
  - workaholic:catch
---

# Catch

<!-- workaholic:policy-lens — keep: hooks/policy-lens.sh matches this marker. -->

Run the preloaded `workaholic:catch` skill's **Run Workflow** section end to end (Phases 0–3). `$ARGUMENT` is an optional window (e.g. `/catch 30 days`); default is the last two weeks. This command (main agent) spawns the per-developer collectors as `general-purpose` subagents and does all synthesis and follow-up Q&A itself, per the skill.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
