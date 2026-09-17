---
type: Feedback
title: 開発中のmainとrelease branchでCI merge gateを分ける
kind: instruction
source: discussion
subject: person:operator
created_at: 2026-09-17T17:38:39+09:00
author: a@qmu.jp
supersedes: 
---

# 開発中のmainとrelease branchでCI merge gateを分ける

kind: instruction / source: discussion / subject: person:operator

# 開発中のmainとrelease branchでCI merge gateを分ける

高速に変更を積み重ねる開発段階で、全remote CIの完了をmainへのmerge前提にすると、各unitがCI待ちで長時間停止し、短い実装を連続して進めるloopの利点が失われる。現在のmainでは、対象ローカルtest・build・安全scanが通ればmergeを許可し、remote CIはmerge後の検知として扱えるmerge policyを選択可能にしてほしい。将来release branchを導入した場合は、そのbranchへの昇格・release mergeで全CI成功を必須にする。branch roleまたはrepository設定からこの二段階policyを機械的に判定し、workerが毎回人の判断を待たない契約とテストを追加してほしい。secret/leakや明示的authorization denialのgateはこの緩和対象に含めない。


Source: https://github.com/qmu/workaholic/issues/1186
