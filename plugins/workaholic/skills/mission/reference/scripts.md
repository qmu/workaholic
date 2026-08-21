# Mission scripts — reference

Companion reference for [`../SKILL.md`](../SKILL.md)'s **Scripts** section, which carries the
index table. Below is each script's full contract — arguments, emitted JSON keys, idempotence,
and the design reasoning behind the ones that carry a ruling. Read the entry for a script before
running it; the table alone is a locator, not a contract.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/create.sh "<title>" [assignee]
```

Create a new mission: derive the slug from the title (via `slug.sh`), scaffold `.workaholic/missions/active/<slug>/mission.md` (frontmatter + the four empty sections), stamp `created_at`/`author` from the `gather` skill, seed `assignees` with the optional second argument or (default) the creator's `git config user.email`, record `merge_policy` from the optional third argument (`auto` | `review`; **absent is written empty and reads as `review`** — K2 — and an unrecognized value is refused `bad_merge_policy`), refresh the OKF bundle indexes, and git-stage. The mission is born `status: active`: there is no draft state, because merging its pull request is the approval (K1). Refuses to overwrite an existing mission in either area. Emits `{created, slug, path}` JSON. (The `/mission` command runs this with a **publish tree** as the working directory, so `mission.md` lands there and is pushed to `main` in the creation batch's single commit — see the command's create flow. Nothing about the script changes; only the caller's `cd` target does.)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/slug.sh "<title>"
```

Derive a mission slug from a title (lowercase, non-`[a-z0-9]` runs → single hyphen, ends trimmed). The **single source of the slug rule** — both `create.sh` (the mission directory name) and the claim protocol (the `.worktrees/<slug>` directory name, minted by `claim.sh`) derive the slug here, so a mission's claim worktree always matches its mission slug. Emits the slug on stdout (empty when the title has no `[a-z0-9]`).

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/read-relation.sh <artifact-file>
```

Read an artifact's `mission:` relation; prints one slug per line, nothing when absent or empty. The **single source of the relation's shape** — every seam reads through this rather than parsing frontmatter itself. Accepts `mission: [a, b]` and a bare `mission: a` alike, and only ever looks inside the frontmatter block (a body line starting `mission:` is not the relation). Never fails: a missing file, a file with no frontmatter, and an empty field all print nothing. Note this reads a relation **on** an artifact — `mission.md`'s own fields (`title`/`status`/`gate_*`) are read by `list.sh`, `progress.sh`, and `gate.sh` instead.

**Ownership is no longer a mission script.** `mission-owners.sh` and
`read-assignees.sh` moved to `gather/` on 2026-08-06 (P2) and became
`gather/scripts/owners.sh`, `gather/scripts/owns.sh` and
`gather/scripts/read-assignees.sh` — one oracle for every artifact kind, because a
**ticket** now carries its owners in the same `assignees` field a mission does
instead of in its directory. The resolution order, the legacy `assignee` fallback,
and "empty means unowned/claimable" are unchanged in substance; see
`workaholic:gather`, *Ownership — who an artifact belongs to*. A mission still reads
its owners exactly as before, through that one reader:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/owners.sh <mission-file>
```

### `migrate-strategies.sh` — retired 2026-08-13

**There is no strategy-erasing migration.** From 2026-07-28 to 2026-08-13 this script (and the `missions_migrate_strategies` seam in `lib/resolve.sh` that every mission script ran) folded a lingering `.workaholic/strategies/` tree into feedback records and removed the directory. The strategy artifact was re-introduced on 2026-08-13 with a bounded, dated, owned shape (`workaholic:strategy`), so a migration that erases `strategies/` on the next mission-script touch would delete the live area. Both the script and the seam are gone; the folding it already performed stands in history and nothing reverses it. Do not re-add it — an erasing living migration and a live artifact area cannot share a directory. A consuming repository still holding the *legacy nested* shape (`strategies/<area>/<slug>/strategy.md`) is **reported** by `/workaholify`'s layout convergence, never erased by it.

### `approve.sh` — retired 2026-07-31

**There is no approval script, and no `/mission approve` subcommand** (`docs/loop-engineering-workflow.md` K2). Merging a mission's pull request is its approval, so the flip it performed has nothing left to flip. Its three payloads went to three different places, and a reader looking for one of them should go there:

- **`merge_policy`** → recorded at **creation**: `create.sh`'s optional third argument, empty from `scaffold-draft.sh`. **Absent means `review`**, exactly as on a ticket.
- **Ownership seeding** → **dropped**. An unowned mission is claimable by anyone.
- **The Experience / Acceptance floor** → **kept**, in `hooks/validate-mission.sh`, re-aimed from `status: approved` onto any mission under `missions/active/`.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/drive-authorized.sh <ticket-file>
```

Answer, for one ticket: **is this ticket's queue pre-authorized?** (The unified `/drive` run applies this same floor one level up, to the mission it offers as a unit; the resolver stays the authority for any caller that needs a per-ticket answer.) Emits `{authorized, reason, missions}` — `reason` is `""` (authorized), `no_ticket`, `no_mission` (nothing authorized it), `mission_not_found`, `not_active` (a claimed mission has **ended** — `achieved`/`abandoned`/`carried`; history authorizes nothing), or `no_plan` (a claimed mission is in flight but its `## Acceptance` is empty — a mission with no plan authorizes nothing; the floor is `progress.sh`'s `total > 0`). Reads the relation through `read-relation.sh`, so `mission: [a, b]` and a bare `mission: a` behave identically. **`not_active` replaces the retired `not_authorized`** (K1): that reason meant "not `status: approved`", which stopped being a distinguishable state once `draft` was retired. Every in-flight spelling passes — `active`, and the retired `draft`/`approved` in a checkout the living migration has not rewritten — so nothing is de-authorized mid-drive.

Missions get a write-time floor too: `hooks/validate-mission.sh` (PostToolUse `Write|Edit`, the mission analogue of `validate-ticket.sh`) rejects a comment-only `## Experience` or an empty `## Acceptance` at the write, where the author can still fix it. **It fires on any mission under `missions/active/`** — the area, not a status word, because since K1 nothing marks "the thing that can be claimed" (an end state written into `active/` is exempt: that is a placement problem for `close.sh`, not a claimable mission). **Ownership is not checked** (K2): an unowned mission is claimable by anyone, and `/specificate` writes unowned proposals by design. A legacy `strategy:` key from the retired strategy layer is tolerated and ignored. `archive/` missions are history and are never retro-blocked. Practical consequence: an agent editing an active mission must land the Experience and Acceptance content in that write — the scaffold writers use a shell heredoc, which this hook never sees.

**Conservative by construction**: a ticket claiming several missions is authorized only if **every** one of them passes. Naming a mission is a commitment, not a label — the same reason `/drive` holds a ticket to the gate of every mission it names ("all of them must pass, not the most convenient one"). One ended or planless mission refuses the whole ticket.

This is a **script, not prose**, on purpose: the approval gate lived entirely in `drive/SKILL.md` prose, which is why it never carried a single assertion. A rule that decides whether work may run without a human has to be reproducible and testable.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/gate.sh <mission-slug-or-file>
```

Read the mission's **quality-gate** declaration (`gate_type`/`gate_target`/`gate_assert`) and resolve the mission worktree's ports the gate is checked against. Emits `{type, target, assert, valid, driveable, reason, slug, port_base, dev_port, docs_port}`.

`valid` and `driveable` answer **different questions**, and the distinction is the point:

- **`valid`** — the *declaration* is well-formed: `gate_type` is empty or one of `documentation`/`live-app`/`check`. It says nothing about whether the gate can be run.
- **`driveable`** — the gate can actually be *exercised*: one is declared **and** its worktree ports resolved (for `check`, the worktree itself exists — no port is involved). `reason` names why not — `no_gate` (none declared: the **normal** case, not an error) or `no_worktree` (declared, but no worktree to serve or run its target in). Since J1 an *unclaimed* mission owns no worktree at all, so `no_worktree` is the expected answer until `/drive` claims it — the gate becomes driveable inside the claim, which is where it is exercised anyway.

`driveable` exists because `valid: true` with empty ports reported success for a gate that could not be addressed at all: a mission could declare a live gate, pass validation, and be silently unverifiable. The port fields are `""` when the mission has no worktree.

The ports are resolved from the **main checkout** (`git rev-parse --git-common-dir`, whose dirname is the main root), **not** `--show-toplevel`: a mission lives in its own `.worktrees/<slug>/` and `/drive` auto-routes there, so `--show-toplevel` returns the worktree and the lookup becomes `<worktree>/.worktrees/<slug>/.env` — a path nothing creates. That returned empty ports for every mission in the prescribed layout.

`/drive` surfaces this for a missioned ticket so the work is judged against the mission's gate when one is declared; the live check runs the project's server on `dev_port` and drives `target` with the Playwright plugin.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/progress.sh <mission-file-or-slug>
```

Compute `{checked, total}` over a mission's `## Acceptance` checklist. Accepts either a path to `mission.md` or a bare slug.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/list.sh
```

List every mission — across both `active/` and `archive/` — with its `status`, recorded `merge_policy`, derived ownership, computed progress, and its `predicted_hours`/`actual_hours`: a JSON array of `{slug, title, status, merge_policy, assignee, owners, relation, next, checked, total, ready, ready_reason, predicted_hours, actual_hours, path}`, sorted by slug (`path` is the resolved `mission.md` location, so consumers never rebuild it by hand). Emits `[]` when there are no missions. `owners` is the full owner set (`gather/scripts/owners.sh` — the mission's own `assignees` first, then the legacy `assignee`), `assignee` aliases the first owner for back-compat, and `relation` is the caller-centric partition (`mine` / `unassigned` / `others` — the same "not somebody else's" gate `summary.sh`, the lens, and `/drive`'s survey read, all through `gather/scripts/owners.sh`, computed once here so consumers never re-derive it; a missing git email degrades to nothing-`mine`, never an error). `next` is the first unchecked acceptance item via `next-acceptance.sh`. `ready`/`ready_reason` are the **planning-session drive-readiness verdict**: `ready: true` when the mission is in flight and has a plan (`total > 0`); otherwise `ready: false` with `ready_reason` naming the blocker — `no_plan` (empty `## Acceptance`) or `not_active` (an ended mission) — so the bare `/mission` session can explain what is missing. The retired `draft` reason is gone with the state itself (K1), as `not_authorized` went before it. Together these let the bare `/mission` view render its two tiers and drive its replan loop with **no inline logic**. All keys are additive; older consumers parse a subset and are unaffected.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/summary.sh
```

Summarize the **current user's assigned active** missions (read-only). The `/mission summary` command mode this once powered is **retired** (2026-07-22 — the bare `/mission` view is developer-centric now, rendered from `list.sh`'s `relation` partition, so a my-business-only mode became a near-duplicate); the script stays because it is the **canonical statement of the shared assignee gate** — "not somebody else's": mine first, then unassigned/claimable, colleagues excluded — which the mission lens and `/drive`'s survey both answer to, and its business-set output still serves programmatic callers. **Its bar is deliberately lower than the mission lens's** (assignee alone — no location or signal gate), because the lens speaks unasked while this output is read on request: an unfilled `0/0` mission shows here (and in the bare view's full tier) that the lens stays silent about. Emits a JSON array `[{slug, title, checked, total, next, path}]` sorted by slug, or `[]` when no active mission is assigned to the current user. Reuses `progress.sh` and `next-acceptance.sh`, so the ownership and progress rules stay defined once. Mutates nothing.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/next-acceptance.sh <mission-slug-or-file>
```

Emit the display text of the mission's **first unchecked** `## Acceptance` item — the next criterion on the road to achievement — with its trailing `(#<filename>)` marker stripped. Scoped to the `## Acceptance` section with the same checklist convention as `progress.sh`. Prints nothing when every item is checked or the section is empty. The mission lens uses it to show "next: …" alongside `checked/total`.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/append-changelog.sh <mission-slug-or-file> <event> <artifact-filename> [date]
```

Append one dated line to a mission's `## Changelog`. **The single writer of changelog lines** — every workflow seam calls it rather than hand-editing `mission.md`. Append-only and **idempotent**: the `(event, artifact)` pair is the stable event id, so re-running for the same event never duplicates a line. Git-stages the mission file. Standard events: `ticket archived` (drive), `story reported` (report), `concern deferred (stuck)` (ship), `concern resolved (unstuck)` (report), `mission achieved` / `mission abandoned` / `mission carried into <successor-slug>` (close.sh), `ticket added` / `mission replanned` / `acceptance dropped` (replan).

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/link-acceptance.sh <mission-slug-or-file> <selector> <artifact-filename>
```

Stamp the `(#<artifact-filename>)` link onto one `## Acceptance` item — **the only writer of an acceptance link**, and the step every ticket-emitting seam runs (Creation Interrogation and replan alike). `<selector>` is the item's 1-based position in `## Acceptance`, or a substring matching exactly one item. **The pairing is the caller's and is never inferred**: a link guessed by title similarity or position would eventually check a box the work did not satisfy. Item text is preserved byte-for-byte and the marker lands at the end of the item's **last** line, so a wrapped criterion links exactly like a one-line one. Idempotent — re-linking the same item to the same artifact reports `already_linked` and exits 0. Emits `{linked, path, index, artifact[, reason]}`; the refusals (`no_match`, `ambiguous`, and `linked_to_other` — re-pointing a link is a plan change that belongs in a replan) print on stdout and exit 1. Git-stages the mission file.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/tick-acceptance.sh <mission-slug-or-file> <artifact-filename>
```

Flip the `## Acceptance` item whose `(#<artifact-filename>)` marker matches from `- [ ]` to `- [x]`. The match is **item-scoped**: the marker counts wherever it sits in the item, including a wrapped continuation line. Idempotent (an already-checked or unmatched item is a no-op) and scoped to the `## Acceptance` section. Progress stays derived — this changes only checklist state; `progress.sh` recomputes `checked/total`. Git-stages the mission file.

Its `reason` separates the three answers a caller must not confuse: `already_checked` (an item this artifact links to is satisfied already), `unlinked_items` — **not addressable**, the board carries unchecked items with no link at all, so no artifact could tick them — and `no_unchecked_match`, which now means only **not satisfied** (the open items are linked; this artifact does not satisfy one). The JSON carries `unlinked` on every call, so a seam reports the stranded count without a second read.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/unlinked-acceptance.sh [<mission-slug-or-file>]
```

Name the **unchecked, unlinked** acceptance items — the ones no artifact can ever tick. Pure read. With a mission argument it reports that mission; with none it sweeps every mission in the active area, which is the repo-wide measurement (37 items across six missions on 2026-08-03, every one proposal-scaffolded). Emits `[{slug, path, items: [{index, text}]}]`, omitting missions with nothing unlinked — so `[]` means a clean tree. Each `index` is exactly `link-acceptance.sh`'s selector, which is what makes a stranded board repairable by script rather than by hand.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/predict-duration.sh <planned-item-count>
```

Predict a mission's agent-hours **deterministically** from archived-mission trend: `median(actual_hours ÷ acceptance-item total)` across archived missions carrying both, times the planned item count. Emits `{predicted_hours, basis, per_item_median}` — `predicted_hours: null` and `basis: 0` when no archived mission has both fields, so the create flow states confidence honestly instead of dressing a guess as data. **Pure read; writes nothing.** Called once at the end of the Creation Interrogation's emission.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/record-run-hours.sh <mission-slug-or-file> <hours> <run-id>
```

Accumulate a `/drive` run's agent-hours into `actual_hours` (float add), **idempotently per run-id** — a run already recorded (its `run recorded (+Xh) — <run-id>` changelog line present) adds nothing, so a crash-recovery re-run is safe. The changelog line carries the increment so the sum reconstructs from history. **This is the only writer of `actual_hours`** (same doctrine as `tick-acceptance.sh`; never hand-edited). Emits `{recorded, actual_hours, run_id, path}`.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/list-related-prs.sh <slug>
```

List OPEN pull requests referencing a mission slug (slug present in a PR's title or body — a mission-linked story names the mission; `work-*` branch names do not), so the **Replan** flow can see a sibling lane's in-flight, not-yet-merged work before emitting duplicate delta tickets. Emits `{slug, available, prs:[{number, title, url, headRefName}]}`. **Read-only, best-effort**: `available: false` (empty `prs`) when `gh` is missing/unauthenticated or the repo has no usable remote — *unknown*, not *no siblings*, so a replan is never blocked by tooling. Complements the publish tree's fetch-first base (that guards a replan against a stale `main`; this guards it against a sibling's *unmerged* work).

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/close.sh <mission-slug-or-file> <achieved|abandoned|carried> [date] \
  [--successor <slug>]
```

End a mission — the only sanctioned way. Flips `status`, appends the closing changelog line through `append-changelog.sh` so the transition itself becomes history (`workaholic:design` / `history-structures`), moves the mission dir into `archive/`, refreshes the OKF indexes, and git-stages. Idempotent: re-closing with the same status is a no-op (`{closed: false, reason: "already_closed"}`); re-closing with another status flips it in place and appends its own line. Emits `{closed, slug, status, path}` JSON (plus `successor` / `successor_path` on a carry).

**Completion lifecycle — "merge and clean up" is a chain, and only one link may be automatic.** When a mission's tickets are all done, it moves through four stages, each with a distinct owner: **complete** (`## Acceptance` fully checked per `progress.sh`, gate exercised when declared) → **PR** (opened by `/drive` §5 from the claim worktree's branch — auto-*creation*, so the morning starts at review) → **merge** (`/ship`, deploy-evidence-gated) → **`/mission-close`** (archives the mission). The merge is automatic only where the mission's `merge_policy` says `auto`, which a human recorded at approval; absent that ruling it stays a human decision on evidence, and the PR is where a night's work becomes reviewable. A blanket auto-merge was rejected outright — it would bypass PR review and the deploy-before-merge doctrine.
