---
type: Feedback
title: Make the tick's Slack questions self-explanatory and close the loop in the thread
kind: instruction
source: development
subject: person:tamura.yoshiya@gmail.com
created_at: 2026-08-31T20:03:50+09:00
author: a@qmu.jp
supersedes: 
---

# Make the tick's Slack questions self-explanatory and close the loop in the thread

The operator, in an interactive session on this repository, asked for two changes to the questions `/moderate` posts on Slack.

Verbatim (Japanese, as written):

> moderate で slack 上から僕に質問をした時、もっと自己説明的にわかりやすく質問をしてもらいたい、長すぎないように、また claude code web routine の方で回答したら、その後の対応を済ませた後に同じ slack スレッドに僕の回答内容とその結果どうなったかも残るようにしてもらいたい

Two parts.

**(1) The question itself must be self-explanatory, and short.** A question today opens
with a machine subject — a unit id, an artifact path, a claim verdict, a strategy slug —
and assumes the reader knows which step asked and why. The operator reads it on Slack with
no other context in front of them. What is asked for is that each question say, in plain
terms, what happened and what it is asking the person to decide or do, and then stop. The
one-sentence body bound in `workaholic:notify` is a ceiling to respect, not to breach: the
repair is wording and self-containment, not more text.

**(2) The thread must end up carrying the answer and its outcome.** When the operator
replies in the question`'s thread, `/moderate`'s `question-answers` step reads the reply,
records it through `record-answer.sh`, may file an `[FB]` issue through
`file-inbound-ask.sh`, and stamps the answer message with the catalog`'s
`:ballot_box_with_check:` reaction — and deliberately posts no reply. So from the thread
the operator cannot see what the loop understood, nor what came of it. What is asked for is
that, after the follow-up work is done, one reply lands in that same thread carrying the
answer as the loop recorded it and the outcome — what was filed, driven or merged, or why
nothing was.

**The constraints the repair must respect**, rather than implement around:

- `workaholic:notify`'s catalog is the one home for a post shape, and the routine
  templates copy it byte-identically (pinned against drift).
- `record-answer.sh` stays the one writer of an answer; `file-inbound-ask.sh` stays the one
  filer.
- The no-reply rule for this event was a deliberate anti-restatement decision. Reversing it
  needs its narrowing stated: one reply, after the act, carrying facts the thread does not
  already have — never a restatement of the question.
- The `/moderate` tick writes nothing but its own log, so any post rides the existing seams.
- The asked-once gate, the keys, the caps and the quiet/working-day holds do not move.
