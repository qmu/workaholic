---
created_at: 2026-06-17T08:22:43+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Rewrite CLAUDE.md's architecture narrative for the single-plugin model

## Overview

The plugin merge updated CLAUDE.md's Project Structure, Version Management, file
paths, and dependency diagram (with a flag note), but the **conceptual narrative**
in several sections still frames the prior three-plugin model (`core`/`standards`/
`work`) in prose. The mechanics it describes are unchanged and correct — only the
plugin-name framing is stale. (Carried concern `43-architecture-narrative-…`.)

Rewrite the affected prose so it describes the single `workaholic` plugin honestly,
and remove the temporary flag note added during the merge.

## Key Files

- `CLAUDE.md` - Sections needing the narrative pass:
  - **`### Plugin Dependencies`** - Remove the temporary "Note: the prose below still describes the prior three-plugin topology…" flag once the prose below is fixed.
  - **`### Cross-Agent Skill Exposure`** - Rewrite: it says "the `standards` skills are installable…", "Script-bearing `core` skills carry `metadata.internal`", "`work` needs nothing — it has no `skills/` dir". In the merged world there is one plugin whose `skills/` holds both the internal script-bearing skills and the exposed pure-prose policy skills; the `metadata.internal` gating story is unchanged but the per-plugin framing must collapse to one plugin.
  - **`#### Cross-agent distribution (workflow skills, built)`** - References "the DRY `plugins/core` source", "Claude Code reads `plugins/` directly and consumes nothing from `outputs/`". Update plugin framing (the build now sources `plugins/workaholic/skills`).
  - **Component Nesting / No-Per-Workflow-Agent-Files** - mentions preloading "the relevant `core` skill" and `core:<skill>` in subagent prompts → `workaholic:<skill>`.
  - The **`## Important`** note and intro are fine.
- `.claude-plugin/marketplace.json` - The `workflows` plugin entry description still says "Claude Code users install core/work instead" — fix to point at the `workaholic` plugin.
- `README.md` - Re-read for any remaining three-plugin conceptual framing (paths already fixed).

## Related History

- This is the documentation half of the plugin merge, deliberately deferred during the autonomous night-drive run (the merge ticket's Final Report flagged it as a non-blocking follow-up so a careful prose pass could be done interactively rather than rushed unattended).

## Implementation Steps

1. Rewrite the four CLAUDE.md sections above to the single-`workaholic`-plugin model, preserving the unchanged mechanics (the `metadata.internal` gating, the `${CLAUDE_PLUGIN_ROOT}` determinism rationale, the generated `outputs/workflows` bundle, the source-vs-artifact split).
2. Remove the temporary flag note at `### Plugin Dependencies`.
3. Replace `core:`/`standards:`/`work:` namespace mentions in prose with `workaholic:`.
4. Fix the `workflows` entry description in `.claude-plugin/marketplace.json`.
5. Re-read `README.md` for any remaining three-plugin conceptual framing.

## Considerations

- **Mechanics unchanged — only framing.** Do NOT alter the substance: script-bearing
  skills still keep `metadata.internal` + `${CLAUDE_PLUGIN_ROOT}` and reach other
  agents via the generated `outputs/workflows` bundle; the determinism rationale
  (verified 2026-05-26) still holds. Only the "three plugins" wording collapses to
  one. (`CLAUDE.md` Cross-Agent Skill Exposure)
- **Pure prose; no gates.** This is documentation — no build/verify impact — but
  keep it accurate so future agents/contributors aren't misled (the whole reason
  the night-drive failure earlier happened was stale on-disk state vs. docs).
- **Single source of truth for versions/paths.** Where the prose lists files or
  paths, mirror the already-correct Project Structure and Version Management
  sections rather than re-deriving. (`CLAUDE.md`)
- `write-in-own-voice`: write the rewritten narrative cleanly and confidently, not
  as a patch over the old three-plugin sentences.
