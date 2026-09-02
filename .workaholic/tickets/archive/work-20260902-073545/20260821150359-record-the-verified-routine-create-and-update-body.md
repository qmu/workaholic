---
created_at: 2026-08-21T15:03:59+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
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


## Final Report

Development completed as planned.

Step 1 (reproduce and localize before writing anything) was performed rather than skipped, and
it changed what the document says. A live routine record was read back from an **unattended,
routine-fired** session — one `list_triggers` call returning all 8 records on the account — and
the account's environments were enumerated in the same session. Two findings follow, and both
are written into `reference/routines.md` as measurements rather than as inferences:

- The read-back's key paths are `session_request.{environment_id, config, events}`, not the
  `job_config.ccr.{environment_id, session_context, events}` the ask recovered by walking
  400s. The document records **both** and refuses to collapse them: a read projection is not a
  write body, and the standing rule (the API silently drops unknown fields, so only a
  read-back settles a write) says a 200 would prove nothing either way.
- No record on the account carries a `notifications` key at all, while `propose.md` declares
  `notifications: push`. That mapping is therefore written down as the shape to try and marked
  **unverified**, which is a different and more useful answer than omitting the row.

The `mcp_connections` asymmetry got its own subsection with live evidence beside it: two
templates declare no `mcp:` and both their records carry three connectors, so the auto-attach
is observable on this account today and a converging caller diffing `mcp` reports drift on
every routine on every run.

The environment count claim left `render-routine.sh`'s header. It is not replaced with "one" —
the header now says the count is enumerated at run time and names what the two measurements
found, because one account having one environment twice is not a licence to state a count for
anybody else's.

No behaviour changed: no script emits a different byte, and the full suite passes unchanged.

### Discovered Insights

- **Insight**: a routine-fired container is **not** without an account-routine transport here.
  `ToolSearch` finds no `RemoteTrigger`-family tool — the 2026-08-10 measurement reproduces
  exactly — but the `Claude_Code_Remote` connector, which all three live routines carry in
  their own `mcp_connections`, exposes `list_triggers` / `list_environments` (and create,
  update and delete) to this session class.
  **Context**: every paragraph in `reference/routines.md` written before today reasons from
  "the routine-fired class genuinely carries none", and `no_transport` is defined as the
  absence of the `RemoteTrigger` family specifically. Both statements are still true as
  written; what is new is that they no longer imply *this session cannot reach an account
  routine*. Anything that would widen the transport search is a separate ask — the templates
  select the connector, so the reachability is a property of how this account is configured,
  not of the session class.

- **Insight**: `enabled` is **absent** on a disabled record rather than `false`.
  **Context**: two of the eight records read back carry no `enabled` key and are the two known
  to be off. A reader testing `record.enabled === false` sees neither, and the report-only
  ruling on the enabled state (§5) depends on that read being right — a routine converged in
  every field while switched off is exactly the failure it exists to name.
