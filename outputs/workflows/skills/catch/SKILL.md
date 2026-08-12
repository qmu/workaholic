---
name: catch
description: Use when the user runs `/catch`, asks to "catch me up", "what has everyone been working on", "summarize the last two weeks", or "show a by-developer development report". Scans the recent commit/ticket/story trail, fans out one collector per active developer to summarize their work, then synthesizes the overall development direction, the active missions (progress plus merged and unmerged in-flight work), and stands ready for follow-up questions.
allowed-tools: Bash
---

# Catch

Generate a by-developer catch-up report over a recent time window (default: the last two weeks), then answer follow-up questions. `/catch` reads tickets, branch stories, docs, and commit messages: it writes **no project files and makes no commits** — the one repository write is a best-effort `git fetch` at the start of the scan, which updates only remote-tracking refs (`refs/remotes/*`), never the working tree, the index, or any project file. The scan also stages two values in a private `mktemp -d` it removes on every exit path: the mission list and the tickets array are handed to `jq` **by file, never as an argument**, because Linux caps one argv entry at 128 KiB and a mature ticket corpus crosses that on its own — passing them inline aborted the whole scan with `jq: Argument list too long` and emitted nothing at all. Per-field scanner schema, the collector output example, and the exact report template live in [reference/rendering.md](reference/rendering.md).

## Agent Compatibility

Portable to any Agent-Skills-compatible agent; the two Claude-Code mechanisms are enhancements, not requirements. Without subagents, run the **Collect Developer** section sequentially, once per developer — inputs and outputs are identical.  is a cost/speed hint for the collectors, ignored elsewhere. There is no the agent's selection prompt: the report prints, and the follow-up Q&A is ordinary conversation.

## Run Workflow

The `/catch` command (main agent) runs this directly: bash/Read steps inline, per-developer collectors as parallel workers, synthesis itself. Fan-out stays one level deep — collectors are non-interactive leaves that read files and return JSON.

### Policy Lens (read first)

Judge development direction through the four pillar policy skills (preloaded on Claude Code; open them yourself on other agents), framing characterizations against the relevant pillar's intent. The report **describes** activity — it does not grade it — so keep characterizations factual and checkable (`implementation` / `objective-documentation`).

### Phase 0: Gather the Window and Roster

1. Window from `$ARGUMENT` (any `git log --since` expression, e.g. `/catch 30 days`); default `2 weeks ago`.
2. Scan:

   ```bash
   bash catch/scripts/scan-window.sh "<window>"
   ```

   Runs a bounded best-effort `git fetch --all --prune` first (`CATCH_FETCH_TIMEOUT` seconds, default 20; `0` skips — either degradation reports `fetch_ok: false`, never a stalled `/catch`), then scans `--branches --remotes` so remote-only branches appear. Returns `{window, fetch_ok, buckets, developers[], tickets[], stories[], deployments[], missions[]}` — field detail in [reference/rendering.md](reference/rendering.md). The joins: `developers[].email` matches `tickets[].author` and `deployments[].author`; an archived ticket's git-derived `commit_hash` ties missioned work to a commit; each commit's `bucket` (`recent` = yesterday+today / `this_week` / `last_week` / `older`) drives the time-windowed focus; `missions[]` (from the mission skill's `list.sh` — progress derived, never stored) carries merged `window_events[]` and open `in_flight[]` per mission. The scan reads missions read-only.
3. Run `bash gather/scripts/git-context.sh` for `repo_url` (commit links) and `branch`.
3b. Compute the orchestration-throughput KPI over the same window:

   ```bash
   bash gather/scripts/commit-kpi.sh "<window>"
   ```

   Returns `{window, total_commits, agent_commits, agent_share, median_changed_lines, p90_changed_lines, oversize_commits}`. Render it verbatim into the **Orchestration Throughput** table — never recompute any of it inline; render a `null` `oversize_commits` as "n/a".
4. Empty window: if `developers[]` is empty, print "No commits in the last `<window>`.", suggest a wider window, and stop.
5. Stale-view note: if `fetch_ok` is `false`, add a line under the report title that the remote was not reachable and the view may be stale — never present a local-only scan as an up-to-date remote view. Add nothing when `true`.

### Phase 1: Collect Per Developer (parallel fan-out)

Spawn one `general-purpose` collector per developer in a single message, each preloading `catch` and running **Collect Developer** with: the developer's `name`/`email`/`commits[]`/`branches[]`, the `buckets`, their `tickets[]` and `deployments[]` subsets (matched by `email`), the full `missions[]`, the `stories[]` list, and `repo_url`. Skip authors whose email contains `[bot]` unless the user asked to include automation (footnote them). Track outcomes: a failed collector becomes a "could not summarize" line, never a blocker.

### Phase 2: Synthesize the Report

Assemble the collectors' JSON into the report (template and rendering guidelines: [reference/rendering.md](reference/rendering.md)) and print it in full. Three parts:

1. **Overall Direction** — your own synthesis across developers: dominant themes, where effort concentrated, how the threads fit together; fold in a one-line read of a mission that dominates the window.
2. **Missions** — synthesized by you (the main agent) directly from the scanner's `missions[]`, never from collectors (the one-level-fan-out rule: cross-developer synthesis stays in the main agent). One entry per active mission: derived `checked/total` (the only progress number — never add in-flight into it), merged `window_events`, and unmerged `in_flight`, rendered as separate lists so merged progress and in-flight work are never conflated.
3. **By Developer** — one section per developer, populated verbatim from that collector's fields, including its `missions` attribution line (which must agree with the top-level Missions section).

### Phase 3: Stand Ready for Questions

Answer follow-ups from the gathered context; read the specific tickets, stories, commits, or source files a question points at. No special mechanism — normal conversation.

## Collect Developer

Run by a Phase 1 collector (a parallel workers preloading this skill), once per developer, from the inputs above. Characterize the window factually:

1. Read the developer's `commits[]` bodies (the structured `Why:` / `Changes:` / `Concerns:` / `Insights:` keys) and subjects.
2. Read their `tickets[]` (`## Overview`, `## Final Report`) for intent and outcome.
3. Skim the `stories[]` that clearly cover their branches (match by title/theme) — sample, do not read all.
4. Summarize **focus areas** (what parts of the system), **themes** (the through-line), **notable changes** (the few highest-impact items, each with a commit hash), and **open threads** (deferred concerns, unfinished `todo` tickets, `Concerns:` keys).
5. Time-windowed focus, one line each from the `bucket` field: `recent_focus` (`recent`), `week_focus` (`recent` + `this_week`), `last_week_focus` (`last_week`); an empty bucket returns an empty string — do not pad.
6. **Struggles** — only from concrete signals: `Concerns:` keys, open `todo`/`icebox` tickets, `abandoned` tickets (their `## Failure Analysis` is the strongest signal), matching story concern blocks. Each traceable to its source; `[]` when there is no real signal — never invent difficulty.
7. **Per-branch focus** — one line per `branches[]` entry, derived from that branch's commit subjects; carry through `name` and `commit_count`.
8. **Generation style** — an explicit guess from the `timestamp`/`epoch` shape (daytime ticket-driving vs. overnight long-running drive vs. a mix); phrase as inference ("looks like…"), never as fact — the one inference allowed.
9. **Deployments this week** — from their `deployments[]`: `timestamp`, `release_title`, `status`, `confirmation`. Set `deployments_fallback` when they shipped this week but no referenceable confirmation exists (the "`/ship` can capture it going forward" guidance). Render `bypassed`/`fail` distinctly — never as a confirmed deployment, and never fabricate a confirmation (`operation` / `ci-cd`).
10. **Missions advanced** — join their `tickets[]` to `missions[]`: per slug, `merged` (their archived tickets carrying that slug whose `commit_hash` is among their `commits[]` — each `{title, hash}`) and `in_flight` (their open `todo`/`icebox` tickets carrying it — each `{title, scope}`); `[]` when none. Attribution is at ticket granularity — never assert a raw commit belongs to a mission otherwise.

Return the JSON object shown in [reference/rendering.md](reference/rendering.md): `email`, `name`, `commit_count`, `headline`, `focus_areas[]`, `themes`, the three focus strings, `struggles[]`, `branches[]`, `generation_style`, `deployments[]`, `deployments_fallback`, `notable_changes[]`, `open_threads[]`, `missions[]`. Keep it factual and verifiable — name files, hashes, tickets; no evaluative adjectives. A thin window returns a short `headline` and empty fields rather than padding — the report shows the real shape of the work.

## Report Structure

The exact Markdown template and rendering guidelines are in [reference/rendering.md](reference/rendering.md). The shape: `# Catch-up — last <window> (<branch>)`, then **Overall Direction**, the **Orchestration Throughput** table (verbatim from `commit-kpi.sh` — it measures how well the agent fleet is orchestrated, never human performance, and its two guards hold: quota consumed only to raise it is worthless, and history is never reshaped to improve it), **Missions**, and **By Developer** ordered by `commit_count` descending. Keep the report skimmable — the developer reads it, then asks questions; do not pad.

## Writing Guidelines

- Describe actual activity, not aspiration — every characterization checkable against a commit, ticket, or story (`implementation` / `objective-documentation`). Third person, past tense for completed work.
- **Overall Direction** and **Missions** are the two cross-developer syntheses (main-agent work — collectors never see the whole picture); the per-developer sections stay faithful to each collector's returned facts.
- Prefer naming the concrete artifact (file, hash, ticket) over a vague summary, so a follow-up question has somewhere to land.
