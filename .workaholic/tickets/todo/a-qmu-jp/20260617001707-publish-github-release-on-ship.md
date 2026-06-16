---
created_at: 2026-06-17T00:17:07+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on: [20260617001706-move-release-note-generation-to-ship.md]
---

# Publish a GitHub Release on successful ship

## Overview

When a ship completes successfully, publish a GitHub Release (via
`gh release create`) from the generated release-note text, so the repo keeps real
release records on GitHub. Depends on
[20260617001706-move-release-note-generation-to-ship.md], which moves note
generation into `/ship` and establishes the multi-release file scheme.

**Conditional on existing CI (per the user's rule):** if the repository already
has a GitHub Actions workflow that publishes releases (workaholic itself has
`.github/workflows/release.yml`, which runs `gh release create` on push to main —
see `.workaholic/policies/delivery.md`), `/ship` must **not** publish — CI owns it,
and double-publishing would conflict. If no such workflow exists, `/ship` performs
the deploy and creates the GitHub Release itself. This makes the feature correct
both in workaholic (CI publishes) and in arbitrary user repos that adopt the plugin
(no CI → ship publishes).

The logic is a new **bundled script** `publish-release.sh` under the ship skill —
never inline shell in markdown (CLAUDE.md Shell Script Principle). `core:ship`
stays the portable, agent-neutral essence (plain `gh` CLI, no Claude-only
mechanism), so the worktree/trip path inherits publishing for free via
`core:trip-protocol`'s Trip Ship wrapper.

## Key Files

- `plugins/core/skills/ship/scripts/publish-release.sh` - **NEW** bundled script. Inputs: branch, merge commit hash, the release-note file path(s), and a derived tag/title. (1) Detect an existing release-publishing GH Actions workflow by scanning `.github/workflows/*.yml`/`*.yaml` for `gh release create`, `softprops/action-gh-release`, or `actions/create-release`; if found, return `{"published": false, "reason": "ci_publishes"}` and exit 0. (2) Otherwise derive a unique tag and run `gh release create <tag> --title "<title>" --notes-file <note> --latest --target <commit>` per release note. Tolerate "release already exists" idempotently. Return JSON `{published, tag, url, reason}`.
- `plugins/core/skills/ship/SKILL.md` - Add a "Publish GitHub Release" step to the Ship Flow (§5, L126-135) after Merge PR + Verify (gated on success), and a `§2` script-list entry for `publish-release.sh`. Add a confirmation note: the command (main agent) asks via AskUserQuestion before publishing when CI is absent.
- `plugins/work/commands/ship.md` - Thin command; no logic, optionally a one-line routing note. The AskUserQuestion confirmation happens at command/main-agent level (one-level fan-out rule).
- `plugins/core/skills/trip-protocol/SKILL.md` - Trip Ship flow (L313-318) delegates to `core:ship` Ship Flow, so it inherits publishing — but confirm `cleanup-worktree.sh` (step 3) runs **after** the publish step so nothing is lost. Likely no code change, just verify ordering.
- `.github/workflows/release.yml` + `.workaholic/policies/delivery.md` - The existing CI publish mechanism `publish-release.sh` must detect and defer to. `release.yml` uses `ls -t` to pick the most-recent note; note the multi-release scheme from the dependency ticket when reconciling.
- `scripts/test-workflow-scripts.mjs` - Add a hermetic smoke test for `publish-release.sh`'s **detection** branch (temp repo with/without a release workflow), asserting it skips when CI is present without calling `gh`.
- `dist/workflows/skills/ship/` - GENERATED mirror; regenerate via `node scripts/build-plugins/build.mjs` (the new script must appear in the closure).

## Related History

- [20260406204012-fix-missing-release-notes.md](.workaholic/tickets/archive/work-20260406-193458/20260406204012-fix-missing-release-notes.md) - The existing `release.yml` Actions release-publish mechanism `publish-release.sh` detects and defers to.
- [20260528091259-ship-deploy-doc-from-claude-md.md](.workaholic/tickets/archive/work-20260528-091259/20260528091259-ship-deploy-doc-from-claude-md.md) - Most recent ship change: deploy/verify sourced from `CLAUDE.md`, the no-inline-shell/`${CLAUDE_PLUGIN_ROOT}` conventions, and the dist-regen discipline this ticket follows.
- [20260527012300-decouple-core-ship-from-trip.md](.workaholic/tickets/archive/work-20260518-235327/20260527012300-decouple-core-ship-from-trip.md) - `core:ship` is the agent-neutral essence wrapped by trip-protocol; publish added to Ship Flow propagates to both paths — do not duplicate into trip-protocol.
- [42-release-workflow-divergence.md](.workaholic/concerns/42-release-workflow-divergence.md) - Active concern that the `/release` command is stale; this feature touches the same release/versioning surface and should note (not necessarily fix) the overlap.

## Implementation Steps

1. **Write `publish-release.sh`** with the two branches: CI-detection (scan workflows; skip with `reason: ci_publishes`) and publish (`gh release create` per note, idempotent on already-exists, `--target <merge-commit>`).
2. **Derive the tag robustly** (see Considerations) — prefer the project version from `CLAUDE.md` Version Management / `.claude-plugin/marketplace.json` when present, else fall back to the latest `gh release view`/git tag incremented, else a branch/date-based tag. For multiple releases on one branch, ensure tag uniqueness (e.g. `-2` suffix mirroring the note file's `-N`).
3. **Wire it into Ship Flow** (§5) after Merge + Verify, gated on success, with a command-level AskUserQuestion confirmation when publishing (skip the prompt when CI owns publishing).
4. **Confirm trip ordering**: `core:trip-protocol` cleanup runs after publish.
5. **Add a smoke test** for the detection branch in `scripts/test-workflow-scripts.mjs`.
6. **Regenerate `dist/`** and run `verify.mjs`, `validate-metadata.mjs`, `test-workflow-scripts.mjs`.
7. **Note `/release` overlap**: leave a comment / update `.workaholic/policies/delivery.md` so the relationship between CI `release.yml`, `/ship` publishing, and the `/release` command is documented (concern #42 territory).

## Considerations

- **Don't double-publish.** The CI-detection gate is the core correctness
  property: in workaholic, `release.yml` publishes, so `/ship` must skip; in a
  user repo without it, `/ship` publishes. Detection scans `.github/workflows/`
  for known release actions/commands. (`.github/workflows/release.yml`,
  `.workaholic/policies/delivery.md`)
- **All shell logic in the bundled script** — tag derivation, the "release
  exists?" check, the workflow scan, and the `gh release create` call are
  conditional logic that MUST live in `publish-release.sh`, referenced as
  `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/publish-release.sh`. No inline
  conditionals/pipes in SKILL.md or the command. (CLAUDE.md Shell Script Principle, Skill Script Path Rule)
- **Keep `core:ship` portable.** `gh` is a portable external CLI, so plain
  `gh release create` keeps the skill agent-neutral and cross-agent-exposed; do
  not introduce any Claude-only mechanism into `core:ship`. The script makes the
  skill script-bearing, so it stays `metadata.internal: true` and ships via the
  regenerated `dist/workflows` artifact. (CLAUDE.md Cross-Agent Skill Exposure; `standards:implementation` Conservative Vendor Dependence — note generation stays decoupled from gh publishing.)
- **Tag derivation is the riskiest part for generic user repos.** A GitHub Release
  needs a tag; many user repos won't have workaholic's `marketplace.json` version.
  Derive defensively and make the script idempotent so re-running a ship never
  errors on an existing tag. (`publish-release.sh`)
- **Target the merge commit.** `merge-pr.sh` already returns the merge
  `commit_hash` and leaves the repo on synced `main`; pass it as `--target` so the
  release points at the merged state (requirement #3: notes + GitHub release land
  together). (`plugins/core/skills/ship/scripts/merge-pr.sh`)
- **One-level fan-out for confirmation.** The "publish this release?"
  AskUserQuestion is issued by the command/main agent, never a leaf. (CLAUDE.md One-Level Fan-Out)
- `standards:operation` (CI/CD): publishing from a committed, version-controlled
  note file records delivery as code; the detection gate keeps the automated CI
  path authoritative where it exists rather than splitting responsibility.
  (`plugins/standards/skills/operation/policies/ci-cd.md`)
