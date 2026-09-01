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
5. **A degraded strategy renders by name, distinctly from a quiet one** (2026-08-29, mission `keep-the-closing-link-readable-as-the-corpus-grows`). When the attribution walk itself could not complete, that strategy's record carries `readable: false` with the reader's own `reason` (`corpus_unreadable` / `patterns_unreadable`) and **null** counts; `degraded_count` sits beside the other counts and `attribution_unreadable:<slug>` rides `errors[]`. Render it as *the reader could not see into this direction*, **never** as an "no activity" line and never as one of the three `empty_reason` answers — those name why a **completed** walk found nothing. Until this existed such a strategy rendered exactly like a quiet one: same empty `moved`, same empty `waiting`, and it fell into the `no_activity` silence.
6. **The honesty line goes null when any walk was degraded.** `unattributed` is derived by subtracting what the strategies attributed, so a direction whose walk failed pushes its own work into that figure — an over-report for a reason that has nothing to do with attribution. `{"moved": null, "waiting": null}` is the answer, and the render omits the line rather than printing a number nobody should trust.

7. **Every strategy names its declared stage** (2026-08-29, mission
   `make-a-direction-s-lifecycle-a-declared-stage`). `stage` rides on each strategy record off
   `list.sh` — no new read — and the render names it as **one word beside the bold title**,
   in the operator's own characters. A stage the reader could not resolve (an empty `stage`)
   renders as **unreadable by its reason**, never as 進行中: a default that hides a failed read
   is exactly what rule 5 exists to prevent, one field over. **The stage is never a reason to
   post**: the silence rules are untouched, so `no_strategies`, `no_activity` and
   `strategy_list_unreadable` still post nothing at all, and a daily post is a standing claim
   on attention that one more word must not turn from silent into spoken.

**Bounded by construction, and never silently.** `STANDUP_MAX_STRATEGIES` (8) and `STANDUP_MAX_ITEMS` (3) cap what renders; every cut is counted in `strategies_omitted` / `moved_omitted` / `waiting_omitted` and stated. The digest's value is in **omission** — a standup that lists everything is a changelog — so prefer "what moved and what is waiting" over completeness.

## The silence rule — when a morning is not news

Two silences, both `noop: true`, and the reason is always named:

| `noop_reason` | When | Why it is silence |
| ------------- | ---- | ----------------- |
| `no_strategies` | the tree holds no `status: active` strategy | A digest about nothing is a daily post that teaches its readers to skip the surface. **This repository is in that state today**, so it is the first case that had to be right. |
| `no_activity` | nothing moved under any strategy **and** no strategy's `target_date` is inside `STANDUP_TARGET_HORIZON` (14 days, overdue included) | An idle morning. |
| `strategy_list_unreadable` | the strategies area could not be read | Nothing is claimed about a tree that was not read; the reason rides `errors[]`. |
| `all_attribution_unreadable` | every strategy's attribution walk failed (2026-08-29) | The morning could not be read at all. It sits beside `strategy_list_unreadable` rather than folding into `no_activity`, which would assert a quiet morning nobody looked at. A **partial** degradation is **not** a no-op: the strategies that were read still have a morning, and the degraded ones are named in the render. |

**`no_strategies` stays a no-op here even though `/moderate` now asks about it** (2026-08-26, mission `say-when-the-loop-has-run-out-of-direction`). The tick's `direction-health` step turns *this repository has no live direction* into a **question addressed to a person**, and that is precisely why this surface does not also carry it: a *daily digest about nothing* teaches its readers to skip the surface, and the same fact said twice in two places is the noise two status roots were already retired for. The asymmetry is a decision, not an oversight — a question demands an answer and terminates when it gets one; a digest line about an empty tree would repeat every morning forever with nobody asked to act on it.

**Waiting work alone is deliberately not news.** A queued ticket that sat there yesterday will sit there tomorrow, and a digest repeating it every morning is exactly the recurring post `workaholic:notify`'s bright line refuses — so it rides a digest that had another reason to exist, and never creates one. **An approaching date is news daily, and it terminates**: "a dated, owned direction approaching its date with no activity" is the single most useful line this command can produce, and the horizon bounds how long it can repeat. `unattributed` work never breaks the silence either.

## The one post

**The `[Standup]` routine is retired** (2026-08-24 — the digest is rendered by `/moderate`'s `strategy-digest` step at the top of the JST-morning `🔎 Moderation` root; this command survives for a human on demand, and when run by hand it may still post the line below). Only when the digest is not a no-op: one `📣 Standup` line as a **top-level keyed root** on the transport `workaholic:notify` selects, keyed on `` a `📣 Standup` search bounded to today ``. Exact shape: `workaholic:notify`, *The daily standup digest*. Nothing mirrors it any more — the routine that used to is retired, and `/moderate` renders the digest inside its own root rather than as a `📣 Standup` post.

- **Keyed on the date, not on a content hash** — unlike `deploy:<digest>`. The two dedups answer different questions: a release status must not repeat an unchanged answer, and a *daily* digest is expected to say today's morning even when it resembles yesterday's. What must never happen is two posts for one morning, which is the failure the repository scope cannot prevent by itself (N copies of a repository routine), so the key is the morning itself.
- **No mention token of any kind.** The line names the repository's state, not a person's work — the same reason `📦 Release Preparation` carries none. A strategy's `assignees` is *in* the digest as a fact; nobody is paged by it.
- **A run invoked by a human posts nothing** and reports in the session, exactly as `/drive` does. The post exists so an absent reader gets the morning.

## What this skill deliberately does not do

- **No GitHub read at all** — no pull-request count, no issue sweep, hence no `gh-rest.sh` call. Everything a standup needs is in the repository, and a daily unattended read that cannot fail on a token or a 403 is worth more than the extra column. `rules/shell.md`'s REST-only rule is satisfied by having no such read, not by skipping one.
- **No fetch and no branch scan.** The digest describes what reached the base. Work on an unmerged claim branch is in flight, not landed, and `/catch` is the by-developer view that reads branches.
- **No per-strategy progress number.** A strategy is *not a status board* (`workaholic:strategy`) — the schedule is the only temporal claim it makes, and `days_to_target` is that claim, not a computed percentage.
