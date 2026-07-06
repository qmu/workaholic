---
created_at: 2026-07-06T12:13:03+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Setup command that wires a repo to workaholic via a gateway skill (not CLAUDE.md bloat)

## Overview

Add a thin **setup command** (provisional `/setup`; final name open) that bootstraps and enforces an individual repository's alignment with the workaholic guidelines — **without cramming rules into that repo's `CLAUDE.md`**. The core architectural constraint, stated by the developer: everything cannot live in `CLAUDE.md`; the setup command's single most important instruction is to **refer to a gateway skill**, and by referring to that skill Claude Code reaches **our rules in the `policies/` directory**. `CLAUDE.md` stays thin and *points at* the skill; the rules live in the skill/policies, referenced, never embedded. This is the repo's own "thin commands, comprehensive skills" + "refer, never embed" principle, and it is the `development` / `policy-as-plugin` policy in action (policies distributed and reached as a plugin, not copied into each project).

When run in a repository, the setup command makes Claude Code:

1. **Refer to the gateway skill** (primary instruction) — the doorway through which the `policies/` rules load. (Developer's "worktree skill"; naming finalized in this ticket — see Considerations. It carries the working-directory/worktree-root discipline **and** links the pillar policies.)
2. **Audit the repo's `CLAUDE.md`** against required content and documentation standards — verify the required sections/references are present (crucially, that `CLAUDE.md` defers to the gateway skill rather than duplicating rules), report gaps objectively, and offer to fix them.
3. **Ensure the operational rules are enforced**, machine-checked where possible (developer chose hook-enforcement). Concrete rules given: (a) the working directory must always stay at the repository root — never move it; (b) if Claude Code `cd`s away, it must return to the repo root immediately after. Setup installs/verifies a PreToolUse guard for the machine-checkable part; the gateway skill documents the rest.

The value: a fresh repo gets wired into workaholic's policy lens through one referral, `CLAUDE.md` stays lean and truthful, and the "stay at repo root" discipline stops being advisory prose that Claude forgets (the same failure class as the dropped AskUserQuestion `[project]` label — see the sibling ticket `20260706121304-enforce-askuserquestion-project-label.md`).

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout; a new command + skill + hook must follow it (applies to all code work).
- `workaholic:implementation` / `policies/coding-standards.md` — style conventions (applies to all code work).
- `workaholic:implementation` / `policies/command-scripts.md` — the CLAUDE.md-audit logic and the operational-rule enforcement must live in **bundled POSIX `#!/bin/sh -eu` scripts** (Alpine has no bash), never as inline conditional shell in the command/skill markdown.
- `workaholic:implementation` / `policies/objective-documentation.md` — the "required CLAUDE.md content" the audit checks, and the gateway-skill prose, must be **verifiable rules** (a concrete checklist: section X present, references skill Y), not aspirational description.
- `workaholic:design` / `policies/self-explanatory-ui.md` — the setup command's output must, on its own, tell the developer what was checked, what conforms, what is missing, and how to fix it — no external manual.
- `workaholic:development` / `policies/policy-as-plugin.md` — the anchor: policies are reached as a plugin, not copied per project. The gateway-skill-refers-to-`policies/` design is this policy realized; the setup command is how a repo opts into it.

## Key Files

- `plugins/workaholic/commands/<setup>.md` — **new, thin command** (orchestration only, ~50-100 lines). Its most important instruction: refer Claude to the gateway skill. Also drives the CLAUDE.md audit and the hook-verification, all via bundled scripts. Carries the standard `**Notice:**` + plugin-boundary header like the other commands.
- `plugins/workaholic/skills/<gateway>/SKILL.md` — **new gateway skill.** Single referral point that (a) links the `policies/` directory (the pillar hard copies), and (b) holds/links the working-directory ground rules (stay at repo root; return after `cd`). Decide `metadata.internal` based on whether it bundles a script (script-bearing → internal; pure-prose gateway → cross-agent-exposed).
- `plugins/workaholic/skills/<gateway>/scripts/audit-claude-md.sh` — **new POSIX script.** Checks a repo's `CLAUDE.md` for the required content/references and emits JSON (present/missing checklist). The command reads it and reports.
- `plugins/workaholic/hooks/guard-working-directory.sh` + `plugins/workaholic/hooks/hooks.json` — **new PreToolUse(Bash) guard** (POSIX sh, guard-git-commit.sh precedent) that detects a `cd` which would move the working directory outside the repo root and blocks/steers it (absolute paths or a `( cd … )` subshell); registered in `hooks.json`. The "return to root immediately" rule is enforced/repaired here to the extent a Bash-surface hook can; the gateway skill documents what the hook cannot check.
- `plugins/workaholic/skills/branching/` — **check / relate.** `branching` owns worktree *creation/detection*; the new gateway skill owns worktree/working-dir *discipline* + policy gateway. Ensure the boundary is clean and cross-referenced, not duplicated.
- `CLAUDE.md` (this repo) — **minimal, truthful touch only.** Add the new command to the Commands table and the new hook to the hooks/ enumeration (one line each — truthfulness, not a rules subsection). Do **not** embed the operational rules here; they live in the gateway skill. Add the setup command to the Version-management/marketplace command lists if required.
- `.claude-plugin/marketplace.json` — if the gateway skill is cross-agent-exposed, add it to the `workaholic` plugin `skills` array (like the design/implementation/operation entries).
- `scripts/build-plugins/` + `outputs/` — commands and hooks are Claude-Code-only (no `outputs/` footprint); a **cross-agent-exposed** gateway skill (pure prose) would need `node scripts/build-plugins/build.mjs` only if it enters the workflows bundle — most likely it does not (it is a policy gateway, exposed via the `skills` CLI directly). Confirm during implementation.

## Related History

No prior setup/onboarding command exists in workaholic (verified: no `commands/setup.md`, no `worktree`/`setup` skill). The closest existing machinery is the policy-lens hook (`hooks/policy-lens.sh`) that already refers workflow commands to the pillar policy skills — the setup command generalizes that "refer to a skill, reach the policies" pattern to repo bootstrapping. The `install-git-hooks.sh` installer is precedent for a command/skill that *sets up* per-repo enforcement.

## Implementation Steps

1. **Finalize names** (Considerations): the setup command (`/setup` vs `/init` vs `/bootstrap`) and the gateway skill (developer's "worktree skill" — `workspace` / `ground-rules` / `worktree` / `repo-guardrails`). Record the choice.
2. **Create the gateway skill** (`skills/<gateway>/SKILL.md`): the single referral point. Link the `policies/` directory (the pillars) and state the working-directory ground rules (stay at repo root; return after `cd`), each as a verifiable rule per `objective-documentation`. Set `metadata.internal` per script-bearing-vs-pure-prose.
3. **Write `audit-claude-md.sh`** (POSIX): define the required-CLAUDE.md checklist (must reference the gateway skill / policy lens; required sections present) and emit a present/missing JSON. This is the machine-checkable "documentation standards" the developer asked to enforce.
4. **Write `guard-working-directory.sh`** (POSIX, PreToolUse Bash) + register in `hooks.json`: detect a `cd` that leaves the repo root; block/steer to absolute paths or a subshell. Mirror the guard-git-commit.sh structure (route the caller, don't silently mutate). Decide the exact block-vs-warn behavior and document it.
5. **Write the thin setup command** (`commands/<setup>.md`): primary instruction = refer to the gateway skill; then run `audit-claude-md.sh`, report gaps (self-explanatory output), and verify/install the working-directory guard. No embedded rules.
6. **Add hermetic smoke tests** to `scripts/test-workflow-scripts.mjs`: (a) `audit-claude-md.sh` against a conformant and a deficient throwaway `CLAUDE.md` (assert the checklist JSON); (b) `guard-working-directory.sh` against a repo-root-leaving `cd` (assert block) and an absolute-path/subshell command (assert allow). No network/`gh`.
7. **Minimal docs**: add the command to the Commands table and the hook to the hooks enumeration in this repo's `CLAUDE.md` (one line each); expose the gateway skill in `marketplace.json` if pure-prose/cross-agent. Regenerate `outputs/` only if the gateway skill enters a build target (likely not).
8. **Verify**: `node scripts/build-plugins/verify.mjs`, `validate-metadata.mjs`, `test-workflow-scripts.mjs` all green; `hooks/posix-lint.sh` passes the new scripts.

## Quality Gate

New Claude-Code command + gateway skill + PreToolUse hook + audit script; gated on structural presence, green hermetic tests for both scripts, and CLAUDE.md staying thin.

**Acceptance criteria** — the checkable conditions that must hold:

- A thin setup command exists whose **primary, first instruction is to refer to the gateway skill** (verifiable by reading the command body); it contains **no embedded rule bodies**.
- The gateway skill exists, **links the `policies/` directory**, and states the working-directory ground rules as verifiable rules.
- `audit-claude-md.sh` emits an objective present/missing checklist for a repo's `CLAUDE.md` (including "references the gateway skill"); the command reports it self-explanatorily.
- The "stay at repo root" rule is **machine-enforced** by `guard-working-directory.sh` (registered in `hooks.json`) for the Bash `cd` surface; POSIX `#!/bin/sh -eu`, passes `posix-lint.sh`.
- This repo's `CLAUDE.md` gains **only** the truthful one-line command/hook enumeration entries — **no** operational-rules subsection (rules stay in the skill).
- Hermetic smoke tests for `audit-claude-md.sh` and `guard-working-directory.sh` are green.

**Verification method** — the commands/tests/reads that prove them:

- `node scripts/test-workflow-scripts.mjs` green, including the new audit + working-dir-guard assertions.
- `node scripts/build-plugins/verify.mjs` + `validate-metadata.mjs` green; `sh hooks/posix-lint.sh` (or the repo's lint entry) passes the new scripts.
- Read the setup command body: first instruction refers to the gateway skill; no rule bodies inline. Read the gateway skill: links `policies/` + states the ground rules.
- Read this repo's `CLAUDE.md` diff: only enumeration lines changed.

**Gate** — what must pass before approval:

- Both script smoke tests green; the command refers-to-skill (not embeds); CLAUDE.md diff is enumeration-only; verify + validate + posix-lint green; developer reads the final command + gateway skill + the CLAUDE.md diff at the `/drive` approval prompt and confirms the names.

## Considerations

- **Naming is an open decision** (`plugins/workaholic/commands/`, `plugins/workaholic/skills/`). The developer called the gateway a "worktree skill," but `branching` already owns worktree mechanics — a clearer name (`workspace`, `ground-rules`, `repo-guardrails`) may avoid confusion. Confirm command + skill names with the developer at `/drive`.
- **Enforcement boundary of rule (b).** A PreToolUse(Bash) hook sees the command string, so it can block a repo-root-leaving `cd`; enforcing "return to root *immediately after*" across separate tool calls is only partially machine-checkable (cwd persists between Bash calls). Steer to absolute paths / `( cd … )` subshells (which the environment already prefers) rather than promising full state tracking (`plugins/workaholic/hooks/guard-working-directory.sh`).
- **Don't duplicate `branching`.** Keep worktree *discipline* (this skill) distinct from worktree *creation/detection* (`branching`), cross-referenced, not copied (`plugins/workaholic/skills/branching/SKILL.md`).
- **Keep CLAUDE.md thin — the whole point.** Resist the pull to document the operational rules in `CLAUDE.md`; they belong in the gateway skill, reached by reference. The only `CLAUDE.md` change is truthful enumeration (`CLAUDE.md`).
- **Cross-agent exposure of the gateway skill.** If it is pure prose (no bundled script), it can reach non-Claude agents via the `skills` CLI (add to `marketplace.json`); if it bundles a script it must carry `metadata.internal: true`. Decide deliberately (`.claude-plugin/marketplace.json`).
- **Composes with the label-enforcement ticket.** Both this and `20260706121304-enforce-askuserquestion-project-label.md` use the "refer to a skill + PreToolUse guard" pattern; keep the two hooks independent but stylistically consistent.
