---
name: mission
description: Create a mission (a durable, information-rich goal spanning many tickets), list existing missions with computed progress, or close one (achieved/abandoned) into the archive area.
skills:
  - workaholic:mission
  - workaholic:gather
  - workaholic:branching
  - workaholic:create-ticket
  - workaholic:commit
---

# Mission

**Notice:** When user input contains `/mission` - whether "run /mission", "start a mission", "new mission", "show missions", "mission progress", "close the mission", "end a mission", or similar - they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

This command (main agent) runs the preloaded `workaholic:mission` skill. A **mission** is a first-class knowledge artifact: a long-lived, information-rich goal that spans many tickets, drives, reports, and PRs — distinct from a `trip` (a short design/build session) and from a generic "epic/milestone" (see the skill's opening section). It lives at `.workaholic/missions/active/<slug>/mission.md` while in progress, and moves to `.workaholic/missions/archive/<slug>/mission.md` when ended (see the skill's Allowed Location section).

`$ARGUMENT` selects the mode. Match `summary` **first** (before the title branch, so the literal word `summary` reports rather than becoming a mission title), then the empty and `close` branches, then any other non-empty value as a title.

## `summary` — the missions that are my business

When `$ARGUMENT` is exactly `summary`, report the **active** missions that are the current user's business and stop — a read-only view that creates nothing:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/summary.sh
```

The script reports every `active` mission that is **not somebody else's** (the same gate the mission lens uses): those whose `assignee` matches your `git config user.email`, followed by **unassigned** ones — unclaimed work is closer to your business than a colleague's mission, so it is offered rather than hidden. Missions assigned to another developer are excluded. Each entry carries computed `checked/total` progress, its next unchecked acceptance item, and its `assignee` (empty when unassigned).

Present the returned array as one line per mission — `title` (`slug`) — `checked/total`, then `next: <item>`. **Render an unassigned mission distinguishably** — read the entry's `assignee` field (do not re-derive it from the file) and mark an empty one as unclaimed and claimable, so it never reads as work the developer has already taken on. The array is ordered for you: yours first, unassigned after.

If the array is empty, tell the user no active mission is theirs or unclaimed, and that `/mission` (bare) lists everyone's missions and `/mission "<title>"` starts one.

## With a title — create a mission

When `$ARGUMENT` is a non-empty title, create a new mission **in its own dedicated worktree**, and leave it drive-ready. A mission runs in a persistent `.worktrees/<mission-slug>/` worktree so several missions develop in parallel without stepping on each other; the mission worktree outlives the branches driven inside it (it is removed only at `/mission close`). This worktree flow is the create path **only** — the list and `close` modes below never touch worktrees.

**1. Derive the mission slug** (the descriptive worktree directory name):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/slug.sh "$ARGUMENT"
```

If the slug is empty, ask the user for a title with letters/digits and stop.

**2. Create the dedicated worktree** — `.worktrees/<slug>/` on a fresh `work-*` branch off `main`, root `.env` carried in:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/create-mission-worktree.sh "<slug>"
```

Note the returned `worktree_path`. On `"error": "worktree already exists"`, report the existing worktree and stop (do not clobber). This is the sanctioned worktree creator — never hand-roll `git worktree`, and never name the branch yourself.

**3. Write the mission statement inside the worktree.** Run the scaffold with the mission worktree as the working directory (use a `( cd <worktree_path> && … )` subshell so the persistent cwd stays at the repo root):

```bash
( cd <worktree_path> && bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/create.sh "$ARGUMENT" )
```

`create.sh` scaffolds `mission.md` (frontmatter + `## Goal`/`## Scope`/`## Experience`/`## Acceptance`/`## Changelog` and the empty, optional `gate_*` fields), stamps `created_at`/`author`/`assignee`, refreshes the OKF indexes, and git-stages — all inside the worktree. On `reason: "exists"`, report the path and do not overwrite.

**3b. Interrogate — mandatory, and not skippable.** Follow the skill's **Creation Interrogation** section (`workaholic:mission`) end to end. It defines the rounds (Direction → the demanded experience → the ticket set → per-ticket pre-answers → Acceptance), the ordering rule, and the emission rules; do not restate them here.

Issue every question from **this command (main agent)** — a subagent cannot call `AskUserQuestion` (CLAUDE.md One-Level Fan-Out). "As many questions as necessary" therefore means **multiple sequential `AskUserQuestion` rounds**, not one prompt. A `general-purpose` leaf may *propose* the question set as JSON for you to ask; only the command asks. Prefix every `question` body with the `[<project label>]` from `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh` or `guard-askuserquestion-label.sh` rejects it (exit 2).

Do **not** interrogate the mission gate: `gate_*` is optional and normally left empty (see the skill's *Quality gate*). Ask only if the developer volunteers a stable, objective outcome check.

Then write `## Goal`, `## Scope` and `## Experience` into the mission from the answers.

**4. Emit the whole ticket set inside the worktree, in one pass.** Per the skill's *Emitting the set*: write every ticket the interrogation determined — not just the ones the developer happened to name — to the worktree's `.workaholic/tickets/todo/<user>/`, each stamped `mission: <slug>`, carrying its mandatory `## Policies` and `## Quality Gate` (pre-answered in round 4, so no later interrogation is needed), and ordered by `depends_on`. The `create-ticket` "2–4" split cap does **not** apply to a mission — the skill records why. Then write `## Acceptance`, one item per criterion, each naming its ticket by `(#<filename>)`.

By the end of this step the mission is **drive-ready**: a complete, ordered queue whose judgement calls are already answered.

**5. Commit the mission statement and kickoff tickets inside the worktree** via the commit skill (policy-conformant subject, `Co-Authored-By` trailer kept):

```bash
( cd <worktree_path> && bash ${CLAUDE_PLUGIN_ROOT}/skills/commit/scripts/commit.sh "Kick off mission <slug>" "<why>" "<changes>" "None" "None" "<verify>" )
```

**6. Report and hand off.** Tell the developer the mission is set up in `<worktree_path>` with its statement and an ordered, ready-to-drive kickoff queue. **Do not instruct them to `cd`** — `/drive` auto-routes into an existing worktree, so they just open that worktree and drive. Summarize the mission slug, the worktree path, and the kickoff tickets.

## Without a title — list missions

When `$ARGUMENT` is empty, list existing missions with their computed progress:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/list.sh
```

Present the returned array as a readable summary — one line per mission showing `title` (`slug`), `status`, and progress as `checked/total` (progress is **computed** from the `## Acceptance` checklist, never a stored number). For each mission, read the tail of its `## Changelog` at the entry's `path` (list.sh resolves each mission's location across `active/` and `archive/`) and show the most recent few lines, so the user sees where each mission stands and how it has moved. Group `active` missions before `achieved`/`abandoned` ones. If the array is empty, tell the user there are no missions yet and that `/mission "<title>"` creates the first one.

## `close <slug>` — end a mission

When `$ARGUMENT` starts with `close`, end the named mission.

**State where the mission stands first — always, before asking anything.** Read its progress and next unchecked item (`list.sh` / `progress.sh` / `next-acceptance.sh`) and tell the developer, in plain terms: how far the mission got (`checked/total`), which criteria are still unmet, and — when carrying — exactly what would move to the successor. A mission is the unit the developer reasons in; ending one without saying where it stands asks them to decide blind.

If the outcome is not stated in the argument, ask with `AskUserQuestion` (prefix the `question` body with the `[<project label>]` from `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh`) — the outcome is **three-way**:

- **achieved** — the goal was reached.
- **abandoned** — ended without reaching it, and the remainder is not worth doing.
- **carried** — done **as framed**, with the remainder still worth doing: it becomes a successor mission that inherits the unmet criteria. Requires a successor (a title to mint one, or an existing slug).

If the mission's `## Acceptance` progress is not `total/total`, say so in the question body — unfinished criteria mean `abandoned` **or** `carried`, and the difference is whether the remainder is still worth doing. Do not let `carried` become a way to avoid saying `abandoned`: a successor nobody drives is an abandoned mission with a longer name. The developer decides.

Then run the shared mutator (never hand-edit `status:` or `mv` the directory):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/close.sh "<slug>" <achieved|abandoned|carried> \
  [--successor-title "<title>" | --successor <slug>]
```

The script flips `status`, appends a closing `## Changelog` line, moves the mission dir to `.workaholic/missions/archive/<slug>/`, refreshes the OKF indexes, and git-stages. Report the JSON result:

- `closed: true` with `status: "carried"` — the JSON carries `successor` and `successor_path`. **Report where the mission landed and what carried**: the predecessor's final `checked/total`, the successor's slug and its computed progress (`0/<n unmet>`, from `progress.sh` — never a carried-across number), and the unmet criteria that moved. Say plainly how far a fresh session could take the successor from here: its Goal, Scope and gate came along, so the successor is drive-ready once it has tickets. The successor gets **no worktree** from the predecessor (see the skill's *Outcomes*); it is created through the normal `/mission` worktree flow, so say so rather than letting the developer assume in-flight state carried. Then tear down the predecessor's worktree exactly as below.
- `closed: true` — tell the user the mission is ended, its final status, and its archived path. Then **tear down the mission's persistent worktree** — closing a mission is the only sanctioned point that removes it:

  ```bash
  bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/cleanup-mission-worktree.sh "<slug>"
  ```

  Do this **after** `close.sh` succeeds, so a teardown problem never leaves a half-closed mission. The teardown never discards uncommitted work: on `"error": "worktree has uncommitted changes"`, report that the worktree was kept (unshipped work remains) — the mission is still closed. When the worktree is already gone, the teardown is a reported no-op.
- `closed: false` with `reason: "already_closed"` — the mission was already archived with that status; nothing changed (no worktree teardown).
- `closed: false` with `reason: "not_found"` — no such mission; run `list.sh` and show the available slugs (no worktree teardown).
