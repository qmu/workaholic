---
paths:
  - '**/*.sh'
---

# Shell Script Conventions

- Use POSIX sh, not bash
  - Shebang must be `#!/bin/sh -eu` (strict mode: -e exits on error, -u errors on undefined vars)
  - Do not use bash-specific features (arrays, `[[ ]]`, `declare`, etc.)
  - This ensures scripts run on Alpine Linux containers which lack bash
- Use `set -eu` explicitly as fallback
  - Some environments may strip shebang flags

## Enforcement

This convention is machine-checked, so it cannot silently regress:

- **Lint:** `sh ${CLAUDE_PLUGIN_ROOT}/hooks/posix-lint.sh` audits every `*.sh` under
  `plugins/workaholic/` for a non-`#!/bin/sh` shebang or a bash-only construct
  (`[[ ]]`, `=~`, `<<<`, `${BASH_SOURCE}`, `BASH_REMATCH`, `declare`, statement-position
  `local`, array expansion). It emits JSON findings and exits non-zero on any violation.
  Read-only; point it at another directory with `sh hooks/posix-lint.sh <dir>`.
- **POSIX runner:** `node scripts/test-workflow-scripts.mjs` runs the scripts under the
  strictest available POSIX shell (`dash` when present, else `sh`) and asserts the lint
  reports zero findings against the real tree — so a developer and CI run the identical
  check, and a reintroduced bashism fails the suite instead of passing under a permissive bash.

## Reaching GitHub: REST only, never GraphQL

Every workflow script talks to GitHub through **one transport**,
`gather/scripts/gh-rest.sh` (`slug` / `api` / `available`), which is `gh api` — REST.

**Never `gh issue …`, `gh pr …`, or `gh repo …`.** Those subcommand families are
GraphQL-backed, and a Claude Code Web session is *not guaranteed to serve that surface*:
measured 2026-08-12 17:19 UTC in this repository's own `[Specificate]` tick,

> HTTP 403: This GraphQL query is not enabled for this session — only the pinned set of
> PR-review operations is served. Use REST via `gh api repos/{owner}/{repo}/...` instead.

while a run 80 minutes earlier used the same paths successfully. The capability is a
property of the **session**, not of the repository or the credential, so a script that
treats it as static does not degrade — it stops, at the worst possible moment: after the
branch is pushed and before the pull request exists.

This is a **conversion, not a fallback**. A REST-after-GraphQL ladder would keep two
behaviours to reason about and still fail whenever the 403 arrived in a shape the ladder
did not expect. One always-available transport cannot drift.

`gh release …` is **not** covered — it is REST-backed, and `ship/scripts/publish-release.sh`
uses it correctly.

**Enforcement:** `node scripts/test-workflow-scripts.mjs` scans every `*.sh` under
`plugins/workaholic/skills/` and `plugins/workaholic/hooks/` and fails on any
non-comment `gh issue|pr|repo <verb>` call. Its `GRAPHQL_GH_ALLOWLIST` is **empty on
purpose**: an allowlist holding most of the call sites would make the check theatre, so
an entry needs a stated reason why that site cannot use REST. The check exists because
the enumerated list of call sites that drove the conversion was already missing one
(`branching/scripts/list-worktrees.sh`, found by the sweep) — a list goes stale, a check
does not.
