---
origin_pr: 47
origin_pr_url: https://github.com/qmu/workaholic/pull/47
origin_branch: work-20260617-210627
origin_commit: 6a64cf0
created_at: 2026-06-17T22:08:29+09:00
last_seen: 2026-06-17T22:08:29+09:00
first_seen: 2026-06-17T22:08:29+09:00
concern_id: confirmation-execution-depends-on-tooling-that
severity: moderate
status: resolved
resolved_by_pr: 55
resolved_by_commit: a23d69c
---

# Confirmation execution depends on tooling that may be absent in headless/CI sessions

## Description

Step 6 executes the confirmation by `confirmation_method` — `browser` needs browser tooling, `server-batch` needs shell/SSH access and transient credentials, `db-query` needs a DB client. In a headless or CI ship context those may be unavailable, so a target with a declared method could still be unconfirmable at run time, forcing the §1-4 halt (`plugins/workaholic/skills/ship/SKILL.md` Ship Flow step 6).

## How to Fix

Allow a deployment target to declare a confirmation method that is executable in the expected ship environment (e.g. prefer `api-probe`/`db-query` for headless contexts), and document that `browser` confirmations assume an interactive agent. Consider a capability check before deploy.
