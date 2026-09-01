# Driving a single ticket — reference

Companion to [`../SKILL.md`](../SKILL.md) §4 and its **Workflow** section: ordering, the
per-ticket steps, the Final Report format, and the archive seam.

## Ordering within a unit

Once a unit is claimed, its tickets are driven in a considered order — derivation, not a decision
to confirm: the order is **reported, never asked**. List the queue from inside the worktree:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/list-todo.sh
```

For each ticket read the frontmatter `depends_on` plus its Key Files, and order by precedence:

1. **Dependency ordering** — topologically sort the `depends_on` graph. On a cycle, warn in the
   report and fall back to queue order (filename timestamp) for the cycled tickets.
2. **Context grouping** — tickets touching the same files/subsystem run together.
3. **Implicit dependencies** — if A modifies files B reads, A first.

Missing metadata is fine: empty `depends_on` means no dependencies; unordered tickets keep queue
order. (The retired `type`/`layer` fields played a grouping role until 2026-08-07; a grandfathered
ticket carrying them gets no special treatment.) On Claude Code the ordering may be delegated to a
`general-purpose` subagent (preloading `workaholic:drive`, returning
`{tickets[], tiers{}, cycle_warning}`); inline is equally correct and the default elsewhere.

**Converge the queue layout first**, so a checkout still carrying legacy per-user ticket
directories flattens before anything reads or writes it:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/migrate-todo-owners.sh
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/migrate-ticket-states.sh
```

The first moves `todo/<user-slug>/X.md` to `todo/X.md`, stamps `assignees` from the directory, and
git-stages each move (they ride into the next archive commit).

The second folds the retired `tickets/abandoned/` and `tickets/icebox/` directories into
`archive/unbranched/`, carrying the state in frontmatter (`status: abandoned` / `status: icebox`)
instead of in a path (2026-08-13, issue #436). It never touches the body, never touches a ticket
that already carries a `status:`, and is a clean no-op in a repository that never had either
directory — so a second run reports `migrated: 0`.

Both are convergent, never gates: every reader tolerates both layouts, so a checkout that has not
run them is never blocked.

### The icebox is a state, not a place

`list-icebox.sh` reads `status: icebox` out of the archive **and** the retired directory, and
`promote-icebox.sh` clears the field when it moves a ticket back to `todo/` (absent means queued,
so a promoted ticket carrying the stamp would be silently refused by every survey). The icebox
survives as a state distinct from `abandoned` on purpose: iceboxed is **deferred and promotable**,
abandoned is **decided against**.

### The icebox is developer-curated

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/list-icebox.sh
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/promote-icebox.sh <icebox-path>
```

The unified run **never** reads the icebox for work, never promotes from it, and never moves
anything into it. A ticket is in the icebox because a developer put it there; these scripts serve
that developer's act on request. Automating either direction would let a run quietly change what
the project has decided to defer.

## Per-ticket steps

### 0. Beat the heartbeat

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/heartbeat.sh <unit-id>
```

**The first act of every ticket, before reading it** (2026-08-31, ticket `20260831150500`). The
heartbeat is the branch tip and the resume gate is
`WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES`, **default 30** — not the 24-hour
`WORKAHOLIC_CLAIM_STALE_HOURS`, which is the *reported* staleness and governs nothing here.
`archive.sh` beats for free, but only at the **end** of a ticket, so a unit of several short
tickets never lapses and a unit that is **one long ticket** runs its whole implementation on the
claim commit's own timestamp.

**Measured on `batch-20260831141002`**: claimed at 14:10:27, implementation and its hermetic rows
finished around 14:55, and the push was rejected non-fast-forward because a second `[Implement]`
tick had resumed the claim at **14:43:13** — 33 minutes in, against a 30-minute window. The
protocol worked exactly as designed; the driving run was the non-conformant part. The losing run
stood down rather than force-pushing over an actively-driven branch, so a complete, validated,
locally-committed implementation was thrown away and re-driven from the top.

**Why a step and not a cadence.** §4 of `workaholic:drive` said "roughly every ten minutes or once
per ticket", and those coincide only for short tickets. A cadence is something an agent must track
*while its attention is on the implementation*; a step is discharged at a moment the workflow
already stops at. Two alternatives were considered and refused. **A beat inside an existing
per-ticket seam**: the only one that runs early is `gather/scripts/ticket-metadata.sh`, a **pure
reader shared with other callers**, and giving a reader a side effect is how a script acquires
behaviour nobody expects. **Making the loss visible instead**: a reading that says the claim was
taken does not return the work — the measured cost was a finished implementation discarded, and
naming it afterwards recovers none of it.

**Never a background timer.** Nothing in this loop runs concurrently with the agent's own work, and
a script beating on a schedule would be a second liveness authority beside the branch tip, which is
the one oracle (`reference/claims.md`).

A failed beat is **reported, never fatal** — the branch tip is a liveness signal, not a gate — and
the beat adds no store, no cursor and no field on any artifact: it is the empty commit
`heartbeat.sh` already makes against a scratch index.

### 1. Read and understand the ticket

- Read the ticket: requirements, Key Files, implementation steps.
- **If the ticket carries a non-empty `## Open Decisions` section** (`workaholic:specificate`,
  *Open decisions* — mainly a `/specificate`-emitted ticket, since `/ticket` resolves the
  same kind of fork by asking a human directly), resolve each item explicitly before
  implementing it and record the resolution and its reasoning in the Final Report. An
  item this session cannot resolve with reasoning it can defend is not a silent guess —
  it is a named blocker under the failure contract (`blocked` or `handoff`), never
  resolved by picking a side without saying so.

  **An Open Decision is a question to answer, not a ruling that the question is
  unanswerable** (2026-08-23). Before a run may honour one as a blocker it must **read the
  sources the item is about**: the documents, files and prior decisions the item names, and
  **the whole of any page it cites**, not the paragraph the item quotes. The requirement is
  scoped to exactly that — it is not "read everything", and an item naming no source at all
  is a defect in the item rather than a licence to skip the read.

  **A block reached through an Open Decision must state what those sources said** — which
  were read, and why they did not answer the item — in the run report and in the `blocked`
  finish. **A block that cannot name a source it read is not a block.**

  Why the rule needed adding: an Open Decision written by an earlier automated seam was
  **self-certifying**. `/specificate` declared an item unresolvable and the driving run took
  that declaration as evidence rather than as a claim to check — and the failure contract's
  own words ("Decide it from the evidence and the stated intent"; "if you cannot name which
  of those you are missing, you are not blocked on the developer; you are declining to
  decide") were satisfied on their face, because a session can name an authority without
  ever having read the sources. Measured: a tick honoured an item whose answer sat fifty
  lines further down the very page the ticket named, recorded the unit `blocked` without an
  attempt, and ended `pending`; on a consuming repository that shape cost eleven consecutive
  ticks and 2.1 agent-hours for zero lines of implementation, and the answer had been in the
  operator's own record since the day before.

  This is a **prose contract, not a script gate**, deliberately: no mechanical check can
  tell a real read from a claimed one. What it buys is that a blocked report naming no
  source is visibly non-conformant, by the contract's own words.
- **Read its `## Policies` section** — the recorded list of engineering policies this ticket
  answers to. Step 3 opens each named `policies/<slug>.md` before writing code.
- **Read its `## Quality Gate` section** (if present) — the developer-agreed acceptance criteria
  and verification, captured at `/ticket` time. Implement *to* this gate, run its verification
  before archiving, and carry its criteria into the Step 4 return and the archive `<verify>` arg.
- **If the ticket carries a `mission:` relation, read the quality gate of EVERY mission it
  names** — `bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/gate.sh <mission-slug>` once per
  slug (the relation is a list; a bare scalar is one). A mission gate is optional and normally
  absent — the mission's substance is its `## Experience` plus the ticket plan. When declared:
  `type: documentation` / `live-app` → run the project's dev/docs server on the worktree's
  `dev_port` and drive `target` with the Playwright plugin to check `assert`; `type: check` → run
  `target` as a command in the worktree, exit 0. When none — the common case — judge the change
  against the `## Experience` behavior instead. **All named missions' gates must pass, not the
  most convenient one** — naming a mission is a commitment; if the change cannot meet one
  mission's gate, drop that mission from the relation, don't skip its gate. This is about gates,
  not placement: the relation is many-valued, execution stays single-homed in one worktree.

### 2. Apply patches (if present)

For each patch in a `## Patches` section: write it to a temp file, validate with
`git apply --check`, apply with `git apply`, clean up. Report which applied; proceed manually for
failures. No section → skip.

### 3. Implement

- **Load the policy lens first** (when the standards plugin is installed): both entry points
  preload `workaholic:design` / `workaholic:implementation` / `workaholic:operation`. Open every
  hard copy the ticket's `## Policies` lists and judge the change's design, implementation, and
  operation against each policy's Goal / Responsibility / Practices. (A ticket predating the
  section gets the two always-apply implementation policies: `directory-structure`,
  `coding-standards`.)
- Follow the ticket's implementation steps; use existing patterns; run the project's checks (per
  CLAUDE.md) and fix failures before proceeding.

### 4. Return summary (DO NOT COMMIT)

```json
{
  "status": "implemented",
  "ticket_path": "<path to ticket>",
  "title": "<Title from H1>",
  "overview": "<Summary from Overview section>",
  "changes": ["<Change 1>", "..."],
  "quality_gate": "<criteria + what passed + the verification you ran — omit if no Quality Gate>",
  "repo_url": "<repository URL>"
}
```

Then append the Final Report and archive (below).

## System safety

Before implementation, check whether the repository authorizes system-wide configuration changes:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/system-safety/scripts/detect.sh
```

`system_changes_authorized: false` → the system-safety skill's prohibited-operations list applies
unconditionally (no global packages, shell profiles, `/etc/`, system services, `sudo`); use its
Safe Alternatives, or record the ticket `blocked` naming the operation. `true` → the repository is
a provisioning repository and system changes are permitted.

## Prohibited git operations

This repository may have multiple contributors working concurrently; uncommitted changes may not
be yours. **NEVER** run during implementation:

| Command | Risk | Alternative |
|---------|------|-------------|
| `git clean` | Deletes untracked files that may belong to others | Do not use |
| `git checkout .` / `git restore .` | Discards all uncommitted changes including others' work | Targeted checkout of files you modified |
| `git reset --hard` | Discards all uncommitted changes and resets HEAD | Do not use |
| `git stash drop` | Permanently deletes stashed changes | Only with explicit user request |

Check `git status` before any operation that discards changes; if discarding is required, target
only the specific files you modified.

## Final Report

After a ticket passes its gate, append a `## Final Report` section to the ticket file. The
frontmatter is **not** touched at drive time (see *Fields the run never writes*).

```markdown
## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: <what was discovered>
  **Context**: <why this matters for understanding the codebase>
```

Omit the Insights subsection when there is nothing meaningful. Good insights: architectural
patterns, non-obvious code relationships, historical context, edge cases — actionable and
specific, useful months later, not restating the Overview.

## Archive

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/archive.sh \
  <ticket-path> "<title>" <repo-url> "<why>" "<changes>" "<concerns>" "<insights>" "<verify>"
```

**NEVER manually archive** (`mv` + `git add` + `git commit`) — manual moves leave unstaged
deletions. The `## Final Report` must be appended first: the archive commit is the report's
permanent home. `<repo-url>` comes from the gather skill's `git-context.sh`; map the ticket and
Final Report into the body args — `<why>` from the Overview, `<changes>` from what changed for
users, `<concerns>` from Considerations (or "None"), `<insights>` from Discovered Insights (or
"None"), `<verify>` from the verification you ran. These keys feed `/story` (Motivation /
Changes / Concerns / Successful Development Patterns). Message format: the **commit** skill's
Message Format section.

**`<title>` is the commit subject, and it is checked before anything moves.** `archive.sh`
runs the canonical `commit/scripts/check-subject.sh` as its first act, so an off-policy
subject (over 50 characters, a `feat:` prefix, a `[bracket]` tag) refuses with the tree
**byte-identical** to before the call — the ticket stays in `todo/`, nothing is staged, and
re-running the same command with a shorter subject just works. Before 2026-08-12 the gate
only ran inside `commit.sh` at the end, so a refused subject left the ticket already moved
into `archive/<branch>/` with the rename staged and no commit, and the obvious retry died
on `Ticket not found` — recoverable only by the manual `git mv` this section forbids.
The subject is never auto-shortened: pass a shorter one rather than letting a machine
invent the sentence that goes into permanent history.

## Fields the run never writes

A driven ticket's frontmatter is read, never edited:

- **`commit_hash`** — retired; derived from git even for history (`/story`'s
  `ticket-commits.sh`). The old stamp-then-amend recorded an orphaned pre-amend hash; do not
  re-introduce a stamp, and do not read the field where old archives carry it.
- **`category`** — retired; lives only in the commit's `Category:` trailer (`archive.sh` →
  `commit.sh --category` → `/story`'s `collect-commits.sh`). One surface, nothing can disagree.
- **`effort`** — retired; a mission unit's wall-clock is recorded once by `record-run-hours.sh`.
- **`merge_policy`** — recorded at ticket creation, read at route time through
  `effective-policy.sh`, never edited: changing it mid-run would let the run grant itself
  permission to merge.
