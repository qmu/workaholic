---
name: standup
description: Report the day's development activity per strategy - what moved since yesterday, what is waiting, and how close each dated direction is to its date. Reads only - it writes no file, commits nothing, merges nothing and deploys nothing.
skills:
  - workaholic:standup
  - workaholic:notify
---

# Standup

Run the preloaded `workaholic:standup` skill end to end. One behaviour, no argument, no `AskUserQuestion` at any step: read the digest (`digest.sh`), report it per strategy, and — when a Slack surface is available and the digest is not a no-op — post the one `📣 Standup` line `workaholic:notify` defines for it.

**It writes nothing.** No file, no commit, no branch, no pull request, no merge, no deployment. A morning with no active strategy, or with nothing that moved and no date approaching, is a named no-op: it reports the reason and posts nothing.

**It is the repository's routine, not a developer's**: `[Standup]` carries `scope: repository` and is configured by `/setup-repo-routines` from one account, because N copies would post the same digest N times each morning.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
