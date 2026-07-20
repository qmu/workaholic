---
name: mission
description: Create a mission (the overnight-executable execution plan of a strategy — a bounded, information-rich batch of tickets), list existing missions with computed progress, or close one (achieved/abandoned) into the archive area.
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

This command (main agent) runs the preloaded `workaholic:mission` skill. A **mission** is a first-class knowledge artifact: the **overnight-executable execution plan of a strategy** — a bounded, information-rich batch of tickets an agent fleet drives in a night — distinct from a `strategy` (the long-lived direction it executes), a `trip` (a short design/build session), and a generic "epic/milestone" (see the skill's opening section and its **Granularity** record). It lives at `.workaholic/missions/active/<slug>/mission.md` while in progress, and moves to `.workaholic/missions/archive/<slug>/mission.md` when ended (see the skill's Allowed Location section).

`$ARGUMENT` selects the mode — by **content**, not by subcommand (`workaholic:design` / `modeless-design`: the argument's meaning routes the flow, mirroring `/report`/`/ship` context-awareness). Match `summary` **first** (before the title branch, so the literal word `summary` reports rather than becoming a mission title), then the `close` and empty branches. Any other non-empty argument is judged against the existing missions (see *Referencing an existing mission*, below): a clear reference to an active mission routes to the **replan flow**, an ambiguous argument is **asked**, and an argument referencing nothing is a **title** for the create flow.

## `summary` — the missions that are my business

When `$ARGUMENT` is exactly `summary`, report the **active** missions that are the current user's business and stop — a read-only view that creates nothing:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/summary.sh
```

The script reports every `active` mission that is **not somebody else's** (the same gate the mission lens uses): those whose `assignee` matches your `git config user.email`, followed by **unassigned** ones — unclaimed work is closer to your business than a colleague's mission, so it is offered rather than hidden. Missions assigned to another developer are excluded. Each entry carries computed `checked/total` progress, its next unchecked acceptance item, and its `assignee` (empty when unassigned).

Present the returned array as one line per mission — `title` (`slug`) — `checked/total`, then `next: <item>`. **Render an unassigned mission distinguishably** — read the entry's `assignee` field (do not re-derive it from the file) and mark an empty one as unclaimed and claimable, so it never reads as work the developer has already taken on. The array is ordered for you: yours first, unassigned after.

If the array is empty, tell the user no active mission is theirs or unclaimed, and that `/mission` (bare) lists everyone's missions and `/mission "<title>"` starts one.

## Referencing an existing mission — replan

A non-`summary`, non-`close`, non-empty argument may be an instruction **about a mission that already exists** — "extend the alpha mission to cover exports", "〜のミッションの受け入れ基準を見直す", or just an existing slug or title. That routes to a **replan** of that mission, not to creating a duplicate. The judgment is yours (natural-language understanding is the main agent's job — a resolver script cannot read "〜する感じに", and an instruction must never silently become a garbage mission title), but the **criteria are fixed and written here** so a routing decision can be audited afterwards.

**1. Judge the reference.** Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/list.sh` and compare the argument against every mission's `slug` and `title`. The argument **references** a mission when any of these hold:

- it contains the mission's **slug verbatim**;
- it contains the mission's **title verbatim, or as a clear substring** (a fragment long and specific enough that it cannot plausibly be a fresh title);
- it is **phrased as an instruction about a mission** — "…のミッションの…を…する", "update/extend/replan the <name> mission", an imperative that presupposes the mission exists.

Three outcomes:

- **Clearly references one active mission** → the replan flow below.
- **Ambiguous** — it could plausibly be a fresh title, or it matches more than one mission → ask with `AskUserQuestion` (body prefixed with the `[<project label>]` from `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh`): one "update mission <slug>" option per candidate, plus "create a new mission with this title". Never route silently on an ambiguous argument.
- **References nothing** → the create flow (next section), unchanged.

**Only `status: active` missions are replan targets.** An argument referencing an **archived** mission gets a short report instead: the archive is immutable history — point at the mission's `carried` successor if one exists (`carried_from` links it), or at creating a new mission.

**2. Locate the mission and ensure its worktree.** Resolve `mission.md` via the `list.sh` entry's `path`. If `.worktrees/<slug>` does not exist (a `carried` successor, or a hand-authored mission), create it now:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/create-mission-worktree.sh "<slug>"
```

This is how a carried successor — minted by `close.sh` with no worktree and no tickets — gets fleshed out; the create flow dead-ends on its existing `mission.md` (`create.sh` `reason: "exists"`), and replan is the sanctioned path instead. All writes happen in the worktree via `( cd <worktree_path> && … )` subshells, exactly as in the create flow.

**3. Re-interrogate — scoped by the instruction.** Follow the skill's **Replan** section (`workaholic:mission`): it defines which Creation Interrogation rounds re-run (Direction changes → rounds 1–2; plan growth → rounds 3–5 for the delta; a thin `0/0` mission → all five), what the delta may touch, and what it must never touch. The bar equals creation's — a structured delta model, grilled until drive-ready — because `drive_authorized` skips per-ticket approval downstream, so an under-interrogated delta is concretized across the whole mission unchecked. Issue every question from this command with the `[<project label>]` prefix; `gate_*` is never interrogated.

**If the mission's `strategy:` is still empty** (a legacy/thin mission, or one flagged as a replan item by `/monitor`'s pre-flight), run the **Strategy resolution** step now — the same infer/create/ask as the create flow's step 3a — and stamp the link, recorded as a `strategy linked` / `strategy created` changelog line. Re-stamping `drive_authorized: true` requires it resolved.

**4. Apply the delta in the worktree.** Rewrite `## Goal` / `## Scope` / `## Experience` from the answers (body-section writes are the command's job, at creation and here alike — no new mutator script). Emit the delta tickets **in one pass** into the worktree's `.workaholic/tickets/todo/<user>/`, each stamped `mission: <slug>` with its mandatory `## Policies` and `## Quality Gate` pre-answered and `depends_on` ordered (unique timestamps; the mission-scoped split-cap exception applies). Append one `## Acceptance` item per new criterion with its `(#<filename>)` marker.

**5. Record the history and the re-stamp.** Append changelog lines through the shared mutator — `ticket added — <filename>` per emitted ticket, plus one `mission replanned — <artifact>` line — and re-stamp `drive_authorized` only under the skill's Replan re-stamp conditions (a cut-short interrogation leaves it unset). Then commit inside the worktree via the commit skill, subject `Replan mission <slug>`.

**6. Report.** Summarize what changed (sections rewritten, criteria appended, tickets emitted with filenames) and where — the mission's worktree, ready to `/drive`.

## With a title — create a mission

When `$ARGUMENT` is a non-empty title that references no existing mission (per the judgment above), create a new mission **in its own dedicated worktree**, and leave it drive-ready. A mission runs in a persistent `.worktrees/<mission-slug>/` worktree so several missions develop in parallel without stepping on each other; the mission worktree outlives the branches driven inside it (it is removed only at `/mission close`). This worktree flow is the create path **only** — the list and `close` modes below never touch worktrees.

**1. Derive the mission slug** (the descriptive worktree directory name):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/slug.sh "$ARGUMENT"
```

If the slug is empty, ask the user for a title with letters/digits and stop.

**2. Create the dedicated worktree** — `.worktrees/<slug>/` on a fresh `work-*` branch cut from `main` (resolved to a concrete commit before creation, and the reported branch read back from the worktree's real HEAD — so the worktree always lands on the `work-*` branch it reports, even on a fresh clone with no local `main`), root `.env` carried in:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/create-mission-worktree.sh "<slug>"
```

Note the returned `worktree_path`. On `"error": "worktree already exists"`, report the existing worktree and stop (do not clobber). This is the sanctioned worktree creator — never hand-roll `git worktree`, and never name the branch yourself.

**3. Write the mission statement inside the worktree.** Run the scaffold with the mission worktree as the working directory (use a `( cd <worktree_path> && … )` subshell so the persistent cwd stays at the repo root):

```bash
( cd <worktree_path> && bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/create.sh "$ARGUMENT" )
```

`create.sh` scaffolds `mission.md` (frontmatter including an empty `strategy:` key + `## Goal`/`## Scope`/`## Experience`/`## Acceptance`/`## Changelog` and the empty, optional `gate_*` fields), stamps `created_at`/`author`/`assignee`, refreshes the OKF indexes, and git-stages — all inside the worktree. On `reason: "exists"`, report the path and do not overwrite.

**3a. Resolve the strategy link.** Follow the skill's **Strategy resolution** step (`workaholic:mission`) before writing the rounds' output: every mission executes one strategy. **Decide, do not ask, whenever you can** — infer from the request + existing strategies (`( cd <worktree_path> && bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/list.sh )`) and link silently when one active strategy fits (record `strategy linked — <slug>`); create one on the spot when none fits (`strategy/scripts/create.sh`, `## Direction` derived from the mission's Goal one level more general, record `strategy created — <slug>`); and ask **only** when several active strategies genuinely compete — one `AskUserQuestion` (`[<project label>]` prefix from `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh`), one option per candidate strategy plus "create new". Stamp `strategy: <slug>` into `mission.md` and record the outcome via `append-changelog.sh`. The mission cannot be stamped `drive_authorized: true` (step 4b) until this link exists — `validate-mission.sh` enforces it.

**3b. Interrogate — mandatory, and not skippable.** Follow the skill's **Creation Interrogation** section (`workaholic:mission`) end to end. It defines the rounds (Direction → the demanded experience → the ticket set → per-ticket pre-answers → Acceptance), the ordering rule, and the emission rules; do not restate them here.

Issue every question from **this command (main agent)** — a subagent cannot call `AskUserQuestion` (CLAUDE.md One-Level Fan-Out). "As many questions as necessary" therefore means **multiple sequential `AskUserQuestion` rounds**, not one prompt. A `general-purpose` leaf may *propose* the question set as JSON for you to ask; only the command asks. Prefix every `question` body with the `[<project label>]` from `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh` or `guard-askuserquestion-label.sh` rejects it (exit 2).

Do **not** interrogate the mission gate: `gate_*` is optional and normally left empty (see the skill's *Quality gate*). Ask only if the developer volunteers a stable, objective outcome check.

Then write `## Goal`, `## Scope` and `## Experience` into the mission from the answers.

**4. Emit the whole ticket set inside the worktree, in one pass.** Per the skill's *Emitting the set*: write every ticket the interrogation determined — not just the ones the developer happened to name — to the worktree's `.workaholic/tickets/todo/<user>/`, each stamped `mission: <slug>`, carrying its mandatory `## Policies` and `## Quality Gate` (pre-answered in round 4, so no later interrogation is needed), and ordered by `depends_on`. The `create-ticket` "2–4" split cap does **not** apply to a mission — the skill records why. Then write `## Acceptance`, one item per criterion, each naming its ticket by `(#<filename>)`.

By the end of this step the mission is **drive-ready**: a complete, ordered queue whose judgement calls are already answered.

**4b. Stamp the authorization.** Set `drive_authorized: true` in the mission's frontmatter — **only now**, once the interrogation is complete and the whole set is written. That stamp is what lets `/drive` drain this queue without the per-ticket approval prompt (`mission/scripts/drive-authorized.sh` reads it; see the skill's *Drive authorization*). Do **not** stamp a mission whose interrogation was cut short or whose set is partial: the stamp asserts that the developer answered every judgement call about these exact tickets, and an unearned stamp removes a gate nobody agreed to remove.

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

**State where the mission stands first — always, before asking anything.** Give the **Mission Position Report** (defined once in `workaholic:mission`; do not restate it here), plus — when carrying — exactly what would move to the successor. A mission is the unit the developer reasons in; ending one without saying where it stands asks them to decide blind.

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

- `closed: true` with `status: "carried"` — the JSON carries `successor` and `successor_path`. **Report where the mission landed and what carried**: the predecessor's final `checked/total`, the successor's slug and its computed progress (`0/<n unmet>`, from `progress.sh` — never a carried-across number), and the unmet criteria that moved. Say plainly how far a fresh session could take the successor from here: its Goal, Scope and gate came along, so the successor is drive-ready once it has tickets. The successor gets **no worktree** from the predecessor (see the skill's *Outcomes*); it is fleshed out through the **replan flow** — `/mission <instruction referencing the successor>` creates its worktree and emits its tickets (the create flow dead-ends on the successor's existing `mission.md`) — so say so rather than letting the developer assume in-flight state carried. Then tear down the predecessor's worktree exactly as below.
- `closed: true` — tell the user the mission is ended, its final status, and its archived path. Then **tear down the mission's persistent worktree** — closing a mission is the only sanctioned point that removes it:

  ```bash
  bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/cleanup-mission-worktree.sh "<slug>"
  ```

  Do this **after** `close.sh` succeeds, so a teardown problem never leaves a half-closed mission. The teardown never discards uncommitted work: on `"error": "worktree has uncommitted changes"`, report that the worktree was kept (unshipped work remains) — the mission is still closed. When the worktree is already gone, the teardown is a reported no-op.
- `closed: false` with `reason: "already_closed"` — the mission was already archived with that status; nothing changed (no worktree teardown).
- `closed: false` with `reason: "not_found"` — no such mission; run `list.sh` and show the available slugs (no worktree teardown).
