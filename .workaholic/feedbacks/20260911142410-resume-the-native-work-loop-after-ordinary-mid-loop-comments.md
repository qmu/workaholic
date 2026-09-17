---
type: Feedback
title: Resume the native work loop after ordinary mid-loop comments
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-11T14:24:10+09:00
author: a@qmu.jp
supersedes: 
---

# Resume the native work loop after ordinary mid-loop comments

# Resume the native work loop after ordinary mid-loop comments

Source: https://github.com/qmu/workaholic/issues/1147

The operator asks that the native work loop, after handling an ordinary human comment
inserted mid-loop, return to the same loop on its own — the same coordinator instance and the
same startup anchor — rather than letting a routine final response silently terminate
observation.

The ask, in the operator's own words:

> When a human inserts an ordinary question, correction, or follow-up while the native work
> loop is running, handle that comment and then return automatically to the same loop with its
> existing coordinator instance and startup anchor. Do not let a routine final response silently
> terminate observation. Only stop for confirmation when the agent's final comment contains
> information the human genuinely needs to review before work can continue; in that case, ask
> 「ループを再開してよろしいですか？」 and remain stopped until the answer arrives. Add this
> distinction to the loop's conversation/final-response contract and cover both paths with
> tests: routine interruption resumes automatically, while a review-required handoff explicitly
> asks and waits.

Two paths are named and must be told apart: a routine interruption, which resumes
automatically; and a review-required handoff, which asks the one Japanese question above and
waits until the answer arrives. An explicit wait or stop addressed to the loop is a different
fact and keeps the hold contract it already has.
