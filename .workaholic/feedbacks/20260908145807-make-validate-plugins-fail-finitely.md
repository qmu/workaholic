---
type: Feedback
title: Make Validate Plugins fail finitely
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-08T14:58:07+09:00
author: a@qmu.jp
supersedes: 
---

# Make Validate Plugins fail finitely

Validate Plugins remains pending indefinitely in `Test agentic loop contracts and consumers`. The observation-clock fixture waits for a second observation-only wake while its QFS stub repeats source `8.1`; #1100 correctly deduplicates that source after the first read, so the fake Codex process never reaches its terminating second invocation. The CI step has no enclosing timeout, turning the fixture defect into an unlimited pending check. Make the fixture emit a distinct second source coordinate, bound the process-level test, and make the CI step fail finitely on future leaked processes. Source: https://github.com/qmu/workaholic/issues/1107
