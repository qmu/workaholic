---
origin_pr: 43
origin_pr_url: https://github.com/qmu/workaholic/pull/43
origin_branch: work-20260617-000311
origin_commit: 1ed7fbb
created_at: 2026-06-17T01:51:15+09:00
severity: low
status: resolved
resolved_by_pr: b6ae710
resolved_by_commit: 
---

# Architecture narrative still describes the prior three-plugin model

## Description

All functional paths, manifests, build scripts, and the Project Structure/Version Management docs are updated to the single `workaholic` plugin, but CLAUDE.md's Cross-Agent Skill Exposure and distribution prose still frame `core`/`standards`/`work` conceptually (a flag note was added at the dependency section) (see commit ddb8e97).

## How to Fix

A dedicated narrative-rewrite pass over CLAUDE.md's Architecture Policy and distribution sections; mechanics are unchanged, only the plugin-name framing is stale. The `workflows` marketplace entry description ("Claude Code users install core/work instead") needs the same fix.
