---
created_at: 2026-07-07T02:30:34+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission:
---

# Fix Codex failing to load workaholic: drop the Claude-only `description` key from hooks.json

## Overview

When Codex installs the `workaholic` plugin (via `.agents/plugins/marketplace.json`, whose `workaholic` entry points at the raw `./plugins/workaholic` dir so Codex gets the design/implementation/operation policy skills), it fails to load with:

```
failed to parse plugin hooks config .../workaholic/1.0.81/hooks/hooks.json:
unknown field `description`, expected `hooks` at line 2 column 15
```

Root cause: `plugins/workaholic/hooks/hooks.json` opens with a top-level `description` key (line 2). That key **is** a documented, optional field in **Claude Code's** `hooks/hooks.json` schema — Claude reads it fine — but **Codex's** stricter parser rejects any top-level key other than `hooks`. Because the same source `hooks/hooks.json` is shared across both agents (the Codex marketplace installs the raw plugin dir), it must use only the intersection of the two schemas.

The `description` field was added in commit `ddb8e97` ("Collapse core, standards, and work into one workaholic plugin") purely as human documentation of what each hook does. It is redundant: `CLAUDE.md` already documents every hook (the commit/branch/label guards, the layout gate, the working-directory advisory, and the always-on policy lens). The plugin's *real* description lives in `.claude-plugin/plugin.json`.

**Fix (minimal, developer-confirmed at `/ticket`):** remove the top-level `description` key from `plugins/workaholic/hooks/hooks.json`, leaving `{ "hooks": { … } }`. This is safe for Claude Code (the field is optional; hooks load identically) and unblocks Codex. Delete the content rather than relocating it (CLAUDE.md is the source of truth for the hooks). Add an automated guard so a re-added sibling key cannot silently break Codex again.

## Policies

The standard engineering policies — synced from qmu.co.jp into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each linked policy hard copy before writing code and keep every change defensible against that policy's Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — the fix stays within the plugin's `hooks/` layout and the repo tooling under `scripts/build-plugins/`; no new top-level surfaces.
- `workaholic:implementation` / `policies/coding-standards.md` — the JS added to `validate-metadata.mjs` follows house style.
- `workaholic:implementation` / `policies/objective-documentation.md` — the removed blob duplicated `CLAUDE.md`; the new guard is a verifiable schema assertion (hooks.json's only top-level key is `hooks`), not prose. Keep documentation single-sourced and checkable.
- `workaholic:operation` / `policies/ci-cd.md` — `validate-metadata.mjs` is the local/CI gate that already asserts Codex manifests are well-formed and version-aligned; extending it keeps "does this load on Codex?" answerable locally, and the whole check set must stay green.

## Key Files

- `plugins/workaholic/hooks/hooks.json` - remove the top-level `description` key (line 2), leaving `{ "hooks": { … } }`. This is the actual bug fix. The build never touches this file (there is no `hooks.json` under `outputs/`), so this is a direct source edit with no regeneration.
- `scripts/build-plugins/validate-metadata.mjs` - add a check that `plugins/workaholic/hooks/hooks.json` parses as JSON and its **only** top-level key is `hooks` (mirroring Codex's strict `deny_unknown_fields` parser), so CI fails if any sibling key (`description`, etc.) is reintroduced. This validator already owns "is the plugin well-formed for Codex?", so the guard belongs here.
- `scripts/test-workflow-scripts.mjs` - optional: a hermetic assertion covering the same top-level-shape invariant, if a smoke test is preferred over / in addition to the validate-metadata guard.
- `CLAUDE.md` - already documents every hook; confirm it still fully covers what the deleted `description` said (it does — the commit/branch/label guards, layout gate, working-directory advisory, and policy lens sections). Add a one-line note (Version Management / cross-agent section) that `hooks/hooks.json` must stay `{ "hooks": … }`-only for Codex compatibility, so the constraint is documented, not just guarded.
- `.agents/plugins/marketplace.json` - context only (the `workaholic` entry → `./plugins/workaholic` is why Codex reads `hooks/hooks.json`); no change required for the minimal fix.

## Related History

`ddb8e97` collapsed core/standards/work into the single `workaholic` plugin and introduced the `description` key on `hooks.json`. The cross-agent distribution model (CLAUDE.md "Cross-Agent Skill Exposure") already treats the plugin's `commands/`, `agents/`, `hooks/`, and `rules/` as Claude-Code-only — the stated assumption being that non-Claude agents "read only the `skills/` dir" so those dirs are "invisible, not broken." This bug is a counterexample: Codex, installing the raw plugin dir, **does** read `hooks/hooks.json` and parses it strictly. `validate-metadata.mjs` was itself added precisely to catch silent Codex-side breakage (version drift) that Claude-side checks missed; this extends that intent to hooks-config schema compatibility.

## Implementation Steps

1. **Remove the field.** Delete the top-level `"description": "…"` key (line 2) from `plugins/workaholic/hooks/hooks.json`, leaving the file as `{ "hooks": { … } }`. Do not alter any hook entry.
2. **Confirm Claude still loads the hooks.** Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh` and confirm `guards_present: true` with an empty `missing_guards` (all PreToolUse guards still register from the edited `hooks.json`).
3. **Add the regression guard.** In `scripts/build-plugins/validate-metadata.mjs`, read `plugins/workaholic/hooks/hooks.json`, assert it is valid JSON and that `Object.keys(manifest)` is exactly `["hooks"]` (only `hooks` at the top level). Fail with a clear message naming the offending key(s) and Codex's `deny_unknown_fields` expectation. Keep it defensive if the file is absent (skip, don't crash).
4. **Document the constraint.** Add a short note where the cross-agent distribution is described (CLAUDE.md) that `hooks/hooks.json` must carry only `hooks` at the top level because Codex installs the raw plugin dir and parses it strictly — so the plugin/hook description lives in `.claude-plugin/plugin.json` and CLAUDE.md, never in `hooks.json`.
5. **Bump version** per CLAUDE.md Version Management (the cached-in-Codex version in the error is `1.0.81`; the fix ships in a new patch so a Codex re-add picks it up).
6. **No `outputs/` rebuild is required for the hooks.json change itself** (it is not a generated artifact), but run the full local verification set anyway (below) since the version bump and the validate-metadata change must stay consistent.

## Quality Gate

How the outcome's quality is assured (Workflow Step 4b), developer-confirmed at `/ticket`.

**Acceptance criteria** — the checkable conditions that must hold:

- `plugins/workaholic/hooks/hooks.json` parses as JSON and its only top-level key is `hooks` (no `description` or any other sibling key).
- Claude Code still registers every hook: `check-deps/scripts/check.sh` returns `guards_present: true` with empty `missing_guards`.
- `node scripts/build-plugins/validate-metadata.mjs` passes and now **fails** if a sibling top-level key is reintroduced into `hooks.json` (guard is real, not vacuous).
- Codex re-adds the `workaholic` plugin and loads it **without** the `unknown field 'description'` parse error (manual verification against a fresh Codex cache of the bumped version).
- `CLAUDE.md` states the `hooks.json` top-level-`hooks`-only constraint for Codex compatibility.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/validate-metadata.mjs` — green, and demonstrably red when a `description` key is temporarily re-added (verify the guard bites, then revert).
- `node scripts/build-plugins/verify.mjs` and `node scripts/test-workflow-scripts.mjs` — remain green (no regression).
- `bash plugins/workaholic/skills/check-deps/scripts/check.sh` — `guards_present: true`, `missing_guards: []`.
- Manual: in Codex, `codex plugin marketplace add qmu/workaholic --ref <branch>` then `codex plugin add workaholic@workaholic` (or clear the `~/.codex/plugins/cache/workaholic` cache and re-add) and confirm no hooks-config parse error on load.

**Gate** — what must pass before approval:

- hooks.json is `{ "hooks": … }`-only; `validate-metadata.mjs` (with the new guard), `verify.mjs`, and the smoke suite are all green; the guard is proven to fail on a re-added sibling key; `check-deps` shows all guards present; and the Codex load is confirmed clean (or, if Codex is unavailable in-session, the developer confirms it at ship time and the automated schema guard stands in as the machine-checked proxy).

## Considerations

- **`description` is valid on Claude, invalid on Codex** — this is a cross-agent schema-intersection bug, not an outright malformed file. The lesson generalizes: any file the Codex marketplace installs from the raw `./plugins/workaholic` dir must use only fields both agents accept. The guard encodes that for `hooks.json`; watch for the same class of issue in other shared plugin config (`plugins/workaholic/hooks/hooks.json` is the only current offender). (`scripts/build-plugins/validate-metadata.mjs`)
- **Parse fix vs. runtime behavior** — removing `description` fixes the *load* failure. It does not change whether Codex then attempts to *run* the Claude-only hooks (they reference `${CLAUDE_PLUGIN_ROOT}` and Claude-specific events like `PreToolUse`/`UserPromptSubmit`). The reported symptom is purely the parse error; if Codex later mis-fires or errors on the hook entries themselves, that is a separate, larger concern (the "structural: isolate hooks from Codex" option deferred at `/ticket`) — note it, don't scope-creep into it here. (`plugins/workaholic/hooks/hooks.json`)
- **CLAUDE.md is the single source of truth for hook documentation** — deleting the blob is only safe because CLAUDE.md already covers every hook; verify that remains true at implementation time so no knowledge is lost. (`CLAUDE.md`)
- **Versioned Codex cache** — the error cites `1.0.81`; Codex caches per version under `~/.codex/plugins/cache/`. The fix only reaches a user after a version bump and a re-add/refresh, so the bump (step 5) is part of the fix, not optional. (`.claude-plugin/marketplace.json`)
