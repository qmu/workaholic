---
created_at: 2026-06-27T15:32:48+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Infrastructure]
effort:
commit_hash:
category:
depends_on: [20260627153246-posix-convert-validate-ticket-hook.md, 20260627153247-posix-convert-remaining-plugin-scripts.md]
---

# Make the POSIX-sh rule self-enforcing: run the smoke harness under `sh` + add a bash-shebang lint

## Overview

The `rules/shell.md` POSIX-sh convention has now regressed **twice** — it was established in
Jan 2026 (`20260127103522`) and silently re-violated by ~31 scripts as the plugins merged.
Converting them (tickets `20260627153246` + `20260627153247`) fixes the present, but nothing
stops a third regression: a new `#!/bin/bash` script with `[[ ]]`/arrays passes every current
check. Two gaps make the rule unenforceable today:

1. **`scripts/test-workflow-scripts.mjs` invokes scripts with `bash`**, so even a bashism-laden
   script passes — the harness proves behavior, not POSIX-compliance.
2. **No check fails on a bash shebang or a bashism** under `plugins/workaholic`, so drift is invisible
   until it breaks on Alpine in production.

This ticket closes both: switch the harness to invoke converted scripts under `sh` (ideally
`dash` when available, the strictest common POSIX shell) so a bashism actually fails a test, and
add a fast **shebang/bashism lint** (a bundled doctor-style script, runnable identically by a
developer and CI) that fails on any `#!/bin/bash`, `#!/usr/bin/env bash`, or obvious bashism
(`[[`, `=~`, `<<<`, `${BASH_SOURCE`, `declare `) in any `plugins/workaholic/**/*.sh`. It must run
green only **after** the two conversion tickets land — hence the `depends_on`.

## Policies

The standard engineering policies that govern this ticket. The implementing session **MUST**
read each linked policy hard copy before writing code.

- `workaholic:implementation` / `policies/directory-structure.md` — the new lint script lands in a predictable place (a skill `scripts/` dir or `scripts/`, mirroring `layout-doctor.sh`) (applies to all code work).
- `workaholic:implementation` / `policies/coding-standards.md` — the lint is itself POSIX sh, fail-fast, no silent fall-through (applies to all code work).
- `workaholic:implementation` / `policies/command-scripts.md` — **central:** the lint must be one runnable command a developer and CI invoke identically (no second re-implementation); the harness change keeps `dev = CI`.
- `workaholic:implementation` / `policies/policy-conformance-audit.md` — this *is* a conformance audit turned into an automated gate: surface POSIX drift as a hard failure rather than letting it re-accrete.
- `workaholic:operation` / `policies/ci-cd.md` — reproducible local + CI verification; the lint plugs into the same `node scripts/test-workflow-scripts.mjs` / `verify.mjs` pattern the repo already runs.
- `workaholic:implementation` / `policies/observability.md` — the lint output is structured and actionable (which file, which line, which bashism), not free-form.

Repo-own rules (CLAUDE.md): the hard rule **`plugins/workaholic/rules/shell.md`** (what the lint
enforces); **Shell Script Principle** + **Skill Script Path Rule** (lint logic is a bundled script,
referenced via `${CLAUDE_PLUGIN_ROOT}` if hosted in a skill); any **new script-bearing skill** carries
`metadata.internal: true`; if the lint host is in a shipped closure, **Outputs Freshness** applies.

## Key Files

- `scripts/test-workflow-scripts.mjs` — switch the per-script `bash ${SCRIPTS.x}` invocations to `sh` (prefer `dash` when present, falling back to `sh`). The `user-slug` test already uses `sh` — mirror it. This is what makes the suite a real POSIX gate.
- **New** `plugins/workaholic/hooks/posix-lint.sh` (or `skills/<host>/scripts/posix-lint.sh`) — the shebang/bashism linter. Mirror `plugins/workaholic/hooks/layout-doctor.sh`'s shape: walk a target tree, emit structured findings + a human summary, non-zero exit on any violation. Co-locating in `hooks/` (like `layout-doctor.sh`) keeps it out of `outputs/` and avoids a rebuild.
- `plugins/workaholic/hooks/layout-doctor.sh` — the reference: a read-only `#!/bin/sh -eu` auditor that classifies a tree and emits JSON + stderr summary.
- `scripts/test-workflow-scripts.mjs` (again) — add a test that runs `posix-lint.sh` against `plugins/workaholic` and asserts **zero** findings (the whole point), plus a hermetic fixture with a planted `#!/bin/bash` file asserting it IS flagged.
- `plugins/workaholic/rules/shell.md` — document the lint invocation so the rule names its own enforcement command.
- `.github/workflows/` — wire the lint into CI if the repo runs `test-workflow-scripts.mjs` there; otherwise the smoke-test assertion already covers it (a developer and CI run the same `node scripts/test-workflow-scripts.mjs`).

## Related History

The enforcement-as-script pattern this ticket reuses already exists in the repo.

Past tickets that touched similar areas:

- [20260127103522-posix-shell-compatibility.md](.workaholic/tickets/archive/feat-20260126-214833/20260127103522-posix-shell-compatibility.md) - Established `rules/shell.md` but added **no** automated guard, which is why it regressed twice; this ticket supplies the missing guard.
- [20260528123011-add-workflow-script-smoke-tests.md](.workaholic/tickets/archive/work-20260528-122941/20260528123011-add-workflow-script-smoke-tests.md) - Created the harness this ticket upgrades from a bash runner to a POSIX gate.

## Implementation Steps

1. **Switch the harness to a POSIX shell.** In `scripts/test-workflow-scripts.mjs`, replace the hard-coded `bash ${SCRIPTS.x}` runner(s) with a resolver that prefers `dash`, then `sh`, and invokes converted scripts under it. Run the full suite; any script still relying on a bashism now fails — fix or confirm the conversion tickets covered it. (This step is *why* the ticket depends on the two conversions: under `bash` they pass regardless; under `sh` they must be genuinely POSIX.)
2. **Write `posix-lint.sh`** (`#!/bin/sh -eu`, read-only): accept an optional target dir (default the repo's `plugins/workaholic`), walk `**/*.sh`, and flag (a) any shebang that is not `#!/bin/sh*`, and (b) any line containing a bashism token (`[[`, `]]`, ` =~ `, `<<<`, `${BASH_SOURCE`, `declare `, `local `). Emit JSON findings `{path, line, kind, snippet}` + a human summary on stderr; exit non-zero iff any finding. Fail safe if the tree is absent.
3. **Add smoke coverage** in `scripts/test-workflow-scripts.mjs`: (a) run `posix-lint.sh` against the real `plugins/workaholic` and assert **0 findings** (regression lock — green only after the conversions); (b) build a throwaway dir with a planted `#!/bin/bash`/`[[ ]]` script and assert it IS flagged with the right `kind`.
4. **Document the command** in `rules/shell.md`: add a short "Enforcement" note pointing at `bash ${CLAUDE_PLUGIN_ROOT}/hooks/posix-lint.sh` (and that CI runs it via the smoke harness), so the rule and its guard live together.
5. **Verify.** `node scripts/test-workflow-scripts.mjs` (now under `sh`/`dash`, plus the two new lint tests) all green; `node scripts/build-plugins/verify.mjs`. Run `build.mjs` **only** if the lint is hosted inside a shipped skill closure (hosting it in `hooks/` avoids that).

## Considerations

- **Ordering is load-bearing:** this ticket's own regression-lock test (lint against the real tree → 0 findings) can only pass after `20260627153246` and `20260627153247` convert every script. Hence `depends_on` lists both; `/drive` must implement it last.
- **`dash` may be absent** on some dev machines; resolve `dash || sh` and skip gracefully (like the existing `jq`-absent skips) so the harness never hard-fails on a missing shell — but ensure CI has a real POSIX shell so the gate has teeth there. (`scripts/test-workflow-scripts.mjs`)
- **Keep the lint cheap and obvious** — a token grep, not a full shell parser. False positives on a legitimate `local`-looking string in a heredoc are acceptable to flag (and easily worked around); the policy bans these tokens outright. (`policy-conformance-audit`)
- **Host the lint in `hooks/`** (beside `layout-doctor.sh`) to keep it out of `outputs/` and avoid a build/rebuild and bundle bloat — the same judgment the layout doctor made. If instead hosted in a skill, that skill needs `metadata.internal: true` and an `outputs/` rebuild.
- **This is the anti-third-regression** measure both discovery passes recommended; without it the conversion is a point-fix that will rot again. (`plugins/workaholic/rules/shell.md`)

## Final Report

<!-- filled at drive time -->
