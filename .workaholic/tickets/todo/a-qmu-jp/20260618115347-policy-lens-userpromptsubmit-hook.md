---
created_at: 2026-06-18T11:53:47+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort: 2h
category:
depends_on:
---

# Always-triggered policy-lens hook for `/ticket`, `/report`, `/ship`

## Overview

The engineering policies (`planning` / `design` / `implementation` / `operation`
skills, each indexing qmu.co.jp hard copies under `policies/`) should be applied
automatically whenever a workflow command runs — so that a ticket spec, a report
assessment, and a ship decision are all judged against the policies, and so that
a **new project gets its directory layout and TypeScript coding conventions
enforced from the first ticket**. Today this is attempted via hand-written
"Policy Lens" prose duplicated across several command/skill files, and it has
drifted badly:

- Every copy still gates on *"When the `standards` plugin is installed"* — but
  `standards` was merged into the single `workaholic` plugin long ago, so the
  condition is meaningless.
- **None** of the copies mention the new `planning` (企画) pillar.
- `/ship` has **no** policy lens at all (neither `commands/ship.md` nor the
  `ship` skill preloads or references the policies).
- The two policies the maintainer most wants always-on —
  `implementation/directory-structure` and `implementation/coding-standards`
  (TypeScript conventions) — get no special "always apply" emphasis anywhere.

We do **not** want to hard-code policy content into the workflow skills. Instead,
add a single **always-triggered, non-blocking policy-*referring* mechanism**: a
`UserPromptSubmit` hook that, whenever the submitted prompt invokes `/ticket`,
`/report`, or `/ship`, injects a short context block that points the agent at the
policy index skills (and flags directory-structure + coding-standards as
always-apply). It refers to the policies by skill/path; it never reproduces their
text, so the policy hard copies under `skills/*/policies/*.md` remain the single
source of truth (still synced from qmu.co.jp). This is a *lens*, not a
*safeguard*: it adds context and blocks nothing (contrast the existing
`PostToolUse` `validate-ticket.sh`, which exits 2 to block).

## Key Files

- `plugins/workaholic/hooks/hooks.json` - PRIMARY. Add a `UserPromptSubmit` entry
  alongside the existing `PostToolUse` ticket validator, pointing at the new
  script. Update the file-level `description` (currently "Ticket format and
  location validation") to cover both hooks.
- `plugins/workaholic/hooks/policy-lens.sh` - NEW. The hook script. Reads the
  hook JSON on stdin, checks whether `.prompt` invokes one of the three workflow
  commands, and on a match prints the policy-reference context (see Steps); exit
  0 always (never blocks). POSIX/bash consistent with `validate-ticket.sh` and
  `rules/shell.md`; uses `jq` (already a hook dependency).
- `plugins/workaholic/commands/ticket.md` - Remove the stale per-command "Policy
  Lens" paragraph (lines ~18) now that the hook centralizes the trigger; if any
  pointer is kept, it must drop "standards plugin" and add `planning`.
- `plugins/workaholic/commands/report.md` - Same: remove/refresh the stale
  "Policy Lens" paragraph (line ~16).
- `plugins/workaholic/commands/ship.md` - Currently has no lens; the hook now
  covers it. Do not add new prose — let the hook be the single source.
- `plugins/workaholic/skills/create-ticket/SKILL.md` - De-stale Step 0 ("Load the
  Policy Lens", lines ~130-136) and the `## Policy Lens` layer→pillar table
  (lines ~349-361): drop the "standards plugin" gating and `standards:*`
  namespace, add the `planning` pillar/row. Keep the table — the layer→pillar
  mapping is genuine knowledge that belongs in the skill (knowledge) layer; the
  hook only triggers loading, the table tells the agent which pillar maps to
  which `layer`.
- `plugins/workaholic/skills/report/SKILL.md` - De-stale its Policy Lens step;
  add `planning`.
- `plugins/workaholic/skills/{create-ticket,report}/SKILL.md` frontmatter - Add
  `workaholic:planning` to the `skills:` preload list (currently only
  design/implementation/operation). The `ship` skill does not preload policies
  today; the hook supplies the reference, so leave ship's frontmatter unless the
  agent needs the index in-context — decide during implementation.
- `plugins/workaholic/skills/implementation/policies/{directory-structure,coding-standards}.md` -
  The always-apply targets the hook names. Read-only; cite by path, do not edit.

## Related History

- The `planning` pillar and ~40 policies were just added by the v1.0.57 standards
  sync (PR #46), which is exactly why the older lens prose is now stale/incomplete.
- The existing hook precedent is `hooks/validate-ticket.sh` + `hooks/hooks.json`
  (`PostToolUse`, blocking). This ticket adds the *non-blocking, context-adding*
  counterpart (`UserPromptSubmit`).

## Implementation Steps

1. **Verify the trigger contract first.** Confirm in this Claude Code version
   that a `UserPromptSubmit` hook fires for plugin slash commands and that the
   payload's `.prompt` contains the literal `/ticket …` / `/report` / `/ship`
   text. If it does not (e.g. the prompt is already expanded), fall back to
   matching on a stable marker. Do not build on an unverified assumption — this
   is the load-bearing detail of the whole mechanism. (Consult the
   `claude-code-guide` agent or current Claude Code hooks docs if unsure.)
2. **Write `policy-lens.sh`.** Read stdin JSON, extract `.prompt` with `jq`,
   and test for the three command tokens (a single `grep -E` over
   `/(ticket|report|ship)\b`, anchored to the slash form; optionally also the
   natural-language invocations the command `**Notice:**` headers list). On no
   match: exit 0 silently. On match: emit
   `{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"…"}}`
   and exit 0. Keep all logic in the script (no inline shell in markdown,
   `rules/shell.md`); mirror `validate-ticket.sh`'s shebang/style.
3. **Author the injected context** (the referring payload, kept short and
   pointer-only — no policy text):
   - Name the four index skills to load/apply as the lens: `workaholic:planning`,
     `workaholic:design`, `workaholic:implementation`, `workaholic:operation`.
   - State that `implementation/directory-structure` and
     `implementation/coding-standards` (TypeScript conventions) are
     **always-apply**, especially when scaffolding a new project or a new layout.
   - Say "apply the policies relevant to this change; read the skill/policy files
     for the rules — do not assume them." This keeps content single-sourced.
4. **Register the hook** in `hooks.json` under `UserPromptSubmit` with a sensible
   `timeout`; refresh the file `description`.
5. **De-duplicate and de-stale the prose.** Remove the now-redundant per-command
   Policy Lens paragraphs from `commands/ticket.md` and `commands/report.md`;
   refresh the create-ticket Step 0 + Policy Lens table and report's lens step
   (drop "standards plugin"/`standards:*`, add `planning`). Add
   `workaholic:planning` to the create-ticket and report skill `skills:`
   frontmatter.
6. **Outputs / build.** Hooks and commands are Claude-Code-only and are **not**
   part of the generated `outputs/workflows` bundle, so no rebuild should be
   needed — but if any *workflow skill* body changed (e.g. report SKILL prose),
   run `node scripts/build-plugins/build.mjs` and confirm `git status outputs/`
   reflects only intended changes (Outputs Freshness CI gate).
7. **Validate.** `node scripts/build-plugins/verify.mjs`,
   `validate-metadata.mjs`, and `node scripts/test-workflow-scripts.mjs` still
   pass. Manually exercise `policy-lens.sh`: pipe a fake `UserPromptSubmit`
   payload for `/ticket …` and assert the context block is emitted; pipe a
   non-workflow prompt and assert silent exit 0.

## Considerations

- **Refer, never embed (DRY / single source of truth).** The hook must only
  point at policy skills/paths; the moment it restates a rule (a layout, a TS
  lint rule), the policy has two homes and the qmu.co.jp sync stops being
  authoritative. This is the core constraint of the request.
- **Lens, not safeguard.** Exit 0 on every path; the hook adds context and never
  blocks. Blocking enforcement (e.g. failing a ship when a layout violates
  directory-structure) is explicitly out of scope here and would be a separate,
  later decision.
- **Trigger reliability is the main risk.** If `UserPromptSubmit` does not see
  the slash token, the whole mechanism silently no-ops. Step 1 must settle this;
  the script should match defensively (slash form + the documented NL phrasings)
  and degrade to silent no-op rather than ever erroring on a normal prompt.
- **Claude-Code-only by design.** Hooks live in the plugin's `hooks/` dir, which
  the `skills` CLI and Codex never scan (CLAUDE.md, Cross-Agent Skill Exposure).
  The three target commands are themselves Claude-only, so scoping the mechanism
  to a hook is consistent — no cross-agent obligation.
- **Don't over-inject.** The block must stay short (a few lines). It fires on
  every `/ticket`/`/report`/`/ship`; a long payload taxes every invocation. Point
  and stop.
- **Policy lens mapping** (`workaholic:implementation` → command-scripts,
  directory-structure; `objective-documentation`): keep the layer→pillar table in
  the skill, not the hook — orchestration knowledge belongs in the knowledge
  layer; the hook is the thin always-on trigger.
