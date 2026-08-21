---
name: commit
description: Commit the working changes with a policy-conformant message via commit.sh.
skills:
  - workaholic:commit
  - workaholic:gather
---

# Commit

Run the preloaded `workaholic:commit` skill end to end — inspect the working tree, stage safely per its **Multi-Contributor Awareness** and **Staging Behavior**, derive a conformant message per its **Message Format**, and commit through `commit.sh` (the only authorized commit path). This command is for a small, legitimate, **non-ticketed** change; prefer `/drive` for anything ticketed. It commits on the current branch only — no branch, no PR, no push; use `/story` and `/ship` for those.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
