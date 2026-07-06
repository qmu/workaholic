---
created_at: 2026-07-06T12:13:04+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Machine-enforce the [project] label on every AskUserQuestion prompt

## Overview

Every workaholic workflow prompt is supposed to prefix its `AskUserQuestion` `question` body with a `[<project label>]` (from `project-label.sh`) so a developer running many parallel Claude sessions can tell **which repository is asking**. Today this is **prose-only** across the `create-ticket` / `drive` / `report` / `ship` / `catch` / `trip-protocol` / `explain` skills and their commands — so it is repeatedly forgotten, and a developer with ten sessions open cannot tell what a prompt is about. This is the standing deferred concern **#67 "Prompt phrasing is prose, not machine-checked"** (carried to #69), and it is a live, recurring failure.

Make it **machine-enforced** with a PreToolUse hook that inspects the actual `AskUserQuestion` tool input at issue time — strictly stronger than the concern's original "add a verify.mjs prose check" suggestion, because it acts on the real prompt, not the convention text. Discovery confirmed feasibility: a PreToolUse hook can match the tool **name** `AskUserQuestion` and read `tool_input.questions[].question` (exactly as `guard-git-commit.sh` reads `.tool_input.command`).

The over-fire question resolves in our favor: labeling **any** prompt with the repo is a net good, even an ad-hoc non-workflow question, so the guard need not distinguish workflow prompts from ad-hoc ones — a point of failure the concern raised is simply sidestepped.

This fix is Claude-Code-only (hooks have no `outputs/` footprint) and keeps the rule out of `CLAUDE.md` (only the hook enumeration line is touched) — consistent with the "everything cannot live in CLAUDE.md; enforce via the plugin" direction driving the sibling setup-command ticket `20260706121303-setup-command-and-gateway-skill.md`.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional layout for the new hook (applies to all code work).
- `workaholic:implementation` / `policies/coding-standards.md` — style conventions (applies to all code work).
- `workaholic:implementation` / `policies/command-scripts.md` — the label check/inject logic lives in a bundled **POSIX `#!/bin/sh -eu`** hook script (Alpine has no bash), never inline; must pass `hooks/posix-lint.sh`.
- `workaholic:implementation` / `policies/objective-documentation.md` — turns a prose convention into a machine-checked one; the skill notes that say "hook-enforced" must be verifiable statements.
- `workaholic:design` / `policies/self-explanatory-ui.md` — the `[project]` label IS a self-explanatory-UI requirement (a prompt must, on its own, say which repo it concerns); enforcing it serves that policy directly.

## Key Files

- `plugins/workaholic/hooks/guard-askuserquestion-label.sh` — **new POSIX PreToolUse hook.** Reads `.tool_input.questions[].question` (jq), and for each question that lacks a leading `[...]` label either (Option A, preferred) **rewrites** the input via `hookSpecificOutput.permissionDecision:"allow"` + `updatedInput` with `[<label>] ` prepended, or (Option B, fallback) **blocks** with exit 2 and a stderr message telling Claude to re-issue with the prefix (the `guard-git-commit.sh` precedent). Derives the label network-free (reuse `skills/gather/scripts/project-label.sh` output / its basename logic).
- `plugins/workaholic/hooks/hooks.json` — **edit.** Add a PreToolUse entry with matcher `"AskUserQuestion"` pointing at the new script; extend the top-level `description`.
- `plugins/workaholic/skills/gather/scripts/project-label.sh` — **DRY anchor** (no edit expected): the hook must produce the same `project` value the prompts use, so the label agrees.
- `plugins/workaholic/skills/{create-ticket,drive,report,ship,catch,trip-protocol,explain}/SKILL.md` + `commands/{ticket,commit,explain}.md` — **light prose edit:** note the convention is now hook-enforced (keeps the "User interaction" bullets truthful). No rule bodies added.
- `CLAUDE.md` — **minimal, truthful touch only.** Add the new guard to the hooks enumeration and (if warranted) one line under the enforcement section, peer to the commit/branch gates. **No** rules subsection — consistent with keeping CLAUDE.md thin.
- `.workaholic/concerns/67-prompt-phrasing-is-prose-not-machine.md` + `69-carried-from-pr-67-prompt-phrasing.md` — **resolved by this work** (the report/ship concern flow flips their status on the next ship; not a manual edit here).
- `scripts/build-plugins/` + `outputs/` — **no footprint.** Hooks are Claude-Code-only; `build.mjs` does not copy hooks into `outputs/`. No rebuild; Outputs Freshness CI unaffected. The `outputs/workflows/**/SKILL.md` mirrors of the "User interaction" bullets are regenerated only if those bullets are edited — run `build.mjs` in that case.

## Related History

The `[project]` prefix convention was introduced with `project-label.sh` (branch `work-20260701-093015`) and immediately flagged as unenforced (concern #67, `fc163bd`), then carried forward through #69. The two existing PreToolUse(Bash) guards (`guard-git-commit.sh`, `guard-git-branch.sh`, from branch `work-20260628-002047`) are the exact pattern to clone — this ticket adds a third guard on a different tool matcher.

Past work:

- [work-20260701-093015.md](.workaholic/stories/work-20260701-093015.md) - Introduced `project-label.sh` and the `[project]` prompt-prefix convention (the rule this ticket enforces).
- [work-20260628-002047.md](.workaholic/stories/work-20260628-002047.md) - Added the two-layer commit/branch enforcement stack (`guard-git-commit.sh` / `guard-git-branch.sh`) — the PreToolUse-guard precedent to mirror.

## Implementation Steps

1. **Empirically verify the mechanism** (hooks load at session start; test with `claude --debug`): does Claude Code honor `updatedInput` for the `AskUserQuestion` tool? If yes → implement **Option A (auto-inject)**; if no → implement **Option B (block, exit 2)**. Record the verified choice in the ticket/commit.
2. **Write `guard-askuserquestion-label.sh`** (POSIX `#!/bin/sh -eu`): parse `.tool_input.questions`, detect a missing leading `[...]` per question, and inject-or-block per step 1. Derive the label network-free (reuse `project-label.sh`). Handle the multi-question array. Skip a question that already starts with `[`.
3. **Register in `hooks.json`**: PreToolUse matcher `"AskUserQuestion"` → the new script; update the description.
4. **Light prose pass**: in the `create-ticket/drive/report/ship/catch/trip-protocol/explain` skills and `ticket/commit/explain` commands, note the label is now hook-enforced (truthfulness). If these bullets are edited in build-target skills, run `node scripts/build-plugins/build.mjs` to regenerate the `outputs/` mirrors.
5. **Test**: add a hermetic unit test that pipes sample `AskUserQuestion` `tool_input` JSON (labeled and unlabeled, single and multi-question) into the hook and asserts the block/rewrite output; ensure `hooks/posix-lint.sh` passes it.
6. **Minimal CLAUDE.md**: add the guard to the hooks enumeration (one line); optionally one line under the enforcement section.
7. **Verify**: `verify.mjs`, `validate-metadata.mjs`, `test-workflow-scripts.mjs` green; posix-lint clean.

## Quality Gate

New PreToolUse(AskUserQuestion) guard; gated on the empirically-verified mechanism, a green hermetic hook test, and CLAUDE.md staying thin.

**Acceptance criteria** — the checkable conditions that must hold:

- A PreToolUse hook matches tool `AskUserQuestion` and reads `tool_input.questions[].question`; on a question lacking a leading `[...]` it either injects `[<label>] ` (Option A) or blocks with exit 2 and a corrective message (Option B) — whichever the empirical test in step 1 proved the harness honors.
- The hook derives the repo label **network-free** and produces the same value as `project-label.sh`.
- POSIX `#!/bin/sh -eu`; passes `hooks/posix-lint.sh`.
- `hooks.json` registers the matcher; the guard is enumerated in `CLAUDE.md` with **no** new rules subsection.
- A hermetic test feeds labeled + unlabeled + multi-question `tool_input` and asserts the correct block/rewrite; green.
- No `outputs/` rebuild needed unless the "User interaction" prose was edited in a build-target skill (then regenerated and fresh).

**Verification method** — the commands/tests/reads that prove them:

- Run the hook against sample JSON fixtures (unlabeled → block/inject; already-labeled → pass; multi-question → each handled) and assert output; wire this into `test-workflow-scripts.mjs`.
- `claude --debug` transcript (or the recorded step-1 finding) shows the guard firing on a real unlabeled `AskUserQuestion`.
- `sh hooks/posix-lint.sh` clean; `node scripts/build-plugins/verify.mjs` + `validate-metadata.mjs` green; `git status --porcelain outputs/` empty (or only the expected prose-mirror regeneration).

**Gate** — what must pass before approval:

- The mechanism is empirically verified (not assumed); hook test green; posix-lint + verify + validate green; CLAUDE.md diff is enumeration-only; developer reads the final hook + hooks.json at the `/drive` approval prompt.

## Considerations

- **Mechanism must be verified, not assumed.** `updatedInput` for `AskUserQuestion` is documented generically for PreToolUse but must be confirmed empirically; if unsupported, fall back to the exit-2 block (the proven `guard-git-commit.sh` behavior). Do not ship on an unverified assumption (`plugins/workaholic/hooks/guard-askuserquestion-label.sh`).
- **Over-fire is acceptable — do not over-engineer scoping.** The label helps every prompt, so there is no need to distinguish workflow prompts from ad-hoc ones; a blanket match on `AskUserQuestion` is correct, not a bug (avoids the concern's scoping worry).
- **Label agreement.** The hook and the prompts must produce the identical label; reuse `project-label.sh` as the single source rather than re-deriving divergently (`plugins/workaholic/skills/gather/scripts/project-label.sh`).
- **Keep CLAUDE.md thin.** Only the hook enumeration line changes; the rule itself is the hook plus the existing skill prose — not a new CLAUDE.md section (`CLAUDE.md`).
- **Resolves #67/#69.** Note the resolution so the next `/report` deferred-concern judge marks them resolved (`.workaholic/concerns/67-prompt-phrasing-is-prose-not-machine.md`).
- **`outputs/` mirrors are not hook-covered.** Non-Claude agents run the generated `outputs/workflows` skills, which a Claude-Code hook cannot reach; their "User interaction" prose remains the only guard there — acceptable, but do not claim the hook protects them.
