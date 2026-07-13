---
name: mission
description: Create a mission (a durable, information-rich goal spanning many tickets), list existing missions with computed progress, or close one (achieved/abandoned) into the archive area.
skills:
  - workaholic:mission
  - workaholic:gather
---

# Mission

**Notice:** When user input contains `/mission` - whether "run /mission", "start a mission", "new mission", "show missions", "mission progress", "close the mission", "end a mission", or similar - they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

This command (main agent) runs the preloaded `workaholic:mission` skill. A **mission** is a first-class knowledge artifact: a long-lived, information-rich goal that spans many tickets, drives, reports, and PRs — distinct from a `trip` (a short design/build session) and from a generic "epic/milestone" (see the skill's opening section). It lives at `.workaholic/missions/active/<slug>/mission.md` while in progress, and moves to `.workaholic/missions/archive/<slug>/mission.md` when ended (see the skill's Allowed Location section).

`$ARGUMENT` selects the mode:

## With a title — create a mission

When `$ARGUMENT` is a non-empty title, create a new mission:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/create.sh "$ARGUMENT"
```

The script derives the slug from the title, scaffolds `mission.md` (frontmatter + the four sections `## Goal`, `## Scope`, `## Acceptance`, `## Changelog`), stamps `created_at`/`author`, refreshes the OKF indexes, and git-stages. Report the JSON result:

- `created: true` — tell the user the mission slug and path, and that the next step is to fill in `## Goal`, `## Scope`, and the `## Acceptance` checklist (each item naming the ticket/story that will satisfy it — see the skill's acceptance-checklist convention). Associate future tickets with `mission: <slug>` at `/ticket` time.
- `created: false` with `reason: "exists"` — a mission with that slug already exists; report its path and do not overwrite.
- `created: false` with `reason: "no_title"` / `"empty_slug"` — ask the user for a valid title.

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

- `closed: true` — tell the user the mission is ended, its final status, and its archived path.
- `closed: false` with `reason: "already_closed"` — the mission was already archived with that status; nothing changed.
- `closed: false` with `reason: "not_found"` — no such mission; run `list.sh` and show the available slugs.
