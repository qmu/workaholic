---
type: Feedback
title: An unattended tick can be stopped forever by a permission prompt
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-08-31T11:35:07+00:00
author: a@qmu.jp
supersedes: 
---

# An unattended tick can be stopped forever by a permission prompt

# An unattended tick can be stopped forever by a permission prompt, and nothing says so

Source: https://github.com/qmu/workaholic/issues/762

Three consecutive ticks on a consuming repository are sitting at `requires_action` and have
not finished: 07:50, 08:50 and 09:50 UTC. Every tick before them that day reached `idle`.

The 09:50 run stopped here, on a read:

    sed -n '/^# Usage/,/^$/p' $SRC/skills/moderate/scripts/ask-question.sh | head -30
    grep -n -- '--record-ask|--key|--to|--coordinate' $SRC/skills/moderate/scripts/ask-question.sh

    permission prompt Bash: Claude requested permissions to edit
    .../skills/moderate/scripts/ask-question.sh which is a sensitive file.

`sed -n …p` and `grep -n` read; neither writes. The prompt was raised for an edit that the
command cannot perform, and the run has been waiting on it since.

A routine has nobody to answer a prompt. The tick therefore never reaches `persist-log`, so
its own log line is never written — the one record that would show it stopped is the record
the stop prevents. From outside, a tick blocked on a prompt and a quiet hour are the same
absence of a post.

Two asks. Read-only inspection of a plugin script should not raise a write prompt at all —
the tick reads its own scripts constantly and each read is a chance to hang. And when a tick
does stop before persisting, that fact needs to reach the operator by some path that does not
depend on the step the stop prevented.
