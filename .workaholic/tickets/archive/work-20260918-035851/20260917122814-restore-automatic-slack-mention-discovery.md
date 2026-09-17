---
created_at: 2026-09-17T12:28:14+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260917122803-restore-automatic-slack-mention-discovery.md]
merge_policy:
verification_handoff: 
claim: work-20260918-035851
---

# Restore automatic Slack mention discovery

## Overview

既知 thread 外の新しい Slack mention/reply を効率よく発見し、発見後は通常の active-thread cadence に載せる。

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/transport/` — mention/reply discovery capability と cursor。
- `plugins/workaholic/skills/work/` — discovery 結果の dedup と active-thread 登録。
- Slack observation regression tests — history window 外 root の mention fixture。

## Implementation Steps

1. 既知 root polling と channel history では古い root 配下の reply を見落とす再現を固定する。
2. active conversations を横断する bounded mention/reply discovery を transport seam に追加する。
3. message key で重複排除し、発見 thread を通常 cadence に登録して直ちに追跡する。

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- current channel-history window 外の root に付いた新規 mention を事前登録なしで発見する。
- 同じ message を重複処理せず、発見後は thread cadence が継続する。

**Verification method** — the commands/tests/probes that prove them:

- Slack transport fixture と work observation suite を実行する。

**Gate** — what must pass before approval:

- full-thread audit なしで mention 発見の回帰 fixture が成功する。

## Considerations

探索は bounded に保ち、channel history を reply coverage の証明として扱わない。

## Final Report

Development completed as planned.

The mention reading was a text test over the channel delta and nothing else, so a mention on a
root older than the read window — or in a reply, which Slack channel history never carries —
could not be seen at all. `observe-channel.sh` now searches the channel's own history for the
declared sender's mention token through the existing `search_exact` operation, one bounded call
per tick; every coordinate it finds joins the durable watch set and is read immediately, bounded
by `WORKAHOLIC_MENTION_FANOUT`. One thread is read at most once per tick whichever arm named it.

### Discovered Insights

- **Insight**: capture placement decides whether a discovered message can be routed. Capturing
  the search's rows before reading their thread made the thread read see its own message as a
  duplicate, and the classifier — which emits only newly-captured ids — dropped the very reply
  the arm exists to deliver.
  **Context**: capture in this design is per surface (the channel capture owns the delta's rows,
  the thread capture owns a thread's). A new discovery arm must discover coordinates and leave
  capture to whichever surface reads the message, or it silently starves the classifier.
- **Insight**: `new_input_ids` is the channel delta's own list, so a human reply found by thread
  discovery was **not** activity — `codex-loop.sh` derived `activity` from that list alone and
  backed the interval off on the very ticks somebody had answered the loop's own question.
  **Context**: the two lists are deliberately separate (`new_input_ids` vs `thread_replies`), so
  the fix belongs in the cadence term rather than by merging the lists; a `reaction_only` reply
  is correctly not activity.
- **Insight**: `search_exact` is spelled differently by the two adapters — `where text == <query>`
  in `adapters/qfs.sh` (whole-text equality) and `contains` in `adapters/qfs-native.sh`.
  **Context**: mention discovery depends on containment, so it is the pipe-SQL route that can
  actually answer it; the non-native route simply finds nothing, which is why the arm reports
  `exhaustive: false` rather than treating an empty result as evidence of absence.
