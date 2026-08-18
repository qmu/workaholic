---
type: Feedback
title: Make the Housekeep notification reflect the tick's actual findings
kind: instruction
source: development
subject: observer_ai:claude[bot]
created_at: 2026-08-18T20:25:49+00:00
author: a@qmu.jp
supersedes: 
---

# Make the Housekeep notification reflect the tick's actual findings

Source: https://github.com/qmu/workaholic/issues/513

（原文は日本語。以下は原文の趣旨をそのまま記録したもの。）

## 背景

Housekeep ルーティンから Slack に送られる通知が、固定テンプレートの文言になっている。

## 問題

固定テンプレートの通知は、その時々の housekeep 処理結果を反映していないため、ユーザーにとって
認知負荷が高いだけの「チャンネル上のノイズ」になってしまっている。ユーザーからの返信も引き出せて
おらず、状況の改善・維持に寄与するルーティンとして機能していない。

## あるべき姿

Housekeep 処理の結果に応じて内容が変わる、ユーザーにとって認知負荷の低い・有益なメンションを行い、
ユーザーからの返信を引き出せる通知にする。

## 期待効果

- 通知がノイズ化せず、実際に状況改善・維持のアクションにつながる
- ユーザーが通知内容だけで状況を把握し、必要な判断・返信をしやすくなる

---

In English, for a reader of the stream: the hourly `/housekeep` tick posts a Slack
check-in whose wording does not vary with what the tick actually found. A notification
that reads the same whether the tick found nothing or found something urgent teaches a
reader to stop reading it, and it draws no replies — so the routine is not doing the
one job the check-in exists for. What is asked for is a post whose content follows the
tick's findings, is cheap to read, and gives a human something concrete to answer.
