---
created_at: 2026-08-21T15:03:59+09:00
author: a@qmu.jp
assignees: [tamura.yoshiya@gmail.com]
depends_on:
mission: make-the-routine-create-body-documented-and-buildable
merge_policy:
verification_handoff: 
---

# Record the verified routine create and update body

## Overview

PROPOSED. `reference/routines.md` documents exactly one leaf of the routine record —
`job_config.ccr.session_context.autofix_on_pr_create`. Everything else a create needs was
recovered on 2026-08-20 by walking 400s: `job_config.ccr.{environment_id, session_context,
events}`, `events[].data.{uuid, session_id, type, parent_tool_use_id, message}`, and
`session_context.{model, sources, allowed_tools, autofix_on_pr_create}`. Two template fields
have no stated mapping at all — `notifications: push` → `notifications.channel.{email, push,
slack}`, and `model`/`allowed_tools` → `session_context`. And `mcp: []` is **unachievable in a
single call**: a create silently auto-attaches connectors, so clearing them needs a second
`update` carrying `clear_mcp_connections: true`. §5 lists `mcp` among the fields to diff and
says none of this, so a `[Workaholic]` created by the book diverges from its own template the
instant it exists.

This ticket writes the record down. It changes no behaviour.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/reference/routines.md` — the home of the record; today one leaf.
- `plugins/workaholic/skills/workaholify/scripts/render-routine.sh` — its header carries the "there are two [environments]" claim, which is one account's fact stated as general (the account measured had exactly one, `Default`).
- `plugins/workaholic/skills/workaholify/routines/*.md` — the template fields whose mapping is being recorded.


## Implementation Steps

1. **Reproduce and localize before writing anything.** Read a live routine record back through
   a `RemoteTrigger`-family tool and diff its shape against what the ask lists. The report is a
   measurement from one account on one day; the record must state what was observed, not what
   was inferred. Where a field cannot be observed from this session, say so rather than
   guessing — the API silently drops unknown fields, so a 200 proves nothing.
2. Write the create body into `reference/routines.md`, field by field, including which fields
   are required and which are optional.
3. Write the **create-vs-update asymmetry** as its own named subsection: `mcp_connections: []`
   in a create is ignored and the server auto-attaches; `clear_mcp_connections: true` on a
   following `update` is what empties it.
4. Write the template-field → record-field mapping table: `notifications` →
   `notifications.channel.*`, `model`/`allowed_tools`/`autofix_on_pr_create` → `session_context`.
5. Drop the account-specific environment count from `render-routine.sh`'s header comment. The
   claim that "there are two" is not this repository's to make.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `reference/routines.md` names every field of the create and update bodies the ask lists, each marked observed or unverified.
- The create-vs-update `mcp_connections` asymmetry has its own named subsection.
- Every template field maps to a stated record field; none is left to a caller to guess.
- `render-routine.sh`'s header no longer states how many environments an account has.

**Verification method** — the commands/tests/probes that prove them:

- Read a live routine record back and diff it against the document, field by field.
- `grep` each template's frontmatter keys against the mapping table — no key unmapped.
- `node scripts/test-workflow-scripts.mjs` unchanged (this ticket alters no behaviour).

**Gate** — what must pass before approval:

- The document distinguishes what was observed from what was inferred, per field.
- `node scripts/build-plugins/build.mjs` + `verify.mjs` clean.


## Considerations

- The mapping is recorded from observation on one account. Say so in the document: a field
  observed once is a measurement, and the next account may differ.
- Nothing here changes what any script emits, so the smoke tests should be unchanged by it.
  A test that starts failing means a behaviour crept into a documentation ticket.

