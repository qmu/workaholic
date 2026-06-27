---
created_at: 2026-06-27T21:02:17+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Infrastructure]
effort: 1h
commit_hash:
category:
depends_on: [20260627210216-restructure-commit-body-for-report.md]
---

# Promote the change category to a `Category:` git trailer

## Overview

The Added/Changed/Removed change category is the grouping key for release notes and the story's
Changes section, but today it lives **only in ticket frontmatter** — it never travels in the commit
message. `drive/scripts/archive.sh` derives it heuristically from the commit-title verb
(`Add*|Create*|Implement*|Introduce*` → Added, `Remove*|Delete*` → Removed, else Changed) and
stamps it into the archived ticket's `category:` field via `update.sh`; `write-release-note`
groups by that frontmatter field. If `.workaholic/tickets/` is ever pruned or a history is
backfilled from `git log` alone, the category is gone.

This ticket promotes the category to a **`Category:` git trailer** emitted by `commit.sh`, so the
Added/Changed/Removed signal is machine-readable straight from `git log --format='%(trailers:key=Category)'`
— resilient even without the ticket. The change is **additive**: `archive.sh` keeps stamping the
frontmatter (so `write-release-note`'s existing read path is untouched), and the trailer becomes a
second, log-native source that `/report`'s `collect-commits.sh` can parse so downstream grouping no
longer depends on the ticket surviving.

It mirrors the trip-commit precedent (`20260310220756`) of moving a structured field into the
commit message via the shell script rather than reconstructing it from context.

## Policies

The standard engineering policies that govern this ticket. The implementing session **MUST** read
each linked policy hard copy before writing code and keep every change defensible against that
policy's Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/observability.md` — **central:** a `Category:` trailer is the commit-log analogue of a structured field over an unstructured blob — searchable/aggregatable signal designed as an input for automation (`/report`, `write-release-note`), exactly what this policy asks for.
- `workaholic:implementation` / `policies/command-scripts.md` — the trailer is emitted by the one canonical `commit.sh`, computed in-script (not assembled in command markdown); one source of truth.
- `workaholic:implementation` / `policies/coding-standards.md` — applies to the `commit.sh`/`archive.sh`/`collect-commits.sh` edits; keep them POSIX.
- `workaholic:implementation` / `policies/directory-structure.md` — logic stays in the bundled scripts; generated copies under `outputs/`.
- `workaholic:operation` / `policies/ci-cd.md` — reproducible local + CI verification; rebuild `outputs/` in lockstep (Outputs Freshness).

Repo-own rules (CLAUDE.md): **`rules/shell.md`** POSIX (enforced by `hooks/posix-lint.sh`),
**Shell Script Principle**, **Outputs Freshness** (rebuild `outputs/`), **no version bump**.

## Key Files

- `plugins/workaholic/skills/commit/scripts/commit.sh` — emit the `Category:` trailer in the commit body. Add it as a git trailer line (with `Co-Authored-By`) — either a new positional/flag (`--category <Added|Changed|Removed>`) or an env var, whichever keeps the signature cleanest after ticket 1's restructure. Validate the value against the three allowed categories; fail-fast on an invalid one.
- `plugins/workaholic/skills/drive/scripts/archive.sh` — the CATEGORY heuristic already exists (lines 43-47). Pass that computed value into `commit.sh` so the trailer and the frontmatter come from the same source. Keep the `update.sh` frontmatter stamping (additive — do not remove it).
- `plugins/workaholic/skills/report/scripts/collect-commits.sh` — extend it to parse the trailer (`git log --format=... %(trailers:key=Category,valueonly)` or equivalent) and emit a `category` field per commit, so `/report` can group by a log-native value.
- `plugins/workaholic/skills/report/SKILL.md` — document the new `category` field in the Overview-Generation schema; note that the Changes/§4 grouping can now read it (keeping ticket frontmatter as the fallback).
- `plugins/workaholic/skills/write-release-note/SKILL.md` — currently groups by ticket-frontmatter `category` (Content Structure l.26-35, Guideline 4). State that the trailer is the resilient source and frontmatter remains the immediate read; only rewire the read if it stays equivalent (avoid breaking the existing path).
- `plugins/workaholic/skills/drive/scripts/update.sh` — unchanged (still stamps `category:` frontmatter); referenced to confirm the additive design.
- `scripts/test-workflow-scripts.mjs` — `testArchive` already asserts `category: Added` is derived from the `Add` verb (l.262). Add an assertion that the **commit message** now carries `Category: Added` as a trailer (`git log -1 --format=%B` includes it, and/or `%(trailers:key=Category)` returns it). Add a `collect-commits.sh` assertion that the emitted JSON carries the parsed `category`.
- `scripts/build-plugins/build.mjs` — `commit`/`report` ship into `outputs/workflows`; rebuild after the change.

## Related History

Builds directly on the body-restructure ticket and reuses the trip-commit field-in-message pattern.

Past tickets that touched similar areas:

- [20260210154917-expand-commit-message-sections.md](.workaholic/tickets/archive/drive-20260210-121635/20260210154917-expand-commit-message-sections.md) - The body-format precedent this trailer rides alongside.
- [20260310220756-trip-commit-message-rules.md](.workaholic/tickets/archive/drive-20260310-220224/20260310220756-trip-commit-message-rules.md) - Precedent for mechanically writing a structured field ([Agent] subject, Phase/Step body) into the commit via the shell script — the analogue of a Category trailer.
- [20260212182713-fix-release-note-generation.md](.workaholic/tickets/archive/drive-20260212-122906/20260212182713-fix-release-note-generation.md) - The release-note grouping path that consumes Added/Changed/Removed today (via ticket frontmatter), the consumer this ticket makes log-native.

## Implementation Steps

1. **Emit the trailer in `commit.sh`.** Accept the category (flag, positional, or env) validated against `Added|Changed|Removed`; append `Category: <value>` as a git trailer next to `Co-Authored-By`. Keep POSIX.
2. **Feed it from `archive.sh`.** Pass the already-derived `CATEGORY` (lines 43-47) into `commit.sh`; keep the `update.sh` frontmatter stamping (additive).
3. **Parse it in `collect-commits.sh`.** Emit a per-commit `category` field from the trailer so `/report` reads a log-native value (ticket frontmatter remains the fallback).
4. **Document** the field in `report/SKILL.md` and note the resilient-source relationship in `write-release-note/SKILL.md`; do not break the existing frontmatter read.
5. **Test:** assert the `Category:` trailer in the archived commit and the parsed `category` in `collect-commits.sh` output.
6. **Regenerate + verify:** `build.mjs`, `verify.mjs`, `validate-metadata.mjs`, `test-workflow-scripts.mjs`, `posix-lint.sh` — all green; stage `plugins/` + `outputs/` together.

## Considerations

- **Additive, not a migration.** Keep stamping `category:` frontmatter so `write-release-note`'s current read is unbroken; the trailer is a parallel, resilient source. Only switch the primary read to the trailer if it is provably equivalent and tested. (`plugins/workaholic/skills/drive/scripts/update.sh`, `plugins/workaholic/skills/write-release-note/SKILL.md`)
- **One source for both surfaces.** The trailer and the frontmatter must come from the *same* computed `CATEGORY` in `archive.sh` (lines 43-47) so they can never disagree. Don't re-derive the category separately in `commit.sh`. (`plugins/workaholic/skills/drive/scripts/archive.sh`)
- **Abandonment commits** have no category (they are not Added/Changed/Removed work); the trailer should be omitted there, not forced. Confirm the direct `commit.sh` abandonment invocation handles an absent category cleanly. (`plugins/workaholic/skills/drive/SKILL.md`)
- **Trailer hygiene:** use a real git trailer (`Key: Value`, recognized by `git interpret-trailers`/`%(trailers)`), so `git log --format='%(trailers:key=Category,valueonly)'` works. Validate the value to keep the schema closed (fail-fast on a typo'd category). (`plugins/workaholic/skills/commit/scripts/commit.sh`)
- **Depends on ticket 1** (`20260627210216`): both edit `commit.sh`'s signature and `collect-commits.sh`; sequencing avoids a merge conflict on the same lines. `/drive` must implement this second.
- **Outputs lockstep + POSIX gate** apply as in ticket 1.

## Final Report

<!-- filled at drive time -->
