---
type: Concern
concern_id: commit-subject-rule-binds-on-no-path
mission: 
tickets: []
origin_pr: 
origin_pr_url: 
origin_branch: 
origin_commit: 
severity: moderate
last_seen: 
first_seen: 
status: active
compound: true
resolved_by_pr: 
resolved_by_commit: 
---

# The commit-subject rule binds on no path — including the sanctioned one

## Description

The repo invests two hook layers, a CLAUDE.md section and a shared hooks/lib/check-subject.sh in one commit-subject rule (present-tense, <=50 chars, no feat:/[bracket] prefix), and there is no execution path on which it actually binds. The umbrella half: every bypass surface is open — guard-git-commit.sh allows `git commit -F file` (it only inspects an inline -m), the git-native hooks/git/commit-msg is opt-in via core.hooksPath and is NOT installed even in this repo, `--no-verify` waives it by design, and no server-side required status check exists. Read alone that is tolerable, because it describes a determined bypass while the sanctioned path is assumed correct-by-construction. The other half removes that assumption: skills/commit/scripts/commit.sh — the script /commit and /drive's archive.sh both route through — performs NO subject validation and never calls check-subject.sh, and guard-git-commit.sh deliberately exempts script-wrapped commits because they expose no top-level `git commit`. So the path the repo tells everyone to use is not merely bypassable; it is the largest unguarded surface, and it is the default. Measured, not argued: commit e3366bfd on branch work-20260715-112717 carries a 52-character subject that commit.sh accepted silently, and check-subject.sh rejects that same string when driven directly.

## How to Fix

Call check-subject.sh at the top of commit.sh and fail non-zero on a violation. That is one line, it closes the DEFAULT path without touching either guard, and it turns the shared rule source into something the sanctioned route actually executes. The remaining bypasses (--no-verify, -F file, an uninstalled commit-msg) are a deliberate belt-not-vault stance; an unbypassable surface would need a server-side required status check, which no local hook can provide — treat that as a separate rollout decision rather than a code fix.
