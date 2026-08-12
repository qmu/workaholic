---
type: Feedback
title: /setup-routines must configure the routines itself, not only when a RemoteTrigger tool happens to exist
kind: instruction
source: slack
created_at: 2026-08-12T20:48:00+00:00
author: a@qmu.jp
supersedes: 
---

# /setup-routines must configure the routines itself, not only when a RemoteTrigger tool happens to exist

Source: https://github.com/qmu/workaholic/issues/408 (reported in Slack #dev-workaholic, filed as an issue)

## The report, in the reporter's words

`/setup-routines` を別リポジトリで実行したところ、以下のような応答が返ってきた:

> 普段はこれを開発者がブラウザの claude.ai 上で手作業で登録するのですが、今回のセッションにはたまたま API 経由でルーチンを直接作れるツール(RemoteTrigger)が生えていたので、手順書を印刷する代わりにその場で登録まで済ませました。

問題として指摘された点:

- `/setup-routines` については、「手順書を表示するだけの実装」から「コマンド自体がルーチンを設定・更新する、元の実装」に戻すよう既に指示していたはず。しかし今回の応答を見ると、その指示は反映されていない。
- 直接登録が行われたのは、そのセッションに `RemoteTrigger` という API ツールが偶然存在していたからであり、実装がそのように変更された結果ではない。
- 該当ツールが無いセッションでは、依然として「手順書を表示する」旧挙動(または類似のフォールバック)に留まっている可能性が高い。

期待する挙動: `/setup-routines` はセッション側のツール有無に依存せず、コマンド自体が常にルーチンの設定・更新を行う実装であること(以前指示した「元の実装」への回帰)。

## What this asks for

The command must read as *the thing that configures the routines*, not as a
renderer that occasionally gets to configure. The reporter's evidence is the
session's own wording: it announced the direct registration as a lucky accident
("たまたま … 生えていた"), which is exactly how the current contract is written —
detect a `RemoteTrigger`-family tool first, converge when present, render setup
sheets when absent. That framing is what the earlier instruction asked to be
reversed, and it survived the last change.
