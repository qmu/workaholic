---
created_at: 2026-08-05T13:14:33+00:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission: scope-each-user-s-routine-to-the-fb-issues-assigned-to-them
merge_policy:
---

# Carry the trigger scope through the routine model

## Overview

PROPOSED. Once the mechanism is decided, the routine model has to express,
send, confirm and drift-check it, and today it does none of the four. A scope
nobody can see is a scope that silently drifts — and drift here is
one-directional, because the live routine is what runs and nothing rebuilds it
from the template. This ticket carries the scope end to end: template
frontmatter → the create/update body → the confirm digest → the drift report →
`/setup-routines`' output.

Putting it in the digest is the load-bearing part. `authorize-routine-change.sh`
refuses `digest_mismatch` so that one confirmation covers exactly one routine
body; a scope that sits outside `CONTENT_FIELDS` could be changed under a
confirmation a developer already gave, which is precisely the substitution the
gate exists to close.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:operation` — a standing outward-facing process is confirmed verbatim, one at a time

## Key Files

- `plugins/workaholic/skills/workaholify/routines/fb.md` — the `[Propose]` template; first carrier of the scope
- `plugins/workaholic/skills/workaholify/scripts/render-routine.sh` — emits the create/update body
- `plugins/workaholic/skills/workaholify/scripts/lib/routine_change.py` — `CONTENT_FIELDS`, the confirm digest
- `plugins/workaholic/skills/workaholify/scripts/lib/compare_routines.py` — per-field drift
- `plugins/workaholic/skills/workaholify/scripts/lib/list_routines.py` — what `/setup-routines` reports
- `plugins/workaholic/skills/workaholify/SKILL.md` — the recorded statement of what a live routine carries
- `scripts/test-workflow-scripts.mjs` — fixtures for the comparison

## Implementation Steps

1. Add the scope to the routine template frontmatter, `[Propose]` first, in whatever form the decision ticket chose.
2. Emit it from `render-routine.sh` into the `RemoteTrigger` create/update body.
3. Add it to `routine_change.py`'s `CONTENT_FIELDS` so it enters the confirm digest.
4. Compare it in `compare_routines.py` so a differing scope is reported as its own drifted field, not silently equal.
5. Report it through `list_routines.py` / `list-routines.sh` so `/setup-routines` shows it per routine.
6. Update the `workaholify` SKILL's record of what a live routine carries, and add a fixture whose scope differs.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A routine rendered from the `[Propose]` template carries the scope, and `/setup-routines` reports it
- A live routine whose scope differs from its template is reported as drift on that field

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `compare-routines.sh` driven against a fixture whose scope differs from the template

**Gate** — what must pass before approval:

- The confirm digest changes when the scope changes, so a scope edit cannot ride an earlier confirmation

## Considerations

The templates are shared by every repository that carries a workaholic routine,
so adding a field changes the drift report fleet-wide: every live routine will
read as drifted on the new field until it is refreshed. That is correct — the
report is telling the truth — but it will surface as a burst of drift, and the
refresh is one verbatim confirmation per routine by design.
