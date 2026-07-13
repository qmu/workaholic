---
origin_pr: 48
origin_pr_url: https://github.com/qmu/workaholic/pull/48
origin_branch: work-20260617-231848
origin_commit: 63bbb9e
created_at: 2026-06-18T00:21:49+09:00
last_seen: 2026-06-18T00:21:49+09:00
first_seen: 2026-06-18T00:21:49+09:00
concern_id: confirmation-execution-depends-on-tooling-that
severity: moderate
status: active
resolved_by_pr: 
resolved_by_commit: 
---

# Confirmation execution depends on tooling that may be absent in headless/CI sessions

## Description

Ship Flow step 4 executes the confirmation by `confirmation_method` — `browser` needs browser tooling, `server-batch` needs shell/SSH + transient credentials, `db-query` needs a DB client. In a headless/CI ship context those may be unavailable, so a target with a declared method could still be unconfirmable at run time, forcing the §1-4 halt (carried from PR #47; `plugins/workaholic/skills/ship/SKILL.md` Ship Flow step 4).

## How to Fix

Let a target declare a method executable in its expected ship environment (prefer `api-probe`/`db-query` for headless), document each method's runtime prerequisites in the deployments template, and consider a pre-deploy capability check that warns when the environment lacks the required tooling.
