---
type: Feedback
title: Relatedness remains a semantic judgement
kind: concern
source: development
subject: observer_ai:a@qmu.jp
created_at: 2026-09-08T15:53:52+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: relatedness-remains-a-semantic-judgement
owner: a@qmu.jp
mission: [make-slack-acknowledgements-informative-without-becoming-notification-noise]
tickets: []
origin_pr: 1105
origin_pr_url: https://github.com/qmu/workaholic/pull/1105
origin_branch: work-20260908-140833
origin_commit: e92b58a6a
last_seen: 2026-09-08T15:53:52+09:00
---

# Relatedness remains a semantic judgement

## Description

同じ intended outcome かは conversation context に依存し、validator 単独では決められません（[86591a711](https://github.com/qmu/workaholic/commit/86591a711) の `plugins/workaholic/commands/infinite-development.md`）。

## How to Fix

明確な関係だけを group 化し、不確かなものは singleton に保ちます。
