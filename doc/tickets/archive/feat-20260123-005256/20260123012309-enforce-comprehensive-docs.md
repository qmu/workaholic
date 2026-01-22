# Enforce Comprehensive Documentation

## Overview

The doc-writer subagent is skipping documentation updates by claiming changes are "internal implementation details." This is unacceptable - every aspect of the codebase should be documented. The subagent must document all changes without making judgment calls about what's "worth" documenting.

## Key Files

- `plugins/core/agents/doc-writer.md` - Remove permissive language that allows skipping docs
- `plugins/tdd/commands/drive.md` - Strengthen documentation requirements in step 2.3

## Implementation Steps

1. Update `plugins/core/agents/doc-writer.md` to remove all permissive language:

   - Remove "Keep documentation minimal"
   - Remove "Not every project needs every doc type"
   - Remove "Don't create elaborate doc hierarchies for simple projects"
   - Add explicit requirement: "Document every change, no exceptions"
   - Add explicit prohibition: "Never skip documentation by claiming something is an 'internal detail'"
   - Make clear the subagent does NOT have discretion to skip documentation

2. Update section 3 "Plan Before Writing" to:

   - Remove subjective "relevant to actual users" phrasing
   - State that all components must be documented
   - List required documentation categories that must always exist

3. Update `plugins/tdd/commands/drive.md` step 2.3 to:

   - Add explicit instruction: "The doc-writer must ALWAYS update documentation - 'no updates needed' is NOT an acceptable response"
   - Add requirement to document: the change itself, affected components, updated workflows

4. Add validation requirement:
   - The doc-writer must report specific files updated
   - If report says "no documentation updates needed", reject it and re-run

## Considerations

- The subagent should be a documentation executor, not a documentation gatekeeper
- Comprehensive docs are always better than sparse docs - users can skim if needed
- "Internal implementation detail" is never a valid reason to skip documentation
