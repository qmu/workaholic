---
type: Feedback
title: Reconcile accepted scope across blocked implementation PRs
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-17T12:28:59+09:00
author: a@qmu.jp
supersedes: 
---

# Reconcile accepted scope across blocked implementation PRs

kind: instruction / source: discussion / subject: person:tamurayoshiya

# Reconcile accepted scope when implementation pull requests accumulate without delivery

The unattended moderate/work loop must detect when accepted human requests have implementation pull requests but remain absent from the published branch and runtime. In the observed failure, many related implementation PRs accumulated behind the same external CI account block. Each had local evidence, but none reached the main branch. Moderate continued to report routine health instead of reconciling the accepted scope, integrating compatible branches, and making the shared delivery blocker explicit.

Track accepted requests through implementation, merge, deployment, and public verification as one delivery ledger. When several open PRs collectively satisfy one conversation, moderate should identify the missing delivery state, propose or create a bounded integration unit, preserve dependency order, and prevent “PR created” from being treated as completion. If a shared external gate blocks all PRs, report one blocker with the full affected scope and continue independent integration work rather than leaving fragmented branches for the operator to discover.


Source: https://github.com/qmu/workaholic/issues/1159
