---
created_at: 2026-08-21T15:03:59+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-routine-create-body-documented-and-buildable
merge_policy:
verification_handoff: 
---

# Build the routine API body in one place

## Overview

PROPOSED. `render-routine.sh` emits display strings — `"[Slack]"`, `"[Bash, Read, Glob,
Grep]"` — so every caller re-parses them into JSON arrays before it can build a request body.
It emits no `sources` at all, and `[Workaholic]` needs a **different repository** from the one
being wired (it checks out qmu/workaholic), a fact stated only in that template's prose. So a
caller converging five templates re-implements the body five times and special-cases one of
them by reading paragraphs.

This ticket puts the body in one place and makes `sources` data.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/scripts/render-routine.sh` — emits the display strings today; either gains a JSON mode or is joined by a sibling.
- `plugins/workaholic/skills/workaholify/scripts/list-routine-templates.sh` — the other reader of the same frontmatter; whatever field is added must appear here too.
- `plugins/workaholic/skills/workaholify/routines/workaholic.md` — the one template whose checkout is not the repository being wired.
- `scripts/test-workflow-scripts.mjs` — pins the rendering; a new field or mode needs its own coverage.


## Implementation Steps

1. Resolve Open Decision 1 below before writing code — the two shapes have different blast
   radii and the choice is not this session's to make silently.
2. Add `sources:` to the routine templates and render it. `[Workaholic]` declares
   qmu/workaholic; every other template declares the repository being wired. The prose
   sentence in `workaholic.md` becomes a pointer to the field, not the source of truth.
3. Emit the connector list and the tool list as JSON arrays on the machine-facing path, so no
   caller parses `"[Bash, Read]"` back apart.
4. Build the whole request body in one place, reading the environment id as a parameter — this
   ticket does not decide where that id comes from (that is the third ticket), it only stops
   the body being rebuilt per caller.
5. Cover the new surface in `test-workflow-scripts.mjs`: the rendered body for each template,
   and `[Workaholic]`'s differing `sources`.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- One place builds the request body; no caller parses a display string back into JSON.
- Every template declares `sources:`, and `[Workaholic]`'s points at qmu/workaholic.
- The setup sheets still render their human-pasteable form unchanged.

**Verification method** — the commands/tests/probes that prove them:

- Render each of the five templates and diff the produced body against a live record's shape.
- `render-setup-sheet.sh --all <repo-url>` output is byte-identical to before the change.
- `node scripts/test-workflow-scripts.mjs` covers the new surface and passes.

**Gate** — what must pass before approval:

- Open Decision 1 is resolved explicitly in the driving session's Final Report.
- `node scripts/build-plugins/build.mjs` + `verify.mjs` clean; `outputs/` regenerated.


## Considerations

- The display strings are what the **setup sheets** print for a human to paste. A JSON-only
  rewrite would break the sheet; both surfaces have to keep working.
- `sources:` is a new template field, so `list-routine-templates.sh` and both sheet renderers
  read it or they drift — the same failure mode `scope:` was introduced to avoid.

## Open Decisions

1. **A sibling script, or a JSON mode on `render-routine.sh`?** The ask offers both without
   choosing (`build-routine-body.sh <template-id> <repo-url> <environment-id>` emitting the
   whole JSON, *or* `render-routine.sh` gaining a JSON-typed mode) and this session cannot ask.
   They differ in blast radius: a sibling leaves the existing renderer and its four callers
   untouched and adds a second script reading the same frontmatter — the drift `scope:` was
   centralised to avoid; a mode keeps one reader but changes a script the setup sheets already
   depend on. Resolve it explicitly in the Final Report; do not inherit the ask's first
   phrasing as the design.

