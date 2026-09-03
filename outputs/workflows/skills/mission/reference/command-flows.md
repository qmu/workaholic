# The command flows — /mission and /mission-close orchestration

The orchestration the thin `/mission` and `/mission-close` commands run. It is written for the **loading command (main agent)**: every the agent's selection prompt below — the merge-policy ruling, the interrogation rounds, ambiguity resolution, the close outcome — is issued by that command, never by a subagent (a `general-purpose` leaf cannot call the agent's selection prompt; it may at most *propose* a question set as JSON for the command to ask). Prefix every `question` body with the `[<project label>]` from `bash ../gather/scripts/project-label.sh`, or `guard-askuserquestion-label.sh` rejects it (exit 2).

## Routing the argument

**No word of `$ARGUMENT` is a subcommand** (P5, 2026-08-06): it names the mission you mean, and nothing else. Content routes the flow — a clear reference to one **in-flight** mission → the **replan flow**; an ambiguous argument → **ask**; an argument referencing nothing → a **title** for the **create flow**; an empty argument → the **planning session** (a scope — no mission named, so all of yours — not a mode).

The judgment is the main agent's (a resolver script cannot read "〜する感じに", and an instruction must never silently become a garbage mission title), but the **criteria are fixed here** so a routing decision can be audited afterwards. Run:

```bash
bash ../mission/scripts/list.sh
```

and compare the argument against every mission's `slug` and `title`. The argument **references** a mission when any of these hold:

- it contains the mission's **slug verbatim**;
- it contains the mission's **title verbatim, or as a clear substring** (a fragment long and specific enough that it cannot plausibly be a fresh title);
- it is **phrased as an instruction about a mission** — "…のミッションの…を…する", "update/extend/replan the <name> mission", an imperative that presupposes the mission exists.

**Ambiguous** — it could plausibly be a fresh title, or it matches more than one mission — is asked, never routed silently: one "update mission <slug>" option per candidate, plus "create a new mission with this title". **Only in-flight missions (`status: active`) are replan targets**; an argument referencing an **archived** mission gets a short report instead — the archive is immutable history — pointing at the mission's `carried` successor if one exists (`carried_from` links it), or at creating a new mission.

## Create flow — `/mission "<title>"`

Create a new mission, publish it behind a pull request, and leave it drive-ready. **Creation makes no worktree and no branch** (decision J1; the SKILL's *Worktree lifecycle* carries the reasoning): every mission write goes into a **publish tree** and is published for merge, leaving the developer's branch and uncommitted work untouched.

**1. Derive the slug** (which names the mission directory, and later its claim worktree):

```bash
bash ../mission/scripts/slug.sh "$ARGUMENT"
```

If the slug is empty, ask the user for a title with letters/digits and stop.

**2. Open the publish tree** — a checkout of `origin/main` independent of the caller's:

```bash
bash ../branching/scripts/open-publish-tree.sh
```

Note the returned `path`; every write below resolves against it. On `ok: false`, report the reason and stop before writing anything. The publish tree is cut from a freshly fetched `origin/main` by construction, so a mission is never planned against a stale base.

**3. Ask the merge-policy ruling, then scaffold.** `merge_policy` is recorded at creation (K2), so the one genuinely human ruling this flow owns is asked before the scaffold: one the agent's selection prompt — **should this mission's completed units confirm their deploy before merging, or merge immediately with quality gated later at the `release/*` QA window?**, options `auto` and `review` (neither asks a human to review a PR — both merge unattended since the 2026-08-11 auto-merge mission). It is **never decided for the developer**: `auto` by default grants unattended merging nobody asked for, and `review` by default silently discards the question. Then run the scaffold with the publish tree as the working directory (a `( cd … )` subshell, so the persistent cwd stays at the repo root):

```bash
( cd <publish_path> && bash ../mission/scripts/create.sh "$ARGUMENT" "" <auto|review> )
```

`create.sh` scaffolds the frontmatter and empty sections, seeds `assignees` with the creator, records `merge_policy` from its third argument, refreshes the OKF indexes, and git-stages — all inside the publish tree ([`scripts.md`](scripts.md)). The mission is born `status: active`; there is no draft state (K1). On `reason: "exists"`, report the path and do not overwrite. The seeded `assignees` may be replaced or emptied deliberately (ownership is not a floor, K2).

**4. Interrogate — mandatory, not skippable.** Follow the SKILL's **Creation Interrogation** end to end: the feedback read-back, the elicitation gates, the five rounds, the Recommended-label test, the ordering rule. Then write `## Goal` and `## Experience` into the mission from the answers — body-section writes are the command's job, at creation and replan alike; no mutator script exists for them. `gate_*` is never interrogated.

**5. Emit the whole ticket set in one pass**, per the SKILL's *Emitting the set*: every ticket the interrogation determined — not just the ones the developer happened to name — into the publish tree's `.workaholic/tickets/todo/`, each stamped `mission: <slug>`, inheriting the mission's `assignees` and `merge_policy` (a deliberate per-ticket divergence carries its `Decided:` line), carrying its pre-answered `## Policies` and `## Quality Gate`, ordered by `depends_on` with unique timestamps (the mission-scoped split-cap exception applies). Then write `## Acceptance`, one item per criterion, and stamp each item's `(#<filename>)` link via `link-acceptance.sh`. By the end the mission is **drive-ready**. There is no approval step — the pull request is the approval (K1/K2).

**6. Publish — one commit, only when complete.**

- **Never publish a half-formed mission.** Publish only once the interrogation is complete and the whole set is written: a mission reaching `main` asserts that the developer answered every judgement call about these exact tickets. If the interrogation is abandoned — the developer walks away, the session is interrupted, a round is left unanswered — commit **nothing** and push **nothing**; tell the developer plainly the mission is **not published** and the partial work is intact in the still-open publish tree (`close-publish-tree.sh` refuses unpublished commits, and the tree is how the work is recovered). `validate-mission.sh` refusing an active mission with an empty `## Experience` or `## Acceptance` means the interrogation's output never reached the file — fix that, never work around the floor.
- **The ticket floor is checked before the publish commit**: run `check-floor.sh <slug>`; a non-zero exit means the mission is **not published**, and its `alternative` names what to tell the author instead (SKILL, *The ticket floor*).
- **One commit, because the batch is one act** — a mission statement on `main` without its tickets is a mission `/drive` would survey as claimable with an empty queue. Publish and close the tree:

```bash
bash ../branching/scripts/publish-tree-pr.sh "Add mission <slug>" "<why>" "<changes>" "None" "None" "<verify>" .workaholic/
bash ../branching/scripts/close-publish-tree.sh
```

- **Pass `.workaholic/` as the file argument — load-bearing, not decoration**: `create.sh` stages its own writes, but the ticket files are written with the editor and are therefore **untracked**, and `commit.sh`'s default staging is `git add -u` — tracked modifications only. Without the path the statement would land with an empty queue. The publish tree was reset to `origin/main` on open, so `.workaholic/` there contains exactly this batch and nothing else.
- A publish failure (`no_origin`, `branch_collision`, `push_failed`) means the mission is **not published** — name the reason and say so. `pr_failed` is reported differently: the mission **is** on its branch and only the pull request is missing, so the recovery is to open it by hand, never to re-run the interrogation.

**7. Report — honestly about location.** The mission is at `.workaholic/missions/active/<slug>/mission.md` on the named branch; give the pull-request URL, name the pushed commit, and summarize the slug and the kickoff tickets. It reaches `main` — and `/drive`'s survey — when that pull request merges. Report **no worktree path**: none exists yet, and reporting a directory the developer cannot `cd` into is worse than reporting none. Say that `/drive` creates the worktree when it claims the mission, and that `/goal /implement ok` is how to execute it.

## Replan flow — `/mission "<instruction about an existing mission>"`

**1. Locate the mission and open a publish tree.** Resolve `mission.md` via the `list.sh` entry's `path`, then run `open-publish-tree.sh` exactly as in the create flow. Replan re-enters the interrogation against the mission **as published on `main`** (a mission still sitting in an unmerged pull request is not yet replannable — merge it first), applies the delta there, emits the delta tickets, and creates **no worktree**. This is how a `carried` successor — minted by `close.sh` with no tickets — or a thin hand-authored mission gets fleshed out: the create flow dead-ends on its existing `mission.md` (`create.sh` `reason: "exists"`), and replan is the sanctioned path instead. All writes happen in the publish tree via `( cd <publish_path> && … )` subshells.

**2. Surface sibling PRs** before re-interrogating, so the delta does not duplicate a sibling lane's in-flight, not-yet-merged work:

```bash
bash ../mission/scripts/list-related-prs.sh "<slug>"
```

If `prs` is non-empty, tell the developer which open PRs touch this mission and factor them into the delta — do **not** emit tickets duplicating acceptance a sibling PR already implements. `available: false` means the check could not run (no `gh`/auth/remote) — *unknown*, not "no siblings".

**3. Re-interrogate — scoped by the instruction.** Follow the SKILL's **Replan** section: which Creation Interrogation rounds re-run, what the delta may touch, and what it must never touch. The bar equals creation's — a structured delta model, grilled until drive-ready, because an under-interrogated delta is concretized across the whole mission unchecked. Issue every question from the command, label-prefixed; `gate_*` is never interrogated.

**4. Apply the delta in the publish tree.** Rewrite `## Goal` / `## Experience` (and a legacy `## Scope`, if the mission still carries one) from the answers. Emit the delta tickets **in one pass** (the same emission rules as creation, including the split-cap exception and the link-stamping step); append one `## Acceptance` item per new criterion with its `(#<filename>)` marker.

**5. Check the floor, record the history, then publish.** **The floor applies to the replan seam exactly as it applies to creation** (2026-09-03): a `carried` successor arrives with zero tickets and a thin hand-authored mission with one, and replan is the sanctioned path that fleshes either out — so it is the seam a below-floor mission actually reaches. Run `check-floor.sh <slug>` in the publish tree before the publish commit; a non-zero exit means the delta is **not published**, and its `alternative` names what to tell the author instead. The number is never spelled here (`mission`, *The ticket floor* — the enumeration of every seam that reads it). Then append changelog lines through `append-changelog.sh` — `ticket added — <filename>` per emitted ticket, plus one `mission replanned — <artifact>` line. There is no approval step to run (K2): **merging the delta's pull request is the acceptance of the new set**. A cut-short interrogation publishes **nothing** — the mission keeps its already-merged plan rather than landing half a new one. Then publish the delta as one commit and close the tree:

```bash
bash ../branching/scripts/publish-tree-pr.sh "Replan mission <slug>" "<why>" "<changes>" "None" "None" "<verify>" .workaholic/
bash ../branching/scripts/close-publish-tree.sh
```

`.workaholic/` for the create flow's reason: the delta tickets are untracked, and `git add -u` alone would publish the rewritten mission sections without the tickets that implement them. An abandoned replan publishes **nothing** and says so.

**6. Report.** Summarize what changed (sections rewritten, criteria appended, tickets emitted with filenames) and where — the named branch, the pull-request URL. The next `/drive` tick can claim it once that pull request merges.

## Planning session — bare `/mission`

Bare `/mission` opens a **working planning session**, not just a report. Its arc is fixed: status → replan loop → reconciliation → roadmap gaps → execution hand-off. This is the daytime half of the overnight model: `/mission` makes everything drive-ready, `/implement` executes it unattended. Read the whole roadmap once via `list.sh`; every field the session needs is computed there — `relation` (`mine`/`unassigned`/`others`), `next`, `merge_policy`, `ready`/`ready_reason` (`no_plan`/`not_active`) — **never re-derive any of them** from `assignees`/`status`/`checked` yourself.

**1. Status — weighted toward the caller** (most of the output is the caller's business; others' work stays visible but compact — de-emphasized, never hidden). **Every mission line names the strategy it belongs to** (2026-08-26) — read once, before rendering:

```bash
bash ../strategy/scripts/mission-strategy.sh
```

A mission the reader could attribute renders `— <strategy title> (<stage>)`; one it could not renders an explicit **`— no strategy`**, never a blank, because "belongs to no direction" and "could not be attributed" must not look alike. **The stage is the direction's declared phase** (2026-08-29, mission `make-a-direction-s-lifecycle-a-declared-stage`) — `進行中` / `改良中` / `観察中`, the operator's own word — read off the same `list.sh` row the roadmap already has, so it costs no extra read and goes **where the strategy already is** rather than as a new column, because this is a surface a person scans many rows of. A direction whose stage could not be read renders **`(stage unreadable)`**, never `進行中`: a default that hides a failed read is what the explicit `— no strategy` beside it already refuses. The attribution is **transitive and lossy** (`exhaustive: false`), so close the section with the honest line the reader supplies: how many missions could not be attributed, and any strategy named in `unreadable` — a direction that could not be read must never render as an absent one. **No mission gained a field**: this is `attributed-work.sh`'s own citation walk, inverted.

- **Full treatment** for the caller's **`mine` and `unassigned` in-flight** missions (mine first, then unassigned): `title` (`slug`) — `checked/total`, the `next` item, the drive-ready state (ready, or the `ready_reason` blocker), and the most recent few `## Changelog` lines from the entry's `path`. Mark an `unassigned` entry as unclaimed and claimable.
- **One line each — everything else** (`others`, and any archived mission), under a compact trailing section: `title` (`slug`) — `status` — `checked/total`. No changelog, no paragraphs.
- If no mission is `mine` or `unassigned`, say so plainly (only colleagues'/archived work exists) and that `/mission "<title>"` starts one; if the array is empty, there are no missions yet.

**2. Replan loop — make every assigned mission drive-ready.** For each `mine`/`unassigned` in-flight mission whose `ready` is `false`, run the **replan flow** above, one mission at a time, through a publish tree — never a worktree. The `ready_reason` says what is missing (`no_plan` → the interrogation must produce a plan and Acceptance). Interrogation asks **only genuine design rulings** (the decide-and-record bar); mechanical fixes are decided and recorded, not asked. The developer may **defer** a mission ("leave it") — record that and move on; do not re-raise it this session. An already-`ready` mission needs nothing here — say so and skip it.

**3. Reconciliation.** Close the loop with one honest line derived from the readers, never asserted: **`N/M assigned missions drive-ready`**, naming each mission left short and why — deferred by the developer, or blocked on a named ruling. This mirrors `/drive`'s honest-terminal shape.

**4. Roadmap gap discussion — are the missions sufficient?** Once every assigned mission is drive-ready, turn upward: does the roadmap cover what the accumulated direction asks for? Direction lives in the feedback stream — read it via:

```bash
bash ../feedback/scripts/list.sh
```

Unaddressed instructions and insights with no active mission or ticket advancing them are the gaps. The survey is act-and-report: run it unasked, and if nothing is unaddressed, say so in one sentence and move on — never pad the session. For each gap (or when the developer says the plan feels thin), open a short **discussion**, not automation: ground candidate next missions in the relevant feedback entries — including the `kind: concern` / `kind: insight` records an unattended `/drive` deferred, which are what the last runs said to front-load — and in the archived missions' outcomes. Propose concretely ("a mission that …") and let the developer shape or reject. An agreed candidate flows straight into the **create flow** above without leaving the conversation. **Never auto-create** a mission or ticket from the survey. An unassigned-but-active mission is *not* a gap — the signal is "nothing advancing it", not "no mine".

**5. Execution hand-off.** End by recommending **`/goal /implement ok`** as the way to execute the readied missions — long, unattended, at any hour. It surveys the unclaimed missions, claims each as a PR-unit, and drives it in the claim's own worktree, so there is nothing to point it at by hand; the `ok` token is what makes it loopable (`drive` §7).

## Close flow — `/mission-close <slug> [achieved|abandoned|carried]`

`$ARGUMENT` is the **slug of the mission to end**, and optionally the outcome; it selects no mode. With no slug, run `list.sh`, show the active missions, and stop — ending a mission is not something to guess the subject of.

**State the Mission Position Report first — always, before asking anything** (defined once in the SKILL; do not restate it), plus — when carrying — exactly what would move to the successor. A mission is the unit the developer reasons in; ending one without saying where it stands asks them to decide blind.

If the outcome is not stated in the argument, ask it (label-prefixed) — **three-way**, per the SKILL's *Outcomes*: `achieved`, `abandoned`, or `carried` (which requires `--successor <slug>`; `--successor-title` is **refused** by the ticket floor — create the successor through the ordinary `/mission` path first, since that interrogation is what emits its ticket set). If the mission's `## Acceptance` progress is not `total/total`, say so in the question body — unfinished criteria mean `abandoned` **or** `carried`, and the difference is whether the remainder is still worth doing. Do not let `carried` become a way to avoid saying `abandoned`: a successor nobody drives is an abandoned mission with a longer name. The developer decides.

Then run the shared mutator — never hand-edit `status:` or `mv` the directory — **inside a publish tree** (`open-publish-tree.sh`, then a `( cd <publish_path> && … )` subshell), publish the result with subject `Close mission <slug>`, and close the tree. The archive move is a mission write like any other; leaving it on the caller's checkout would reintroduce exactly the invisibility the publish model removes.

```bash
bash ../mission/scripts/close.sh "<slug>" <achieved|abandoned|carried> [--successor <slug>]
```

Report the JSON result:

- `closed: true` with `status: "carried"` — the JSON carries `successor` and `successor_path`. **Report where the mission landed and what carried**: the predecessor's final `checked/total`, the successor's slug and its **computed** progress (`0/<n unmet>`, from `progress.sh` — never a carried-across number), and the unmet criteria that moved. Say plainly how far a fresh session could take the successor: its Goal and gate came along, so it is drive-ready once it has tickets; it gets **no worktree** from the predecessor (the SKILL's *Outcomes*) and is fleshed out through the **replan flow** — say so rather than letting the developer assume in-flight state carried.
- `closed: true` — the mission is ended; report its final status and archived path.
- `closed: false` with `reason: "already_closed"` — already archived with that status; nothing changed.
- `closed: false` with `reason: "not_found"` — no such mission; run `list.sh` and show the available slugs.

**Close touches no worktree.** Worktrees are claim-born and ship-torn (the SKILL's *Worktree lifecycle*): a `.worktrees/<slug>` still standing after a close is an in-flight or stale **claim**, which `list-claims.sh` surfaces and a human decides about — say so rather than removing it here. Closing a mission is a statement about the record, and a bookkeeping action must not double as a destructive one.
