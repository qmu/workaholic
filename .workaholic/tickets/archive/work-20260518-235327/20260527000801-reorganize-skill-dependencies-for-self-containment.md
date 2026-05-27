---
created_at: 2026-05-27T00:08:01+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 1h
commit_hash: 8da225f
category: Changed
depends_on:
---

# スキル依存関係の再編（自己完結スキルへの統合検討）

## 概要

`core` スキルは互いのスクリプトを呼び合っており（SKILL.md 内で **81 箇所** のクロススキル参照）、これが `${CLAUDE_PLUGIN_ROOT}`（Claude Code の「プラグイン」という箱）に依存しているため、Agent Skills 標準に乗らない＝他コーディングエージェントへ移植できない根本原因になっている。Agent Skills 標準には「プラグイン」の箱が無く、各スキルは自分のフォルダ内しか参照できない**独立した自己完結単位**として配布される（仕様: "use relative paths from the skill root", "one level deep from SKILL.md"）。

このチケットは**実装そのものより先に「再編後の依存関係の姿を見る」ことを目的**とする。小さなスキルを相互参照で組む現構造を、**より大きく凝集した自己完結スキルへ統合**する案を設計・提示する。単なる連結ではなく、「どのスキルをどう束ねれば、クロススキル参照を最小化しつつ重複を抑えられるか」という再編設計を成果物とする。

**重要な前提（正直に明記）**: スキルを自己完結化しても、`drive`/`ship`/`report`/`ticket`/`trip` の価値はコマンド・サブエージェント・フック・Agent Teams という**プラグイン層のオーケストレーション**であり、これは Agent Skills 標準では表現できない。したがって本再編の射程は「知識・スクリプトを自己完結スキルに整理する」ところまでで、ワークフロー機構そのものの移植可能化ではない。再編がどこまで移植性に効くかも、成果物で明確にする。

## 現状の依存関係（実測）

```mermaid
graph TD
  drive --> branching
  drive --> check-deps
  drive --> commit
  create-ticket --> branching
  create-ticket --> gather
  trip-protocol --> branching
  trip-protocol --> check-deps
  trip-protocol --> system-safety
  report --> branching
  ship --> branching

  subgraph 共有ユーティリティ（多数から参照）
    branching
    gather
    check-deps
    commit
    system-safety
  end
  subgraph ワークフロー（オーケストレーション）
    drive
    ship
    report
    create-ticket
    trip-protocol
  end
```

- `branching` が最も広く共有されている（`drive`/`ship`/`report`/`create-ticket`/`trip-protocol` の 5 つから参照）。素朴にインライン化すると 5 重複になる。
- `gather`/`check-deps`/`commit`/`system-safety` も複数ワークフローから参照される。
- 加えてスクリプト内にプラグイン越境参照あり: `drive/scripts/archive.sh` → `../../../../core/skills/commit/scripts/commit.sh`、`check-deps/scripts/check.sh` → `${plugin_root}/../core`。

## 主要ファイル

- `plugins/core/skills/*/SKILL.md` — クロススキル参照の発生源（81 箇所）。再編の対象。
- `plugins/core/skills/{branching,gather,check-deps,commit,system-safety}/scripts/` — 共有ユーティリティ。統合方針（どこへ束ねる／共有のまま Claude 専用に残す）を決める対象。
- `plugins/core/skills/drive/scripts/archive.sh`、`plugins/core/skills/check-deps/scripts/check.sh` — プラグイン越境参照を持つスクリプト。
- `CLAUDE.md` — 「Common Operations」「Skill Script Path Rule」は現在この共有前提を**推奨**している。再編すれば、この方針自体の改定が必要になる（成果物で要否を判断）。
- `plugins/standards/skills/leading-*/SKILL.md` — 既に自己完結で移植済み。「自己完結スキルの基準形」として参照。

## 関連履歴

- [20260525205530-audit-claude-specific-refs-in-portable-skills.md](.workaholic/tickets/archive/work-20260518-235327/20260525205530-audit-claude-specific-refs-in-portable-skills.md) - 移植性監査。各エージェントのスクリプト解決方式（全エージェントが project CWD・skill dir をテキスト注入・モデルが prepend）と「スクリプト保有スキルは internal 維持」の結論を確定。本チケットはその先の「依存構造そのものの再編」を扱う。
- [20260525205529-package-core-standards-cross-agent-skills.md](.workaholic/tickets/archive/work-20260518-235327/20260525205529-package-core-standards-cross-agent-skills.md) - standards のみ露出。`metadata.internal` による除外機構と `skills` CLI の挙動を記録。

## 実装ステップ（成果物＝再編設計）

1. **現状の依存グラフを確定する。** 全 `core` スキルについて、SKILL.md とスクリプトの両方から「自分以外のスキル/プラグインへの参照」を抽出し、参照元→参照先と使用箇所数の表を作る（上の Mermaid を実データで精緻化）。

2. **各共有ユーティリティの「被参照数」を出す。** `branching`(5) のように広く使われるものと、`commit`(1) のように局所的なものを区別する。被参照数が統合方針を決める主因になる。

3. **統合候補を 2〜3 パターン設計する。** 例:
   - **(A) ワークフロー単位の自己完結化**: `drive` に `branching`/`check-deps`/`commit` を取り込み大きな自己完結スキルにする等。→ クロス参照は消えるが共有ユーティリティが重複する。
   - **(B) 被参照数しきい値**: 1〜2 箇所からしか使われない utility はインライン、多数から使われる utility（`branching`/`gather`）は「共有のまま Claude 専用」に留める折衷。
   - **(C) 知識/機構の分離**: 純知識部分は自己完結の移植可能スキルへ、スクリプト/オーケストレーションは Claude プラグイン専用に分離。
   各パターンについて、再編後の依存グラフ（Mermaid）、重複の量、移植可能になるスキル集合を提示する。

4. **トレードオフを評価し推奨案を出す。** DRY 喪失・重複ドリフトのリスク、移植できるスキルがどれだけ増えるか、`drive`/`ship` 等の Claude critical path の信頼性への影響（共有スクリプトの決定論的 `${CLAUDE_PLUGIN_ROOT}` を手放す是非）を天秤にかけ、推奨統合構造を 1 つ提示する。

5. **（実装は別チケット）** 本チケットの成果は「再編設計と推奨案」まで。実際のスキル統合・スクリプト移動・CLAUDE.md 改定は、設計が承認された後に別チケットへ切り出す。

## 考慮事項

- **単なる連結ではない。** ユーザ意図は「複数の小スキルを結合した、より大きく凝集した自己完結スキル」を作ること。束ねる境界は「ワークフローの凝集度」で引くべきで、ファイルを足し合わせるだけにしない。
- **重複 vs 共有のトレードオフが核心。** `branching` を 5 ワークフローへインライン化すれば 5 重複。`branching` のロジックが変わるたび 5 箇所同期が要る（＝現在の共有設計が防いでいるドリフト）。設計はこの代償を明示すること。
- **ビルド/パッケージング手段は本チケットの射程外だが選択肢として記録。** 「ソースは DRY のまま、配布時に共有スクリプトを各スキルへインライン展開する」パッケージ工程は重複問題を回避しうる。設計の代替案として触れてよいが、ここでは依存構造の再編に集中する。
- **移植性は再編だけでは完結しない。** コマンド/サブエージェント/フック/Agent Teams は Agent Skills 標準外。本再編は「知識・スクリプトの自己完結化」までを対象とし、ワークフロー機構の移植は扱わない（`work` プラグインは Claude 専用のまま）。
- **`standards` は変更不要。** 既に自己完結・移植済み。再編の基準形として参照するのみ。
- **`CLAUDE.md` の現行方針と衝突する。** 「Common Operations / Skill Script Path Rule」は共有前提を推奨している。再編を採用するなら同方針の改定が必要になる旨を成果物に含める。

## Final Report

設計完了。実測に基づき推奨案 (B) を確定した。実際の統合実装は別チケットへ切り出す。

### 確定した依存データ（実測）

クロススキル・エッジ（SKILL.md、数字＝参照回数）と被参照数（fan-in）：

| 共有ユーティリティ | fan-in | 呼び出し元 | インライン化の代償 |
|---|---|---|---|
| `branching` | 5 | create-ticket(2), drive(2), report(5), ship(4), trip-protocol(5) | 5 重複（真のハブ） |
| `check-deps` | 2 | drive(1), trip-protocol(1) | 2 重複 |
| `gather` | 1 | create-ticket(1) | 重複ゼロ |
| `commit` | 1 | drive(1)（+ `archive.sh`→`commit.sh` の越境 1） | 重複ゼロ |
| `system-safety` | 1 | trip-protocol(2) | 重複ゼロ |

SKILL.md 越境参照は計 9 エッジ、script 越境は 1 件（`drive/archive.sh`→`commit/scripts/commit.sh`）のみ。SKILL.md 内のプラグイン越境(`../`)参照は 0。

### 評価した3パターン

- **(A) ワークフロー単位で全吸収**：5 つの大きな自己完結スキル。`branching` 5 重複・`check-deps` 2 重複でドリフト再来。かつワークフローは command/subagent/hook 記述なので自己完結化しても他エージェントでは動かず移植実利が薄い。非推奨。
- **(B) fan-in しきい値で選択的統合（推奨）**：fan-in=1 の `gather`→create-ticket、`commit`→drive、`system-safety`→trip-protocol を吸収（重複ゼロ）。`branching`/`check-deps`（fan-in≥2）は共有のまま Claude 専用と明示。core スキルが 3 減り、越境参照の大半と script 越境 1 件が消え、グラフが単純化。無リスクの整理。
- **(C) 知識/機構の分離**：移植面を実際に増やす唯一の案だが、抽出される知識が workaholic 固有なら単体価値は限定的。

### 推奨と結論

**推奨は (B)。** 依存の絡まりの実体は「fan-in=1 の utility が独立スキルとして散らばっていること」で、これは重複ゼロで畳める。唯一の真のハブ `branching` は無理に分解せず共有のまま Claude 専用に残す。**移植性は本再編だけでは増えない**（ワークフローは Agent Skills 標準外）点も確定事項として記録する。移植できるのは純知識スキルのみで、それは standards で達成済み。

### Discovered Insights

- **Insight**: 依存の絡まりの定量的実体は `branching`（fan-in 5）ただ一つで、他の共有 utility（gather/commit/system-safety）は全て fan-in=1。
  **Context**: 「共有スクリプトが移植を阻む」問題は、実際にはほぼ `branching` 一点に集約される。fan-in=1 の utility は単一呼び出し元へ重複ゼロで吸収でき、再編の大半はローリスク。
- **Insight**: スキルの自己完結化と移植性は別問題。drive/ship/report/ticket/trip は command/subagent/hook/Agent Teams を記述するため、スクリプトを自己完結化しても他エージェントでは依然動かない。
  **Context**: 「移植のために再編する」という動機は (A) では満たされない。移植面を増やすのは知識抽出 (C) のみで、それも価値限定的。再編の主目的は移植性ではなく内部のクリーンさと位置づけるべき。

### 次のアクション（別チケット）

推奨 (B) の実装チケット：fan-in=1 の 3 utility を呼び出し元へ吸収、`archive.sh` の越境を drive 内に閉じ、`branching`/`check-deps` は共有のまま `metadata.internal: true` を明示、`CLAUDE.md` の Common Operations / Skill Script Path Rule を実態に合わせて改定。
