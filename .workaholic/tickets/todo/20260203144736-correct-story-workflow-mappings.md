---
created_at: 2026-02-03T14:47:36+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Correct Skill and Subagent Mappings in Story Workflow

## Overview

The story documentation workflow has two incorrect mappings that violate proper separation of concerns. The write-story skill is preloaded by story-moderator when it should be preloaded by story-writer. The pr-creator subagent is invoked directly by the /story command when it should be invoked by story-writer after documentation is complete.

## Key Files

- `plugins/core/agents/story-moderator.md` - Currently incorrectly preloads write-story skill (line 6)
- `plugins/core/agents/story-writer.md` - Should preload write-story skill and invoke pr-creator
- `plugins/core/commands/story.md` - Currently incorrectly invokes pr-creator directly (lines 59-65)
- `.workaholic/specs/command-flows.md` - Documentation shows correct architecture but implementation diverges

## Related History

Historical tickets reveal the extraction pattern for story-writer and pr-creator, where both were designed as focused single-responsibility agents.

Past tickets that touched similar areas:

- [20260127004417-story-writer-subagent.md](.workaholic/tickets/archive/feat-20260126-214833/20260127004417-story-writer-subagent.md) - Original extraction of story-writer subagent (same component)
- [20260127005601-pr-creator-subagent.md](.workaholic/tickets/archive/feat-20260126-214833/20260127005601-pr-creator-subagent.md) - Original extraction of pr-creator subagent (same component)
- [20260127021000-extract-story-skill.md](.workaholic/tickets/archive/feat-20260126-214833/20260127021000-extract-story-skill.md) - Extraction of write-story skill (same skill)

## Implementation Steps

1. **Update story-moderator.md** - Remove `write-story` from skills frontmatter:
   - Change line 6 from `skills: - write-story` to remove the skills entry entirely
   - Story-moderator orchestrates scanner and story-writer but does not write stories itself

2. **Update story-writer.md** - Add `write-story` skill and pr-creator invocation:
   - Add frontmatter: `skills: - write-story`
   - Add instruction to invoke `pr-creator` subagent after story generation completes
   - Pass branch name and base branch to pr-creator
   - Return pr-creator's PR URL in the output JSON

3. **Update story.md command** - Remove direct pr-creator invocation:
   - Remove lines 59-65 that directly invoke pr-creator subagent
   - Update completion output section to note that PR URL comes from story-moderator's result (which gets it from story-writer)
   - The /story command should only interact with story-moderator, not pr-creator

4. **Update command-flows.md spec** if needed:
   - Verify the mermaid diagram accurately reflects the corrected flow
   - The diagram already shows correct architecture (story-writer -> pr-creator)
   - May need to update component table if story-writer gains skills

## Considerations

- **Architecture compliance**: This change aligns with the design principle that skills are preloaded by the agent that uses them, not by orchestrators
- **Sequential dependency**: pr-creator must run after story file is written, so story-writer (which writes the story) is the correct invoker
- **Single responsibility**: story-moderator orchestrates, story-writer generates content and hands off to pr-creator
- **Backward compatibility**: No user-facing changes; the /story command behavior remains identical
