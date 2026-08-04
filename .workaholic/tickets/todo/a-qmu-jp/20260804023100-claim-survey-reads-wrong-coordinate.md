---
created_at: 2026-08-04T02:31:00+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort:
commit_hash:
category:
depends_on:
mission:
claim: work-20260804-105730
---

# claim サーベイが誤った座標を読む: 駆動済みチケットが backlog に残り、PR 待ちユニットが resumable になる

## Overview

`/drive` の survey が claim の状態を2箇所で読み違える。どちらも単独では無害に見えるが、合わさると **終端トークンが恒久的に `pending` になり**、かつ **人間がレビュー中のユニットを次の tick が奪い返す**。

### 症状1: `plan-units.sh` が claim 済み成果物を backlog から差し引かない

5つのバックログチケットをそれぞれ別ユニットとして claim・駆動し、全て PR まで到達させた直後の survey が、**その5件をそのまま `backlog[]` に列挙**した。`claimed[]` には3ユニットが正しく出ているので、claim 自体は見えている。差し引きだけが効いていない。

スキル文書は「claim が既に保持しているものを共有 reader 経由で差し引く」と述べており、また archive によるリネーム（`todo/<user>/X.md` → `archive/<branch>/X.md`）を追跡して**ベース側のパスで報告する**と明記されている。実際には駆動済み（= archive 済み）のチケットが差し引かれていない。

結果: 何も残っていないのに survey が「まだ claim できるものがある」と報告し続け、§7 の表に従うと token が `ok` になれない。

### 症状2: `queue_drained` 判定がユニット自身の成果物ではなく `todo/` 全体を見ている

`review` ルートのユニットは PR で停止するのが正しい設計で、その結果ブランチ tip が進まず heartbeat が失効する。これを stale な run と区別するために `queue_drained`（= そのユニットに駆動すべきものが残っていないなら resumable にしない）がある。

実 run では、**自身のチケットを archive 済みで PR も open な batch ユニット**が `resumable: true` / `resume_reason: "heartbeat_lapsed"` と報告された。ブランチ tip の `todo/` には**他の**（無関係な）チケットが残っており、判定がそれを「このユニットに駆動すべきものが残っている」と解釈したように見える。

スキル文書自身が、この誤判定が実際に起きた場合の害を記録している — 「hourly runner が同じユニットを3回取り直し、最初の pass 以外は人間がレビュー中のブランチに空の `Resume` コミットを足しただけだった」。batch ユニットの判定は、`todo/` 全体ではなく**そのユニットの artifacts**に限定される必要がある。

## Policies

- `workaholic:implementation` / `policies/observability.md` — サーベイが実態と異なる報告をすると、外から状態が把握できない。
- `workaholic:operation` / `policies/ci-cd.md` — 終端トークンは caller 側ループの契約であり、恒久 `pending` はループを終わらせない。

## Key Files

- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — backlog からの claim 差し引き。
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — 共有スキャン。rename 追跡とベース側パスへの写像、および resumability 判定。
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — 同じスキャンのレンダラ（回帰確認に使える）。

## Related History

- 「archive がチケットを rename するため、claim 時のパスを tip で引くと見つからない」問題は既知として文書化され、tree-to-tree diff による net old→new 写像で解決したとされている。今回の症状1はその写像が backlog 差し引きまで届いていないように見える。

## Quality Gate

### Acceptance Criteria

- claim 済み（archive 済みを含む）のチケットが `backlog[]` に現れない。`excluded[]` に `claimed_active` 等の理由付きで出るか、少なくとも offer されないこと。
- 自身の artifacts を全て駆動し終えた batch ユニットは、heartbeat が失効していても `resumable: false` かつ `resume_reason: "queue_drained"` を報告する。ブランチ tip に無関係なチケットが残っていても影響されないこと。
- mission ユニットの既存判定（tip でそのミッションを名指すチケットが1件以上残っているか）は変わらないこと。
- 全チケットを駆動して PR まで到達させた直後の survey が、`missions` / `backlog` / `resumable` すべて空を報告する（= `/drive` が `ok` を返せる）。
