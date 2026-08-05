---
created_at: 2026-08-05T13:14:34+00:00
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

# Open every FB issue with its assignee set

## Overview

PROPOSED. Once the assignee is the routing key, an FB issue opened without one
reaches nobody's routine instead of everybody's — a silent drop replacing a
noisy duplicate, and the quieter failure is the worse one. `open-issue.sh` runs
`gh issue create -R <slug> --title --body-file` with no `--assignee` at all, so
the only crossing this repository sanctions produces exactly that issue. The
issue that prompted this mission carries an assignee only because its author
set one by hand.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` — what crosses a repository boundary is confirmed by a person, verbatim
- `workaholic:operation` — a refusal from the target is reported, never routed around

## Key Files

- `plugins/workaholic/skills/feedback/scripts/open-issue.sh` — the only sanctioned issue writer; currently passes no assignee
- `plugins/workaholic/skills/feedback/SKILL.md` — the crossing section, where the assignee rule belongs
- `plugins/workaholic/commands/fb.md` — the one verbatim confirmation, which must now show the assignee
- `outputs/workflows/` — regenerated, since the feedback skill ships cross-agent

## Implementation Steps

1. Take an assignee argument in `open-issue.sh`, pass it as `--assignee`, and report it in the emitted JSON.
2. Document the default: the requesting developer, unless someone else is explicitly named.
3. Show the assignee in `/fb`'s single verbatim confirmation, since it now determines who is woken.
4. Distinguish "`gh` refused the assignment" from "`gh` accepted and dropped it", and report either rather than claiming an assignee that was never set.
5. Update the feedback skill's crossing section and regenerate with `node scripts/build-plugins/build.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An issue opened through `/fb` carries an assignee, and the confirmation showed it
- An assignment the target refused or silently dropped is reported, not swallowed

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/verify.mjs` — `outputs/` in lockstep with the source

**Gate** — what must pass before approval:

- No path opens an FB issue without an assignee, and none reports one it did not set

## Considerations

GitHub accepts `--assignee` for a user who cannot actually be assigned on the
target — a non-collaborator on a private repository — and drops it without
failing the create. If step 4 only checks the exit status, the routing key can
be absent while the run reports success, which is the same silent drop this
ticket exists to remove, merely moved one step later.
