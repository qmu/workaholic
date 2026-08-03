---
created_at: 2026-08-04T02:30:00+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort:
commit_hash:
category:
depends_on:
mission:
---

# 「何もしない」はずのスクリプトが git index をコミットに巻き込む（heartbeat.sh / list-open-concerns.sh）

## Overview

読み取り専用または no-op と文書化されている2つのスクリプトが、**ステージ済みの index を次のコミットに混入させる**。どちらもゲートに掛からず、コミットメッセージが自身の diff より少ないことを述べる状態を作る。

### 症状1: `heartbeat.sh` が index をコミットする

`heartbeat.sh` は自身を「ファイルを変更しないので PR の diff に現れない空コミット」と説明しているが、実際にはその時点でステージされているものを何でもコミットする。

実 run で観測した挙動:

- ユニットのドライブ中、`git rm` で3ファイルの削除がステージされている状態で heartbeat を打った。
- 結果、`Refresh heartbeat` という subject のコミットにその3件の削除が入った。内容はブランチ上正しいが、subject はそれを一切説明しない。
- `git log` および commit subject から生成されるストーリーが、実作業を「協調ノイズ」に誤って帰属させる。

### 症状2: `list-open-concerns.sh` が 151 件の rename をステージする

`list-open-concerns.sh` は feedback stream の living migration（`migrate-concerns.sh`）を走らせ、その rename を `git add` する。警告は出ない。

実 run で観測した挙動:

- 無関係な2ファイルをパス指定で明示的にステージして `git commit` したところ、コミットは **154 ファイル**を含んだ（151 件はレガシー `concerns/` ツリーの `feedbacks/` への rename）。
- コミットメッセージは2ファイル分の説明しか書いていなかったため、事後に amend して差分全体を説明し直す必要があった。

## 根本原因（共通）

いずれも「読み取り専用」「no-op」と契約している操作が **git の index という共有状態を変更する**。呼び出し側は index が自分のものだと仮定するので、次のコミットが静かに膨らむ。どちらもゲートで検出されない — コミットは成功し、内容も正しく、ただ説明だけが不足する。

## Policies

- `workaholic:implementation` / `policies/observability.md` — 黙って状態を変えない。副作用は報告する。
- `workaholic:development` / `policies/change-history.md` — コミットメッセージがその diff を説明することは変更履歴の前提。

## Key Files

- `plugins/workaholic/skills/drive/scripts/heartbeat.sh` — 空コミットの作り方。
- `plugins/workaholic/skills/feedback/scripts/list-open-concerns.sh` — migration 呼び出しと、その `git add`。
- `plugins/workaholic/skills/feedback/scripts/migrate-concerns.sh` — rename をステージしている当事者。

## Quality Gate

### Acceptance Criteria

- `heartbeat.sh` は index が汚れていても**空のコミット**を作る（例: 現在の HEAD ツリーに対して `--allow-empty` で commit-tree する）か、汚れている場合は**拍動を拒否して理由を報告する**。どちらでもよいが、ステージ済みの他人の変更を無言で取り込まないこと。
- `list-open-concerns.sh`（および `migrate-concerns.sh`）は、migration の rename を **自身の subject でコミットする** か、**ステージせず working tree に残す**。呼び出し側の次のコミットに混ざらないこと。
- いずれも、副作用が発生した場合は JSON 出力にその事実（例: `migrated: 151`）を含める。
- 既存の呼び出し側（`/drive` の拍動、`/report` の concern 判定）が壊れないこと。
