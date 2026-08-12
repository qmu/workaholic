---
type: Feedback
title: Document that a manual routine fire ignores a custom run body
kind: instruction
source: discussion
created_at: 2026-08-12T19:18:16+00:00
author: a@qmu.jp
supersedes: 
---

# Document that a manual routine fire ignores a custom run body

Measured 2026-08-12 18:30 UTC: firing a routine manually through the trigger API with a custom events body still ran the routine's stored prompt verbatim — the run body does not override the message. An operator drilling the propose-implement loop needs this stated where the manual-fire procedure is described, so nobody designs a hand-off around a prompt override that does not exist. Record the behavior in the loop documentation that covers manual routine fires.

Source: https://github.com/qmu/workaholic/issues/401
