---
type: Feedback
title: "workflows" plugin fails marketplace sync — missing manifest
kind: instruction
source: discussion
created_at: 2026-08-10T09:22:22+00:00
author: a@qmu.jp
supersedes: 
---

# "workflows" plugin fails marketplace sync — missing manifest

# "workflows" plugin fails marketplace sync — missing manifest

Claude Team's plugin marketplace sync reported an error for this marketplace: the `workflows` plugin was skipped as of commit `5866bcf` (last sync 2026-07-29 14:48), because it requires `.claude-plugin/plugin.json` or a top-level `SKILL.md` declaring its components — or `strict: false` in `marketplace.json` to accept its inline manifest instead. Fix: add the missing manifest file for the `workflows` plugin, or set `strict: false` in `marketplace.json` so its inline manifest is accepted.
