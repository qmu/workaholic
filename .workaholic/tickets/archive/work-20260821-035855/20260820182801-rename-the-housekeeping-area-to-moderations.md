---
created_at: 2026-08-20T18:28:01+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260820182800-add-the-rename-registry-and-its-convergence-seam.md
mission: make-a-rename-a-registry-entry-not-a-sweep
merge_policy: auto
---

# Rename the housekeeping area to moderations

## Overview

PROPOSED. On 2026-08-19 the maintenance tick's routine, command and skill all became
**moderate** (`[Housekeep]` → `[Propose]` → `[Moderate]`, `/housekeep` → `/moderate`,
`skills/housekeep/` → `skills/moderate/`). One thing did not move: the artifact the
tick writes still lives at `.workaholic/housekeeping/`. The tree therefore names the
log after a word that appears nowhere else in the live plugin except in service of
that directory — 70 occurrences across `plugins/`, `scripts/`, `docs/`, `outputs/`,
`README.md` and `CLAUDE.md`, every one of them a path or a sentence about a path.

The developer's ruling is that `housekeep` disappears completely: the log is the
**Moderate** routine's artifact, so it is `.workaholic/moderations/`. This is the
rename registry's first `area` row and its first real proof.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/hooks/workaholic-layout-allowlist.txt:27` — the `housekeeping`
  entry. **Lockstep**: it and the `rules/workaholic.md` table move in the same commit,
  or the area's next write is hard-blocked (CLAUDE.md's closed-layout policy).
- `plugins/workaholic/rules/workaholic.md:14,59,105` — the layout table row, the
  *second OKF exception* paragraph, and the frontmatter table's `housekeeping/` row.
- `plugins/workaholic/skills/moderate/scripts/log-append.sh:7,89` — the only writer;
  `DIR="$ROOT/.workaholic/housekeeping"`.
- `plugins/workaholic/skills/moderate/scripts/log-read.sh:58` — the dedup reader.
- `plugins/workaholic/skills/moderate/scripts/step-open-log.sh:40,41,45,47,52` — the
  `grep -q '^housekeeping$'` **allowlist probe** and its `area_unregistered` degraded
  message. This is the one place where a half-applied rename fails silently-ish: the
  tick still runs and its log does not.
- `plugins/workaholic/skills/moderate/scripts/persist-log.sh:174,339` — `LOG_REL` and
  the publish-tree commit body.
- `plugins/workaholic/skills/moderate/scripts/run.sh:252,253` — the log-file read.
- `plugins/workaholic/skills/okf/scripts/refresh-index.sh:343,349` — the bare-link
  exception in the bundle-root index generator (and its five generated copies under
  `outputs/workflows/*/okf/scripts/`, which `build.mjs` regenerates).
- `plugins/workaholic/skills/moderate/SKILL.md:23,34,59`,
  `reference/workflow.md:30,259`, `skills/workaholify/routines/moderate.md:67` — prose.
- `scripts/e2e/loop-drill.sh:1138,1173`, `docs/loop-drill-runbook.md:307`,
  `scripts/test-workflow-scripts.mjs` (≈13 occurrences from line 17347), `README.md:336`
  (the mermaid node `HK["housekeeping/&lt;day&gt;.md"]`), `CLAUDE.md:88,152`.
- `.workaholic/housekeeping/2026-08-18.md`, `2026-08-19.md` — the two existing day
  files, moved by the migration.

## Implementation Steps

1. **Add the registry row first** — `area`, `housekeeping`, `moderations`, today's
   date, the reason. Then run `converge-layout.sh` on this checkout and confirm it
   moves the two day files and reports the surviving `name` occurrences. If it does
   not, the defect is in the sibling ticket's mechanism; fix it there, not here.
2. **Move the allowlist entry and the rules table in one commit.** `housekeeping` →
   `moderations` in `workaholic-layout-allowlist.txt`, and the three
   `rules/workaholic.md` sites. Do **not** leave the old entry behind as a tolerance:
   unlike `icebox/`/`abandoned/`, no repository outside this one has ever written this
   area (the tick shipped 2026-08-17 and is repository-scoped), so a permissive
   survivor buys nothing and keeps the word alive.
3. **Move the five moderate scripts** (`log-append.sh`, `log-read.sh`,
   `step-open-log.sh`, `persist-log.sh`, `run.sh`). `step-open-log.sh`'s allowlist
   probe and its `area_unregistered` message must move together — a probe left reading
   `^housekeeping$` against a converged allowlist reports the area as unregistered on
   every tick and the log stops being written.
4. **Move `refresh-index.sh`'s area list and its bare-link clause**, keeping the OKF
   exception intact: no `type:`, no `index.md`, linked bare from the bundle root.
5. **Sweep the prose**: the moderate SKILL and its reference, the routine template, the
   loop drill and its runbook, `README.md`'s mermaid node, and `CLAUDE.md`'s two sites.
   The `CLAUDE.md` OKF-floor paragraph names the exception by directory — it becomes
   `moderations/` and gains one clause recording that it was `housekeeping/` until this
   change, since that file's rule is to state current behaviour with the history in
   git.
6. **Sweep the tests** (`test-workflow-scripts.mjs`, ≈13 sites). Note the unrelated
   `type: housekeeping` fixture near line 7930 — it is a legacy trip/story frontmatter
   value, not this area; leave it alone and say so in the commit body so the next
   grep-driven sweep does not "fix" it.
7. **Decide, and record, what happens to the two queued tickets whose filenames carry
   the word** (`20260819052241-stop-the-housekeep-tick-posting-pr-status-notices.md`,
   `20260819062058-fix-the-housekeep-check-in-s-already-asked-gate.md`). They are live
   queue items, not history. The registry's `name` half will report them; renaming a
   queued ticket's filename breaks nothing but is churn. Make the call in the ticket
   body, do not leave it to the next reader.
8. **Regenerate and verify**: `node scripts/build-plugins/build.mjs` (the five
   `outputs/workflows/*/okf/scripts/refresh-index.sh` copies), `verify.mjs`,
   `validate-metadata.mjs`, `node scripts/test-workflow-scripts.mjs`,
   `bash plugins/workaholic/hooks/layout-doctor.sh .`,
   `sh scripts/e2e/loop-drill.sh verify-propose` if it exercises the log.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `.workaholic/moderations/` holds the two day files; `.workaholic/housekeeping/` is gone.
- `grep -ril housekeep` over `plugins/ scripts/ docs/ outputs/ README.md CLAUDE.md`
  returns nothing (the `.workaholic/` record and git history are untouched).
- A `/moderate` tick writes, reads and persists its log at the new path, and
  `step-open-log.sh`'s allowlist probe passes.
- The registry carries the row, and a repository still holding `housekeeping/` is
  converged by `/workaholify` and told what it became.

**Verification method** — the commands/tests/probes that prove them:

- `grep -ril housekeep plugins/ scripts/ docs/ outputs/ README.md CLAUDE.md` — empty
- `bash plugins/workaholic/skills/moderate/scripts/run.sh` on a throwaway repo, then
  `log-read.sh` returns the entries it wrote
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs`
- `node scripts/test-workflow-scripts.mjs`
- `bash plugins/workaholic/hooks/layout-doctor.sh .` → `conforming: true`
- `converge-layout.sh` on a throwaway tree seeded with `.workaholic/housekeeping/x.md`
  moves it and reports the move

**Gate** — what must pass before approval:

- Every check above passes, the allowlist and the rules table moved in the same commit,
  and a tick proves the log round-trips at the new path.

## Considerations

- **This rename has a silent-failure mode the others do not.** `step-open-log.sh`
  degrades with `area_unregistered` rather than failing: the tick keeps running and
  only its log disappears, which is precisely the audit trail that would tell you.
  Prove the round-trip with a real tick, not by reading the diff.
- **No back-compat tolerance, deliberately.** The retired ticket-state directories got
  one because every consuming repository had them; this area is written by a
  repository-scoped routine that shipped four days ago, so the tolerance would protect
  nobody and would keep the word the developer asked to remove.
- **`.workaholic/` history is not swept.** Stories, archived tickets and feedback
  records keep `housekeep` — they describe what was true when written, and the
  repository's own rule grandfathers git-tracked history. The acceptance grep is scoped
  to the live tree for exactly that reason.
- **`outputs/` is generated.** Its five `refresh-index.sh` copies change only through
  `build.mjs`; hand-editing them fails the `Outputs Freshness` CI.

## Final Report

Development completed as planned, and the registry drove it exactly as ticket 1
promised: adding the row and running `converge-layout.sh` moved the two day files,
rewrote the root index link, and returned the list of **17** files still naming the
old word — the same set this ticket's Key Files had enumerated by hand. That
agreement is the mission's proof, not a coincidence worth passing over.

**Step 7 resolved: the two queued tickets keep their filenames.** A mission's
`## Acceptance` items are tickable through a `(#<filename>)` link and
`tick-acceptance.sh` keys on that link, so renaming a queued ticket's file would
strand its mission's item — a real cost against pure tidiness. They also sit under
`.workaholic/`, which the conversion never searches, so nothing reports them. What
did move is `CLAUDE.md`'s reference to one of them: it now cites the ticket by its
**timestamp id**, the form that file already uses elsewhere.

**Two things kept the old word on purpose.** The suite's `type: housekeeping`
fixture is the retired per-ticket `type:` field, not this area; it now carries a
comment saying so, and `rename-conversions.sh` will keep reporting that one file
until the row is deleted — which is the tool working, not a defect. And the
registry row itself stays: this repository has cut over, consuming repositories
have not, and the row is what tells them what the name became.

No back-compat tolerance was added, as the ticket specified. Unlike the retired
ticket-state directories, this area is written by a repository-scoped routine that
shipped four days ago, so a permissive survivor would protect nobody and keep the
word alive.

### Discovered Insights

- **Insight**: the bulk conversion swept `scripts/test-workflow-scripts.mjs` and
  rewrote **both halves** of the rename fixture's `old -> new` pair into the same
  word, leaving a test that seeded `moderations/` and then asserted `moderations/`
  was gone. **Context**: a test whose fixture names a *real* rename is destroyed by
  that rename's own conversion — silently, because the assertions still parse. Any
  fixture for a rename mechanism must name a rename that does not exist. The
  replacement pairs `terms` with `glossary`, which buys a second property: `terms`
  is in the allowlist, so it is what proves the doctor consults the registry
  **before** the allowlist rather than after.

- **Insight**: `step-open-log.sh` probes the allowlist with a literal
  `grep -q '^housekeeping$'` and, on a miss, degrades to `area_unregistered` — the
  tick keeps running and only its log stops being written. **Context**: this is the
  one silent-ish failure in the whole rename. The audit trail that would tell you
  the log stopped *is* the log, so a half-applied rename here is invisible from the
  outside; the probe and the allowlist have to move in the same commit, and a
  reviewer should look for that pairing specifically.

- **Insight**: `log-append.sh` writes `# Housekeeping log — <day>` as the day
  file's own first line, so the old name lived in generated *content*, not only in
  paths. **Context**: existing day files keep the old heading and nothing rewrites
  them — correct, since they are history — which means the tree will hold both
  headings for a while. Nothing reads the heading, so this costs nothing; the point
  is that a rename sweep has to look for names a script *writes*, not just names it
  *reads*.
