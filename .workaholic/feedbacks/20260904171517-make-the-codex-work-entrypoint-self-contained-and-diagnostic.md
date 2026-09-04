---
type: Feedback
title: Make the Codex work entrypoint self-contained and diagnostic
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-04T17:15:17+09:00
author: a@qmu.jp
supersedes: 
---

# Make the Codex work entrypoint self-contained and diagnostic

Source: https://github.com/qmu/workaholic/issues/978

The Codex work entrypoint must be self-contained in the supported installation shape. It must distinguish a missing external clock wrapper from missing plugin artifacts, report a precise clock_wrapper_missing condition, avoid recommending plugin repair when the plugin is intact, and prove the documented CLI dry-run from an empty consuming repository.
