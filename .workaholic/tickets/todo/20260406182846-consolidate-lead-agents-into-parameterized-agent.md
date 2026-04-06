---
created_at: 2026-04-06T18:28:46+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Consolidate 10 Lead Subagent Files into a Single Parameterized Lead Agent

## Overview

The 10 lead agent files (`a11y-lead.md`, `db-lead.md`, `delivery-lead.md`, `infra-lead.md`, `observability-lead.md`, `quality-lead.md`, `recovery-lead.md`, `security-lead.md`, `test-lead.md`, `ux-lead.md`) all follow an identical policy-dispatcher pattern: read the caller's prompt, apply the corresponding policy from the lead skill, execute, return JSON. The only differences between the 10 files are (1) the domain name substituted into the template, (2) the description string, and (3) which analysis skill they preload (`analyze-policy` for 7 of them, `analyze-viewpoint` + `write-spec` for the other 3). Replace these 10 files with a single `lead.md` agent that preloads all 10 domain skills and both analysis skill sets, and receives the domain as a parameter in the caller's prompt. Update the `/scan` command and `select-scan-agents` script to invoke the single `lead` agent with a domain parameter.

## Key Files

- `plugins/standards/agents/a11y-lead.md` - Lead agent to be replaced (policy type)
- `plugins/standards/agents/db-lead.md` - Lead agent to be replaced (viewpoint type)
- `plugins/standards/agents/delivery-lead.md` - Lead agent to be replaced (policy type)
- `plugins/standards/agents/infra-lead.md` - Lead agent to be replaced (viewpoint type)
- `plugins/standards/agents/observability-lead.md` - Lead agent to be replaced (policy type)
- `plugins/standards/agents/quality-lead.md` - Lead agent to be replaced (policy type)
- `plugins/standards/agents/recovery-lead.md` - Lead agent to be replaced (policy type)
- `plugins/standards/agents/security-lead.md` - Lead agent to be replaced (policy type)
- `plugins/standards/agents/test-lead.md` - Lead agent to be replaced (policy type)
- `plugins/standards/agents/ux-lead.md` - Lead agent to be replaced (viewpoint type)
- `plugins/core/commands/scan.md` - Caller that invokes all 10 leads by slug
- `plugins/standards/skills/select-scan-agents/scripts/select.sh` - Emits per-domain agent slugs
- `plugins/standards/skills/select-scan-agents/SKILL.md` - Documents agent tiers
- `.claude/rules/define-lead.md` - Schema enforcement rule with Agent Template section

## Related History

The lead architecture was created through a series of analyst-to-lead transformations, and has already undergone one schema-wide structural change (resetting policies). Consolidation of thin files into cohesive units is a well-established pattern in this codebase.

- [20260404002424-reset-lead-skill-policies.md](.workaholic/tickets/archive/drive-20260403-230430/20260404002424-reset-lead-skill-policies.md) - Reset all 10 lead skill policies and renamed "Default Policies" to "Policies" across all agents and rules (same 10 agent files being modified)
- [20260209160336-create-define-lead-skill.md](.workaholic/tickets/archive/drive-20260208-131649/20260209160336-create-define-lead-skill.md) - Created the define-lead schema with agent template section (same schema being modified)
- [20260330210138-consolidate-drivin-skills.md](.workaholic/tickets/archive/drive-20260329-173608/20260330210138-consolidate-drivin-skills.md) - Consolidated 12 drivin skill directories into 5 cohesive units (precedent for consolidation refactoring)

## Implementation Steps

1. **Create `plugins/standards/agents/lead.md`**

   Create a single generic lead agent that preloads all 10 domain skills, the leaders-principle, and both analysis skill sets. The caller passes the domain (e.g., `security`, `ux`, `db`) in the prompt, and the agent applies the matching `lead-<domain>` skill.

   The skills list must include all 12 domain-related skills plus both analysis frameworks:

   ```
   skills:
     - leaders-principle
     - lead-a11y
     - lead-db
     - lead-delivery
     - lead-infra
     - lead-observability
     - lead-quality
     - lead-recovery
     - lead-security
     - lead-test
     - lead-ux
     - analyze-policy
     - analyze-viewpoint
     - write-spec
   ```

   The body instructs the agent to:
   1. Read the caller's prompt to determine the domain and task type.
   2. Apply the corresponding Policy from the `lead-<domain>` skill.
   3. For viewpoint domains (ux, infra, db): follow analyze-viewpoint and write-spec skills.
   4. For policy domains (all others): follow analyze-policy skill.
   5. Execute the task within the lead's Role and Responsibility.
   6. Return a JSON result describing what was done.

2. **Delete the 10 individual lead agent files**

   Remove:
   - `plugins/standards/agents/a11y-lead.md`
   - `plugins/standards/agents/db-lead.md`
   - `plugins/standards/agents/delivery-lead.md`
   - `plugins/standards/agents/infra-lead.md`
   - `plugins/standards/agents/observability-lead.md`
   - `plugins/standards/agents/quality-lead.md`
   - `plugins/standards/agents/recovery-lead.md`
   - `plugins/standards/agents/security-lead.md`
   - `plugins/standards/agents/test-lead.md`
   - `plugins/standards/agents/ux-lead.md`

3. **Update `plugins/core/commands/scan.md` Phase 3b**

   Replace the 10 separate lead rows in the agent invocation table with 10 invocations of the single `standards:lead` agent, each with a domain parameter in the prompt:

   Before (10 distinct subagent_type values):
   ```
   | `ux-lead` | `standards:ux-lead` | Pass base branch |
   | `security-lead` | `standards:security-lead` | Pass base branch |
   ...
   ```

   After (single subagent_type, domain in prompt):
   ```
   | `lead (ux)` | `standards:lead` | Pass domain: ux, base branch |
   | `lead (security)` | `standards:lead` | Pass domain: security, base branch |
   ...
   ```

   Each Task tool call uses `subagent_type: "standards:lead"` and includes the domain in the prompt text (e.g., "Domain: security. Scan the repository...").

4. **Update `plugins/standards/skills/select-scan-agents/scripts/select.sh`**

   The ALL_AGENTS variable currently lists individual lead slugs. Change to emit a generic `lead` slug paired with a domain qualifier. The output format needs adjustment since the same agent slug is used 10 times with different parameters.

   Option A: Emit `lead:ux`, `lead:db`, etc. as compound identifiers, and have the scan command parse the colon-separated domain.

   Option B: Change the output schema to separate leads into their own array with explicit domain fields:
   ```json
   {"mode": "full", "managers": [...], "leads": [{"agent": "lead", "domain": "ux"}, ...], "writers": [...]}
   ```

   Option B is cleaner because it avoids convention-based parsing. The scan command reads the `leads` array and the `writers` array separately.

5. **Update `plugins/standards/skills/select-scan-agents/SKILL.md`**

   Update the Agent Tiers section to reflect the consolidated lead agent. Update the partial scan mapping to note that triggered "agents" in the lead tier now mean triggering the `lead` agent with a specific domain parameter.

6. **Update `.claude/rules/define-lead.md` Agent Template section**

   The Agent Template section (starting around line 99) currently describes the per-domain thin agent pattern. Update it to document the consolidated parameterized agent instead, noting that a single `lead.md` file replaces all domain-specific agent files.

## Considerations

- Preloading all 10 lead skills into a single agent increases the context window consumption per invocation. Each lead skill is small (the Role + empty Policies section is ~30-40 lines), so ~300-400 lines total. This is acceptable, but if lead skills grow significantly in the future, this approach may need revisiting. (`plugins/standards/skills/lead-*/SKILL.md`)
- The agent name change from `standards:ux-lead` to `standards:lead` means any external references (outside scan.md) that invoke leads by slug must be updated. Search for all `subagent_type` references containing lead slugs. (`plugins/core/commands/scan.md`, `plugins/work/skills/trip-protocol/SKILL.md`)
- The `select.sh` script's partial scan logic touches individual domain names for selective triggering (e.g., `quality-lead`, `security-lead`). After consolidation, partial scan must still track which domains to activate, emitting `lead` with the appropriate domain parameter rather than separate agent slugs. (`plugins/standards/skills/select-scan-agents/scripts/select.sh` lines 90-128)
- The `define-lead.md` rule's Agent Template section describes the thin per-domain agent file pattern. This section needs rewriting to describe the parameterized pattern, or removal if the consolidated agent is self-explanatory. (`.claude/rules/define-lead.md` lines 99-134)
- The viewpoint leads (ux, infra, db) need `analyze-viewpoint` + `write-spec` while policy leads need `analyze-policy`. The consolidated agent must preload all three analysis skills and the instructions must guide which analysis framework to use based on the domain. This is a new branching concern that did not exist when each agent had its own static skills list. (`plugins/standards/agents/lead.md`)
