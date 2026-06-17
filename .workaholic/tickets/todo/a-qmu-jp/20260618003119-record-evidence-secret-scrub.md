---
created_at: 2026-06-18T00:31:19+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort:
commit_hash:
category:
depends_on:
---

# Scrub secrets in `record-evidence.sh` before writing evidence to the story

## Overview

`record-evidence.sh` (added on the immediately preceding branch) appends a
`## Deployment Evidence` block — including the confirmation command/URL and the
observed result — to the branch story, which becomes the **public PR body**.
Today the only guard is a comment in the script telling operators not to pass
credentials. There is **no automatic check**, so a confirmation result that
happens to contain an API key, bearer/basic auth header, token, or session
cookie would be written verbatim into a version-controlled, publicly visible
file.

Add a pre-write secret scan so evidence cannot leak a secret: detect common
secret patterns in the `<result>` (and other free-text args) and either refuse
to write (exit non-zero with a clear message) or redact the matched spans
before appending.

## Key Files

- `plugins/workaholic/skills/ship/scripts/record-evidence.sh` - PRIMARY. The script that appends the evidence block. Add the scan/redaction step before the `>> "$story"` append, keeping it POSIX (`#!/bin/sh -eu`, no bash-isms) per `rules/shell.md`.
- `plugins/workaholic/skills/ship/SKILL.md` - §2-5c documents `record-evidence.sh`; note the secret-scrub behavior (refuse vs redact) so the Ship Flow step 5 prose matches.
- `scripts/test-workflow-scripts.mjs` - Add hermetic cases: a clean result writes the block; a result containing a fake token is refused (or redacted) and the secret never lands in the story.
- `outputs/workflows/skills/ship/ship/scripts/record-evidence.sh` - GENERATED copy; regenerate `outputs/` after the change (`node scripts/build-plugins/build.mjs`), CI-guarded.

## Related History

The script this hardens was introduced on the previous branch as part of the confirm-before-merge ship reorder; this is the secret-safety follow-up flagged in that branch's story.

Past tickets that touched similar areas:

- [20260617231848-ship-confirm-in-production-before-merge.md](.workaholic/tickets/archive/work-20260617-231848/20260617231848-ship-confirm-in-production-before-merge.md) - Added `record-evidence.sh` and the `## Deployment Evidence` capture; its story explicitly flagged the missing secret scrub as a concern (carried as `.workaholic/concerns/48-record-evidence-sh-does-not-scrub.md`).

## Implementation Steps

1. **Add a secret-pattern scan** to `record-evidence.sh` over the free-text inputs (primarily `<result>`, also `<command>`/method text). Cover common shapes: long hex/base64 tokens, `AKIA…`/cloud key prefixes, `Authorization: Bearer …` / `Basic …`, `xox[baprs]-…` (Slack), `gh[pousr]_…` / `github_pat_…`, generic `key=`/`token=`/`password=` assignments, and PEM headers.
2. **Choose the failure mode** (default: refuse). On a match, exit non-zero with `{"recorded": false, "reason": "possible_secret"}` and a message naming what to remove, so the Ship Flow surfaces it and the operator re-supplies a sanitized result. Optionally support a redaction mode (replace the matched span with `***redacted***`) behind a flag if refuse is too strict in practice.
3. **Keep it POSIX and self-contained** — implement the scan with `grep -E`/`case` (no bash arrays/`[[ ]]`); the script already runs on Alpine. Do not depend on python for the scan if avoidable (keep the existing python/node/perl use only where already present).
4. **Document** the behavior in `record-evidence.sh`'s header and in `ship/SKILL.md` §2-5c / Ship Flow step 5.
5. **Add smoke tests** in `scripts/test-workflow-scripts.mjs`: clean result → block written; token-bearing result → refused (or redacted), and assert the secret string is absent from the story.
6. **Regenerate `outputs/`** and run `node scripts/build-plugins/{build,verify,validate-metadata}.mjs` and `node scripts/test-workflow-scripts.mjs`.

## Considerations

- **system-safety / secret handling** — evidence is committed and shown on the PR; never let a credential reach it. Pair this with the existing rule that credentials used for confirmation are transient and never persisted (`plugins/workaholic/skills/system-safety/SKILL.md`, `record-evidence.sh` header).
- **False positives vs leakage** — refusing on a suspected secret is safer than redacting silently (the operator learns and fixes the source). If refusal proves noisy in real use, add an opt-in redaction mode rather than weakening the scan.
- **Scope** — the scan is a guardrail, not a vault; it catches common shapes, not every possible secret. Document that limitation so it is not mistaken for a guarantee.
- **Shell rule** — keep all logic in the bundled POSIX script; no inline conditionals in markdown (`CLAUDE.md` Shell Script Principle, `rules/shell.md`).
