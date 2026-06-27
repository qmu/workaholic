---
created_at: 2026-06-27T15:32:46+09:00
author: a@qmu.jp
type: refactoring
layer: [Config, Infrastructure]
effort:
commit_hash:
category:
depends_on:
---

# Convert the `validate-ticket.sh` hook to POSIX sh (the bashism outlier)

## Overview

`plugins/workaholic/rules/shell.md` mandates POSIX sh for every `*.sh` in the plugin
(`#!/bin/sh -eu`, no `[[ ]]`, `=~`, arrays, `<<<`, `${BASH_SOURCE}`, `declare`) so scripts
run on Alpine containers that have no bash. `plugins/workaholic/hooks/validate-ticket.sh`
violates this the most by an order of magnitude: it carries `#!/bin/bash` and **40 `[[ ]]`,
20 `=~`, 2 `<<<` here-strings, 1 `${BASH_SOURCE}`, and 2 `local`**. Because it is the
single heaviest, highest-attention converter — a PostToolUse hook that fires on every
ticket Write/Edit and gates the `.workaholic/` layout — it gets its own ticket so the
rewrite can be reviewed in isolation rather than buried in a 30-file sweep.

This is **re-enforcement of an existing rule**, not new policy: the rule was created in
Jan 2026 (`20260127103522-posix-shell-compatibility.md`, which converted the then-five
scripts and wrote `rules/shell.md`) and has since regressed as the core/standards/work
plugins merged into `workaholic`. The hook is **Claude-only** (`hooks/` is excluded from
the `outputs/` bundle), so this conversion is **source-only — no `build.mjs`/`outputs/`
rebuild** is required, only the smoke-test gate.

## Policies

The standard engineering policies — synced from qmu.co.jp into the `workaholic` policy
skills — that govern this ticket. The implementing session **MUST** read each linked policy
hard copy before writing code and keep every change defensible against that policy's Goal
(目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — keep the script in place under `hooks/`; do not move or rename it (applies to all code work).
- `workaholic:implementation` / `policies/coding-standards.md` — fail-fast, declarative, no silent fall-through; `#!/bin/sh -eu` is the strict-mode analogue; every `case` must handle the unmatched input explicitly (applies to all code work).
- `workaholic:implementation` / `policies/command-scripts.md` — the hook must run identically for a developer, in CI, and on a bash-less container; a bash-only hook is exactly the environment-specific divergence this forbids.
- `workaholic:implementation` / `policies/containerization.md` — local = CI = production parity on a minimal Alpine image without adding bash; the Alpine rationale `rules/shell.md` cites.
- `workaholic:implementation` / `policies/observability.md` — fail-loud: strict mode must surface a failed step, not swallow it; the rejection messages must stay clear and actionable.
- `workaholic:operation` / `policies/ci-cd.md` — the conversion is proven by the same hermetic harness a developer and CI both run (`node scripts/test-workflow-scripts.mjs`).

Repo-own rules (CLAUDE.md): the hard rule **`plugins/workaholic/rules/shell.md`** (the literal
requirement); **Shell Script Principle** (no bashisms migrate into markdown); **Skill Script
Path Rule / Plugin Boundary Rule** (edit only `plugins/workaholic` source; never touch the
marketplace-installed copy). `rules/shell.md` requires **both** the `#!/bin/sh -eu` shebang
**and** a redundant explicit `set -eu` near the top ("some environments strip shebang flags").

## Key Files

- `plugins/workaholic/hooks/validate-ticket.sh` — the script to convert (275 lines). The whole body is in scope.
- `plugins/workaholic/rules/shell.md` — the target contract: `#!/bin/sh -eu` + explicit `set -eu`, no bashisms.
- `scripts/test-workflow-scripts.mjs` — the gate. `validate-ticket.sh` is double-covered (`testValidateLayout` for the layout gate + `testValidateTicket` for ticket-location rules); these must stay green. **Note:** the harness currently invokes the hook with `bash`, so it will NOT catch residual bashisms on its own — run the converted script under `sh`/`dash` manually (or temporarily) while developing. (Switching the harness to `sh` is the separate gate-hardening ticket `20260627153248`.)
- `plugins/workaholic/hooks/layout-doctor.sh` — a same-directory reference already at `#!/bin/sh -eu`; copy its POSIX idioms.
- `.workaholic/tickets/archive/feat-20260126-214833/20260127103522-posix-shell-compatibility.md` — the prior-art playbook for the same rewrites (arrays→newline strings, length checks, etc.).

## Related History

The POSIX-sh convention already exists and was established once; this hook is the worst
current regression of it.

Past tickets that touched similar areas:

- [20260127103522-posix-shell-compatibility.md](.workaholic/tickets/archive/feat-20260126-214833/20260127103522-posix-shell-compatibility.md) - Created `rules/shell.md` and converted the original 5 scripts off bash; contains the reusable bashism-rewrite recipes (same goal, smaller corpus).
- [20260213131504-enforce-absolute-paths-for-skill-scripts.md](.workaholic/tickets/archive/drive-20260213-131416/20260213131504-enforce-absolute-paths-for-skill-scripts.md) - Adjacent shell-convention work; the `${BASH_SOURCE}`→`$0` resolution here must preserve `${CLAUDE_PLUGIN_ROOT}`-style invocation.
- [20260528123011-add-workflow-script-smoke-tests.md](.workaholic/tickets/archive/work-20260528-122941/20260528123011-add-workflow-script-smoke-tests.md) - Established `scripts/test-workflow-scripts.mjs`, the verification harness this conversion runs.

## Implementation Steps

1. **Swap the shebang and add the fallback.** `#!/bin/bash` → `#!/bin/sh -eu`, and add an explicit `set -eu` immediately after (the script currently uses `set -e`; make it `set -eu`). Confirm `-u` does not trip on any legitimately-unset var (guard with `${VAR:-}` where needed).
2. **Resolve the script dir without `${BASH_SOURCE}`** (line ~46): replace `${BASH_SOURCE[0]}` with `$0` for the `hook_dir="$(cd -- "$(dirname -- "$0")" && pwd)"` allowlist-file lookup. Verify the allowlist still resolves when the hook is invoked by absolute path (its normal invocation).
3. **Rewrite every `[[ … =~ regex ]]`** (20 sites) to POSIX: prefer `case "$x" in pattern) … ;; esac` for fixed alternations (e.g. the `^(UX|Domain|Infrastructure|DB|Config)$` layer check, the `^(enhancement|bugfix|refactoring|housekeeping)$` type check, category/effort enums), and `printf '%s' "$x" | grep -qE 'regex'` for the genuinely regex checks (ISO-8601 `created_at`, email `author`, the `^[0-9]{14}-.*\.md$` ticket-shape, the `\.workaholic/` path tests, hex `commit_hash`).
4. **Rewrite every `[[ -z/-n/-f/! … ]]`** (the remaining `[[ ]]` of 40) to `[ … ]`/`test` with POSIX operators.
5. **Replace the two `<<<` here-strings** (the `while IFS= read -r layer; … done <<< "$layer_values"` and the `depends_on` loop) with `printf '%s\n' "$layer_values" | while IFS= read -r layer; do …; done` — and account for the subshell: a `exit 2` inside a piped `while` runs in a subshell, so capture failure (e.g. set a sentinel file or restructure so the validation failure still propagates a non-zero exit from the script). This is the **trickiest** rewrite; cover it with the smoke test.
6. **Drop `local`** in `validate_field` (POSIX functions have no `local`): use plain assignments with unique-enough names, or restructure the helper to echo its result without locals.
7. **Run the gate.** `node scripts/test-workflow-scripts.mjs` — both `testValidateLayout` and `testValidateTicket` must pass. Additionally run the converted hook directly under `sh validate-ticket.sh` and (if available) `dash validate-ticket.sh` with a few crafted `{tool_input:{file_path}}` payloads to prove no bashism survives. Confirm `node scripts/build-plugins/verify.mjs` is still green (hooks are not in `outputs/`, so it is vacuously unaffected — no `build.mjs` needed).

## Considerations

- **The piped-`while` subshell is the one real behavior trap** (`plugins/workaholic/hooks/validate-ticket.sh`, the `<<<` loops). Under bash `<<<` runs the loop in the current shell, so an inner `exit 2` exits the script; piping into `while` runs it in a subshell, so `exit 2` only leaves the subshell. Restructure (e.g. capture an invalid value and test after the loop, or `grep -vqE` the whole list at once) so an invalid `layer`/`depends_on` entry still makes the hook exit 2. The smoke test must assert an invalid layer is rejected.
- **`set -u` regressions.** The hook reads optional frontmatter fields; with `-u`, an unset variable aborts. Audit each variable for a `${VAR:-}` default so a ticket missing an optional field is handled by the existing logic, not killed by `-u`.
- **Source-only — do not rebuild `outputs/`.** `hooks/` is excluded from the cross-agent bundle, so this ticket must produce **no** `outputs/` diff. If a diff appears, something else changed. (`scripts/build-plugins/build.mjs` skips `hooks/`.)
- **The harness runs scripts under `bash`** (`scripts/test-workflow-scripts.mjs`), so green tests alone do not prove POSIX-compliance — that is why a manual `sh`/`dash` run is in the steps, and why the gate-hardening ticket (`20260627153248`) exists. Do not consider this done on `bash`-only evidence.
- **Behavior must be byte-identical** — same exit codes, same stderr messages, same accept/reject decisions. This is a refactor; the 15+ existing layout/ticket assertions are the contract.

## Final Report

<!-- filled at drive time -->
