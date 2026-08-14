---
name: release-status
description: Report what is waiting to deploy on the base right now, per deployment target, and what about it needs a human. Reads only - it writes no file, commits nothing, merges nothing and deploys nothing.
skills:
  - workaholic:ship
  - workaholic:notify
---

# Release Status

Run the preloaded `workaholic:ship` skill's §7 **Release status** section end to end. One behaviour, no argument, no `AskUserQuestion` at any step: read the deploy state against the base (`report-deploy-status.sh`), report it, and — when a Slack surface is available and the digest is genuinely new — post the one status line `workaholic:notify` defines for it.

**It writes nothing.** No file, no commit, no branch, no pull request, no merge, no deployment. That is the whole contract and it is not conditional: the section it reports on — a release note's `## Deployment Plan` — is drafted inside a shipping unit's own pull request by `/ship`, and the ship skill's §7 records the three writer designs that were measured and refused. A tick with nothing new writes nothing, commits nothing and posts nothing.

**It is the repository's routine, not a developer's**: `[Release Status]` carries `scope: repository` and is configured by `/setup-repo-routines` from one account, because N copies would post the same line N times an hour into the same thread.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
