---
type: Feedback
title: A shell cwd reset let archive.sh push directly to main
kind: instruction
source: discussion
created_at: 2026-08-10T17:11:07+00:00
author: noreply@anthropic.com
supersedes: 
---

# A shell cwd reset let archive.sh push directly to main

# A shell cwd reset let archive.sh commit and push directly to main

During an /implement run driving qmu/workaholic#365 (ticket 20260810164156), a Bash tool call's
working directory silently reverted from a claim's worktree
(.worktrees/batch-20260810170054) to the main checkout between two otherwise-sequential
commands. archive.sh, invoked next with a cwd-relative ticket path, resolved and archived the
MAIN checkout's copy of the ticket and pushed the resulting commit (8d300a04) straight to
origin/main -- bypassing the claim protocol, the PR, and the branch-safety scan gate entirely.
The commit was content-neutral (a pure rename) and was corrected by merging origin/main into
the claim branch rather than resetting or force-pushing main, so no history was rewritten and
no work was lost, but the underlying gap remains: nothing in this repository currently detects
or prevents a Bash-invoked git command (commit/push) from acting against the wrong checkout
when several worktrees are open in one session. guard-repo-confinement.sh checks Write/Edit
targets against the toplevel and every worktree, but has no equivalent for git operations
launched through Bash.

How to Fix: consider a PreToolUse(Bash) guard that inspects a git commit/push invocation's
cwd against the branch/worktree the calling script or session declares it is operating on, or
require every claim-worktree script invocation to use an explicit (cd <worktree> && ...)
subshell rather than relying on a prior bare cd persisting across tool calls.
