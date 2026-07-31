---
type: Feedback
title: Verified: two near-simultaneous merges now produce exactly two messages
kind: concern
source: discussion
created_at: 2026-08-01T04:52:23+09:00
author: a@qmu.jp
supersedes: 20260801044631-the-fix-is-unproven-until-two.md
---

# Verified: two near-simultaneous merges now produce exactly two messages

2026-08-01 に実測で確認しました。PR #140 と #143 を9秒差（19:46:13Z → 19:46:22Z）でマージ — 重複を生んだときの4秒差と同条件です。結果は `#dev-workaholic` にメッセージ2通、#140 と #143 が各1回。修正前の同条件では4通（各PRが2回）でした。

これで prompt スコープ指定が効いていることが確認できたので、この concern は解決とします。ただし証明されたのは「起動元のPRを1件だけ報告する」という指示にセッションが従うことであって、スクリプトの正しさではありません — 欠陥はモデルによるプロンプトの読み方に存在するので、このプロンプトを編集するたびに同じ2本マージを再実行する必要があります。
