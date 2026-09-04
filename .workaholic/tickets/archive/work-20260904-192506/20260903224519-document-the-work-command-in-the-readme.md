---
created_at: 2026-09-03T22:45:19+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff:
claim: work-20260904-192506
---

# Document the `/work` command in the README

## Overview

The repository added `plugins/workaholic/skills/work/` and the `/work` command as the
single-session entry point for the development loop, plus `scripts/codex-loop.sh` as the local
driver, but `README.md` still describes the source and executor commands without naming this new
orchestration surface. A reader can therefore install the current plugin and still miss the command
that runs one complete loop tick.

This ticket updates the public overview only. The command and skill remain the source of truth for
runtime behavior; the README should explain where `/work` sits, what one tick encompasses, and how
it relates to `/specificate`, `/implement`, and `/moderate` without copying their detailed contracts.

## Policies

- `workaholic:implementation` / `policies/objective-documentation.md` — document the behavior a reader needs at the point of use
- `workaholic:implementation` / `policies/directory-structure.md` — keep command and skill locations legible
- `workaholic:development` / `policies/ai-utilization.md` — make the unattended AI workflow understandable to its operator

## Key Files

- `README.md` — command overview, workflow maps, command count, and documentation pointers
- `plugins/workaholic/commands/work.md` — the current command-level contract to summarize
- `plugins/workaholic/skills/work/SKILL.md` — the current tick orchestration contract
- `scripts/codex-loop.sh` — the local process that repeatedly invokes one `/work` tick

## Implementation Steps

1. Add `/work` to the README's command and workflow overview as the entry point that performs one
   complete development-loop tick.
2. Explain its relationship to the existing source, executor, and maintenance routines without
   presenting `/work` as a second executor or duplicating the detailed step contracts.
3. Update diagrams, command counts, legends, and surrounding prose whose closed command set became
   stale when the new command was added.
4. Mention `scripts/codex-loop.sh` only as the local repetition mechanism; keep the distinction
   between one command invocation and a repeating driver explicit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A reader can find `/work` from the README and understand what one invocation does.
- The README still names `/drive` and `/implement` as the one executor rather than implying that
  `/work` implements units itself.
- Every command list, count, and workflow diagram in the README agrees with the current plugin tree.
- Skill-level details remain linked to their owning files rather than copied into the README.

**Verification method** — the commands/tests/probes that prove them:

- Compare the README's command nodes and counts against `plugins/workaholic/commands/*.md`.
- Render every changed Mermaid block and confirm the new node and edges are valid and readable.
- Run `node scripts/test-workflow-scripts.mjs`.

**Gate** — what must pass before approval:

- No runtime file changes as part of this documentation-only ticket.
- No statement contradicts `commands/work.md` or `skills/work/SKILL.md`.

## Considerations

The README is orientation, not another executable contract. Exact timing, agent-capability
substitutions, and maintenance step behavior stay beside the command and skill that own them.

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: The command table already named `/work`, while the full command graph still claimed a closed set of fourteen commands and omitted the orchestration edges.
  **Context**: Public orientation must update both the discoverable command entry and the diagram that explains how commands relate.
