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

`create.sh` scaffolds `mission.md` (frontmatter + `## Goal`/`## Scope`/`## Acceptance`/`## Changelog` and the empty `gate_*` fields), stamps `created_at`/`author`/`assignee`, refreshes the OKF indexes, and git-stages — all inside the worktree. Then work with the developer to fill in `## Goal`, `## Scope`, and the `## Acceptance` checklist (each item naming the ticket/story that will satisfy it), **and the mission's quality gate**: set `gate_type` (`documentation` or `live-app`), `gate_target` (a route served on the worktree's port), and `gate_assert` (one line: what must hold) — the objective mission-level check that `/drive` reads via `mission/scripts/gate.sh` and verifies against the worktree's port with Playwright. On `reason: "exists"`, report the path and do not overwrite.

**4. Create the ordered kickoff tickets inside the worktree.** With the worktree as the working directory, run the full `workaholic:create-ticket` **Workflow** (three-mode discovery + the mandatory Quality-Gate interrogation) once **per** kickoff ticket the developer wants to start the mission with — writing each to the worktree's `.workaholic/tickets/todo/<user>/`, stamping `mission: <slug>` in its frontmatter, and ordering them with `depends_on` so `/drive` runs them in sequence.

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

When `$ARGUMENT` starts with `close`, end the named mission. If the outcome is not stated in the argument, ask with `AskUserQuestion` (prefix the `question` body with the `[<project label>]` from `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh`): was the mission **achieved** (its goal reached) or **abandoned** (ended without reaching it)? If the mission's `## Acceptance` progress (from `list.sh`) is not `total/total`, say so in the question body — unfinished criteria usually mean `abandoned`, but the developer decides. Then run the shared mutator (never hand-edit `status:` or `mv` the directory):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/close.sh "<slug>" <achieved|abandoned>
```

The script flips `status`, appends a closing `## Changelog` line, moves the mission dir to `.workaholic/missions/archive/<slug>/`, refreshes the OKF indexes, and git-stages. Report the JSON result:

- `closed: true` — tell the user the mission is ended, its final status, and its archived path. Then **tear down the mission's persistent worktree** — closing a mission is the only sanctioned point that removes it:

  ```bash
  bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/cleanup-mission-worktree.sh "<slug>"
  ```

  Do this **after** `close.sh` succeeds, so a teardown problem never leaves a half-closed mission. The teardown never discards uncommitted work: on `"error": "worktree has uncommitted changes"`, report that the worktree was kept (unshipped work remains) — the mission is still closed. When the worktree is already gone, the teardown is a reported no-op.
- `closed: false` with `reason: "already_closed"` — the mission was already archived with that status; nothing changed (no worktree teardown).
- `closed: false` with `reason: "not_found"` — no such mission; run `list.sh` and show the available slugs (no worktree teardown).
