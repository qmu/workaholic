---
type: Feedback
title: Restore mission-sized batching as the release boundary
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-08T12:46:44+09:00
author: a@qmu.jp
supersedes: 
---

# Restore mission-sized batching as the release boundary

kind: instruction / source: discussion / subject: person:tamurayoshiya
feedback: 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md

# Restore mission-sized batching as the release boundary

The feedback ingestion loop appears to turn each small feedback issue into its own version, merge, release, and delivery, producing too many versions in a day. Re-examine the behavior end to end so related small changes are deliberately grouped under a real mission with multiple tickets, completed as one PR-unit, written up as one story, and only then merged, versioned, and delivered. The plugin was just reduced and fundamentally redesigned, so address the underlying model of mission formation, batching, and release boundaries rather than adding more cautionary prose or another local exception.

Source: https://github.com/qmu/workaholic/issues/1091
