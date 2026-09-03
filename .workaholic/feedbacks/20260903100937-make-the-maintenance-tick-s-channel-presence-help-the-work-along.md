---
type: Feedback
title: Make the maintenance tick's channel presence help the work along
kind: instruction
source: slack
subject: person:tamurayoshiya
created_at: 2026-09-03T10:09:37+09:00
author: a@qmu.jp
supersedes: 
---

# Make the maintenance tick's channel presence help the work along

Source: https://github.com/qmu/workaholic/issues/946

The operator's words, verbatim:

> Moderation って、こういう bot みたいな挙動を期待しているのではなく、もっと有機的に開発の円滑化を
> 支援してくれていないと、ただのうざい通知なのです

## What the ask says

`/moderate`'s channel presence reads as a bot reporting its own internals. The post is read by a
developer deciding what to do next, and that is the whole specification. Four defects are named
with the morning that produced them:

1. **A global clause is stapled to every question regardless of relevance.** The unattributed-work
   sentence is a repository-level fact pasted into all five `🙋` bodies because the renderer had it
   in hand, not because the reader needed it there.
2. **The tick's own bookkeeping is addressed to a person.** `未到達 0 件、未所属 1 件を残します` says
   what the tick's counters will hold afterwards. Nobody asked.
3. **Questions of one kind arrive one per subject.** Three arrived directions produced three
   near-identical questions six seconds apart, then two more — five pings in twenty-four seconds.
   The per-tick cap spaces the symptom out rather than removing it.
4. **A question gives the reader nothing to decide with.** It states a count and asks whether the
   direction is finished, without saying what the direction achieved, without linking what landed,
   and without offering the tick's own reading — while every other part of this loop states a
   judgement rather than handing a person a bare choice.

And the machine talks about itself out loud: the `tick-day:` key printed at a reader, a sentence
explaining which internal step suppressed a post, and the same `⚠` lines repeated verbatim in the
root and again in the digest thirty-eight minutes later. Meanwhile the one line worth breaking
silence for — `base-health` admitting it could not read `main`'s checks — is the fourth bullet of a
digest, in the same weight as a commit count.

The tick already holds every input a useful morning message needs: what landed since yesterday,
what is queued, which pull requests conflict and on which files, which missions have every
acceptance ticked with one ticket left. It spends them on counts and step names.

## What would make it done

- Questions of one kind are **one message** naming N subjects, not N messages naming one each.
- A question **carries what is needed to answer it** — what the direction achieved, in a sentence,
  and the tick's own reading of whether it looks finished. Stating a view is not deciding.
- The machine's internals **leave the message**: no `tick-day:` key, no step numbers, no counters
  describing what the tick will hold afterwards, no explanation of why something was suppressed. A
  reader who never learns this loop has steps should still understand every line.
