---
created_at: 2026-08-04T02:31:00+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort: 1h
commit_hash:
category: Changed
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

## Final Report

Development completed as planned. Both reported symptoms turned out to be **one** root
cause, which changed the shape of the fix: nothing in `plan-units.sh` needed touching, and
the whole repair landed in the claim reader's artifact resolution.

### Discovered Insights

- **Insight**: The two symptoms are the same bug. `claims_scan` resolves each claimed
  artifact's tip-side path through `git diff --find-renames`; when that diff reports the
  archive as add + delete rather than a rename, the artifact is dropped and the claim's
  `artifacts` list comes back empty. An empty list makes `plan-units.sh` subtract nothing
  (symptom 1) **and** makes `claims_has_work` take its deliberate "no artifacts means
  unknown, so assume work remains" branch (symptom 2).
  **Context**: The two were reported as separate defects in separate subsystems, and the
  second one's stated hypothesis — that a batch's `queue_drained` test scans all of
  `todo/` — is not what the code does; a batch never scans `todo/` at all unless its
  artifact list is empty. Reproducing before fixing is what made the single cause visible.

- **Insight**: `git diff --find-renames` is a similarity heuristic (50% by default,
  abandoned entirely past `diff.renameLimit`), and `archive.sh` is not a pure move — it
  stamps `effort` and appends the Final Report. A short ticket that grows a long report
  therefore falls below the threshold and is reported as add + delete.
  **Context**: The pre-existing rename test moves tickets with a bare `git mv`, so git
  pairs them at 100% similarity and the test was green through the whole defect. A fixture
  that exercises a heuristic at its easiest input proves nothing about the heuristic.

- **Insight**: A silent artifact drop is worse than a loud one because `excluded[]` is
  defined as "items the survey saw and dropped". A ticket whose claim lost track of it does
  not appear there at all — it reappears in `backlog[]` looking untouched, with no trace
  anywhere in the survey that it is already in flight on a pushed branch.
  **Context**: This is why the fallback resolution is exact (a unique ticket filename)
  rather than a widened similarity threshold: a threshold that is merely lower still fails
  silently at some input, and the failure mode is invisible by construction.

- **Insight**: The by-filename fallback must be scoped to `.workaholic/tickets/`. Every
  mission's artifact is named `mission.md`, so an unscoped basename lookup would resolve a
  deleted mission's claim onto a different mission's file — a silent cross-claim, which is
  strictly worse than the dropped artifact it would be repairing.
  **Context**: Ambiguity therefore falls back to the mapped path and drops the artifact,
  which is the conservative pre-existing behavior. Pinned by its own test.
