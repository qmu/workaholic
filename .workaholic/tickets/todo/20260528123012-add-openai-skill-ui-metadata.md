---
created_at: 2026-05-28T12:30:12+09:00
author: a@qmu.jp
type: enhancement
layer: [UX, Config]
effort:
commit_hash:
category:
depends_on:
---

# Add OpenAI Skill UI Metadata

## Overview

Add `agents/openai.yaml` metadata for the Workaholic skills that are exposed to Codex and other Agent-Skills surfaces. The skill bodies already provide machine-readable instructions, but OpenAI-facing metadata can improve skill list display names, short descriptions, and default prompts for users installing or invoking Workaholic skills.

## Key Files

- `plugins/standards/skills/*/SKILL.md` - Source standards skills that should receive matching OpenAI UI metadata.
- `plugins/core/skills/create-ticket/SKILL.md`, `drive/SKILL.md`, `report/SKILL.md`, `ship/SKILL.md`, `review-sections/SKILL.md`, and `write-release-note/SKILL.md` - Source workflow skills exposed through `dist/workflows`.
- `scripts/build-plugins/build.mjs` - May need to copy `agents/openai.yaml` directories from source skills into generated workflow skills.
- `dist/workflows/skills/*/agents/openai.yaml` - Generated artifacts expected after the build if workflow metadata is sourced from `plugins/core`.
- `plugins/standards/skills/*/agents/openai.yaml` - Standards metadata can live directly with the source skills because standards are not generated through `dist/workflows`.

## Related History

The cross-agent packaging work exposed the Workaholic skills beyond Claude Code. This ticket improves how those exposed skills present themselves in OpenAI-compatible skill UIs.

Past tickets that touched similar areas:

- [20260525205529-package-core-standards-cross-agent-skills.md](.workaholic/tickets/archive/work-20260518-235327/20260525205529-package-core-standards-cross-agent-skills.md) - Added cross-agent exposure for standards skills.
- [20260527012303-codex-plugin-manifests-and-exposure.md](.workaholic/tickets/archive/work-20260518-235327/20260527012303-codex-plugin-manifests-and-exposure.md) - Exposed workflow skills through Codex plugin manifests.
- [20260527142131-add-opencode-generated-target.md](.workaholic/tickets/archive/work-20260518-235327/20260527142131-add-opencode-generated-target.md) - Confirmed one generated `dist/workflows` plugin can serve Codex plus the skills CLI ecosystem.

## Implementation Steps

1. Confirm the expected `agents/openai.yaml` schema from current Codex skill guidance before writing files.
2. Add concise `agents/openai.yaml` files for the four standards skills with human-facing display names, short descriptions, and default prompts that match each `SKILL.md`.
3. Add concise `agents/openai.yaml` files for the exposed workflow skills in `plugins/core/skills`.
4. Update `scripts/build-plugins/build.mjs` so generated workflow skills copy the `agents/` directory from each source skill when present.
5. Regenerate `dist/workflows/` and verify the generated metadata exists beside each exposed workflow `SKILL.md`.
6. Add or extend validation so stale or malformed `agents/openai.yaml` files fail locally or in CI.

## Considerations

- Keep UI metadata short and human-facing. Do not duplicate long workflow instructions already present in `SKILL.md`.
- Ensure generated workflow metadata is source-driven. Hand-writing only under `dist/workflows` will be lost on the next build.
- The metadata must stay aligned with trigger descriptions. If the portable skill loadability ticket changes frontmatter descriptions first, mirror that language here where useful.
- Standards skills are marked `user-invocable: false` today. Decide whether their OpenAI metadata should present them as direct user tools or quiet policy lenses before exposing default prompts.
