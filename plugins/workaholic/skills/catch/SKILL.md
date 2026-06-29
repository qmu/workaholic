---
name: catch
description: Use when the user runs `/catch`, asks to "catch me up", "what has everyone been working on", "summarize the last two weeks", or "show a by-developer development report". Scans the recent commit/ticket/story trail, fans out one collector per active developer to summarize their work, then synthesizes the overall development direction and stands ready for follow-up questions.
allowed-tools: Bash
user-invocable: false
skills:
  - workaholic:gather
  - workaholic:planning
  - workaholic:design
  - workaholic:implementation
  - workaholic:operation
metadata:
  internal: true
---

# Catch

Generate a **by-developer catch-up report** over a recent time window (default: the last two weeks) so a developer can absorb the overall direction of the repository and how each individual is taking their part, then ask follow-up questions to go deeper. `/catch` is **read-only**: it reads tickets, branch stories, docs, and commit messages, and writes nothing.

## Agent Compatibility

This skill works on any Agent-Skills-compatible agent. Unlike `/trip` (which depends on Claude Code Agent Teams), `/catch` is a portable skill — the two Claude-Code mechanisms it uses are **enhancements, not requirements**:

- **Parallel fan-out** — Phase 1 spawns one `general-purpose` collector subagent per active developer (`model: "haiku"`) so the per-developer summaries run concurrently and cheaply. On agents without subagents, run the **Collect Developer** section **sequentially** in the same session, once per developer — the inputs and outputs are identical.
- **Model routing** — `model: "haiku"` is a Claude-Code cost/speed hint for the collectors. On other agents it is ignored; use whatever model is available.

There is **no `AskUserQuestion`** in this workflow. `/catch` runs to completion and prints a report; the follow-up Q&A is ordinary conversation, so the skill is fully portable.

## Run Workflow

The `/catch` command (main agent) runs this workflow directly: it executes the bash/Read steps inline, spawns the per-developer collectors as `general-purpose` subagents, and synthesizes the report itself. Fan-out stays one level deep — collectors are non-interactive leaves that read files and return JSON; they never spawn further subagents and never prompt the user.

### Policy Lens (read first)

Before judging development direction, load the project's engineering policies as your lens: `workaholic:planning`, `workaholic:design`, `workaholic:implementation`, and `workaholic:operation`. On Claude Code these arrive automatically (this skill preloads them and the `/catch` command's `policy-lens.sh` hook injects the index); on other agents, open each index skill yourself. When the report characterizes a developer's direction (e.g. "consolidating infrastructure", "hardening operation"), frame it against the relevant pillar's intent rather than inventing categories. The report **describes** activity — it does not grade it — so keep characterizations factual and verifiable (see `workaholic:implementation` / `objective-documentation`).

### Phase 0: Gather the Window and Roster

1. Determine the **window** from `$ARGUMENT`: if the invocation names a span (e.g. `/catch 30 days`, `/catch "1 month"`), pass it through; otherwise default to `2 weeks ago`. Any `git log --since` expression is valid.
2. Run the scan script:

   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/catch/scripts/scan-window.sh "<window>"
   ```

   It returns `{ window, developers[], tickets[], stories[] }`:
   - `developers[]` — each active author in the window: `name`, `email`, `commit_count`, and `commits[]` (`hash`, `subject`, `timestamp`, `body`). `email` is the **join key** for the by-developer axis.
   - `tickets[]` — every ticket under `todo`/`archive`/`icebox` with its frontmatter `author`, `title`, and `scope`. Group these by `author` to match each developer's commits.
   - `stories[]` — branch-story file paths under `.workaholic/stories/`, the narrative record of completed branches.
3. Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/git-context.sh` to get `repo_url` (used to render commit links) and `branch`.
4. **Empty window**: if `developers[]` is empty, print "No commits in the last `<window>`." and suggest a wider window (e.g. `/catch 1 month`). Stop — there is nothing to summarize.

### Phase 1: Collect Per Developer (parallel fan-out)

Spawn **one `general-purpose` subagent per developer** in `developers[]`, in a **single message** (`model: "haiku"`). Each prompt instructs the collector to preload `workaholic:catch`, run the **Collect Developer** section, and return that section's JSON. Pass each collector:

- the developer's `name`, `email`, and `commits[]` (from `developers[]`);
- the subset of `tickets[]` whose `author` equals this developer's `email`;
- the `stories[]` list and `repo_url` (so it can read stories and link commits).

Bots are developers too only if relevant — by default **skip authors whose email contains `[bot]`** (e.g. `github-actions[bot]`) unless the user asked to include automation. Note any skipped bot authors in the final report's footnote.

Wait for all collectors to finish. Track which succeeded and which failed; a failed collector becomes a "could not summarize" line in the report, never a blocker.

### Phase 2: Synthesize the Report

Assemble the collectors' JSON into the **Report Structure** below. Two parts:

1. **Overall Direction** — your own synthesis across all developers: the dominant themes of the window, where effort concentrated, and how the individual threads fit together. This is the part the developer reads first to orient.
2. **By Developer** — one section per developer, populated verbatim from that collector's returned fields.

Print the full report to the developer.

### Phase 3: Stand Ready for Questions

After printing, the developer will ask follow-up questions to understand a thread more deeply or to discuss direction. Answer from the gathered context; read the specific tickets, stories, commits, or source files a question points at (you have their paths and hashes). No special mechanism — this is normal conversation.

## Collect Developer

Run by a Phase 1 collector (a `general-purpose` subagent that preloads this skill), once per developer. **Inputs** (from the command): `name`, `email`, `commits[]`, this developer's `tickets[]`, the `stories[]` paths, and `repo_url`.

**Task** — characterize what this developer worked on in the window, factually:

1. Read the developer's `commits[]` bodies (they carry the structured `Why:` / `Changes:` / `Concerns:` / `Insights:` keys from the commit format) and subjects.
2. Read the developer's `tickets[]` (their `## Overview` and `## Final Report`) for intent and outcome behind the commits.
3. Skim any `stories[]` that clearly cover this developer's branches (match by title/theme) for the narrative arc — do not read all 50; sample the ones that match.
4. Summarize **focus areas** (what parts of the system they touched), **themes** (the through-line of the work), **notable changes** (the few highest-impact items, each with a commit hash), and **open threads** (carried concerns, unfinished tickets in `todo`, or `Concerns:` keys from commit bodies).

Keep it factual and verifiable — name files, hashes, and tickets; avoid evaluative adjectives ("elegant", "powerful"). Do not invent activity not present in the inputs.

### Collector Output (JSON)

```json
{
  "email": "a@qmu.jp",
  "name": "TAMURA Yoshiya",
  "commit_count": 145,
  "headline": "One-sentence summary of this developer's window.",
  "focus_areas": ["cross-agent build pipeline", "ship/deploy gating"],
  "themes": "1-3 sentence narrative of the through-line connecting the work.",
  "notable_changes": [
    { "title": "Ship gate now confirms in production before merge", "hash": "abc1234" }
  ],
  "open_threads": ["carried concern: outputs/ freshness drift if build skipped"]
}
```

If a developer's window is thin (a few commits, no tickets), return a short `headline` and empty arrays rather than padding — the report shows the real shape of the work.

## Report Structure

The printed report (Markdown):

```markdown
# Catch-up — last <window> (<branch>)

## Overall Direction

<2-4 sentence synthesis across all developers: dominant themes, where effort
concentrated, how the individual threads fit together.>

**Active this window:** <N> developer(s), <total> commits.

## By Developer

### <Name> (<email>) — <commit_count> commits

**<headline>**

- **Focus:** <focus_areas, comma-separated>
- **Themes:** <themes>
- **Notable changes:**
  - <title> ([<hash>](<repo_url>/commit/<hash>))
- **Open threads:** <open_threads, or "None">

### <Next developer> ...
```

**Guidelines:**
- Commit hashes are clickable links: `([abc1234](<repo_url>/commit/abc1234))`, never bare text.
- Order developers by `commit_count` descending (most active first).
- If a collector failed, render its section as `_Could not summarize — <N> commits, see git log._` and continue.
- Footnote any skipped bot authors: `_Skipped automated authors: github-actions[bot] (2 commits)._`
- Keep the report skimmable — the developer reads it, then asks questions. Do not pad.

## Writing Guidelines

- Describe actual activity, not aspiration — every characterization must be checkable against a commit, ticket, or story (`workaholic:implementation` / `objective-documentation`).
- Third person, past tense for completed work.
- The **Overall Direction** is the only place you synthesize across developers; the per-developer sections stay faithful to each collector's returned facts.
- Prefer naming the concrete artifact (file, hash, ticket) over a vague summary, so a follow-up question has somewhere to land.
