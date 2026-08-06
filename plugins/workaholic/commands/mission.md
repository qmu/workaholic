---
name: mission
description: Create a mission (an optional, epic-equivalent grouping — a bounded, information-rich batch of tickets), replan an in-flight one, list existing missions with computed progress, or close one (achieved/abandoned/carried) into the archive area.
skills:
  - workaholic:mission
  - workaholic:gather
  - workaholic:branching
  - workaholic:create-ticket
  - workaholic:commit
---

# Mission

**Notice:** When user input contains `/mission` - whether "run /mission", "start a mission", "new mission", "approve the mission", "show missions", "mission progress", "close the mission", "end a mission", or similar - they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

This command (main agent) runs the preloaded `workaholic:mission` skill. A **mission** is a first-class knowledge artifact: an **optional, epic-equivalent grouping** — a bounded, information-rich batch of tickets an agent fleet drives together (typically overnight), never a required parent of any ticket — and deliberately not a generic "epic/milestone" (see the skill's opening section and its **Granularity** record). It lives at `.workaholic/missions/active/<slug>/mission.md` while in progress, and moves to `.workaholic/missions/archive/<slug>/mission.md` when ended (see the skill's Allowed Location section).

`$ARGUMENT` selects the mode — by **content**, not by subcommand (`workaholic:design` / `modeless-design`: the argument's meaning routes the flow, mirroring `/report`/`/ship` context-awareness). Match the retired literals `summary` and `approve` **first** (short deprecation notes, below — neither is ever a mission title), then the `close` and empty branches. Any other non-empty argument is judged against the existing missions (see *Referencing an existing mission*, below): a clear reference to an in-flight mission routes to the **replan flow**, an ambiguous argument is **asked**, and an argument referencing nothing is a **title** for the create flow.

## `summary` — retired (developer decision, 2026-07-22)

The `summary` mode is **retired**: the bare `/mission` view (below) is developer-centric, so a separate my-business-only mode would differ only by hiding others' missions — a near-duplicate (one concept, one word). When `$ARGUMENT` is exactly `summary`, do not create anything and do not treat it as a title: tell the user the mode was folded into bare `/mission` and render the bare view instead. (`mission/scripts/summary.sh` remains — it is the canonical statement of the shared assignee gate the mission lens and `/drive`'s survey answer to; only the command mode is gone.)

## `approve <slug>` — retired 2026-07-31

The subcommand and its script are **gone** (`docs/loop-engineering-workflow.md` K1/K2). **Merging a mission's pull request is its approval**: since J4 every mission arrives behind a PR, so `approve` gated the same content a second time and required a manual command to undo the first gate. There is nothing left to flip — a mission on `main` is claimable as soon as it has a plan and a ticket queue.

When `$ARGUMENT` starts with `approve`, do not create anything and do not treat it as a title. Say the mode was retired, name what replaced it (merge the mission's pull request; if it is already on `main` it is already claimable), and then render the **Mission Position Report** for the named mission — that is what the developer was actually reaching for. If its `ready_reason` is `no_plan`, route to the **replan flow** below; that is now the only path from a thin mission to drive-ready.

## Referencing an existing mission — replan

A non-`summary`, non-`close`, non-empty argument may be an instruction **about a mission that already exists** — "extend the alpha mission to cover exports", "〜のミッションの受け入れ基準を見直す", or just an existing slug or title. That routes to a **replan** of that mission, not to creating a duplicate. The judgment is yours (natural-language understanding is the main agent's job — a resolver script cannot read "〜する感じに", and an instruction must never silently become a garbage mission title), but the **criteria are fixed and written here** so a routing decision can be audited afterwards.

**1. Judge the reference.** Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/list.sh` and compare the argument against every mission's `slug` and `title`. The argument **references** a mission when any of these hold:

- it contains the mission's **slug verbatim**;
- it contains the mission's **title verbatim, or as a clear substring** (a fragment long and specific enough that it cannot plausibly be a fresh title);
- it is **phrased as an instruction about a mission** — "…のミッションの…を…する", "update/extend/replan the <name> mission", an imperative that presupposes the mission exists.

Three outcomes:

- **Clearly references one in-flight mission** (`status: active`) → the replan flow below.
- **Ambiguous** — it could plausibly be a fresh title, or it matches more than one mission → ask with `AskUserQuestion` (body prefixed with the `[<project label>]` from `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh`): one "update mission <slug>" option per candidate, plus "create a new mission with this title". Never route silently on an ambiguous argument.
- **References nothing** → the create flow (next section), unchanged.

**Only in-flight missions (`status: active`) are replan targets.** An argument referencing an **archived** mission gets a short report instead: the archive is immutable history — point at the mission's `carried` successor if one exists (`carried_from` links it), or at creating a new mission.

**2. Locate the mission and open a publish tree.** Resolve `mission.md` via the `list.sh` entry's `path`, then:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/open-publish-tree.sh
```

Replan re-enters the interrogation against the mission **as published on `main`** (a mission still sitting in an unmerged pull request is not yet replannable — merge it first), applies the delta there, emits the delta tickets, and publishes them. It creates **no worktree**. This is how a carried successor — minted by `close.sh` with no tickets — gets fleshed out; the create flow dead-ends on its existing `mission.md` (`create.sh` `reason: "exists"`), and replan is the sanctioned path instead. All writes happen in the publish tree via `( cd <publish_path> && … )` subshells, exactly as in the create flow.

**2b. Surface sibling PRs.** Before re-interrogating, list open PRs that already reference this mission slug so the delta does not duplicate a sibling lane's in-flight, not-yet-merged work:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/list-related-prs.sh "<slug>"
```

If `prs` is non-empty, tell the developer which open PRs touch this mission and factor them into the delta — do **not** emit tickets duplicating acceptance a sibling PR already implements. `available: false` means the check could not run (no `gh`/auth/remote); note that rather than treating it as "no siblings". This pairs with the publish tree's fetch-first base: the fetch keeps the replan off a stale `main`, this keeps it off a sibling's unmerged work.

**3. Re-interrogate — scoped by the instruction.** Follow the skill's **Replan** section (`workaholic:mission`): it defines which Creation Interrogation rounds re-run (Direction changes → rounds 1–2; plan growth → rounds 3–5 for the delta; a thin `0/0` mission → all five), what the delta may touch, and what it must never touch. The bar equals creation's — a structured delta model, grilled until drive-ready — because approval is the last human gate before an unattended run, so an under-interrogated delta is concretized across the whole mission unchecked. Issue every question from this command with the `[<project label>]` prefix; `gate_*` is never interrogated.

**4. Apply the delta in the publish tree.** Rewrite `## Goal` / `## Scope` / `## Experience` from the answers (body-section writes are the command's job, at creation and here alike — no new mutator script). Emit the delta tickets **in one pass** into the publish tree's `.workaholic/tickets/todo/`, each stamped `mission: <slug>` and inheriting the mission's `assignees` with its mandatory `## Policies` and `## Quality Gate` pre-answered and `depends_on` ordered (unique timestamps; the mission-scoped split-cap exception applies). Append one `## Acceptance` item per new criterion with its `(#<filename>)` marker.

**5. Record the history.** Append changelog lines through the shared mutator — `ticket added — <filename>` per emitted ticket, plus one `mission replanned — <artifact>` line. There is no approval step to run (K2): **merging the delta's pull request is the acceptance of the new set** (the skill's *Review after a replan*). A cut-short interrogation publishes **nothing** — the mission keeps its already-merged plan rather than landing half a new one. Then publish the delta as one commit and close the tree:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/publish-tree-pr.sh "Replan mission <slug>" "<why>" "<changes>" "None" "None" "<verify>" .workaholic/
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/close-publish-tree.sh
```

`.workaholic/` for the same reason as the create flow's step 5: the delta tickets are untracked, and `git add -u` alone would publish the rewritten mission sections without the tickets that implement them.

An abandoned replan publishes **nothing** and says so, exactly as the create flow's step 5 requires.

**6. Report.** Summarize what changed (sections rewritten, criteria appended, tickets emitted with filenames) and where — on the named branch, behind the pull request whose URL you report. The next `/drive` tick can claim it once that pull request merges.

## With a title — create a mission

When `$ARGUMENT` is a non-empty title that references no existing mission (per the judgment above), create a new mission, **publish it to `main`**, and leave it drive-ready.

**Creation makes no worktree and no branch** (decision J1, `docs/loop-engineering-workflow.md`). A worktree is claim-born and ship-torn — `/drive`'s `claim.sh` creates `.worktrees/<slug>/` when it claims the mission, and ship or `release-claim.sh` removes it (`workaholic:mission`'s *Worktree lifecycle*). A mission written inside an unmerged worktree was invisible to `plan-units.sh`, which is exactly the failure `docs/drive-loop-runbook.md` §6 documented. So every mission write — the statement, the whole ticket set, and `close` — goes into a **publish tree** and is published for merge, leaving the developer's branch and uncommitted work untouched. This matches `/propose`, which already scaffolds its proposal outside the caller's checkout and publishes it.

**1. Derive the mission slug** (which names the mission directory, and later its claim worktree):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/slug.sh "$ARGUMENT"
```

If the slug is empty, ask the user for a title with letters/digits and stop.

**2. Open the publish tree** — a checkout of `origin/main` independent of the caller's:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/open-publish-tree.sh
```

Note the returned `path`; every write below resolves against it. On `ok: false`, report the reason and stop before writing anything. The fetch-first rationale that used to hang on worktree creation lives here now: the publish tree is cut from a freshly fetched `origin/main` by construction, so a mission is never planned against a stale base.

**3. Ask the merge-policy ruling, then write the mission statement inside the publish tree.**

`merge_policy` is recorded **at creation** (K2), so the one genuinely human ruling this flow owns is asked before the scaffold: one `AskUserQuestion` (`question` body prefixed with the `[<project label>]` from `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh`) — **may this mission's completed units merge automatically, or must a human review each PR?**, options `auto` and `review`. It is **never** decided for the developer: `auto` by default grants unattended merging nobody asked for, and `review` by default silently discards the question. (Asking before the plan is written is safe here in a way it would not be when approving someone else's draft: the developer is about to author this plan themselves, and nothing is claimable until they publish it and its pull request merges.)

Then run the scaffold with the publish tree as the working directory (use a `( cd <path> && … )` subshell so the persistent cwd stays at the repo root):

```bash
( cd <publish_path> && bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/create.sh "$ARGUMENT" "" <auto|review> )
```

`create.sh` scaffolds `mission.md` (frontmatter + `## Goal`/`## Scope`/`## Experience`/`## Acceptance`/`## Changelog` and the empty, optional `gate_*` fields), stamps `created_at`/`author`, seeds **`assignees` with the creator** (whoever creates a mission interactively owns it — the mission skill's *Ownership* section), records `merge_policy` from its optional third argument, refreshes the OKF indexes, and git-stages — all inside the publish tree. The mission is born `status: active`; there is no draft state (K1). The mission scripts are unchanged by this flow: they are cwd-relative and never branch or commit, so only the `cd` target moved. On `reason: "exists"`, report the path and do not overwrite. Ownership is no longer a floor (K2), so the seeded `assignees` may be replaced or emptied deliberately.

**3b. Interrogate — mandatory, and not skippable.** Follow the skill's **Creation Interrogation** section (`workaholic:mission`) end to end. It defines the rounds (Direction → the demanded experience → the ticket set → per-ticket pre-answers → Acceptance), the ordering rule, and the emission rules; do not restate them here.

Issue every question from **this command (main agent)** — a subagent cannot call `AskUserQuestion` (CLAUDE.md One-Level Fan-Out). Apply the **Recommended-label test** (`rules/interaction.md`) to every round: a call whose answer you could honestly recommend is decided-and-recorded (a mission `## Changelog` line or the relevant ticket's `## Quality Gate`), not asked — so "as many questions as necessary" means as many *unrecommendable* rounds as necessary, each a genuine fork, issued as **sequential `AskUserQuestion` rounds**, not one prompt. A `general-purpose` leaf may *propose* the question set as JSON for you to ask; only the command asks. Prefix every `question` body with the `[<project label>]` from `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh` or `guard-askuserquestion-label.sh` rejects it (exit 2).

Do **not** interrogate the mission gate: `gate_*` is optional and normally left empty (see the skill's *Quality gate*). Ask only if the developer volunteers a stable, objective outcome check.

Then write `## Goal`, `## Scope` and `## Experience` into the mission from the answers.

**4. Emit the whole ticket set inside the publish tree, in one pass.** Per the skill's *Emitting the set*: write every ticket the interrogation determined — not just the ones the developer happened to name — to the publish tree's `.workaholic/tickets/todo/`, each stamped `mission: <slug>` and inheriting the mission's `assignees` (ownership is a field on a ticket exactly as on a mission, P2), carrying its mandatory `## Policies` and `## Quality Gate` (pre-answered in round 4, so no later interrogation is needed), and ordered by `depends_on`. Each ticket **inherits the mission's `merge_policy`**; a deliberate per-ticket divergence carries its `Decided:` line. The `create-ticket` "2–4" split cap does **not** apply to a mission — the skill records why. Then write `## Acceptance`, one item per criterion, each naming its ticket by `(#<filename>)`.

By the end of this step the mission is **drive-ready**: a complete, ordered queue whose judgement calls are already answered.

**4b. No approval step — the pull request is the approval.** The mission was born `status: active` with its `merge_policy` already recorded in step 3; there is nothing left to flip (K1/K2).

**Publish only once the interrogation is complete and the whole set is written.** Do **not** publish a mission whose interrogation was cut short or whose set is partial: a mission reaching `main` asserts that the developer answered every judgement call about these exact tickets, and merging one that does not removes a gate nobody agreed to remove. `validate-mission.sh` refuses an active mission with an empty `## Experience` or `## Acceptance` at write time; a refusal means the interrogation's output never reached the file, so fix that rather than working around the floor.

**One commit, because the batch is one act.** A mission whose statement reached `main` without its tickets is a mission `/drive` would survey as claimable with an empty queue.

**Pass `.workaholic/` as the file argument — it is load-bearing, not decoration.** `create.sh` stages its own writes, but the ticket files are written with the editor and are therefore **untracked**, and `commit.sh`'s default staging is `git add -u`, which stages tracked modifications only. Without the path the mission statement would land with an empty queue — precisely the half-formed mission this step forbids. The publish tree was reset to `origin/main` on open, so `.workaholic/` there contains exactly this batch and nothing else.

**Never publish a half-formed mission.** If the interrogation is abandoned before the ticket set is emitted — the developer walks away, the session is interrupted, a round is left unanswered — commit **nothing** and push **nothing**. Tell the developer plainly that the mission is **not published** and that the partial work is intact in the publish tree (leave it open; `close` refuses unpublished commits, and the tree is how the work is recovered). A runner claiming a mission with no tickets is a worse outcome than losing an unfinished draft the publish tree still holds. The same applies to a publish failure (`no_origin`, `branch_collision`, `push_failed`): name the reason and say the mission is not published. `pr_failed` is reported differently — the mission **is** on its branch and only the pull request is missing, so the recovery is to open it by hand, never to re-run the interrogation.

**6. Report and hand off — honestly about location.** Tell the developer the mission is at `.workaholic/missions/active/<slug>/mission.md` on the named branch, give the pull-request URL, name the pushed commit, and summarize the slug and the kickoff tickets. It reaches `main` — and `/drive`'s survey — when that pull request merges. Do **not** report a worktree path: none exists yet, and reporting a directory the developer cannot `cd` into is worse than reporting none. Say that `/drive` creates the worktree when it claims the mission, and that `/goal /implement ok` is how to execute it.

## Without a title — the developer's planning session

When `$ARGUMENT` is empty, bare `/mission` opens a **working planning session**, not just a report (developer intent, 2026-07-22). Its arc is fixed: explain where the caller's missions stand → walk the not-ready ones through replan until every assigned mission is drive-ready → reconcile → discuss roadmap gaps → hand off to `/goal /implement ok`. This is the daytime half of the overnight model: `/mission` makes everything drive-ready, `/implement` executes it unattended. Read the whole roadmap once:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/list.sh
```

Every entry carries the fields the session needs — computed, so no logic lives in this prose: `relation` (`mine`/`unassigned`/`others`), `next` (the next unchecked acceptance item), `merge_policy` (the recorded merge ruling), `ready` (drive-ready: in flight with a plan) and `ready_reason` (`no_plan`/`not_active` when not). Do **not** re-derive any of these from `assignees`/`status`/`checked` yourself.

### Step 1 — Status: where the caller's missions stand

Render the roadmap **weighted toward the caller** (most of the output is the caller's business; others' work stays visible but compact — de-emphasized, never hidden):

- **Full treatment** for the caller's **`mine` and `unassigned` in-flight** missions (mine first, then unassigned): `title` (`slug`) — `checked/total`, the `next` item, the drive-ready state (ready, or the `ready_reason` blocker), and the most recent few `## Changelog` lines from the entry's `path`. **Mark an `unassigned` entry as unclaimed and claimable.**
- **One line each — everything else** (`others`, and any archived mission), gathered under a compact trailing section: `title` (`slug`) — `status` — `checked/total`. No changelog, no paragraphs.

If no mission is `mine` or `unassigned`, say so plainly (only colleagues'/archived work exists) and that `/mission "<title>"` starts one; if the array is empty, there are no missions yet.

### Step 2 — Replan loop: make every assigned mission drive-ready

For each `mine`/`unassigned` in-flight mission whose `ready` is `false`, run its **existing replan flow** now (the *Referencing an existing mission — replan* section above), one mission at a time, through a publish tree — never a worktree. The `ready_reason` says what is missing (`no_plan` → the interrogation must produce a plan and Acceptance; there is no approval-pending state left to distinguish, since the merge is the approval). Interrogation asks **only genuine design rulings** (the decide-and-record bar); mechanical fixes are decided and recorded, not asked. The developer may **defer** a mission ("leave it") — record that and move on; do not re-raise it this session.

An already-`ready` mission needs nothing here — say so and skip it.

### Step 3 — Reconciliation

Close the session with one honest line derived from the readers (never asserted): **`N/M assigned missions drive-ready`**, naming each mission left short and why — deferred by the developer, or blocked on a named ruling. This mirrors `/drive`'s honest-terminal shape.

### Step 4 — Roadmap gap discussion: are the missions sufficient?

Once every assigned mission is drive-ready, turn **upward**: does the roadmap cover what the accumulated direction asks for? Direction lives in the **feedback stream** (`.workaholic/feedbacks/` — read it via `bash ${CLAUDE_PLUGIN_ROOT}/skills/feedback/scripts/list.sh`): unaddressed instructions and insights with no active mission or ticket advancing them are the gaps. This survey is act-and-report: run it unasked, and if nothing is unaddressed, say so in one sentence and move on — never pad the session.

For each gap (or when the developer says the plan feels thin), open a short **discussion**, not automation: ground candidate next missions in the relevant feedback entries — including the `kind: concern` / `kind: insight` records an unattended `/drive` deferred, which are what the last runs said to front-load — and in the archived missions' outcomes. Propose concretely ("a mission that …"), and let the developer shape or reject. An agreed candidate flows straight into the **create flow** (the *With a title* section below — worktree, interrogation, ticket set) without leaving the conversation. **Never auto-create** a mission or ticket from the survey; creation happens only through the agreed hand-off. An unassigned-but-active mission is *not* a gap — the signal is "nothing advancing it", not "no mine".

### Step 5 — Execution hand-off: `/goal /implement ok`

End by recommending **`/goal /implement ok`** as the way to execute the readied missions — long, unattended, at any hour. Running it from this root worktree is unambiguous now that the drive skill is the sole executor: it surveys the unclaimed missions, claims each as a PR-unit, and drives it in the claim's own worktree, so there is nothing to point it at by hand. The `ok` token is what makes it loopable — `/implement` emits it only when every unit it claimed genuinely reached its routed end (`workaholic:drive` §7).

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

Run it **inside a publish tree** (`open-publish-tree.sh`, then `( cd <publish_path> && … )`) and publish the result with subject `Close mission <slug>`, closing the tree afterwards. The archive move is a mission write like any other; leaving it on the caller's checkout would reintroduce exactly the invisibility this model removes.

The script flips `status`, appends a closing `## Changelog` line, moves the mission dir to `.workaholic/missions/archive/<slug>/`, refreshes the OKF indexes, and git-stages. Report the JSON result:

- `closed: true` with `status: "carried"` — the JSON carries `successor` and `successor_path`. **Report where the mission landed and what carried**: the predecessor's final `checked/total`, the successor's slug and its computed progress (`0/<n unmet>`, from `progress.sh` — never a carried-across number), and the unmet criteria that moved. Say plainly how far a fresh session could take the successor from here: its Goal, Scope and gate came along, so the successor is drive-ready once it has tickets. The successor gets **no worktree** from the predecessor (see the skill's *Outcomes*); it is fleshed out through the **replan flow** — `/mission <instruction referencing the successor>` emits its tickets (the create flow dead-ends on the successor's existing `mission.md`) — so say so rather than letting the developer assume in-flight state carried.
- `closed: true` — tell the user the mission is ended, its final status, and its archived path.
- `closed: false` with `reason: "already_closed"` — the mission was already archived with that status; nothing changed.
- `closed: false` with `reason: "not_found"` — no such mission; run `list.sh` and show the available slugs.

**Close touches no worktree.** Worktrees are **claim-born and ship-torn** (`docs/loop-engineering-workflow.md` I6; the doctrine is stated once in `workaholic:mission`'s *Worktree lifecycle* and `workaholic:drive`'s *Claims*): a runner's `claim.sh` creates one and ship — or an explicit `release-claim.sh` — removes it. If `.worktrees/<slug>` is still standing after a close, that is an in-flight or stale **claim**, which `list-claims.sh` surfaces and a human decides about; say so rather than removing it here. Closing a mission is a statement about the record, and a bookkeeping action must not double as a destructive one.
