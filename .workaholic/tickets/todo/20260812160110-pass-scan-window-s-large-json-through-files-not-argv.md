---
created_at: 2026-08-12T16:01:10+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260812160052-catch-scan-window-sh-dies-with-argument-list-too-long-on-a-large-ticket-corpus.md]
merge_policy:
claim: work-20260812-185209
---

# Pass scan-window's large JSON through files, not argv

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it from a
     proposal into queued work. -->

`/catch` cannot render a report at all on a repository with a large ticket corpus:
`skills/catch/scripts/scan-window.sh` aborts with `jq: Argument list too long` and emits
nothing. The MISSIONS assembly passes the whole serialized tickets array to `jq` as a
single `--argjson` value, and Linux caps one argv entry at `MAX_ARG_STRLEN` (128 KiB) —
a limit independent of the much larger total `ARG_MAX`, so raising `ulimit` or shortening
the window does not help. Reported at qmu/workaholic#387 against a ~1,600-file corpus;
this repository is already at ~740 ticket files, so the ceiling is on the near path here
too and the failure is a matter of corpus growth, not of an unusual invocation.

The failure mode is total: the script exits non-zero with empty stdout, so `/catch` has
nothing to render — permanently broken on exactly the mature repositories it is most
useful for.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh`, no bashisms
  (`plugins/workaholic/rules/shell.md`); the script runs under `set -eu`.
- `workaholic:implementation` / `policies/observability.md` — a scan that cannot complete
  must say so rather than emitting nothing an operator has to interpret.
- `workaholic:operation` — the failure scales with corpus size, so the fix is judged on
  whether it still holds at several times today's corpus.

## Key Files

- `plugins/workaholic/skills/catch/scripts/scan-window.sh` — the MISSIONS assembly
  (`emit_changelog_events | jq -Rs --argjson list "$MLIST" --argjson tickets "$TICKETS"`,
  ~L237-L239) is the reported abort site. Other `jq` calls at ~L85-L89 (`--argjson`
  scalars plus `$REMOTES`), ~L170, ~L268, ~L312 and ~L323 are the audit surface. The
  script creates no temp directory today, so the fix introduces one.
- `scripts/test-workflow-scripts.mjs` — the catch/scan-window block (~L6797 onward) builds
  a throwaway repository and asserts the JSON envelope; this is where the regression pin
  goes.
- `plugins/workaholic/skills/catch/reference/rendering.md` — documents the output fields
  per field; the envelope must not change shape.
- `plugins/workaholic/skills/catch/SKILL.md` — the caller's contract.

## Implementation Steps

1. **Reproduce first.** Generate a throwaway repository whose `.workaholic/tickets/` corpus
   serializes past 128 KiB (a few hundred synthetic ticket files is enough — size the
   fixture from the measured `$TICKETS` length, not from a file count guess) and run
   `scan-window.sh`. Record the actual error, exit status, and empty stdout. Do not proceed
   on the report's description alone.
2. **Localize.** Confirm the limit that fires is `MAX_ARG_STRLEN` on a single argument and
   not total `ARG_MAX` — measure the serialized length of `$TICKETS` and `$MLIST`
   separately and identify which argument crosses it. This distinction decides the fix:
   splitting the call would not help a single oversized value.
3. **Audit every `jq` invocation in the script**, not only the abort site. Classify each
   `--argjson`/`--arg` by whether its value is bounded (a date, a window string, a remote
   list) or grows with the corpus (`$TICKETS`, `$MLIST`). Record the classification in the
   Final Report — the reporter notes the others "carry small scalars and are fine today",
   which is a statement to verify rather than inherit.
4. **Pass the unbounded values through files.** Write each to a file under a `mktemp -d`
   directory and read it with `--slurpfile`, keeping the filter's `$list` / `$tickets`
   bindings so the body of the expression is unchanged and diffable. Install a `trap` to
   remove the directory on exit, including the error paths — the script runs under
   `set -eu` and must not leave temp files behind on an abort.
5. **Keep the output envelope byte-identical** for a corpus that works today: the fix is a
   transport change, not a shape change. Diff the emitted JSON before and after on the
   existing test fixture.
6. **Pin the regression.** Extend the catch/scan-window tests with a case whose corpus
   crosses the 128 KiB argv ceiling, asserting the scan completes and emits the full
   envelope. Keep the fixture generated rather than committed, and keep it hermetic (temp
   dir, no network, no `gh`) like the rest of the suite.
7. Regenerate `outputs/` (`node scripts/build-plugins/build.mjs`) if the catch skill ships
   in the bundle — a script change leaves it stale and `Outputs Freshness` CI fails on the
   diff.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `scan-window.sh` completes and emits its full JSON envelope on a corpus whose serialized
  tickets array exceeds 128 KiB.
- The envelope is unchanged on a corpus that already worked.
- No temp file or directory survives a successful run or an aborted one.
- Every `jq` argument that grows with the corpus is passed by file; the audit's
  classification of the remaining ones is recorded.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the new oversized-corpus case plus the
  existing catch assertions, green.
- The step-1 reproduction re-run against the fixed script, before/after output in the
  Final Report.
- A before/after diff of the emitted JSON on the existing fixture, showing no change.

**Gate** — what must pass before approval:

- The reproduction and the `MAX_ARG_STRLEN`-vs-`ARG_MAX` localization are recorded before
  the fix, per the diagnosis-first rule.
- The temp-directory cleanup is demonstrated on the error path, not only the happy one.

## Considerations

- The reporter's `--slurpfile` shape is recorded as their proposed mechanism and reports a
  local verification; it is still adopted only after step 1-2 confirm the limit. Note
  `--slurpfile` binds an *array* of the file's values, hence the `[0]` in the reporter's
  sketch — a detail that silently changes the filter's semantics if dropped.
- `--rawfile`/`fromjson` and `--jsonargs` are alternatives worth one thought; prefer
  whichever keeps the filter body unchanged, since the value here is a transport fix that a
  reviewer can read as such.
- Corpus growth is the underlying pressure and this ticket does not address it. If the
  Final Report finds the scan is also getting slow at this size, that is a separate
  observation for the feedback stream, not scope creep here.
- This repository is at roughly 740 ticket files today, so a fixture sized from the real
  corpus will keep working as the corpus grows only if it generates its own data rather
  than reading `.workaholic/`.
