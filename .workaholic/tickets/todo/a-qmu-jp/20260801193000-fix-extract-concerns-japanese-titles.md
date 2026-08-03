---
created_at: 2026-08-01T19:30:00+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort:
commit_hash:
category:
depends_on:
mission:
---

# extract-deferred-concerns の slug 化が日本語タイトルの懸念を黙って捨てる

## Overview

`plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh` の `slugify()` は `re.sub(r'[^a-z0-9 ]', ' ', s)` で ASCII 英数字以外をすべて落とすため、**日本語のみのタイトル**を持つストーリー §6 の懸念ブロックは `concern_id` が空（または全ブロックが同一の縮退 id）になり、フィードバックストリームへ**登録されずに黙って落ちる**。

実runで観測した症状（2026-08-01）:

- §6 に日本語タイトルの懸念が2件あるストーリーに対し、抽出結果が `{"created":0,"updated":0,"extracted":0,"story_only":0}` となり、レコードが1件も作られなかった。
- 過去の抽出では、日本語タイトルの一部が英単語1語（例: タイトル中の "concern" 相当部分）だけに縮退し、`<ts>-concern.md` のような無意味な id のレコードが生成されていた。縮退 id は以後の重複判定（`existing_ids`）とも衝突し、別の懸念が同一 id と見なされて捨てられる。

日本語で運用するリポジトリ（CLAUDE.md で日本語を規定しているプロジェクト）では §6 のタイトルは通常日本語であり、「懸念は全 severity ストリームに記録される」という本スキルの契約が事実上破られる。

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` - 落とす場合も黙って落とさない（機械可読な報告）。
- `workaholic:operation` / `policies/ci-cd.md` - ship フローの記録契約（§6 → ストリーム）を言語に依存させない。

## Key Files

- `plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh` - `slugify()` と、slug が空になった場合の分岐（現状の挙動を確認のうえ修正）。

## Related History

- ship スキルの「Concerns land in the feedback stream」契約（extract-deferred-concerns の冒頭コメント）。

## Quality Gate

### Acceptance Criteria

- 日本語のみのタイトルの §6 ブロックが、安定した非空の `concern_id` でストリームに登録される。
- 同一ストーリー内の複数の日本語タイトルが異なる id になる（縮退衝突しない）。
- 既存の ASCII タイトルの id 生成は変わらない（後方互換）。
- id を生成できないブロックが万一残る場合も、黙って捨てずに出力 JSON で件数と理由を報告する。

### Verification Method

- 日本語タイトル2件を含むストーリーでの抽出テスト（created=2、id が非空かつ相異なること）。
- 既存の英語タイトルのストーリーで id が従来と一致すること。

### Gate

上記2テストの通過と、silent drop の不在（報告フィールドの存在）で完了とする。

## Implementation Steps

1. `slugify()` を Unicode 対応にする。案: (a) 非 ASCII をローマ字化/翻字せず、タイトルのハッシュ短縮（例: sha1 先頭8桁）を `<ts>-c-<hash>` 形式で使う、(b) 日本語を含む場合はタイトル全体の正規化ハッシュに切り替える、(c) 既存 ASCII パスは現行ロジック維持。
2. 空 slug / 縮退 slug の分岐を「捨てる」から「フォールバック id を割り当てて登録」に変更し、出力 JSON に `fallback_ids` 等の報告を追加する。
3. 上記テストで検証する。

## Considerations

- id はストリームの永続キーであり、後から生成規則を変えると同一懸念の同一性が切れる。ASCII タイトルの既存規則は維持し、非 ASCII のみ新規則を追加する方が安全。
- 依頼元では手動でレコードを直接作成して回避済み（`concern_id` を ASCII で明示）。本修正後の移行作業は不要。
