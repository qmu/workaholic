---
type: Feedback
title: Finish Codex support as an external process with inspectable state
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-09-06T10:17:22+09:00
author: a@qmu.jp
supersedes: 
---

# Finish Codex support as an external process with inspectable state

Source: https://github.com/qmu/workaholic/issues/999

feedback: 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md

## The ask, in the operator's own words

> 特にcodexサポートを強化してもらいたいです、codexは外部プロセスとして起動できると思うので、
> .codexディレクトリのような場所から内部の状態を確認しつつ完成させることを目標にしたいです、
> そのほか追加されるfbへも対応して下さい、止まらないことが最重要なので、全裁量をもって
> 判断してもらって良いです、これから飛行機に乗ります

Given while starting `/work` on 2026-09-06, immediately before the operator boarded a flight, so
the loop runs unattended against this direction with full discretion, and **not stopping is the
operator's stated first priority**.

## What is being asked for

**Strengthen Codex support until it is finished, and prove it from observable state.** Three
parts, and the third changes how the first two are judged:

1. **Codex runs as an external process.** Codex is launchable as an external process, so the
   loop does not need Codex to hold a session the way Claude Code does.
   `skills/work/scripts/codex-loop.sh` already dispatches detached workers; the ask is that this
   path be carried to completion rather than left as the documented fallback for an agent with
   no Scheduled surface.

2. **The internal state is inspectable from a `.codex`-like directory.** Today `.codex-loop/`
   holds the supervisor's transcripts and `status.json`. The ask names a place a person — or a
   later tick — can look at to see what the Codex side is actually doing, and asks that the work
   be completed *while checking that state*, not merely declared complete. An empty
   `.codex-loop/` on a machine the operator believes is looping is the shape this is against.

3. **Handle the FBs that arrive while this runs.** The inbound channel keeps producing asks
   while the operator is unreachable; those are not deferred behind this direction.

## What this does not ask for

It does not ask for a second loop premise beside the Claude one, and it does not ask for the
retired three-session split. One coordinator, one clock, one tick log — the Codex path reaches
that same shape with processes instead of subagents, which is what `skills/work/SKILL.md`
already states.

## The operator is unreachable

Every fork this raises that would ordinarily wait for a ruling is the run's to take
("全裁量をもって判断してもらって良い"). A fork that genuinely cannot be taken is an
`## Open Decisions` item under the writing floor, not a stop.
