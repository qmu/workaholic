---
type: Feedback
title: A survey run under a placeholder git identity returns an indistinguishable ok
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-08-21T15:12:27+09:00
author: a@qmu.jp
supersedes: 
---

# A survey run under a placeholder git identity returns an indistinguishable ok

# 仮のgit身元で走った調査が、空の待ち行列と区別できないokを返す

Source: https://github.com/qmu/workaholic/issues/547

Claude Code on the web の `[Implement]` ルーチンが、開発者本人に割り当てられたミッションとチケットを一日分まるごと素通りし、毎回 `ok` で終わっていた。原因は `session-start.sh` の step 0b が要求する対応表 `.claude/git-identities` が消費側リポジトリに置かれていなかったこと。step 0b は仕様どおり fail open するので、残したのはブートストラップのログ 1 行だけだった。

    git identity: no mapping file at <repo>/.claude/git-identities; keeping 'noreply@anthropic.com'

その 1 行の帰結が報告の要点である。所有権は `gather/scripts/owns.sh` が `git config user.email` と突き合わせるが、身元がコンテナ既定の `noreply@anthropic.com` のままなので開発者の実アドレス宛ての成果物は決して一致しない。よって `owns.sh` は `other` を返し、`plan-units.sh` は `owned_by_other` として除外する。`missions[]` と `backlog[]` は空、`backlog_error` も空、`current: true`、`shallow: false`、`owner_unresolved: false` ―― drive §7 の表はこれを **`ok`** と判定する。

報告者の指摘はこうである。`owned_by_other` は調査の**自信のある答え**であり、「誰のものか判別できない」は `owner_unresolved` として別に持たれていて `ok` を禁じる。今回の状態はそのどちらでもない第三の状態 ―― 「判別はできたが、比較した自分の身元が仮の値だった」―― であり、それが自信のある答えの側に落ちるため、外から見た出力は「私に割り当てられた仕事はない」と区別がつかない。`gather/scripts/owners.sh` のヘッダが、まさにこの失敗の形を、この所有権モデルが終わらせるために書かれたものとして記録している。

依頼は二つ。第一に、`/workaholify` が対応表も設置・点検の対象にすること ―― `/workaholify` は `session-start.sh` を設置しその drift を報告するが、そのフックが動作するために要求するデータファイルは設置も点検もしないので、フックだけが入り対応表がないリポジトリは step 0b が永久に no-op のまま「設定済み」に見える。第二に、`CLAUDE_CODE_REMOTE=true` の下で `git config user.email` が空または `@anthropic.com` の既定値であるとき、それを `plan-units.sh` の trustworthiness fields に 1 つ足し、`owner_unresolved` と同様に **`ok` を禁じる**こと ―― 仮の身元の下で走ったランナーは「自分に割り当てられたものが何もない」ことを何も確立していない。`check-deps` 側で報告する案もありうるが、この事実を使うのは調査なので調査が持つほうが一貫する、と報告者は述べ、そこは判断に委ねている。

補足として、この条件は自己修復しない。毎時のティックは同じイメージから立ち上がる新しいコンテナで、対応表は消費側リポジトリのコミットにしか存在しえないため、対応表が入るまで毎時間再現し続ける。そして全ティックが `ok` を返すので、ルーチン一覧からは健全に見える。
