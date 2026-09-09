---
type: Feedback
title: Refuse a post that cannot speak as the declared sender
kind: defect
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-09T10:43:45+09:00
author: a@qmu.jp
supersedes: 
---

# Refuse a post that cannot speak as the declared sender

The skill prefers the declared QFS route and treats the Slack connector as a later resort. The
preference is stated and never enforced, so on this repository the later resort became the *only*
path — and it speaks as the human operator. Read the channel `coop-planner` (`C0BKV34JK39`) and the
outcome is one count:

| identity | messages |
| --- | --- |
| `U08F7PR6KFF` — the operator, a person | **94** |
| `U0BUXKT4JCE` — a bot | 3 (plus its join) |
| `U0C05B4JFA8` — `yodex`, the **declared sender** | **0** (join only) |

Ninety-four of the ninety-eight messages in that channel are posted under a person's own account,
and most of them are the loop's own shapes — `📝 FB`, `🔴 Blocked`, `⚪ Paused`, `🔒 作業サイクル完了` —
carrying the marker `*Sent using* <@U0BTESF5EEQ>`. The declared sender the binding names has never
said one word.

## The bot in the same channel shows what was supposed to happen

`U0BUXKT4JCE` joined on 09-07 13:00 and posted three messages **as itself**: `🔎 Moderation`
summaries on 09-07 17:29 and 09-08 13:09, and a `🙋` question on 09-08 11:07 asking the operator to
rule on three Area A strategies. The operator answered it on 09-08 13:52 with a top-level message
saying *"このスレッドの続きです"* and a permalink back to that question. That is the collaboration the
shapes are designed for: a bot speaks in its own name, a person answers it, and the thread is the
record.

`yodex` joined 45 minutes before that answer. From that moment the loop stopped speaking as a bot
at all. Every post since — 09-08 17:59 and 09-09 10:32, both `📝 FB` — is the operator's own id.

## Why the fallback is the default rather than the exception

Four measurements on 2026-09-09, each one on its own enough to force the connector:

1. **`post_root` is not offered by the declared route.** `describe-native-qfs.sh /slack-yodex qmu
   C0BKV34JK39 yodex` answers `ok: true` with `map_verified: false` and the limitation
   `root_map_unverified_or_ambiguous`; `adapters/qfs-native.sh` then refuses `post_root` with
   `qfs_map_unverified` before reaching any preview. **No root can ever go out over the declared
   route**, so every first post of every day falls through by construction.
2. **`post_reply` is broken by a one-line typo.** The guard at `qfs-native.sh:63` tests
   `.total_affected` while QFS answers at `.preview.total_affected`. Run live against the real
   channel: the preview returns
   `{"preview":{"rows":[…],"total_affected":{"exact":1}},"committed":false}` and the guard
   evaluates `false`, because `null > 0` is `false`. Every reply returns `qfs_preview_refused`.
3. **The declaration is invisible where runners work.** On this repository the binding lives in
   `AGENTS.md`, which is **untracked**, so it does not exist in a claim worktree.
   `read-declared-binding.sh --root <worktree>` answers `{"ok":true,"declared":false,
   "reason":"no_declaration"}` — indistinguishable from a repository that declares nothing. An
   implement runner read exactly that, concluded there was no declared route, and posted through
   the connector.
4. **Called without `--root` the reader answers `no_root`**, which a caller reads the same way.

So a runner reaches the connector through a *correct* reading of the seams it is given. It is not
disobeying the preference; the preference has no teeth.

## What is asked for

**A post that cannot be made as the declared sender is refused, not downgraded.** The connector
substitutes the logged-in human's identity and nothing on the path compares that identity to the
declared one. When the declared sender cannot speak, the right outcome is `no_slack_transport`
and the line carried forward — which is what the runner itself concluded, unprompted, after the
fact: *"I should have reported `no_slack_transport` and carried the line instead of posting under
a different identity."* That judgement belongs in the seam, not in a runner's hindsight.

Three supporting changes, in the order they bite:

- **`read-declared-binding.sh` must distinguish "nothing is declared" from "a declaration exists
  that you cannot see."** It already opens the file; whether that file is tracked is one
  `git ls-files --error-unmatch` away. A worktree that answers `declared: false` because the
  declaring file was never committed has told its caller the opposite of the truth.
- **Fix the `:63` guard** — `(.preview.total_affected.exact // 0) > 0` — so replies stop needing a
  fallback at all.
- **Say why `map_verified` is false for this mount**, or state plainly that this route cannot open
  roots so a person can provision one that can. A route advertised as usable that refuses every
  root is worse than one that declares itself read-only.

## What it cost, so the size is stated rather than implied

The operator has raised this repeatedly and it has not changed. Meanwhile: the loop's own
coordinator reported "Slack へは何も届いていません" on every tick for a whole morning — true of the
loop, false of the system, because a runner beside it was posting under the operator's name the
whole time. Two `🙋` questions this morning cleared their gate and were never delivered. Four
landed-ask finish lines sit at `post_failed`. Eleven consecutive production deploy failures were
never announced. And a person's own account carries 94 messages they did not write.
