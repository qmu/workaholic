---
type: Feedback
title: Reconcile historical loop state without coordinator handwork
kind: instruction
source: discussion
subject: person:operator
created_at: 2026-09-17T17:35:53+09:00
author: a@qmu.jp
supersedes: 
---

# Reconcile historical loop state without coordinator handwork

kind: instruction / source: discussion / subject: person:operator

# work loopが履歴状態を自律収束させ、coordinatorの手作業調停を不要にする

`work` の一回の継続実行で、部分的なSlack観測、非main checkout、heartbeat切れ、既存worktreeの再利用、stacked branch由来の二重claim、重複moderation runner、unit固有のhandoffが連鎖し、coordinatorが多数のreceipt作成・再dispatch・claim補修・continuation更新を手作業で行わないと前進しなかった。実装自体は複数unitをmergeできた一方、moderation tickは20件前後の`needs_agent`を列挙するだけで終わり、同じloopがそれを実行しなかった。

長時間運転では、既存stateを一つのreconciliation phaseで収束させてから通常cadenceへ戻してほしい。具体的には、live worktreeを再作成せずadoptすること、stacked branchの継承trailerを独立claimとして誤認しないこと、重複runnerを一方だけに決定して残りを待たせること、unit固有のpending/handoffで親loopをholdしないこと、`needs_agent` actionを列挙だけで終えず同tickまたは明示的なfollow-up receiptへ必ず所有させることを、一連の統合テストで保証してほしい。coordinatorが同じ判断を何度も手で補う状態は、unattended work loopとして未完了である。


Source: https://github.com/qmu/workaholic/issues/1185
