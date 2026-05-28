---
created_at: 2026-05-28T12:30:10+09:00
author: a@qmu.jp
type: refactoring
layer: [Domain, Config]
effort:
commit_hash:
category:
depends_on:
---

# Improve Portable Workflow Skill Loadability

## Overview

Make the portable workflow skills easier for Codex and other Agent-Skills agents to trigger and execute. The current generated skills are self-contained, but `drive` and `report` are large, and the public skill text still carries a lot of Claude-specific mechanism wording (`AskUserQuestion`, `general-purpose`, explicit model names). Refactor the skill docs toward progressive disclosure, clearer trigger descriptions, and more agent-neutral public prose while preserving Claude Code source behavior.

## Key Files

- `plugins/core/skills/drive/SKILL.md` - Long source skill that generates the portable drive skill.
- `plugins/core/skills/report/SKILL.md` - Long source skill that generates the portable report skill.
- `plugins/core/skills/create-ticket/SKILL.md` and `plugins/core/skills/ship/SKILL.md` - Public workflow skills whose trigger descriptions and compatibility wording should stay consistent with drive/report.
- `scripts/build-plugins/build.mjs` - Publicizes generated skills and can rewrite or strip Claude-specific source constructs for the portable build.
- `dist/workflows/skills/*/SKILL.md` - Generated artifacts to regenerate after source/build changes.
- `scripts/build-plugins/verify.mjs` - Existing generated-artifact verifier.

## Related History

Recent work made the workflow skills self-contained and agent-neutral enough to install. This ticket improves how well those skills load and execute once installed.

Past tickets that touched similar areas:

- [20260527012301-build-step-for-self-contained-portable-skills.md](.workaholic/tickets/archive/work-20260518-235327/20260527012301-build-step-for-self-contained-portable-skills.md) - Introduced the self-contained portable build pipeline.
- [20260527012302-agent-neutral-workflow-skill-prose.md](.workaholic/tickets/archive/work-20260518-235327/20260527012302-agent-neutral-workflow-skill-prose.md) - Started making workflow prose usable outside Claude Code.
- [20260526011415-flatten-report-orchestration-to-general-purpose-subagents.md](.workaholic/tickets/archive/work-20260518-235327/20260526011415-flatten-report-orchestration-to-general-purpose-subagents.md) - Established the current general-purpose subagent orchestration language.
- [20260526011416-route-drive-and-ticket-orchestration-through-general-purpose-subagents.md](.workaholic/tickets/archive/work-20260518-235327/20260526011416-route-drive-and-ticket-orchestration-through-general-purpose-subagents.md) - Moved drive and ticket orchestration to the current subagent model.
- [20260527142133-update-docs-for-plugins-dist-topology.md](.workaholic/tickets/archive/work-20260518-235327/20260527142133-update-docs-for-plugins-dist-topology.md) - Documented that the generated `dist/workflows` plugin is what Codex and other non-Claude agents consume.

## Implementation Steps

1. Rewrite workflow skill frontmatter descriptions to be trigger-oriented. Include user phrases and concrete artifacts, such as `/drive`, queued `.workaholic/tickets/todo` files, branch story generation, PR creation, and shipping a current branch PR.
2. Split the longest `drive` and `report` operational details into one-level `references/` files where that reduces loaded context. Keep the top-level `SKILL.md` focused on routing, mandatory guards, and when to read each reference.
3. Preserve deterministic script references after splitting. Any referenced workflow section must still be discoverable from the top-level skill instructions.
4. Update `scripts/build-plugins/build.mjs` if needed so generated portable skills copy any new `references/` directories and verify their internal links.
5. Reduce Claude-specific mechanism wording in generated portable skills. Public text should talk about "ask the user with the current agent's interaction mechanism" and "run in parallel when the agent supports it" rather than requiring `AskUserQuestion`, `general-purpose`, `opus`, or `haiku`.
6. Regenerate `dist/workflows/` and run `node scripts/build-plugins/verify.mjs`.
7. Compare generated `dist/workflows/skills/drive/SKILL.md` and `dist/workflows/skills/report/SKILL.md` before/after to confirm they are materially shorter or clearer without losing required workflow gates.

## Considerations

- Do not weaken mandatory approval gates. Agent-neutral wording must still require explicit user confirmation for ticket order, per-ticket approval, workspace guards, and deploy confirmation (`plugins/core/skills/drive/SKILL.md`, `plugins/core/skills/report/SKILL.md`, `plugins/core/skills/ship/SKILL.md`).
- Keep references shallow. Codex skill guidance favors one-level references from `SKILL.md`, not nested reference chains.
- `dist/workflows` is generated. Make source/build changes first, then rebuild (`scripts/build-plugins/build.mjs`).
- This is a documentation/refactoring change with behavior risk. Verification should include running the generated verifier and manually scanning the generated public skills for stale Claude-only requirements.
