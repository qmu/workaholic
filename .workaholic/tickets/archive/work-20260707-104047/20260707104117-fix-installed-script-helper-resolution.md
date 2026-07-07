---
created_at: 2026-07-07T10:41:17+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.5h
commit_hash: 7a77556
category: Changed
depends_on:
mission:
---

# Fix Installed Script Helper Resolution

## Overview

Several workflow shell scripts call helper scripts from sibling skills through a repository-source-layout relative path. That path works when invoked from `plugins/workaholic/skills/...` inside this repository, but it is not a stable contract for installed plugin layouts. Make cross-skill shell helper references resolve from the installed same-plugin `skills/` root as well as from the source tree, and add a regression test so helper lookup failures are caught before release.

## Policies

The standard engineering policies synced from the corporate site into the `workaholic` policy skills that govern this ticket:

- `workaholic:implementation` / `policies/directory-structure.md` - the fix stays inside existing plugin skill, script, generated-output, and test directories.
- `workaholic:implementation` / `policies/coding-standards.md` - the Node build/test updates should remain typed-by-structure, explicit, and mechanically verifiable.
- `workaholic:implementation` / `policies/command-scripts.md` - workflow helper scripts must be runnable consistently by any developer or agent from supported plugin layouts.
- `workaholic:implementation` / `policies/objective-documentation.md` - build-script comments and ticket evidence must describe actual resolution behavior, not hoped-for portability.
- `workaholic:operation` / `policies/ci-cd.md` - the release proof must run locally through the same build, verify, and smoke-test commands used by maintainers.

## Key Files

- `plugins/workaholic/skills/drive/scripts/list-todo.sh` - uses the source-layout-only helper path for `gather/scripts/user-slug.sh`.
- `plugins/workaholic/skills/drive/scripts/promote-icebox.sh` - uses the same helper lookup pattern for per-user queue routing.
- `plugins/workaholic/skills/create-ticket/scripts/sweep-todo.sh` - uses the same helper lookup pattern before moving stray todo tickets.
- `plugins/workaholic/skills/drive/scripts/archive.sh` - contains cross-skill references to `mission`, `okf`, and `commit` helpers and should follow the same resolution convention.
- `plugins/workaholic/skills/mission/scripts/create.sh` - calls `gather` and `okf` helpers and should be included in the audit.
- `scripts/build-plugins/script-ref-patterns.mjs` - defines which source script references are detected for generated workflow closures.
- `scripts/build-plugins/build.mjs` - rewrites detected cross-skill script references into generated workflow bundles.
- `scripts/build-plugins/verify.mjs` - validates generated script references and source reference forms.
- `scripts/test-workflow-scripts.mjs` - should add an installed-layout regression that exercises affected scripts from a copied plugin `skills/` tree, not only from the repository source paths.
- `outputs/workflows/` - regenerated portable workflow plugin output after any build-rule changes.
- `.agents/plugins/marketplace.json` and `.claude-plugin/marketplace.json` - confirm the raw `workaholic` and generated `workflows` plugin surfaces still point at the intended directories after the fix.

## Related History

Past tickets established the generated workflow bundle and the cross-skill closure rules, but the current failure mode shows the raw installed plugin layout needs equal coverage.

Past tickets that touched similar areas:

- [20260527012301-build-step-for-self-contained-portable-skills.md](.workaholic/tickets/archive/work-20260518-235327/20260527012301-build-step-for-self-contained-portable-skills.md) - introduced generated self-contained workflow skills and static reference verification.
- [20260706203044-mission-artifact-type-and-command.md](.workaholic/tickets/archive/work-20260706-182705/20260706203044-mission-artifact-type-and-command.md) - recorded the generated workflow nesting model and the need for build-detectable script references.
- [20260706203046-mission-progress-and-changelog-automation.md](.workaholic/tickets/archive/work-20260706-182705/20260706203046-mission-progress-and-changelog-automation.md) - expanded build closures through cross-skill script calls and noted that static verification must catch broken generated paths.
- [20260707023034-fix-codex-hooks-json-parse-error.md](.workaholic/tickets/archive/work-20260706-182705/20260707023034-fix-codex-hooks-json-parse-error.md) - handled a cross-agent plugin compatibility issue and added schema-level guard coverage.

## Implementation Steps

1. Audit all shell scripts under `plugins/workaholic/skills/**/scripts/*.sh` for cross-skill helper references that include `../../../../workaholic/skills/`.
2. Standardize cross-skill helper references on a same-plugin relative form that resolves from both source and installed layouts, for example `${SCRIPT_DIR}/../../<skill>/scripts/<helper>.sh` from `skills/<caller>/scripts/`.
3. Update `scripts/build-plugins/script-ref-patterns.mjs`, `build.mjs`, and `verify.mjs` so the new source reference form is build-detectable, closure-producing, and verified. Preserve generated workflow self-containment.
4. Update `scripts/build-plugins/README.md` comments/table entries so the documented script reference convention matches the actual one.
5. Add a smoke regression in `scripts/test-workflow-scripts.mjs` that creates a temporary installed-plugin-style tree with `skills/<skill>/scripts/...`, runs the non-destructive affected scripts from that tree inside a throwaway git repo, and asserts they find `gather/scripts/user-slug.sh`.
6. Regenerate `outputs/workflows/` with `node scripts/build-plugins/build.mjs`.
7. Confirm manifests still expose the intended raw and portable plugin surfaces; do not accidentally make Codex rely on a source-only path convention.

## Quality Gate

**Acceptance criteria** - the checkable conditions that must hold:

- No shell script under `plugins/workaholic/skills/**/scripts/*.sh` uses a source-layout-only `../../../../workaholic/skills/` helper path.
- Cross-skill helper calls from source scripts use one documented same-plugin relative convention and remain discoverable by the build closure logic.
- `list-todo.sh`, `sweep-todo.sh`, and other non-destructive helper-resolving scripts can run from a temporary installed-plugin-style `skills/` tree without a missing-file error.
- Generated `outputs/workflows/skills/**` remains self-contained: every emitted `${SCRIPT_DIR}/...` script reference resolves to an existing file.
- The raw `workaholic` plugin surface and generated `workflows` surface remain intentionally separated in the manifests.

**Verification method** - the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs`
- `node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`
- `plugins/workaholic/hooks/posix-lint.sh plugins/workaholic/skills`
- `rg -n '\\.\\./\\.\\./\\.\\./\\.\\./workaholic/skills/' plugins/workaholic/skills -g '*.sh'` returns no matches.
- `git status --porcelain outputs/workflows plugins/workaholic/hooks/policy-index.md` is empty after the build output is committed or intentionally staged.

**Gate** - what must pass before approval:

- All verification commands above pass locally.
- The new smoke test fails before the helper-resolution fix and passes after it.
- The final implementation notes state which script-reference convention is now canonical for future workflow scripts.

## Considerations

- Keep the build closure detector and source lint in lockstep; a source form that passes lint but is invisible to `build.mjs` can ship a broken generated plugin (`scripts/build-plugins/script-ref-patterns.mjs`).
- Avoid computed helper paths that hide the referenced skill name from the build. If a resolver function is introduced, it still needs a static, testable dependency signal for generated workflow closure construction (`scripts/build-plugins/build.mjs`).
- Do not only patch one caller. `list-todo.sh`, `sweep-todo.sh`, `promote-icebox.sh`, `archive.sh`, and mission scripts all exercise the same class of cross-skill helper lookup (`plugins/workaholic/skills/**/scripts/*.sh`).
- The generated workflow layout currently nests closure scripts under `outputs/workflows/skills/<target>/<skill>/scripts/`; the source convention must either work there unchanged or be rewritten predictably by the build (`outputs/workflows/skills/`).
- `archive.sh` is destructive in real repositories, so the regression should use throwaway git repositories and prefer non-destructive scripts where possible. If `archive.sh` needs coverage, reuse the existing hermetic archive test pattern (`scripts/test-workflow-scripts.mjs`).

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: The canonical cross-skill shell reference is now `${SCRIPT_DIR}/../../<skill>/scripts`, with optional `/helper.sh` after it. This is the same relative shape in the source plugin, installed raw plugin, and generated workflow bundles because each layout keeps sibling skills under one shared `skills/` directory.
  **Context**: The build detector and verifier must recognize both direct helper calls and directory variables ending at `/scripts`; otherwise a helper directory can resolve in one layout but be invisible to generated closure construction.
