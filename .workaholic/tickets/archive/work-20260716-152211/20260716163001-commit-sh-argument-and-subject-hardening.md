---
created_at: 2026-07-16T16:30:01+09:00
author: a@qmu.jp
type: bugfix
layer: [Domain]
effort: 0.5h
commit_hash:
category: Changed
depends_on:
mission:
---

# commit.sh never runs the subject gate it ships next to, and a trailing flag is silently swallowed

## Overview

Promoted from two triaged deferred concerns (2026-07-16 triage-to-zero;
verdicts verified against source):

1. **`closing-the-default-commit-path-routes`** — `commit.sh` commits via
   `git commit -m` without ever calling `hooks/lib/check-subject.sh`, so the
   script-wrapped path (which the PreToolUse commit guard deliberately does not
   inspect) can produce an off-policy subject. Separately, `check-subject.sh`
   measures length with `wc -m` under no locale pin, so a multibyte subject is
   measured differently across hosts.
2. **`commit-sh-silently-drops-a-category`** — a `--category` (or any flag)
   placed *after* the positional args breaks the parse loop and falls into the
   file-staging loop, where it is skipped with "not found" and no error. Today's
   leading `-*` rejection does not catch the trailing case.

## Key Files

- `plugins/workaholic/skills/commit/scripts/commit.sh` — the parse loop and the staging loop
- `plugins/workaholic/hooks/lib/check-subject.sh` — the shared subject rule (`wc -m`, no `LC_ALL` pin)
- `scripts/test-workflow-scripts.mjs` — `testCommitFlagGuard`, `testCheckSubject`

## Implementation Steps

1. Pin `LC_ALL` to a UTF-8 locale in `check-subject.sh` and add a multibyte-subject test.
2. Call `check-subject.sh` at the top of `commit.sh` (fail fast, before staging); comment the required ordering in both files.
3. In the file-staging loop, error on any argument starting with `-` instead of treating it as a file path.
4. Extend `testCommitFlagGuard` with the trailing-flag case; rebuild `outputs/` (commit.sh is bundled).

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — a boundary must reject unvalidated input, not reinterpret it (a trailing flag as a file path is the same defect class as the fixed `--help`-as-title).
- `workaholic:implementation` / `policies/test.md` — both fixes get regression tests beside the existing flag-guard tests.

## Quality Gate

- `commit.sh --category Added "T" …` and `commit.sh "T" … --category Added` behave identically or the latter errors by name; no flag is ever silently skipped.
- An over-length or off-policy subject passed to `commit.sh` fails before anything is staged, with the same message the git-native hook gives.
- A multibyte (Japanese) subject measures identically under `dash` on any locale; pinned by test.
- `node scripts/test-workflow-scripts.mjs` green; `build.mjs`/`verify.mjs` green after rebuild.

## Considerations

- Keep the commit-guard hooks subject-only; the fix is in the script layer, not the hooks.

## Final Report

Development completed as planned, with one structural addition the ticket's steps implied but did not spell out: the canonical validator moved from `hooks/lib/check-subject.sh` into `skills/commit/scripts/check-subject.sh`, and `hooks/lib/check-subject.sh` became a stable delegator. This is what lets `commit.sh` call the gate as a same-dir sibling AND ships the gate inside the self-contained `outputs/workflows` bundle (the build closure copies whole skill `scripts/` dirs but never `hooks/`). Both hook layers work unmodified through the delegator. Two adjacent boundary gaps of the same class were closed alongside the trailing-flag fix: `--category` with no value (previously a cryptic `shift` failure) and fewer than six positional args (previously the unconsumed fields fell into the staging loop as file paths).

### Discovered Insights

- **Insight**: The `outputs/workflows` build closure is blind to everything outside `skills/*/scripts/` — `computeClosure` scans only skill scripts and SKILL.md for cross-skill refs, and `hooks/` is never copied.
  **Context**: Any logic a bundled script depends on must live inside some skill's `scripts/` dir; sharing from `hooks/lib` silently breaks the cross-agent bundle. The delegator-in-hooks / canonical-in-skill split is the pattern to reuse.
- **Insight**: `C.UTF-8` and `C.utf8` differ by a hyphen, not just case, so a case-insensitive locale probe must list both spellings (glibc lists `C.utf8`; other systems list `C.UTF-8`).
  **Context**: The validator probes `C.UTF-8 C.utf8 en_US.UTF-8 en_US.utf8` in order; on hosts with no UTF-8 locale at all (bare musl has no `locale -a`) it leaves the environment alone, which on musl still decodes UTF-8 correctly and on glibc degrades to byte counting — stricter, never looser.
