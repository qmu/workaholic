---
type: Feedback
title: Missions are too heavy to close: cap their size instead of loosening their gates
kind: instruction
source: discussion
created_at: 2026-08-01T01:21:20+09:00
author: a@qmu.jp
supersedes: 
---

# Missions are too heavy to close: cap their size instead of loosening their gates

ミッションを軽量にしたい。今のミッションは形式が勝ちすぎていて、いつまでも閉じられない。`## Scope` は廃止する（任意化ではなく雛形から消す — どのバリデータも見ておらず、書く側の負担にしかなっていない）。`## Acceptance` は3項目以内を規範とし、「終わったと言える最小の条件」だけを書く（網羅リストや将来の監査項目はミッションに書かない）。分量に上限を設ける（例：mission.md 全体で 60 行 / 2KB 以内）。propose が書く下書きにも同じ上限を課す。フィードバック記録も、本人の言葉＋測定は1段落までに抑える。直したいのはゲートの緩さではなく上限の不在で、approved の floor（オーナー / Experience / 1項目以上）はそのままでよい。
