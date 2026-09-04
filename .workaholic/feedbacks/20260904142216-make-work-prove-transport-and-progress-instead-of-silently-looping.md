---
type: Feedback
title: Make /work prove transport and progress instead of silently looping
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-04T14:22:16+09:00
author: a@qmu.jp
supersedes:
---

# Make /work prove transport and progress instead of silently looping

# Make `/work` prove transport and progress instead of silently looping

Source: https://github.com/qmu/workaholic/issues/974

When `/work` starts, it must not report success merely because a supervisor process exists. Verify the first tick and report whether Slack is connected, whether `/implement` can run, what `/propose` decided, and when the next tick is due. Make missing Slack transport a visible start failure or provide an equivalent connected transport, surface every completed tick and blocked reason to the invoking session, and provide an observable status or durable summary that distinguishes looping from progress. Preserve the Slack workflow where proposals appear as FB threads and later receive their Implemented result.
