---
created_at: 2026-07-15T00:15:00+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort: 1h
commit_hash:
category: Changed
depends_on:
mission:
---

# Archived tickets record a commit hash that never exists

## Overview

The `commit_hash` that `archive.sh` writes into a ticket **always names a commit that does not exist**, so the commit links `/report` builds in section 3 are **almost all 404** (measured on a consumer repository's branch: **33 of 37 unreachable**; one was fetched through the GitHub API and returned 404).

The cause is the ordering in `archive.sh` itself (`plugins/workaholic/skills/drive/scripts/archive.sh:88-98`):

```sh
sh "$COMMIT_SCRIPT" ...                    # creates commit A
COMMIT_HASH=$(git rev-parse --short HEAD)  # = A
sh "$UPDATE_SCRIPT" ... commit_hash "$COMMIT_HASH"   # writes A into the ticket
git add "$ARCHIVED_TICKET"
git commit --amend --no-edit               # the ticket changed -> the hash becomes B
```

**The amend that stores A is what invalidates A.** What lands on the branch is B; A is an orphaned commit nothing references, so it is never pushed and does not exist on the remote. `echo "  Commit: ${COMMIT_HASH}"` prints A too, so the log lies as well.

**Reordering does not fix this.** A commit cannot carry its own hash, so stamp → amend → re-stamp → amend regresses forever (no fixed point exists). There is no way to hold a correct value in frontmatter while keeping one commit.

**Chosen approach (developer decision) — derive it at read time.** `archive.sh` stops writing `commit_hash`. `/report` derives it from git, because the commit that **added** the archived ticket's path *is* the commit that implemented it:

```sh
git log --diff-filter=A --format=%h -- .workaholic/tickets/archive/<branch>/<ticket>.md
```

Git becomes the single source of truth, so **tickets carrying a stale value resolve correctly too** (no backfill migration). Measured: 37 of 37 derive, all reachable, and 36 disagree with the frontmatter value — i.e. 36 are rescued by deriving.

Rejected alternative: split into two commits (an implementation commit plus a bookkeeping commit that stamps the hash). The frontmatter would be self-contained, but every ticket would add a bookkeeping commit and double the log.

## Policies

- `workaholic:implementation` / `policies/objective-documentation.md` — a record must be verifiable. A `commit_hash` naming a nonexistent commit is not merely unverifiable, it is **false**, and only surfaces when a link 404s.
- `workaholic:implementation` / `policies/coding-standards.md` — keep the derivation in a skill `scripts/` file rather than inline shell in SKILL.md prose (Shell Script Principle). POSIX `#!/bin/sh -eu`.
- `workaholic:design` / `policies/multiple-paths.md` — holding the same fact (which commit implemented this ticket) in both frontmatter and git guarantees drift. Make git the single source.

## Key Files

- `plugins/workaholic/skills/drive/scripts/archive.sh:88-104` — drop the `commit_hash` stamp and fix the `Commit:` line (keep the `category` stamp and the amend, so it stays one commit).
- `plugins/workaholic/skills/report/scripts/ticket-commits.sh` — **new**. Derives `{ticket, commit}` per archived ticket on a branch and returns JSON.
- `plugins/workaholic/skills/report/SKILL.md` — update Phase 3 "Gather Source Data" to use this script instead of the frontmatter `commit_hash`. Section 3's link rule (`### 3-N. <Title> ([hash](<repo-url>/commit/<hash>))`) is unchanged.
- `plugins/workaholic/skills/drive/SKILL.md` — update the "Update Frontmatter" `commit_hash` entry (currently "set automatically by archive script").
- `scripts/test-workflow-scripts.mjs` — add the regression near the drive archive tests.
- `outputs/workflows/skills/{report,ship}/**` — **generated**; rebuild with `node scripts/build-plugins/build.mjs` (Outputs Freshness CI fails on a diff).

## Implementation Steps

1. Remove the `commit_hash` stamp from `archive.sh`. Keep the `category` stamp and `git commit --amend` (one commit per ticket). Read the final `Commit:` line **after** the amend (`git rev-parse --short HEAD`) so the output cannot lie either.
2. Add `report/scripts/ticket-commits.sh [branch]`. Walk `.workaholic/tickets/archive/<branch>/*.md`, derive with `git log --diff-filter=A --format=%h -- <path> | head -1`, and emit `[{"ticket":"<basename>","commit":"<short>"}]`. A ticket that cannot be resolved (not committed yet) gets `"commit": ""` rather than being dropped — better visible and empty than silently missing.
3. Update `report/SKILL.md` Phase 3 to use the script's output for section 3's links, and to **not read** the frontmatter `commit_hash` (older tickets still carry broken values, so reading it would adopt them).
4. Update the `commit_hash` entry in `drive/SKILL.md`.
5. Add the regression tests (see Quality Gate).
6. Rebuild `outputs/` with `build.mjs` and pass `verify.mjs` / `validate-metadata.mjs` / `test-workflow-scripts.mjs`.

## Quality Gate

- After archiving, the ticket **has no `commit_hash`**, and `category` is still written as before.
- **`archive.sh`'s final output names a commit that exists** (the post-amend hash).
- The hash `ticket-commits.sh` derives is **reachable from the branch** (`git merge-base --is-ancestor <hash> HEAD`). This is the heart of the ticket: reachable means it would be pushed, means the link resolves.
- The derived value **matches the commit that actually archived** that ticket.
- Existing `test-workflow-scripts.mjs` green; `verify.mjs` / `validate-metadata.mjs` green; `outputs/` matches the build after `build.mjs`.
- **Verify on the real thing**: run `ticket-commits.sh` against the consumer repository's branch (37 tickets) and confirm **all 37 derive and all 37 are reachable** — today 33 of the frontmatter values are unreachable, and that gap is the fix's actual effect.

## Final Report

Development completed as planned (chosen approach: derive at read time).

**Verified on the originating artifact** (the consumer repository's branch, 37 tickets):

| | Reachable hashes |
|---|---|
| Before (frontmatter `commit_hash`) | **3 / 37** — 34 links 404 |
| After (`ticket-commits.sh` derivation) | **37 / 37** — every link resolves |

The derivation works retroactively on existing tickets (it only reads git, so a broken frontmatter value is irrelevant) — no migration needed.

**Tests**: added 8j2 "report/ticket-commits.sh derivation" (7 assertions) and inverted the existing `drive/archive.sh` assertion to the new contract. **538 passed / 0 failed** (529 before). `verify.mjs` (self-containment, policy index, OKF) and `validate-metadata.mjs` green; `outputs/` rebuilt with `build.mjs`.

### Discovered Insights

- **Insight**: **a commit cannot carry its own hash** (no fixed point exists). Stamping then amending always changes the hash, and re-stamping after the amend does the same thing again. It looks like "fix the ordering" but is really a **design choice** — split into two commits, or derive at read time.
  **Context**: the original code hid this behind "stamp, then amend", making it look like one commit, while the amend itself invalidated the stamp. The same trap exists for any requirement to embed an artifact's own identifier into it (version, tag, signature).

- **Insight**: **`/report` was not the only consumer of `commit_hash`.** `catch`'s `scan-window.sh` also read it from frontmatter to tie an archived ticket to a commit, and it surfaced only because removing the stamp turned its test red. Moved to the same derivation.
  **Context**: when removing a field, audit every **reader**, not just the writer. The test suite is what surfaced it (`scan-window stamps archived ticket commit_hash` failed).

- **Insight**: deriving with `--diff-filter=A` (the commit that **added** the path) is the crux. Using "the latest commit that touched the path" would re-point the link the moment `/report` or `/carry` edits the ticket afterwards. Archiving is a one-time add, so A is a stable anchor.
  **Context**: 8j2's "a later edit does not re-point the link" pins this invariant.

- **Insight**: naming another skill's script in SKILL.md prose using a path form (e.g. `report/scripts/…`) makes `verify.mjs` try to resolve it as a cross-skill reference and MISS (drive's build closure does not contain report's scripts). Avoid the path form when mentioning another skill's script in prose.
  **Context**: it surfaced as "1 unresolved reference" from `build.mjs` → `verify.mjs`. That check exists to protect each bundle's self-containment.
