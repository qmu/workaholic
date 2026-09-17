---
created_at: 2026-09-17T12:28:14+09:00
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
