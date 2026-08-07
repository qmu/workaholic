---
created_at: 2026-08-06T12:50:31+00:00
author: noreply@anthropic.com
assignees: [noreply@anthropic.com]
type: refactoring
layer: [Config]
effort:
commit_hash:
category: Changed
depends_on:
mission: slim-commands-skills-and-docs-for-ai-agent-use
merge_policy:
---

# Drop obsolete ticket front-matter fields

## Overview

<!-- PROPOSED. Sharpened by the mission's approval interrogation. -->

FB item 7: remove `type`, `layer`, `effort`, `commit_hash`, and `category` from the
ticket front matter. These fields are largely unread today. The change spans the
ticket writers (scaffold scripts), the validation hook, any reader that parses them,
and the docs that describe the schema — all in one change so nothing references a
removed field.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/*/scripts/*ticket*.sh` — ticket writers/scaffolds emitting these fields.
- `plugins/workaholic/hooks/validate-ticket.sh` — drop any check on the removed fields.
- `plugins/workaholic/skills/create-ticket/`, `drive/`, `report/` — readers, if any parse them.
- `CLAUDE.md` and rules/docs describing the ticket schema.

## Implementation Steps

1. Grep for each field name across skills, hooks, tests, and docs to find every reader/writer.
2. Remove the fields from every writer and stop validating them.
3. Update readers that reference them; update the schema docs.
4. Confirm existing tickets with the fields still validate (grandfathered) or are migrated.

## Quality Gate

**Acceptance criteria:**

- New tickets carry none of the five fields.
- No skill/hook/test/doc references a removed field.

**Verification method:**

- `grep` for each field name returns only historical/grandfathered matches; test suite passes.

**Gate:**

- Backward compatibility for already-written tickets is decided and handled.

## Considerations

<!-- Decide whether existing tickets are migrated or simply tolerated; the hook must
     not retro-block history either way. -->

## Final Report

Development completed as planned. The five fields (`type`, `layer`, `effort`, `commit_hash`, `category`) left the ticket frontmatter across writers (create-ticket template, propose scaffold), the validation hook (checks deleted; retired fields tolerated-never-validated like `claim:`), the drive skill (effort step and archive prerequisite gone, ordering now depends_on → context grouping → implicit deps, layer-derived policy fallback deleted), and the readers (`summary.sh`/`plan-units.sh` drop the keys from output; report/write-release-note/discover prose updated). Existing tickets are grandfathered byte-untouched. `update.sh` was deleted — nothing references it after the change, and a test pins the deletion. Docs updated: CLAUDE.md/README OKF paragraphs state tickets as the `type`-floor exception.

### Discovered Insights

- **Insight**: The commit `Category:` git trailer (archive.sh → `commit.sh --category` → collect-commits) is the surface `/report` actually reads; the frontmatter field was a second, unread copy.
  **Context**: Retiring the field made the trailer the single category source — the same one-source shape the repo prefers everywhere.
- **Insight**: The propose scaffold tolerates its retired `[type] [layer]` positional args instead of refusing them.
  **Context**: Stale routine prompts on the live account may still pass them; a refusal would break every such tick for a cosmetic reason.
