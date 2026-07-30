# Mission scripts — reference

Companion reference for [`../SKILL.md`](../SKILL.md)'s **Scripts** section, which carries the
index table. Below is each script's full contract — arguments, emitted JSON keys, idempotence,
and the design reasoning behind the ones that carry a ruling. Read the entry for a script before
running it; the table alone is a locator, not a contract.

```bash
bash ../mission/scripts/create.sh "<title>" [assignee]
```

Create a new mission: derive the slug from the title (via `slug.sh`), scaffold `.workaholic/missions/active/<slug>/mission.md` (frontmatter + the four empty sections), stamp `created_at`/`author` from the `gather` skill, seed `assignees` with the optional second argument or (default) the creator's `git config user.email` (the approver is the default owner), refresh the OKF bundle indexes, and git-stage. Refuses to overwrite an existing mission in either area. Emits `{created, slug, path}` JSON. (The `/mission` command runs this with a mission worktree as the working directory, so `mission.md` lands inside `.worktrees/<slug>/` — see the command's create flow.)

```bash
bash ../mission/scripts/slug.sh "<title>"
```

Derive a mission slug from a title (lowercase, non-`[a-z0-9]` runs → single hyphen, ends trimmed). The **single source of the slug rule** — both `create.sh` (the mission directory name) and the `/mission` worktree flow (the `.worktrees/<slug>` directory name) derive the slug here, so the worktree directory always matches the mission slug. Emits the slug on stdout (empty when the title has no `[a-z0-9]`).

```bash
bash ../mission/scripts/read-relation.sh <artifact-file>
```

Read an artifact's `mission:` relation; prints one slug per line, nothing when absent or empty. The **single source of the relation's shape** — every seam reads through this rather than parsing frontmatter itself. Accepts `mission: [a, b]` and a bare `mission: a` alike, and only ever looks inside the frontmatter block (a body line starting `mission:` is not the relation). Never fails: a missing file, a file with no frontmatter, and an empty field all print nothing. Note this reads a relation **on** an artifact — `mission.md`'s own fields (`title`/`status`/`gate_*`) are read by `list.sh`, `progress.sh`, and `gate.sh` instead.

```bash
bash ../mission/scripts/mission-owners.sh <mission-file>
```

Resolve **who owns a mission** — the single ownership oracle (2026-07-28). First non-empty tier wins: the mission's **own plural `assignees`** (via `mission/scripts/read-assignees.sh`, the single parser of the field shape), then a **legacy fallback** to the mission's own singular `assignee`, so a mission predating the plural field is never orphaned. Prints one owner per line; **empty output means unowned** (claimable). Every ownership consumer — `list.sh`'s `relation`, `summary.sh`, `hooks/mission-lens.sh`, `/drive`'s survey, `hooks/validate-mission.sh`'s authorized-owner floor, and `ship`'s concern-lane owner — reads through this, never by parsing the fields itself.

```bash
bash ../mission/scripts/read-assignees.sh <file>
```

Read a file's `assignees:` frontmatter field, one owner per line — **the single parser of the field shape** (inline-list `[a, b]` and bare-scalar forms; empty/absent prints nothing). Born on the strategy side (2026-07-24) and relocated here when ownership returned to the mission; `mission-owners.sh`'s primary tier reads through it.

```bash
bash ../mission/scripts/migrate-strategies.sh [workaholic-root]
```

Retire a lingering `.workaholic/strategies/` tree — the direct/test entry to the living migration every mission script also runs through `lib/resolve.sh`'s seam (`missions_migrate_strategies`; the logic lives there so the two entries cannot drift). Each strategy document survives **verbatim** as a feedback record (`feedbacks/<ts>-strategy-<slug>.md`, `kind: insight`, `source: discussion`, original author/`created_at` preserved; the timestamp derives from `created_at`, so the migration is deterministic and idempotent), its `assignees` fold down into each linked active mission whose own `assignees` is still empty, and then the directory is removed (`git rm` when tracked). Best-effort: a failure never blocks the calling seam. Nothing is deleted from knowledge, only from structure.

```bash
bash ../mission/scripts/approve.sh <mission-slug-or-file> <auto|review> [date]
```

**Approve a mission — the only sanctioned path to `status: approved`.** It clears the floor first, mutates only after: `## Experience` must carry non-comment content and `## Acceptance` at least one checklist item (the same floor `hooks/validate-mission.sh` enforces at write time, asserted here at the moment the authority is granted), and the mission must have an owner — an unowned one is **seeded with the approver** (`git config user.email`; decision B4: the approver is the default owner), refused only when there is no identity to seed. Then it sets `status: approved` and `merge_policy`, drops any legacy `drive_authorized` key still present, appends `mission approved — merge_policy: <p>` to the `## Changelog`, refreshes the OKF indexes, and git-stages. It never commits — the calling flow owns the commit seam.

The `merge_policy` argument is **required** and enum-validated (`auto` | `review`): it is the one genuinely human ruling this flow owns (decision G5), and neither default is honest (see *Merge policy* above). The history is appended **before** the status flip, so a mission that cannot record its own approval is refused rather than approved untraceably.

**Idempotent**: re-approving with the same policy is a no-op success (`reason: "already_approved"`); re-approving with a *different* policy records the change as its own changelog line, because the policy rides in the event id. Emits `{approved, slug, status, merge_policy, owners, path, reason}`; a refusal exits non-zero with `reason` one of `missing_args`, `invalid_merge_policy`, `not_found`, `not_in_flight` (the mission has ended — history is immutable), `no_owner`, `no_experience`, `no_plan`, `no_changelog_section`.

```bash
bash ../mission/scripts/drive-authorized.sh <ticket-file>
```

Answer, for one ticket: **is this ticket's queue pre-authorized?** (The unified `/drive` run applies this same floor one level up, to the mission it offers as a unit; the resolver stays the authority for any caller that needs a per-ticket answer.) Emits `{authorized, reason, missions}` — `reason` is `""` (authorized), `no_ticket`, `no_mission` (nothing authorized it), `mission_not_found`, `not_authorized` (a claimed mission is not `status: approved` — a draft, or an ended mission), or `no_plan` (a claimed mission is approved but its `## Acceptance` is empty — approval with no plan authorizes nothing; the floor is `progress.sh`'s `total > 0`). Reads the relation through `read-relation.sh`, so `mission: [a, b]` and a bare `mission: a` behave identically. A legacy `drive_authorized: true` stamp is still honored for the transition window, so a mission in a checkout the living migration has not touched is not de-authorized mid-drive; the JSON contract (including the `not_authorized` key) is unchanged, so `/drive` callers needed no change.

Missions get a write-time floor too: `hooks/validate-mission.sh` (PostToolUse `Write|Edit`, the mission analogue of `validate-ticket.sh`) lets a **draft** pass with **nothing required** (that is the scaffold moment, and `create.sh` scaffolds a draft by design), and — once a mission claims `status: approved` (or a legacy `drive_authorized: true`) — rejects a **missing owner** (`mission-owners.sh` empty — its own `assignees` and the legacy `assignee` both empty; unattended work needs an owner), a comment-only `## Experience`, or an empty `## Acceptance` at the write, where the author can still fix it. (A legacy `strategy:` key from the retired strategy layer is tolerated and ignored.) `archive/` missions are history and are never retro-blocked.

**Conservative by construction**: a ticket claiming several missions is authorized only if **every** one of them is approved. Naming a mission is a commitment, not a label — the same reason `/drive` holds a ticket to the gate of every mission it names ("all of them must pass, not the most convenient one"). One unapproved mission means ask.

This is a **script, not prose**, on purpose: the approval gate lived entirely in `drive/SKILL.md` prose, which is why it never carried a single assertion. A rule that decides whether work may run without a human has to be reproducible and testable.

```bash
bash ../mission/scripts/gate.sh <mission-slug-or-file>
```

Read the mission's **quality-gate** declaration (`gate_type`/`gate_target`/`gate_assert`) and resolve the mission worktree's ports the gate is checked against. Emits `{type, target, assert, valid, driveable, reason, slug, port_base, dev_port, docs_port}`.

`valid` and `driveable` answer **different questions**, and the distinction is the point:

- **`valid`** — the *declaration* is well-formed: `gate_type` is empty or one of `documentation`/`live-app`/`check`. It says nothing about whether the gate can be run.
- **`driveable`** — the gate can actually be *exercised*: one is declared **and** its worktree ports resolved (for `check`, the worktree itself exists — no port is involved). `reason` names why not — `no_gate` (none declared: the **normal** case, not an error) or `no_worktree` (declared, but no worktree to serve or run its target in).

`driveable` exists because `valid: true` with empty ports reported success for a gate that could not be addressed at all: a mission could declare a live gate, pass validation, and be silently unverifiable. The port fields are `""` when the mission has no worktree.

The ports are resolved from the **main checkout** (`git rev-parse --git-common-dir`, whose dirname is the main root), **not** `--show-toplevel`: a mission lives in its own `.worktrees/<slug>/` and `/drive` auto-routes there, so `--show-toplevel` returns the worktree and the lookup becomes `<worktree>/.worktrees/<slug>/.env` — a path nothing creates. That returned empty ports for every mission in the prescribed layout.

`/drive` surfaces this for a missioned ticket so the work is judged against the mission's gate when one is declared; the live check runs the project's server on `dev_port` and drives `target` with the Playwright plugin.

```bash
bash ../mission/scripts/progress.sh <mission-file-or-slug>
```

Compute `{checked, total}` over a mission's `## Acceptance` checklist. Accepts either a path to `mission.md` or a bare slug.

```bash
bash ../mission/scripts/list.sh
```

List every mission — across both `active/` and `archive/` — with its `status`, recorded `merge_policy`, derived ownership, computed progress, and its `predicted_hours`/`actual_hours`: a JSON array of `{slug, title, status, merge_policy, assignee, owners, relation, next, checked, total, ready, ready_reason, predicted_hours, actual_hours, path}`, sorted by slug (`path` is the resolved `mission.md` location, so consumers never rebuild it by hand). Emits `[]` when there are no missions. `owners` is the full owner set (`mission-owners.sh` — the mission's own `assignees` first, then the legacy `assignee`), `assignee` aliases the first owner for back-compat, and `relation` is the caller-centric partition (`mine` / `unassigned` / `others` — the same "not somebody else's" gate `summary.sh`, the lens, and `/drive`'s survey read, all through `mission-owners.sh`, computed once here so consumers never re-derive it; a missing git email degrades to nothing-`mine`, never an error). `next` is the first unchecked acceptance item via `next-acceptance.sh`. `ready`/`ready_reason` are the **planning-session drive-readiness verdict**, keyed on the one status axis: `ready: true` when the mission is `approved` and has a plan (`total > 0`); otherwise `ready: false` with `ready_reason` naming the blocker — `draft` (awaiting approval: an approval target, not a replan target), `no_plan` (empty `## Acceptance`), or `not_active` (an ended mission) — so the bare `/mission` session can explain what is missing. The retired `not_authorized` reason is gone: an unapproved mission *is* a draft. Together these let the bare `/mission` view render its two tiers and drive its replan loop with **no inline logic**. All keys are additive; older consumers parse a subset and are unaffected.

```bash
bash ../mission/scripts/summary.sh
```

Summarize the **current user's assigned active** missions (read-only). The `/mission summary` command mode this once powered is **retired** (2026-07-22 — the bare `/mission` view is developer-centric now, rendered from `list.sh`'s `relation` partition, so a my-business-only mode became a near-duplicate); the script stays because it is the **canonical statement of the shared assignee gate** — "not somebody else's": mine first, then unassigned/claimable, colleagues excluded — which the mission lens and `/drive`'s survey both answer to, and its business-set output still serves programmatic callers. **Its bar is deliberately lower than the mission lens's** (assignee alone — no location or signal gate), because the lens speaks unasked while this output is read on request: an unfilled `0/0` mission shows here (and in the bare view's full tier) that the lens stays silent about. Emits a JSON array `[{slug, title, checked, total, next, path}]` sorted by slug, or `[]` when no active mission is assigned to the current user. Reuses `progress.sh` and `next-acceptance.sh`, so the ownership and progress rules stay defined once. Mutates nothing.

```bash
bash ../mission/scripts/next-acceptance.sh <mission-slug-or-file>
```

Emit the display text of the mission's **first unchecked** `## Acceptance` item — the next criterion on the road to achievement — with its trailing `(#<filename>)` marker stripped. Scoped to the `## Acceptance` section with the same checklist convention as `progress.sh`. Prints nothing when every item is checked or the section is empty. The mission lens uses it to show "next: …" alongside `checked/total`.

```bash
bash ../mission/scripts/append-changelog.sh <mission-slug-or-file> <event> <artifact-filename> [date]
```

Append one dated line to a mission's `## Changelog`. **The single writer of changelog lines** — every workflow seam calls it rather than hand-editing `mission.md`. Append-only and **idempotent**: the `(event, artifact)` pair is the stable event id, so re-running for the same event never duplicates a line. Git-stages the mission file. Standard events: `ticket archived` (drive), `story reported` (report), `concern deferred (stuck)` (ship), `concern resolved (unstuck)` (report), `mission achieved` / `mission abandoned` / `mission carried into <successor-slug>` (close.sh), `ticket added` / `mission replanned` / `acceptance dropped` (replan).

```bash
bash ../mission/scripts/tick-acceptance.sh <mission-slug-or-file> <artifact-filename>
```

Flip the `## Acceptance` item whose `(#<artifact-filename>)` marker matches from `- [ ]` to `- [x]`. Idempotent (an already-checked or unmatched item is a no-op) and scoped to the `## Acceptance` section. Progress stays derived — this changes only checklist state; `progress.sh` recomputes `checked/total`. Git-stages the mission file.

```bash
bash ../mission/scripts/predict-duration.sh <planned-item-count>
```

Predict a mission's agent-hours **deterministically** from archived-mission trend: `median(actual_hours ÷ acceptance-item total)` across archived missions carrying both, times the planned item count. Emits `{predicted_hours, basis, per_item_median}` — `predicted_hours: null` and `basis: 0` when no archived mission has both fields, so the create flow states confidence honestly instead of dressing a guess as data. **Pure read; writes nothing.** Called once at the end of the Creation Interrogation's emission.

```bash
bash ../mission/scripts/record-run-hours.sh <mission-slug-or-file> <hours> <run-id>
```

Accumulate a `/drive` run's agent-hours into `actual_hours` (float add), **idempotently per run-id** — a run already recorded (its `run recorded (+Xh) — <run-id>` changelog line present) adds nothing, so a crash-recovery re-run is safe. The changelog line carries the increment so the sum reconstructs from history. **This is the only writer of `actual_hours`** (same doctrine as `tick-acceptance.sh`; never hand-edited). Emits `{recorded, actual_hours, run_id, path}`.

```bash
bash ../mission/scripts/list-related-prs.sh <slug>
```

List OPEN pull requests referencing a mission slug (slug present in a PR's title or body — a mission-linked story names the mission; `work-*` branch names do not), so the **Replan** flow can see a sibling lane's in-flight, not-yet-merged work before emitting duplicate delta tickets. Emits `{slug, available, prs:[{number, title, url, headRefName}]}`. **Read-only, best-effort**: `available: false` (empty `prs`) when `gh` is missing/unauthenticated or the repo has no usable remote — *unknown*, not *no siblings*, so a replan is never blocked by tooling. Complements `create-mission-worktree.sh`'s fetch-first base resolution (that guards a new worktree's *merged* base; this guards a replan against a sibling's *unmerged* work).

```bash
bash ../mission/scripts/close.sh <mission-slug-or-file> <achieved|abandoned|carried> [date] \
  [--successor-title "<title>" | --successor <slug>]
```

End a mission — the only sanctioned way. Flips `status`, appends the closing changelog line through `append-changelog.sh` so the transition itself becomes history (`design` / `history-structures`), moves the mission dir into `archive/`, refreshes the OKF indexes, and git-stages. Idempotent: re-closing with the same status is a no-op (`{closed: false, reason: "already_closed"}`); re-closing with another status flips it in place and appends its own line. Emits `{closed, slug, status, path}` JSON (plus `successor` / `successor_path` on a carry).

**Completion lifecycle — "merge and clean up" is a chain, and only one link may be automatic.** When a mission's tickets are all done, it moves through four stages, each with a distinct owner: **complete** (`## Acceptance` fully checked per `progress.sh`, gate exercised when declared) → **PR** (opened by `/drive` §5 from the claim worktree's branch — auto-*creation*, so the morning starts at review) → **merge** (`/ship`, deploy-evidence-gated) → **`/mission close`** (archives the mission). The merge is automatic only where the mission's `merge_policy` says `auto`, which a human recorded at approval; absent that ruling it stays a human decision on evidence, and the PR is where a night's work becomes reviewable. A blanket auto-merge was rejected outright — it would bypass PR review and the deploy-before-merge doctrine.
