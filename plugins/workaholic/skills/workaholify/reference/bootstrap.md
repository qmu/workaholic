# Web-bootstrap reference — mechanics and history

Companion to `SKILL.md` §4. The live rules are in the SKILL's Caveats list; this file carries the evidence and the decided limits.

## Why the fast path is version-gated (2026-08-04)

A cloud container image bakes a marketplace clone in, so "installed" can mean a version several releases behind the checkout, and skipping on mere presence made that permanent — the stale copy's retired mission migration dirtied the tree on every prompt and aborted every hourly drive tick on 2026-08-02〜04. The skip now requires the installed version to match the checkout's `.claude-plugin/marketplace.json`; anything else refreshes the marketplace and runs `plugin update` (or `install`).

Two limits of that gate are decided, not pending (2026-08-04): the hook runs at SessionStart and never refreshes a running session (swapping the plugin under already-loaded skills and always-on hooks mid-turn is worse than being one version behind, and there is no non-polling signal to hang a refresh on), and `WANTED` is read from a checkout that can itself be behind the base, so a stale clone and a stale baked-in install can agree and the fast path skips exactly when it should not. Both are answered by making the drift legible rather than adding a gate: `check-deps/scripts/check.sh` reports `checkout_version`/`version_drift` (and, on the second axis, `registry_version`/`registry_unreadable`/`loaded_version_behind_registry`), and `/drive` acts on them. The contract: *the bootstrap makes the install correct at session start; check-deps makes it honest afterwards.* The superseded-binding repair half was investigated and there is none inside the plugin — the binding, the cache layout and the registry are all the harness's; the evidence is recorded in `bootstrap/session-start.sh`'s header.

## The `gh` provisioning step (2026-08-06)

The web container ships no `gh`, and fourteen plugin scripts shell out to it — `publish-tree-pr.sh` pushed the branch and then reported `no_gh` instead of opening the pull request, and `merge-pr.sh` could not run at all, so every cloud `auto` unit was demoted to the PR path and every routine-published artifact waited for a human. The step is guarded on `command -v gh` (an already-provisioned container pays nothing), needs root, and is non-fatal in every branch — `gh` still absent afterwards is the status quo, not a regression, so the hook logs one legible line and session start still succeeds.

## The hook's own corrections (qmu/workaholic#126)

Recorded in the hook's header: it fails open by design, status-checks each step rather than wrapping them in a `{ … } || echo FAILED` group that silently reported success on total failure, drops the invalid `marketplace add --scope user`, and is idempotent. `matches_canonical` compares the installed copy byte-for-byte against `bootstrap/session-start.sh`, so an older copy is reported as drift (`hook_stale`) rather than passing because a file exists at the path. The `[Implement]` prompt's own precondition is what fails without the bootstrap — *"the workaholic plugin must be loaded … if it is not, post the failure and stop"* — which is why a missing bootstrap reads as healthy from the routines list and leaves no trace in git.
