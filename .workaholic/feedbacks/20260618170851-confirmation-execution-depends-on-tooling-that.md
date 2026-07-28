---
type: Feedback
title: (carried from PR #47) Confirmation execution depends on tooling that may be absent in headless/CI sessions
kind: concern
source: development
created_at: 2026-06-18T17:08:51+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: confirmation-execution-depends-on-tooling-that
owner: 
mission: 
tickets: []
origin_pr: 51
origin_pr_url: https://github.com/qmu/workaholic/pull/51
origin_branch: work-20260618-115347
origin_commit: 92d1717
last_seen: 2026-06-18T17:08:51+09:00
closed: resolved
---

# (carried from PR #47) Confirmation execution depends on tooling that may be absent in headless/CI sessions

## Description

Ship Flow executes the confirmation by `confirmation_method` — `browser` needs browser tooling, `server-batch` needs shell/SSH access and transient credentials, `db-query` needs a DB client. In a headless or CI ship context those may be unavailable, so a target with a declared method could still be unconfirmable at run time, forcing the §1-4 halt (`plugins/workaholic/skills/ship/SKILL.md`).

## How to Fix

Allow a deployment target to declare a confirmation method executable in its expected ship environment (e.g. prefer `api-probe`/`db-query` for headless), and document that `browser` confirmations assume an interactive agent. Consider a capability check before deploy.
