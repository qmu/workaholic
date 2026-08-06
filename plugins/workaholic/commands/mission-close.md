---
name: mission-close
description: End a mission - achieved, abandoned, or carried - and move it into the archive area.
skills:
  - workaholic:mission
  - workaholic:gather
  - workaholic:branching
  - workaholic:commit
---

# Mission Close

**Notice:** When user input contains `/mission-close`, or asks to "close the mission", "end a mission", "abandon the mission", or "carry the mission into a successor", they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

`$ARGUMENT` is the **slug of the mission to end**, and optionally the outcome. It selects no mode: this command has exactly one behaviour.

**Why this is its own command** (P5, 2026-08-06). It was `/mission close <slug>` — a behaviour selected by the first word of another command's argument, which is a second command wearing one name. It could not simply be dropped like the retired `summary` and `approve` modes were: `close.sh` is the **only sanctioned way to end a mission**, and that single-writer property is what keeps the archive move from growing a second path. So the behaviour moved rather than going away, and `close.sh` is still the only writer.

With no slug, run `bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/list.sh`, show the active missions, and stop — ending a mission is not something to guess the subject of.

**State where the mission stands first — always, before asking anything.** Give the **Mission Position Report** (defined once in `workaholic:mission`; do not restate it here), plus — when carrying — exactly what would move to the successor. A mission is the unit the developer reasons in; ending one without saying where it stands asks them to decide blind.

If the outcome is not stated in the argument, ask with `AskUserQuestion` (prefix the `question` body with the `[<project label>]` from `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh`) — the outcome is **three-way**:

- **achieved** — the goal was reached.
- **abandoned** — ended without reaching it, and the remainder is not worth doing.
- **carried** — done **as framed**, with the remainder still worth doing: its unmet criteria are appended to an **existing** successor mission. Requires `--successor <slug>`; `--successor-title` is **refused** by the ticket floor (a minted successor arrives with zero tickets), so create the successor through `/mission` first — that interrogation is what emits its ticket set.

If the mission's `## Acceptance` progress is not `total/total`, say so in the question body — unfinished criteria mean `abandoned` **or** `carried`, and the difference is whether the remainder is still worth doing. Do not let `carried` become a way to avoid saying `abandoned`: a successor nobody drives is an abandoned mission with a longer name. The developer decides.

Then run the shared mutator (never hand-edit `status:` or `mv` the directory):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/close.sh "<slug>" <achieved|abandoned|carried> \
  [--successor <slug>]
```

Run it **inside a publish tree** (`open-publish-tree.sh`, then `( cd <publish_path> && … )`) and publish the result with subject `Close mission <slug>`, closing the tree afterwards. The archive move is a mission write like any other; leaving it on the caller's checkout would reintroduce exactly the invisibility this model removes.

The script flips `status`, appends a closing `## Changelog` line, moves the mission dir to `.workaholic/missions/archive/<slug>/`, refreshes the OKF indexes, and git-stages. Report the JSON result:

- `closed: true` with `status: "carried"` — the JSON carries `successor` and `successor_path`. **Report where the mission landed and what carried**: the predecessor's final `checked/total`, the successor's slug and its computed progress (`0/<n unmet>`, from `progress.sh` — never a carried-across number), and the unmet criteria that moved. Say plainly how far a fresh session could take the successor from here: its Goal, Scope and gate came along, so the successor is drive-ready once it has tickets. The successor gets **no worktree** from the predecessor (see the skill's *Outcomes*); it is fleshed out through the **replan flow** — `/mission <instruction referencing the successor>` emits its tickets (the create flow dead-ends on the successor's existing `mission.md`) — so say so rather than letting the developer assume in-flight state carried.
- `closed: true` — tell the user the mission is ended, its final status, and its archived path.
- `closed: false` with `reason: "already_closed"` — the mission was already archived with that status; nothing changed.
- `closed: false` with `reason: "not_found"` — no such mission; run `list.sh` and show the available slugs.

**Close touches no worktree.** Worktrees are **claim-born and ship-torn** (`docs/loop-engineering-workflow.md` I6; the doctrine is stated once in `workaholic:mission`'s *Worktree lifecycle* and `workaholic:drive`'s *Claims*): a runner's `claim.sh` creates one and ship — or an explicit `release-claim.sh` — removes it. If `.worktrees/<slug>` is still standing after a close, that is an in-flight or stale **claim**, which `list-claims.sh` surfaces and a human decides about; say so rather than removing it here. Closing a mission is a statement about the record, and a bookkeeping action must not double as a destructive one.
