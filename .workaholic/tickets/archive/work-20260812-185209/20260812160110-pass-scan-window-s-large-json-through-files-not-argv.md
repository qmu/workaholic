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

## Final Report

Development completed as planned.

### Reproduction, before the fix (step 1)

A generated throwaway repository with 900 synthetic ticket files (serialized tickets array
= **217,691 bytes**) plus one mission, run against the unmodified script:

```
$ sh scan-window.sh "1 month ago"
scan-window.sh: 237: jq: Argument list too long
exit=126
stdout bytes: 0
```

Exactly as reported: non-zero exit, **empty stdout**, nothing for `/catch` to render.

### Localization (step 2) — MAX_ARG_STRLEN, not ARG_MAX

Measured on the same machine:

| quantity | value |
| -------- | ----: |
| total `ARG_MAX` | 2,097,152 bytes |
| `MAX_ARG_STRLEN` (32 × page size) | 131,072 bytes |
| `$TICKETS` serialized | 217,691 bytes |
| `$MLIST` serialized | 295 bytes |

So the value that crosses the limit is `$TICKETS`, as **one argument**, while the total is
nowhere near exhausted. Demonstrated directly rather than inferred: a single 130 KiB
argument to `/bin/true` fails with `E2BIG`, while 400 KiB spread over 400 arguments
succeeds. This is the distinction the ticket demanded, and it decides the fix — splitting
the call into several would not have helped a single oversized value.

### The `jq` audit (step 3) — every invocation, classified

| site | arguments | grows with the corpus? |
| ---- | --------- | ---------------------- |
| L78 `REMOTES` | none (stdin) | n/a |
| L85-89 `DEVELOPERS` | 3 epoch scalars + `$REMOTES` | **no** — epochs are ~10 bytes; `$REMOTES` grows with the number of git remotes a human configured, not with the corpus |
| L170 `TICKETS` | none (stdin) | n/a |
| L237-240 `MISSIONS` | `$MLIST`, `$TICKETS`, `$WINDOW_START_DATE` | **yes** — `$TICKETS` (the abort site) and `$MLIST`; the date is bounded |
| L268 `STORIES` | none (stdin) | n/a |
| L312 `DEPLOYMENTS` | none (stdin) | n/a |
| L323 `WINDOW_JSON` | none (stdin) | n/a |

The reporter's note that the other calls "carry small scalars and are fine today" is
**almost** right, and the one correction matters: `$MLIST` is not a scalar — it is roughly
300 bytes per mission, so it would cross the ceiling at around 430 missions. Far off, but
it is a grow-with-corpus value, which is a reason to move it now rather than to leave it.
Both went to files. The final `cat <<EOF` envelope embeds these values through a heredoc,
not argv, so it was never subject to the limit.

### What changed

- A private `SCAN_TMP=$(mktemp -d)` at the top of the script, with `trap` on `EXIT`, `INT`,
  `TERM` and `HUP`.
- `$MLIST` and `$TICKETS` are written there and read with `--slurpfile`. Because
  `--slurpfile` binds an **array** of the file's values, they are unwrapped by two `as`
  bindings (`($list_file[0]) as $list`, `($tickets_file[0]) as $tickets`) that re-establish
  the original names — so the filter body below is **byte-identical** to the `--argjson`
  version and the diff reads as the transport change it is.
- The regression pin generates its fixture from `MAX_ARG_STRLEN` rather than a file count,
  and asserts the fixture really crosses the ceiling before asserting the scan survives it.
- `catch/SKILL.md`'s "writes no files" claim was narrowed to "no project files", naming the
  scratch directory and why it exists — the change would otherwise have left that sentence
  false.
- `outputs/` regenerated (the catch skill ships in the bundle).

### Verification

- Oversized corpus after the fix: `exit=0`, 513,766 bytes of stdout, all eight envelope
  keys present, 900 tickets, and the mission join computed (`in_flight: 900`,
  `window_events: 1`) — the stage that used to abort.
- Envelope on a corpus that already worked: **byte-identical**, 4,329 bytes before and
  after, `diff` clean.
- Temp cleanup on the error paths, not only the happy one: a forced non-zero exit from the
  `jq` stage under `set -eu` left **0** directories behind, and a `SIGTERM` mid-run left
  **0** (exit 143). A successful run leaves none.
- `node scripts/test-workflow-scripts.mjs` → **2280 passed, 0 failed**, including the seven
  new assertions.
- `build.mjs` / `verify.mjs` / `validate-metadata.mjs` clean.

### Discovered Insights

- **Insight**: `MAX_ARG_STRLEN` is a per-argument cap of 32 pages that no `ulimit` exposes
  and `getconf ARG_MAX` actively misleads about — here 128 KiB against a 2 MiB total.
  **Context**: any script in this repository that hands a corpus-sized JSON value to a
  child process as an argument has the same latent ceiling, and it fails as a total,
  silent-stdout abort rather than a truncation. The shape to look for is
  `--argjson <name> "$VAR"` where `$VAR` is built by a `find`-driven loop.
- **Insight**: `--slurpfile` binds an *array* of the file's values, so a naive swap from
  `--argjson x "$V"` to `--slurpfile x file` silently changes `$x` from the value to
  `[value]`.
  **Context**: the filter here reads `$tickets | map(...)`, which would not have errored on
  the wrapped form — `map` over a one-element array returns a one-element array, so the
  join would have quietly produced empty `in_flight` lists instead of failing. Unwrapping
  at the binding site keeps the mistake impossible to make later.
- **Insight**: the reported abort site was accurate but the reported *audit* was not — one
  of the "small scalars" also grows with the corpus.
  **Context**: this is why step 3 asked for the classification to be verified rather than
  inherited. A bug report's diagnosis is evidence, not a finding.
