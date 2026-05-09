---
created_at: 2026-05-09T00:12:16+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.5h
commit_hash: f1eff71
category: Changed
depends_on: [20260509001215-eliminate-manager-tier.md]
---

# Wire Leading Skills Into Work Plugin Flows

## Overview

After the manager tier is removed, the leading skills become the project's primary policy lens. They must be consulted whenever the work plugin scopes a ticket, drives an implementation, or runs a trip-style multi-agent session. Most of the wiring is already in place — `ticket-organizer`, `planner`, `architect`, and `constructor` agents preload the four `standards:leading-*` skills via the soft cross-plugin reference pattern. This ticket completes the wiring by:

1. Adding the same preloads to `/drive`'s orchestration surface (the `drive` command and the `drive` skill it preloads), so the implementation phase respects the leads' policies.
2. Updating the `discover` skill (the policy-mode discoverer prompt) and the `create-ticket` skill so ticket scoping explicitly references leading skills as the policy lens for the ticket's `layer`.
3. Confirming the trip stack (`trip` command, `trip-protocol` skill, planner/architect/constructor agents) keeps the leading-skill preloads.

Leading skills remain `user-invocable: false` and are referenced through soft cross-plugin preloads (`work` -> `standards`).

## Key Files

### Drive surface

- `plugins/work/commands/drive.md` - Drive command frontmatter and instructions; needs to preload all four leading skills and reference them in implementation guidance
- `plugins/work/skills/drive/SKILL.md` - Drive workflow skill; the Workflow section's "Implement the Ticket" step should direct the implementer to apply the relevant leading-skill policies
- `plugins/work/agents/drive-navigator.md` - Drive navigator subagent; consider whether to preload leading skills (drive-navigator only orders tickets, but its prioritization could consider the lead lens implied by `layer`)

### Ticket surface

- `plugins/work/commands/ticket.md` - Ticket command; already invokes ticket-organizer which preloads leads. Add a one-line note that ticket scoping uses leading skills as policy lenses.
- `plugins/work/agents/ticket-organizer.md` - Already preloads all four leading skills in frontmatter (verified). Confirm and tighten the instruction text in step 5 ("Apply the preloaded **lead standards**") if needed.
- `plugins/work/skills/create-ticket/SKILL.md` - Add a "Lead Lens" subsection that maps `layer` values to the relevant leading skill and tells the author to read those skills when filling in Implementation Steps and Considerations.
- `plugins/work/skills/discover/SKILL.md` - Discover Policy section already searches `plugins/standards/`. Tighten to call out leading skills explicitly as the canonical policy source.

### Trip surface (verification only)

- `plugins/work/commands/trip.md` - Already passes "lead standards preloaded" instruction to the team lead. No change required if the leading-skill preloads in planner/architect/constructor remain intact.
- `plugins/work/agents/planner.md` - Already preloads all four leading skills. Verify.
- `plugins/work/agents/architect.md` - Already preloads all four leading skills. Verify.
- `plugins/work/agents/constructor.md` - Already preloads all four leading skills. Verify.
- `plugins/work/skills/trip-protocol/SKILL.md` - Reference; no change required.

### Reference

- `plugins/standards/skills/leading-validity/SKILL.md`, `leading-availability/SKILL.md`, `leading-security/SKILL.md`, `leading-accessibility/SKILL.md` - The four leads. Their `user-invocable: false` frontmatter and `standards:leading-*` invocation slug are the contract this ticket relies on.
- `plugins/work/.claude-plugin/plugin.json` - Confirms `dependencies: ["core"]` and not `["standards"]`. The leading-skill preloads use the soft cross-plugin reference pattern, not a hard dependency.
- `CLAUDE.md` - "Plugin Dependencies" section documents that work has soft references to standards.

## Related History

The lead skills were created in February 2026 alongside the manager tier; subsequent renames (lead-* → leading-*) and tone rewrites (humble trade-off-acknowledging language) brought them to their current shape. This ticket completes the work-plugin integration that was implicit when leads were originally wired only through the now-removed `/scan` flow.

Past tickets that touched similar areas:

- [20260415163724-rewrite-leads-to-policy-language.md] (recent) - Renamed `lead-*` to `leading-*` and rewrote leads in humble, trade-off-acknowledging tone (current shape this ticket relies on; commit 86a048c in main history)
- [20260211170402-wire-leaders-to-manager-outputs.md](.workaholic/tickets/archive/drive-20260210-121635/20260211170402-wire-leaders-to-manager-outputs.md) - Wired leads to consume manager outputs through `/scan`; this ticket replaces that wiring with direct preloads in the work plugin's flows
- [20260211170401-define-manager-tier-and-skills.md](.workaholic/tickets/archive/drive-20260210-121635/20260211170401-define-manager-tier-and-skills.md) - Created the manager tier the dependent ticket dismantles
- [20260203200934-refactor-ticket-organizer.md](.workaholic/tickets/archive/drive-20260203-122444/20260203200934-refactor-ticket-organizer.md) - Refactored ticket-organizer; same file modified here

## Implementation Steps

1. **Verify that the foundation ticket has merged.**

   This ticket depends on `20260509001215-eliminate-manager-tier.md`. Do not start until that ticket's deletions have landed.

2. **Update `plugins/work/commands/drive.md` to preload leading skills.**

   In the frontmatter `skills:` list, add the four leading skills via the soft cross-plugin slug:

   ```yaml
   skills:
     - drive
     - core:system-safety
     - standards:leading-validity
     - standards:leading-accessibility
     - standards:leading-security
     - standards:leading-availability
   ```

   In Phase 2 Step 2.1 ("Implement Ticket"), add a one-sentence reminder to apply the policies, practices, and standards from the relevant leading skill when implementing.

3. **Update `plugins/work/skills/drive/SKILL.md` Workflow section.**

   In step 3 ("Implement the Ticket"), add a bullet:

   - Read the ticket's `layer` field. For each layer, apply the policies, practices, and standards from the matching leading skill (UX → leading-accessibility, Domain/DB/Config → leading-validity, Infrastructure → leading-availability, anything touching authentication/secrets → leading-security). Multiple layers compound — apply every relevant lead.

   The `drive` skill itself does not need to preload the leads (skills cannot invoke subagents and the leads are skill-format documents). The preloads on the drive command are sufficient because the command context retains them through the workflow.

4. **Decide whether `drive-navigator` preloads leading skills.**

   `drive-navigator` only orders tickets; it does not implement them. The lead policies are not directly relevant to prioritization. Recommendation: **do not** add leading-skill preloads to drive-navigator. Keep its frontmatter unchanged. Document this decision in the Considerations section so future readers understand the choice.

5. **Update `plugins/work/skills/create-ticket/SKILL.md` to reference leading skills.**

   Add a new section after "Frontmatter Fields" titled "Lead Lens":

   ```markdown
   ## Lead Lens

   Each ticket should respect the relevant leading skills based on its `layer` field. Map layer to lead:

   | Layer | Leading skill | Lens |
   | ----- | ------------- | ---- |
   | UX | `standards:leading-accessibility` | Reach, modeless design, WCAG conformance |
   | Domain | `standards:leading-validity` | Type-driven design, layer segregation, functional style |
   | Infrastructure | `standards:leading-availability` | CI/CD, vendor neutrality, IaC, observability |
   | DB | `standards:leading-validity` | Relational-first persistence, domain–persistence segregation |
   | Config | (whichever lead governs the affected behavior) | Apply the lead whose policies the config touches |

   Anything touching authentication, authorization, secrets management, or input validation also engages `standards:leading-security` regardless of layer.

   When writing Implementation Steps, Considerations, and Patches, ensure they respect the policies, practices, and standards of every applicable lead. The ticket-organizer agent has these skills preloaded and applies them automatically; this section documents the mapping for human readers and future agents.
   ```

6. **Tighten `plugins/work/skills/discover/SKILL.md` Discover Policy section.**

   In the "Search Locations" subsection, expand the `plugins/standards/` line to:

   ```markdown
   - Standards plugin content (`plugins/standards/`) — leading skills (`leading-*/SKILL.md`) are the canonical policy source; `leaders-principle/SKILL.md` carries cross-cutting principles
   ```

   In the "Architecture Decisions" subsection, add:

   - Apply the four leading skills as the project's authoritative policy lenses. Cite specific policies and practices when a discovered constraint maps to one (e.g., "leading-validity: Ours/Theirs Layer Segregation").

7. **Confirm `ticket-organizer.md` step 5 wording.**

   The agent already preloads the four leading skills and step 5 says "Apply the preloaded **lead standards**". Verify the wording still maps cleanly to the leads after the foundation ticket has rewritten lead Role sections. Tighten only if needed (e.g., if "lead standards" reads ambiguously, change to "leading skills").

8. **Confirm `ticket.md` references leading skills.**

   Add a one-line note to `plugins/work/commands/ticket.md` (after the "Notice" block) that ticket scoping uses the leading skills as policy lenses. The note exists primarily for human readers; the actual enforcement happens inside `ticket-organizer`.

9. **Verify trip surface is unchanged.**

   ```bash
   grep -l "standards:leading-" plugins/work/agents/planner.md plugins/work/agents/architect.md plugins/work/agents/constructor.md
   ```

   Expected: all three files match. The trip command's lead-standards instruction in Step 4 already references "preloaded **lead standards**". No edits required if all preloads are intact.

10. **Audit cross-plugin reference pattern.**

    Confirm the work plugin still declares only `["core"]` as a dependency (not `["core", "standards"]`). The leading-skill preloads must remain soft — they tolerate the standards plugin being absent. Verify with:

    ```bash
    cat plugins/work/.claude-plugin/plugin.json
    ```

11. **Final sanity grep.**

    ```bash
    grep -rn "standards:leading-" plugins/work/ 2>/dev/null
    ```

    Expected matches: ticket-organizer (4), planner (4), architect (4), constructor (4), drive command (4 after this ticket), create-ticket skill (table reference), discover skill (text reference). No matches inside `drive-navigator` (per the decision in step 4).

## Patches

### `plugins/work/commands/drive.md`

```diff
--- a/plugins/work/commands/drive.md
+++ b/plugins/work/commands/drive.md
@@ -3,6 +3,10 @@ name: drive
 description: Implement tickets from .workaholic/tickets/ one by one, commit each, and archive.
 skills:
   - drive
   - core:system-safety
+  - standards:leading-validity
+  - standards:leading-accessibility
+  - standards:leading-security
+  - standards:leading-availability
 ---
```

### `plugins/work/skills/drive/SKILL.md`

```diff
--- a/plugins/work/skills/drive/SKILL.md
+++ b/plugins/work/skills/drive/SKILL.md
@@ -42,6 +42,11 @@ If no Patches section exists, skip to step 3.

 #### 3. Implement the Ticket

+- Read the ticket's `layer` field. For each layer, apply the policies, practices, and standards from the matching leading skill:
+  UX → `standards:leading-accessibility`, Domain → `standards:leading-validity`,
+  Infrastructure → `standards:leading-availability`, DB → `standards:leading-validity`,
+  Config → the lead whose policies the config touches.
+  Anything touching authentication, authorization, secrets, or input validation also engages `standards:leading-security`.
 - Follow the implementation steps in the ticket
 - Use existing patterns and conventions in the codebase
 - For areas where patches applied, verify and adjust as needed
```

> **Note**: These patches are speculative. Verify the exact frontmatter shape and surrounding context in `drive.md` and `drive/SKILL.md` before applying. The `create-ticket` and `discover` skill edits are too freeform to express as a useful diff — write them as new sections following the structure described in the implementation steps.

## Considerations

- **Drive-navigator deliberately not wired**: The navigator orders tickets by type, layer, and dependency graph. The leading skills do not affect that ordering. Adding preloads would inflate context for no behavioral change. If a future requirement emerges (e.g., "skip tickets the security lead would reject"), revisit the decision then. (`plugins/work/agents/drive-navigator.md`)
- **Soft cross-plugin reference pattern**: All leading-skill references in the work plugin use the `standards:leading-*` slug rather than a `${CLAUDE_PLUGIN_ROOT}/../standards/` path. This matches the soft-reference convention documented in `CLAUDE.md` "Plugin Dependencies" — work tolerates the standards plugin being absent in environments where it is not installed. Do not change the work plugin's `dependencies` to add `"standards"`. (`CLAUDE.md`, `plugins/work/.claude-plugin/plugin.json`)
- **Skills cannot preload subagents**: The `drive` skill cannot directly preload the leading skills via `skills:` frontmatter without the parent command also doing so — the command's preload list is what actually puts the skill content into the implementer's context. The drive command therefore carries the canonical preload list; the drive skill text only references the leads by name. (`plugins/work/skills/drive/SKILL.md` frontmatter, `plugins/work/commands/drive.md` frontmatter)
- **`leaders-principle` stays implicit**: The four leading skills do not currently preload `leaders-principle` themselves; that cross-cutting skill applies through manual invocation. This ticket does not change that pattern. If the leaders-principle should also be preloaded by the work plugin, that is a follow-up scope. (`plugins/standards/skills/leaders-principle/SKILL.md`)
- **Lead-Lens table is informational, not enforceable**: The mapping in `create-ticket/SKILL.md` is a reading aid for ticket authors and human reviewers. The actual policy application happens inside `ticket-organizer` and the `drive` workflow. Keep the table accurate but expect drift; treat it as documentation, not as a contract. (`plugins/work/skills/create-ticket/SKILL.md`)
- **Trip command instruction text**: Trip already says "All agents have the team's **lead standards** preloaded — ensure all planning, design, implementation, and testing respects the policies, practices, and standards defined by the leads." After this ticket, that wording remains correct because the per-agent preloads remain unchanged. (`plugins/work/commands/trip.md` Step 4)
- **No `manage-*` references should remain**: After the foundation ticket lands, the grep in step 11 should find no `manage-*`, `managers-principle`, or `*-manager` references anywhere in `plugins/work/`. If any are found, treat as a regression and remove. (`plugins/work/`)
- **Layer-to-lead mapping is opinionated**: The mapping (UX → accessibility, Domain → validity, etc.) is a starting heuristic, not a strict rule. Tickets often touch multiple layers and engage multiple leads. The Lead Lens table notes this explicitly and tells authors to apply every relevant lead. (`plugins/work/skills/create-ticket/SKILL.md` Lead Lens section)
- **Cross-reference**: This ticket depends on `20260509001215-eliminate-manager-tier.md` and is followed by `20260509001217-update-stale-manager-documentation.md`. The doc-sweep ticket cannot start until the work-plugin wiring is final, because the spec docs describe the work-plugin agent topology.

## Final Report

Development completed as planned. Drive command and drive skill now preload the four leading skills and reference them in implementation guidance; create-ticket gained the Lead Lens table; discover's Policy section calls out leading skills explicitly; ticket-organizer's "lead standards" wording was tightened to "leading skills"; and the /ticket command grew a one-line Lead Lens note. Trip stack required no changes — planner/architect/constructor already preload all four leads. Work plugin's `dependencies` array remains `["core"]` per the soft cross-plugin reference pattern.

### Discovered Insights

- **Insight**: All four leading skills are now preloaded in five places: ticket-organizer, planner, architect, constructor, and the /drive command — the canonical "policy carriers" of the work plugin.
  **Context**: When adding a new orchestration surface (a new command or agent that performs work), the standard pattern is to preload all four leads via `standards:leading-*` slugs. drive-navigator is deliberately excluded because it only orders tickets.
- **Insight**: The drive *skill* cannot preload the leads on its own — only the parent command's preload list actually injects skill content into the implementer's context.
  **Context**: This is why drive.md (the command) carries the preload list while drive/SKILL.md (the skill) only references the leads by name. Future skill authors should expect the same constraint.
