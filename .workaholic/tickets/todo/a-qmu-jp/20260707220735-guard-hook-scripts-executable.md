---
created_at: 2026-07-07T22:07:35+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.5h
commit_hash:
category:
---

# Guard That hooks.json-Referenced Scripts Stay Executable

## Overview

`plugins/workaholic/hooks/hooks.json` invokes each hook by its bare path (`"command": "${CLAUDE_PLUGIN_ROOT}/hooks/<name>.sh"`), so Claude Code executes the file directly and the file **must** carry the execute bit. When a hook is committed without it (git mode `100644`), the hook fails at runtime with `/bin/sh: <path>: Permission denied` — and because these are non-blocking `PreToolUse` hooks, the failure is silent noise that never trips CI or a test. This actually happened: `guard-working-directory.sh` and `guard-askuserquestion-label.sh` (both added 2026-07-06) shipped as `100644` and fired Permission-denied on every Bash/AskUserQuestion call until manually `chmod +x`'d.

The permission bits are now fixed in the working tree. This ticket adds the **regression guard** so the class of bug cannot silently return: a test that asserts every script `hooks.json` invokes by path is executable, run by the CI harness that already exists.

## Key Files

- `scripts/test-workflow-scripts.mjs` — the hermetic test harness CI runs via `.github/workflows/validate-plugins.yml` (`node scripts/test-workflow-scripts.mjs`). New test case added here; registered in the `TESTS` registry array at the bottom (~line 2150). Uses existing helpers `assertTrue`, `REPO_ROOT`, and `node:fs` imports already in scope.
- `plugins/workaholic/hooks/hooks.json` — the single source of hook command paths to check; `${CLAUDE_PLUGIN_ROOT}` resolves to `plugins/workaholic`.
- `plugins/workaholic/hooks/posix-lint.sh` — reference pattern for a "standing guard that keeps a rule from regressing" (do not extend it; POSIX conformance is a separate concern).

## Related History

Mirrors the existing standing-guard pattern in this harness: `testPosixLint` locks POSIX-sh conformance of the real plugin tree, `testGuardWorkingDirectory` / `testGuardAskUserQuestionLabel` exercise the individual hooks. None of them assert the **file mode** of the hooks, which is the gap that let the Permission-denied regression through. This guard closes that gap at the same layer (a node assertion over the real tree) rather than adding a shell script.

## Implementation Steps

1. Add a function `testHooksExecutable()` to `scripts/test-workflow-scripts.mjs`:
   - Read and `JSON.parse` `plugins/workaholic/hooks/hooks.json`.
   - Walk every event group (`hooks.PreToolUse`, `PostToolUse`, `UserPromptSubmit`, and any other top-level event key) → each matcher entry's `hooks[]` array → its `command` string. Collect all `command` values generically (do not hard-code the six current paths) so newly added hooks are covered automatically.
   - For each command, replace the literal `${CLAUDE_PLUGIN_ROOT}` with the resolved plugin root (`join(REPO_ROOT, "plugins/workaholic")`), giving an absolute script path.
   - `assertTrue` that the resolved file exists and `statSync(path).mode & 0o111` is non-zero (owner/group/other execute bit set) for **every** referenced script; on failure, the detail must name the offending path(s).
2. Add a negative/self-check so the assertion logic itself is trusted: in a throwaway temp dir (via the harness's existing `mkdtempSync`/`cleanup` pattern), write a `600`/`644` fixture file and assert the same `mode & 0o111` predicate reports it as non-executable. This proves the check would have caught the original regression.
3. Register the test in the `TESTS` array at the bottom of the file, e.g. `["hooks/hooks.json executable", testHooksExecutable]`.
4. Run `node scripts/test-workflow-scripts.mjs` locally — it must be green on the current (already-fixed) tree.

## Considerations

- **Scope is deliberately narrow** (decided with the developer): only scripts `hooks.json` invokes *by path* are checked. Scripts run as `sh script.sh` or resolved through `${CLAUDE_PLUGIN_ROOT}` from skill markdown do not need the execute bit, so widening to "all `*.sh`" would create false-positive pressure without matching a real failure mode.
- **No new shell script and no new CI wiring** — the check lives in the existing node harness that `validate-plugins.yml` already runs, so there is nothing to keep POSIX-clean and no `outputs/` footprint.
- Keep the walk resilient to hooks.json shape: entries may omit an event key; guard against `undefined` with optional chaining / default `[]` rather than assuming all three events are present.
- This is test-only tooling — no change to any hook's behavior, no `outputs/` rebuild, no version bump.

## Quality Gate

- **Verification method:** run `node scripts/test-workflow-scripts.mjs`; the new `testHooksExecutable` case must pass on the current tree (all six referenced hooks are `100755`) and its self-check fixture must confirm the predicate flags a non-executable file.
- **Acceptance criteria (objective):**
  1. The new test parses the real `hooks.json` and asserts `mode & 0o111 != 0` for **every** `command` path it references, discovering paths dynamically (not a hard-coded list).
  2. The test is red if any referenced hook is reverted to `100644` (demonstrated by the temp-dir self-check using the identical predicate).
  3. The test is registered in the `TESTS` array and runs under `.github/workflows/validate-plugins.yml` with no new workflow step.
  4. `node scripts/test-workflow-scripts.mjs` exits 0 on the branch.
- **Gate that must pass before approval:** the full `node scripts/test-workflow-scripts.mjs` run is green, and reverting any one hook to non-executable turns it red (spot-check during review).
- **Edge cases:** hooks.json with a missing event key; a `command` that does not contain `${CLAUDE_PLUGIN_ROOT}`; multiple hooks under one matcher.
- **Division of assurance:** the implementer writes the test and the self-check fixture; review confirms the dynamic discovery (not a hard-coded six-path list) and the red-on-revert behavior.

## Policies

- `workaholic:implementation` — `implementation/coding-standards` (the guard is code hygiene that makes a silent runtime failure machine-checkable early) and `implementation/directory-structure` (the test stays in the existing harness, no stray script).
- `workaholic:operation` — the guard protects a delivery-path invariant (hooks that ship must actually run), keeping the standing CI gate honest.
