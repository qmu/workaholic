---
name: standup
description: Use when the user runs `/standup` or asks for the daily per-strategy summary — what moved yesterday and what is waiting, per strategy. A pure read: it writes nothing and posts only when the morning is genuinely news.
allowed-tools: Bash
user-invocable: false
metadata:
  internal: true
---

# Standup

The repository's morning digest, **per strategy**: what moved since yesterday, what is waiting, and how close each dated direction is to its date. One command, no argument, no `AskUserQuestion` — and **no write of any kind**: no file, no commit, no branch, no pull request, no merge, no deployment. That is what lets it run unattended on a daily schedule without becoming a new class of write, the same argument `workaholic:ship` §7 makes for the repository tick and `/release-status` inherits.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/standup/scripts/digest.sh [window]   # default window: "1 day ago"
```

Attribution is **not** this skill's question. `workaholic:strategy`, *Which work belongs to a strategy*, owns the rule and its one reader (`attributed-work.sh`); this skill owns the shape of a morning — the strategy set, the schedule proximity, the caps, the silence rule, and the one post.

## What the digest says, and in what order

1. **The strategies, in the order `strategy/scripts/list.sh` returns them**, `status: active` only — a closed direction has no morning. Per strategy: its title, `days_to_target` (negative when the date has passed), what moved inside the window, and what is queued and waiting.
2. **A quiet strategy says so explicitly** — one line, its `empty_reason` carried in the reader's own vocabulary (`no_feedback_refs` = it cites nothing to attribute through, `no_citing_artifacts` = nothing cites it back, `no_activity_in_window` = attributable work exists and none of it moved). "No activity" is a real answer; a strategy silently missing from the digest is not.
3. **The honesty line.** `unattributed` counts work that moved or waits under no strategy at all. Attribution through the feedback stream is transitive and lossy by design, so the digest says what it could not attribute rather than implying it is exhaustive. It is a **count**, never a list: enumerating it would make this a repository changelog, which is `/catch`'s job.
4. **An unreadable input is named, never rendered as quiet** — `errors[]` carries `strategy_list_unreadable` or `attribution_unreadable:<slug>`. The distinction `list-inbound-issues.sh` draws: "nothing to say" and "could not read" must never look alike.

**Bounded by construction, and never silently.** `STANDUP_MAX_STRATEGIES` (8) and `STANDUP_MAX_ITEMS` (3) cap what renders; every cut is counted in `strategies_omitted` / `moved_omitted` / `waiting_omitted` and stated. The digest's value is in **omission** — a standup that lists everything is a changelog — so prefer "what moved and what is waiting" over completeness.

## The silence rule — when a morning is not news

Two silences, both `noop: true`, and the reason is always named:

| `noop_reason` | When | Why it is silence |
| ------------- | ---- | ----------------- |
| `no_strategies` | the tree holds no `status: active` strategy | A digest about nothing is a daily post that teaches its readers to skip the surface. **This repository is in that state today**, so it is the first case that had to be right. |
| `no_activity` | nothing moved under any strategy **and** no strategy's `target_date` is inside `STANDUP_TARGET_HORIZON` (14 days, overdue included) | An idle morning. |
| `strategy_list_unreadable` | the strategies area could not be read | Nothing is claimed about a tree that was not read; the reason rides `errors[]`. |

**Waiting work alone is deliberately not news.** A queued ticket that sat there yesterday will sit there tomorrow, and a digest repeating it every morning is exactly the recurring post `workaholic:notify`'s bright line refuses — so it rides a digest that had another reason to exist, and never creates one. **An approaching date is news daily, and it terminates**: "a dated, owned direction approaching its date with no activity" is the single most useful line this command can produce, and the horizon bounds how long it can repeat. `unattributed` work never breaks the silence either.

## The one post

Under the `[Standup]` routine only, and only when the digest is not a no-op: one `📣 Standup` line as a **top-level keyed root** on the transport `workaholic:notify` selects, keyed on `` `standup:<YYYY-MM-DD>` ``. Exact shape: `workaholic:notify`, *The daily standup digest*, mirrored verbatim in the routine template's prompt.

- **Keyed on the date, not on a content hash** — unlike `deploy:<digest>`. The two dedups answer different questions: a release status must not repeat an unchanged answer, and a *daily* digest is expected to say today's morning even when it resembles yesterday's. What must never happen is two posts for one morning, which is the failure the repository scope cannot prevent by itself (N copies of a repository routine), so the key is the morning itself.
- **No mention token of any kind.** The line names the repository's state, not a person's work — the same reason `📦 Release status` carries none. A strategy's `assignees` is *in* the digest as a fact; nobody is paged by it.
- **A run invoked by a human posts nothing** and reports in the session, exactly as `/drive` does. The post exists so an absent reader gets the morning.

## What this skill deliberately does not do

- **No GitHub read at all** — no pull-request count, no issue sweep, hence no `gh-rest.sh` call. Everything a standup needs is in the repository, and a daily unattended read that cannot fail on a token or a 403 is worth more than the extra column. `rules/shell.md`'s REST-only rule is satisfied by having no such read, not by skipping one.
- **No fetch and no branch scan.** The digest describes what reached the base. Work on an unmerged claim branch is in flight, not landed, and `/catch` is the by-developer view that reads branches.
- **No per-strategy progress number.** A strategy is *not a status board* (`workaholic:strategy`) — the schedule is the only temporal claim it makes, and `days_to_target` is that claim, not a computed percentage.
