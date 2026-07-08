---
name: catch
description: Use when the user runs `/catch`, asks to "catch me up", "what has everyone been working on", "summarize the last two weeks", or "show a by-developer development report". Scans the recent commit/ticket/story trail, fans out one collector per active developer to summarize their work, then synthesizes the overall development direction, the active missions (progress plus merged and unmerged in-flight work), and stands ready for follow-up questions.
allowed-tools: Bash
---

# Catch

Generate a **by-developer catch-up report** over a recent time window (default: the last two weeks) so a developer can absorb the overall direction of the repository and how each individual is taking their part, then ask follow-up questions to go deeper. `/catch` reads tickets, branch stories, docs, and commit messages: it writes **no files and makes no commits**. The one write it performs is a best-effort `git fetch` at the start of the scan, which updates only remote-tracking refs (`refs/remotes/*`) so the report reflects what teammates have pushed — never the working tree, the index, or any project file.

## Agent Compatibility

This skill works on any Agent-Skills-compatible agent. Unlike `/trip` (which depends on Claude Code Agent Teams), `/catch` is a portable skill — the two Claude-Code mechanisms it uses are **enhancements, not requirements**:

- **Parallel fan-out** — Phase 1 spawns one `general-purpose` collector subagent per active developer so the per-developer summaries run concurrently and cheaply. On agents without subagents, run the **Collect Developer** section **sequentially** in the same session, once per developer — the inputs and outputs are identical.
- **Model routing** —  is a Claude-Code cost/speed hint for the collectors. On other agents it is ignored; use whatever model is available.

There is **no the agent's selection prompt** in this workflow. `/catch` runs to completion and prints a report; the follow-up Q&A is ordinary conversation, so the skill is fully portable.

## Run Workflow

The `/catch` command (main agent) runs this workflow directly: it executes the bash/Read steps inline, spawns the per-developer collectors as parallel workers, and synthesizes the report itself. Fan-out stays one level deep — collectors are non-interactive leaves that read files and return JSON; they never spawn further subagents and never prompt the user.

### Policy Lens (read first)

Before judging development direction, load the project's engineering policies as your lens: `planning`, `design`, `implementation`, and `operation`. On Claude Code these arrive automatically (this skill preloads them and the `/catch` command's `policy-lens.sh` hook injects the index); on other agents, open each index skill yourself. When the report characterizes a developer's direction (e.g. "consolidating infrastructure", "hardening operation"), frame it against the relevant pillar's intent rather than inventing categories. The report **describes** activity — it does not grade it — so keep characterizations factual and verifiable (see `implementation` / `objective-documentation`).

### Phase 0: Gather the Window and Roster

1. Determine the **window** from `$ARGUMENT`: if the invocation names a span (e.g. `/catch 30 days`, `/catch "1 month"`), pass it through; otherwise default to `2 weeks ago`. Any `git log --since` expression is valid.
2. Run the scan script:

   ```bash
   bash catch/scripts/scan-window.sh "<window>"
   ```

   The script first runs a best-effort `git fetch --all --prune` so remote-tracking branches reflect what teammates have pushed, then scans `--branches --remotes` (local heads **and** remote-tracking refs) — so a branch that lives only on the remote appears too. It returns `{ window, fetch_ok, buckets, developers[], tickets[], stories[], deployments[], missions[] }`:
   - `fetch_ok` — whether that startup fetch succeeded. `false` means the remote could not be refreshed (offline, no remote, auth); the scan still runs against whatever refs are local, and the report notes the view may be stale (see step 5).
   - `buckets` — the epoch boundaries the scanner used to time-bucket commits: `recent_start` (start of yesterday — the yesterday+today window), `week_start` (Monday 00:00 of the current week), `last_week_start` (Monday 00:00 of the previous week).
   - `developers[]` — each active author in the window: `name`, `email`, `commit_count`, `commits[]`, and `branches[]`. `email` is the **join key** for the by-developer axis.
     - each commit carries `hash`, `subject`, `timestamp` (ISO), `epoch` (committer epoch), `branch` (the branch it was reached from), and `bucket` — one of `recent` (yesterday+today), `this_week` (this calendar week but before yesterday), `last_week` (the previous calendar week), or `older`.
     - `branches[]` — the developer's branches active in the window, each with `name` and `commit_count`, most active first. (The scan uses `--branches --remotes`, so unmerged local topic branches **and** remote-only branches are included; the `refs/remotes/<remote>/` prefix is stripped, so a branch present both locally and on the remote collapses to one entry.)
   - `tickets[]` — every ticket under `todo`/`archive`/`icebox` with its frontmatter `author`, `title`, `scope`, `mission` (the `mission:<slug>` relation, or `""`), and `commit_hash` (set on archived tickets, `""` on unarchived ones). Group these by `author` to match each developer's commits; group by `mission` to attribute a developer's missioned work, and use `commit_hash` to tie an archived missioned ticket back to a commit in the window.
   - `stories[]` — branch-story file paths under `.workaholic/stories/`, the narrative record of completed branches.
   - `deployments[]` — **this week's** deployments/releases, one per branch story carrying a `## Deployment Evidence` block (written by `/ship`): `branch`, `author` (git author of the ship commit — the join key, since stories/release-notes carry no author), `timestamp` (the evidence `When:`), `release_title` (the matching `release-notes/<branch>.md` H1, or the story H1), `status` (`pass`/`fail`/`bypassed`), and `confirmation` (the evidence `Observed:` line — empty when none was recorded). Filtered to the current calendar week.
   - `missions[]` — every mission (from the mission skill's own `list.sh`, so progress stays derived, never stored): `slug`, `title`, `status` (`active`/`achieved`/`abandoned`), `checked`, `total` (merged acceptance progress, `checked ÷ total`), plus two window-scoped views. `window_events[]` — the mission's `## Changelog` lines dated within the window (`{date, event, artifact}` — **merged** activity: `ticket archived` / `story reported` / `concern deferred|resolved`). `in_flight[]` — **unmerged** tickets carrying `mission:<slug>` that are not yet archived (`{path, title, author, scope}`): progress toward the mission from work still on a branch, which the merge-time changelog and `checked/total` cannot yet reflect. The scan reads missions **read-only** — it mutates no `mission.md` (no changelog append, no acceptance tick).
3. Run `bash gather/scripts/git-context.sh` to get `repo_url` (used to render commit links) and `branch`.
4. **Empty window**: if `developers[]` is empty, print "No commits in the last `<window>`." and suggest a wider window (e.g. `/catch 1 month`). Stop — there is nothing to summarize.
5. **Stale-view note**: if `fetch_ok` is `false`, the remote could not be refreshed, so pushed work by others may be missing. Add a short note to the report (a line under the report title) stating the remote was not reachable and the view may be stale — do not present a local-only scan as an up-to-date remote view (`implementation` / `objective-documentation`). When `fetch_ok` is `true`, add nothing.

### Phase 1: Collect Per Developer (parallel fan-out)

Spawn **one parallel workers per developer** in `developers[]`, in a **single message**. Each prompt instructs the collector to preload `catch`, run the **Collect Developer** section, and return that section's JSON. Pass each collector:

- the developer's `name`, `email`, `commits[]`, and `branches[]` (from `developers[]`);
- the `buckets` boundaries (so the collector knows what each commit's `bucket` means);
- the subset of `tickets[]` whose `author` equals this developer's `email` (each ticket now carries `mission` and `commit_hash`, so the collector can attribute the developer's missioned work);
- the subset of `deployments[]` whose `author` equals this developer's `email`;
- the `missions[]` array (so the collector can name the missions its developer advanced — matching a merged ticket's `commit_hash` to the developer's `commits[]`, and an in-flight `todo` ticket by its `mission` slug);
- the `stories[]` list and `repo_url` (so it can read stories and link commits).

Bots are developers too only if relevant — by default **skip authors whose email contains `[bot]`** (e.g. `github-actions[bot]`) unless the user asked to include automation. Note any skipped bot authors in the final report's footnote.

Wait for all collectors to finish. Track which succeeded and which failed; a failed collector becomes a "could not summarize" line in the report, never a blocker.

### Phase 2: Synthesize the Report

Assemble the collectors' JSON into the **Report Structure** below. Three parts:

1. **Overall Direction** — your own synthesis across all developers: the dominant themes of the window, where effort concentrated, and how the individual threads fit together. This is the part the developer reads first to orient. Where a mission dominates the window's effort, fold a one-line read of it into this synthesis.
2. **Missions** — a cross-cutting section, synthesized **by you (the main agent)** directly from the scanner's `missions[]` (not from the collectors — this is the one-level-fan-out rule: cross-developer synthesis stays in the main agent). One entry per **active** mission: its derived progress (`checked/total`), the merged activity under it this window (`window_events`), and the unmerged **in-flight** work (`in_flight`) — rendered so merged progress and in-flight work are never conflated. This is the "how far has each mission come, and what's heading toward it" view.
3. **By Developer** — one section per developer, populated verbatim from that collector's returned fields, including the developer's `missions` attribution line.

Print the full report to the developer.

### Phase 3: Stand Ready for Questions

After printing, the developer will ask follow-up questions to understand a thread more deeply or to discuss direction. Answer from the gathered context; read the specific tickets, stories, commits, or source files a question points at (you have their paths and hashes). No special mechanism — this is normal conversation.

## Collect Developer

Run by a Phase 1 collector (a parallel workers that preloads this skill), once per developer. **Inputs** (from the command): `name`, `email`, `commits[]`, this developer's `tickets[]` (each with `mission`/`commit_hash`), the `missions[]` array, the `stories[]` paths, and `repo_url`.

**Task** — characterize what this developer worked on in the window, factually:

1. Read the developer's `commits[]` bodies (they carry the structured `Why:` / `Changes:` / `Concerns:` / `Insights:` keys from the commit format) and subjects.
2. Read the developer's `tickets[]` (their `## Overview` and `## Final Report`) for intent and outcome behind the commits.
3. Skim any `stories[]` that clearly cover this developer's branches (match by title/theme) for the narrative arc — do not read all 50; sample the ones that match.
4. Summarize **focus areas** (what parts of the system they touched), **themes** (the through-line of the work), **notable changes** (the few highest-impact items, each with a commit hash), and **open threads** (deferred concerns, unfinished tickets in `todo`, or `Concerns:` keys from commit bodies).
5. **Time-windowed focus** — summarize the work in three buckets using each commit's `bucket` field:
   - `recent_focus` — from commits with `bucket: "recent"` (yesterday + today). What they're on right now.
   - `week_focus` — from commits with `bucket: "recent"` **or** `"this_week"` (the full current calendar week — "this week" includes the recent days).
   - `last_week_focus` — from commits with `bucket: "last_week"` (the previous calendar week).
   Each is one line; if a bucket has no commits, return an empty string (do not pad).
6. **Struggles** — what they're wrestling with, drawn **only** from concrete signals: `Concerns:` keys in their commit bodies, their open `todo`/`icebox` tickets, and matching story `## 6. Concerns` blocks. Each item should be traceable to its source; return `[]` if there is no real signal (do not invent difficulty).
7. **Per-branch focus** — for each entry in the developer's `branches[]`, write a one-line `focus` derived from the subjects of that branch's commits. Carry through `name` and `commit_count` from the input.
8. **Generation style** — an explicit **guess** at how the work was produced, inferred from the commit `timestamp`/`epoch` shape: commits spread across daytime hours over several days ⇒ "daytime ticket-driving"; a dense cluster of commits in one overnight run on a single branch ⇒ "overnight long-running drive"; a mix ⇒ describe both. Phrase it as an inference ("looks like…"), never as asserted fact.
9. **Deployments / releases this week** — from the developer's `deployments[]` (already filtered to this week and to this developer by `author`), build one entry per deployment: `timestamp`, `release_title`, `status`, and `confirmation`. For any entry whose `confirmation` is empty (a ship that recorded no production confirmation), and when the developer has shipped this week but `deployments[]` is empty for them, set `deployments_fallback` to the guidance that the confirmation could not be referenced and `/ship` can capture it going forward (it deploys and confirms in production before merge). Render `status: bypassed`/`fail` distinctly — never as a confirmed deployment. Do **not** fabricate a confirmation that was not recorded (`operation` / `ci-cd`).
10. **Missions advanced** — the missions this developer moved this window, drawn from the join between their `tickets[]` and the `missions[]` list. For each mission slug that appears on any of this developer's tickets, build one entry: `slug`, `title` (from `missions[]`), `merged` (their archived tickets carrying that slug **whose `commit_hash` is among this developer's `commits[]`** — each `{title, hash}`), and `in_flight` (their unarchived `todo`/`icebox` tickets carrying that slug — each `{title, scope}`). Return `[]` when none of the developer's tickets carry a `mission`. Attribution is at ticket granularity: never assert that an individual raw commit belongs to a mission unless it is the `commit_hash` of a missioned archived ticket (`implementation` / `objective-documentation`).

Keep it factual and verifiable — name files, hashes, and tickets; avoid evaluative adjectives ("elegant", "powerful"). Do not invent activity not present in the inputs. The generation-style guess is the one inference allowed, and it must be labelled as a guess (`implementation` / `objective-documentation`).

### Collector Output (JSON)

```json
{
  "email": "a@qmu.jp",
  "name": "TAMURA Yoshiya",
  "commit_count": 145,
  "headline": "One-sentence summary of this developer's window.",
  "focus_areas": ["cross-agent build pipeline", "ship/deploy gating"],
  "themes": "1-3 sentence narrative of the through-line connecting the work.",
  "recent_focus": "Yesterday/today: hardening the /catch scanner and its tests.",
  "week_focus": "This week: branch-guard fixes, check-deps staleness, /catch enrichment.",
  "last_week_focus": "Last week: deployment-confirmation gating in /ship.",
  "struggles": ["outputs/ freshness drift if a build step is skipped (Concerns: in 5059220)"],
  "branches": [
    { "name": "work-20260630-050446", "commit_count": 6, "focus": "guard + check-deps + catch tickets" }
  ],
  "generation_style": "Looks like daytime ticket-driving — commits spread across working hours over several days, one branch.",
  "deployments": [
    { "timestamp": "2026-07-01T10:00:00+09:00", "release_title": "Ship gate confirms before merge", "status": "pass", "confirmation": "homepage shows v1.0.69" }
  ],
  "deployments_fallback": "",
  "notable_changes": [
    { "title": "Ship gate now confirms in production before merge", "hash": "abc1234" }
  ],
  "open_threads": ["deferred concern: outputs/ freshness drift if build skipped"],
  "missions": [
    {
      "slug": "rt-notify",
      "title": "Real-time Notifications",
      "merged": [ { "title": "Persist notification prefs", "hash": "abc1234" } ],
      "in_flight": [ { "title": "Wire the websocket fan-out", "scope": "todo" } ]
    }
  ]
}
```

`deployments_fallback` is a non-empty string only when this developer shipped this week but no referenceable confirmation exists (empty otherwise) — it carries the "`/ship` can capture it going forward" guidance. `missions` is `[]` when none of the developer's tickets carry a mission; `merged` and `in_flight` stay disjoint (an archived ticket is never also in-flight).

If a developer's window is thin (a few commits, no tickets), return a short `headline`, empty strings/arrays for the windowed fields, and the real `branches`/`generation_style` rather than padding — the report shows the real shape of the work.

## Report Structure

The printed report (Markdown):

```markdown
# Catch-up — last <window> (<branch>)

## Overall Direction

<2-4 sentence synthesis across all developers: dominant themes, where effort
concentrated, how the individual threads fit together.>

**Active this window:** <N> developer(s), <total> commits.

## Missions

<One block per **active** mission from the scanner's `missions[]`, synthesized by
the main agent. Omit the whole section when there are no active missions. Order
missions by this-window activity (most active first), then by slug.>

### <title> — <checked>/<total> (<status>)

<Optional one-line framing of where the mission stands.>

- **Progress this window (merged):**
  - <date> — <event> — <artifact> (<author> [<hash>](<repo_url>/commit/<hash>) when a `commit_hash` join exists)
  - _or "— none this window"_
- **In flight (unmerged):**
  - <in_flight title> — <author> — <scope> — <branch / latest commit subject where available> _(not yet counted in <checked>/<total>)_
  - _or "— none"_

### <Next active mission> ...

## By Developer

### <Name> (<email>) — <commit_count> commits

**<headline>**

- **Yesterday + today:** <recent_focus, or "—">
- **This week:** <week_focus, or "—">
- **Last week:** <last_week_focus, or "—">
- **Focus areas:** <focus_areas, comma-separated>
- **Themes:** <themes>
- **Struggling with:** <struggles as sub-bullets, or "None surfaced">
- **Branches:**
  - <name> — <commit_count> commits — <focus>
- **Generation style:** <generation_style>
- **Deployments / releases this week:**
  - <timestamp> — <release_title> — <status> — "<confirmation>"
  - _<deployments_fallback, when set>_
- **Notable changes:**
  - <title> ([<hash>](<repo_url>/commit/<hash>))
- **Open threads:** <open_threads, or "None">
- **Missions:** <per mission in `missions`: "<title> — <N> merged (<hashes>), <M> in flight (<titles>)">, or "—">

### <Next developer> ...
```

**Guidelines:**
- Commit hashes are clickable links: `([abc1234](<repo_url>/commit/abc1234))`, never bare text. Branch names link too where useful: `([work-…](<repo_url>/tree/work-…))`.
- Order developers by `commit_count` descending (most active first).
- The three time windows (yesterday+today / this week / last week) come straight from the collector's bucketed focus; render `—` for an empty window rather than omitting the line, so the shape of recent vs. older activity is visible at a glance.
- **Generation style** is an inference — keep the "looks like…" framing; never present it as fact.
- **Deployments / releases:** render `pass` plainly, but mark `bypassed` (accepted-risk merge, production unverified) and `fail` distinctly — never collapse them into "confirmed". When `deployments_fallback` is set, render it as the italic fallback line instead of (or below) the list, so the developer sees that `/ship` can capture the missing confirmation. Omit the whole subsection only when the developer made no deployments this week and has no fallback.
- If a collector failed, render its section as `_Could not summarize — <N> commits, see git log._` and continue.
- Footnote any skipped bot authors: `_Skipped automated authors: github-actions[bot] (2 commits)._`
- **Missions:** progress is the derived `checked/total` — the **only** number; never add in-flight tickets into it. Render merged activity (`window_events`) and unmerged `in_flight` as separate lists, and mark in-flight explicitly as *not yet counted*, so unmerged work is never mistaken for landed progress. A commit link on a merged event is drawn only from a missioned ticket's `commit_hash`; do not assert a raw commit belongs to a mission otherwise (`implementation` / `objective-documentation`). Show an active mission even when it had no window activity (its standing progress is still informative); render `achieved`/`abandoned` missions compactly or omit them. Omit the whole `## Missions` section only when there are no active missions.
- The per-developer **Missions:** line is that developer's slice (their merged + in-flight tickets for each mission); render `—` when they advanced none. It complements, and must agree with, the top-level `## Missions` section.
- Keep the report skimmable — the developer reads it, then asks questions. Do not pad.

## Writing Guidelines

- Describe actual activity, not aspiration — every characterization must be checkable against a commit, ticket, or story (`implementation` / `objective-documentation`).
- Third person, past tense for completed work.
- **Overall Direction** and **Missions** are the two places you synthesize across developers (both are main-agent work — collectors never see the whole picture); the per-developer sections stay faithful to each collector's returned facts, including its `missions` attribution.
- Prefer naming the concrete artifact (file, hash, ticket) over a vague summary, so a follow-up question has somewhere to land.
