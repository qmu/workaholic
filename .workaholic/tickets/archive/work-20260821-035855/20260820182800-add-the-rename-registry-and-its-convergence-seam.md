---
created_at: 2026-08-20T18:28:00+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-rename-a-registry-entry-not-a-sweep
merge_policy: auto
---

# Add the rename registry and its convergence seam

## Overview

PROPOSED. A rename in this repository is currently a **sweep plus a note somebody
has to remember**. `renamed_from:` on a routine template carries one migration by
hand; `layout-doctor.sh` hard-codes `guides|policies|specs` in an `elif` branch to
name the one retired area it knows about; `converge-layout.sh` composes two
migrations named literally in its body. Nothing generalises, so the seventh rename
costs exactly what the sixth did — and a consuming repository holding an old name
meets a floor written for a shape it has never had, with no statement of what the
name became.

This ticket makes a rename a **declared row**. One shipped table; the doctor reads
it to classify, and `/workaholify`'s layout convergence reads it to apply the
mechanical half and *propose* the rest. It ships with the table empty (or carrying
only rows already true), and the mission's other two tickets are its first users
and its proof.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/hooks/workaholic-layout-allowlist.txt` — the existing single
  source of truth for the closed layout, and the shape to imitate: a shipped data
  file, comment-headed, read by both a hook and the doctor. The rename table is its
  sibling in spirit, **not** an extension of it (the allowlist says what is
  permitted; the table says what a name became).
- `plugins/workaholic/hooks/layout-doctor.sh` — the `for entry in "$WH"/*` loop and
  its `elif [ "$name" = "guides" ] … retired-area` branch. That branch is the
  hard-coded special case this ticket generalises; it must keep producing an
  identical finding for those three names once they are rows.
- `plugins/workaholic/skills/workaholify/scripts/converge-layout.sh` — the living-
  migration registry (`APPLIED` / `REPORTED` / `NOT ITS BUSINESS`). Its header states
  the line it will not cross; a rename conversion sits on both sides of that line and
  the header must say which half goes where.
- `plugins/workaholic/skills/gather/scripts/migrate-ticket-states.sh` — the reference
  migration: `#!/bin/sh -eu`, idempotent, best-effort, git-staged, clean no-op on a
  tree that never had the shape, JSON `{"migrated": N, "moves": [...]}`.
- `scripts/build-plugins/build.mjs` — **the constraint that decides where the table
  lives.** `cpSync(sScripts, dScripts, { recursive: true })` copies a closure skill's
  **whole `scripts/` directory**, any extension; nothing else under a skill root is
  copied except `reference/`. A table at `skills/gather/renames.tsv` would therefore
  be absent from `outputs/workflows/` and the shipped migration would read nothing.
- `scripts/test-workflow-scripts.mjs` — where the registry's mechanical check lives
  (CLAUDE.md: a structural change ships its migration *and* its registration in the
  same commit, checked here).
- `plugins/workaholic/rules/workaholic.md`, `CLAUDE.md` — the closed-layout policy and
  the `/workaholify` row; both describe convergence and both go stale in this change.

## Implementation Steps

1. **Confirm the two constraints before designing anything.** (a) Re-read
   `build.mjs`'s script-copy block and confirm that a non-`.sh` file under a skill's
   `scripts/` really is carried into `outputs/workflows/` — the table's home depends
   on it, and if it is not, the table must be embedded in the reader instead. (b)
   Confirm `layout-doctor.sh` is **not** part of any bundle closure (it is a hook), so
   a hook reading a skill data file crosses a boundary that must be spelled out rather
   than discovered later.
2. **Add the table**, at `plugins/workaholic/skills/gather/scripts/renames.tsv`
   (subject to step 1). One row per rename, tab-separated, comment-headed like the
   allowlist: `kind` (`area` | `name`), `old`, `new`, `since` (`YYYY-MM-DD`), `why`
   (a short clause, e.g. an issue number). Two kinds and no third — an `area` is a
   `.workaholic/` top-level directory and is **moved**; a `name` is a token
   (`housekeep`, `workaholic:report`, `/report`) and is **reported**. State in the
   header that adding a row is the whole cost of a rename, and that a row is deleted
   once the fleet has cut over — the table records migrations, not history.
3. **Add one reader**, `gather/scripts/list-renames.sh`, emitting the table as JSON.
   Every consumer goes through it; two hand-rolled TSV parsers would drift exactly as
   four hand-rolled frontmatter readers once did.
4. **Teach `layout-doctor.sh` the `area` rows.** Replace the `guides|policies|specs`
   `elif` with a table lookup that emits `renamed-area` naming `new` and `since`, and
   **add those three names as rows** so their finding text is preserved (keep the
   classification `retired-area` for them, or record in the row why a retirement is
   not a rename — they were deleted, not moved, and conflating the two would offer a
   conversion that has no destination). A tree with no table, or an unreadable one, is
   reported degraded and falls back to today's behaviour; the doctor must never fail
   closed on a data file.
5. **Add the mechanical migration**, `gather/scripts/migrate-renamed-areas.sh`, on
   `migrate-ticket-states.sh`'s contract exactly: idempotent, best-effort, git-staged,
   no-op on a clean tree, `{"migrated": N, "moves": [...]}`. It `git mv`s each `area`
   row's directory and rewrites the **machine-read** occurrences of the old path
   inside `.workaholic/` (an area name embedded in an index link). It touches **no
   prose and nothing outside `.workaholic/`**. A destination that already exists is
   reported, never merged — that is an owner's decision.
6. **Add the proposal half**, `gather/scripts/rename-conversions.sh`: for every row,
   find the surviving occurrences outside the artifact tree and emit, per row, the
   count, the files, and **one ready-to-run bulk conversion command** the operator can
   paste or decline. It **prints and never writes**. Scope its search away from
   `.workaholic/` history by construction, so a story written last month is never
   offered for rewriting.
7. **Register both in `converge-layout.sh`** — the migration in `APPLIED`, the
   conversions in `REPORTED` — using the `${SCRIPT_DIR}/../../gather/scripts/` form,
   which is load-bearing for `build.mjs`'s closure scan (the file's own comment says
   why `${CLAUDE_PLUGIN_ROOT}` would be invisible there). Extend its JSON with the new
   keys and its header with the rename half of the applied/reported line.
8. **Report it from `/workaholify` §3a** — per row, what moved and what is proposed —
   and keep the command's `AskUserQuestion` count unchanged: applying a rename the
   plugin itself declares fails the Recommended-label test.
9. **Cover it in `test-workflow-scripts.mjs`**: the table parses; a row round-trips
   through `list-renames.sh`; the migration is a no-op twice and moves a seeded area
   once; the conversions script writes nothing; `converge-layout.sh` reports both. Pin
   machine-consumed tokens only, never the prose.
10. **Update the documentation in the same change**: `rules/workaholic.md` (the closed
    layout gains a rename axis), `CLAUDE.md`'s `/workaholify` row and its living-
    migration-registry sentence, `README.md` if it names the convergence.
11. **Verify**: `node scripts/build-plugins/build.mjs`, `verify.mjs`,
    `validate-metadata.mjs`, `node scripts/test-workflow-scripts.mjs`,
    `bash plugins/workaholic/hooks/layout-doctor.sh .`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A shipped table declares renames in two kinds (`area`, `name`) and is read through
  one reader; it is present in `outputs/workflows/` after a build.
- `layout-doctor.sh` classifies an `area` row's surviving directory, naming what it
  became and when, and degrades to today's behaviour when the table is unreadable.
- `converge-layout.sh` applies the area moves and reports the name conversions, with
  the header stating which half is which and why.
- Nothing outside `.workaholic/` is rewritten by any script in this ticket.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs`
- `ls outputs/workflows/gather/scripts/renames.tsv` (the bundle carries the table)
- `node scripts/test-workflow-scripts.mjs`
- `bash plugins/workaholic/hooks/layout-doctor.sh .` on a seeded throwaway tree holding a renamed area
- `bash plugins/workaholic/skills/workaholify/scripts/converge-layout.sh` twice on the same tree — the second run reports `changed: 0`

**Gate** — what must pass before approval:

- All four script checks pass, the documentation trio is updated in the same commit,
  and a second `converge-layout.sh` run is a proven no-op.

## Considerations

- **The split is the whole design, and it is not negotiable downward.** A
  `.workaholic/` area is a machine-owned path with exactly one correct destination, so
  moving it is mechanical. A *name* appears in prose a human wrote, in a consuming
  repository's own documents, and in vocabulary that may deliberately differ — this
  repository's standing rule is that everything needing a judgment is reported with
  the decision it needs and never guessed (`converge-layout.sh`'s own header). A
  script that rewrote `report` to `story` across somebody's docs would be exactly the
  class of act that rule refuses.
- **A retirement is not a rename.** `guides/`/`policies/`/`specs/` were deleted; their
  content had no destination. Folding them into the table as `area` rows with a `new`
  value would offer a `git mv` into a directory that should not exist. Either keep
  their branch distinct or give the row an empty `new` meaning "retired, owner
  decides" — decide it in step 4 and record which, rather than leaving a reader to
  infer it from behaviour.
- **The table is a migration record, not history.** Rows are deleted once the fleet
  has cut over, on the same reasoning that deletes `renamed_from:` from a routine
  template. Say so in the header, or the table grows into a changelog nobody prunes
  and the doctor spends every run searching for names no repository still holds.
- **This ticket ships the mechanism with no behaviour change of its own.** Its two
  siblings are the first rows. If the mechanism proves wrong under the first real
  rename, fix it here rather than working around it in the sibling — a registry with
  one hand-written exception is a sweep with extra steps.

## Final Report

Development completed as planned. Both step-1 constraints were confirmed before
anything was designed, and both decided a real thing:

- `build.mjs` copies a closure skill's **whole** `scripts/` directory with
  `cpSync(..., { recursive: true })` and no extension filter, so the table lives at
  `gather/scripts/renames.tsv` and reaches `outputs/workflows/*/gather/scripts/`
  with its three consumers. Verified after the build: all four files are in every
  bundle that carries the gather closure.
- `layout-doctor.sh` is a hook and is in no bundle closure, so its read of a skill
  data file is a boundary crossing. It is made once, through the skill's own
  reader, and named in the script's header — the alternative was a second copy of
  the table on the hooks side.

The two judgment calls the ticket left open were both resolved toward keeping one
behaviour per kind, and are recorded in the table's header and the doctor's:

- **A retirement is not a rename.** `guides/`/`policies/`/`specs/` keep their own
  `retired-area` branch rather than becoming rows. A row with an empty `new` would
  make that column's meaning conditional and give `migrate-renamed-areas.sh` a
  "skip if empty" branch — a second behaviour inside one kind — and would offer a
  `git mv` into a directory that should not exist.
- **`renamed-area` is checked before the allowlist**, not after. The moment a
  rename lands the allowlist carries the *new* name, so the old one would otherwise
  fall through to "not in the canonical allowlist" — the uninformative sentence the
  registry exists to replace.

Ships with the table empty. Tickets 2 and 3 of this mission add its first rows.

### Discovered Insights

- **Insight**: `build.mjs`'s `cpSync(sScripts, dScripts, { recursive: true })` makes
  a skill's `scripts/` directory the only place under a skill root — besides
  `reference/` — where a **non-script data file** reaches the portable bundle.
  **Context**: this silently decides where any future shipped data file must live.
  `skills/<x>/renames.tsv` looks tidier and would have been absent from every
  bundle, so the shipped migration would have read an empty table on every
  non-Claude agent and reported a clean no-op forever — a failure that is invisible
  from the source tree.

- **Insight**: the repository's own `.workaholic/` tree is the reason the proposal
  half cannot be a simple `grep -r`. A story or an archived ticket names the old
  word because it was true when written, and every floor here grandfathers
  git-tracked history; offering those files for conversion would be offering to
  edit the record of what happened. **Context**: the exclusion is not a
  noise-reduction convenience — it is the same rule as `validate-story.sh`
  grandfathering history, applied to a different tool, and a later change that
  "improves" the search by widening it would quietly break it.

- **Insight**: `WORKAHOLIC_RENAMES_TABLE` works as a whole-chain override only
  because all three consumers reach the table through `list-renames.sh` rather than
  parsing it themselves — including `layout-doctor.sh`, which is a hook.
  **Context**: the one-reader rule is usually justified as drift prevention; here it
  bought testability for free, which is a second argument for it the next
  single-reader decision can cite.
