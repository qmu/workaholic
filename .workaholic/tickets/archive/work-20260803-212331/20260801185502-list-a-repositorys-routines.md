---
created_at: 2026-08-01T18:55:02+09:00
author: a@qmu.jp
type: enhancement
layer: [UX]
effort:
commit_hash:
category: Changed
depends_on: [20260801185501-decide-where-routine-config-lives.md]
mission: make-scheduled-routines-a-configurable-inspectable-part-of-a-repository
merge_policy: auto
---

# List what runs against a repository

## Overview

The read half, and the whole of the mission's stated Experience: a developer who just
joined runs the command and sees what runs against a repository, on what schedule, and
from which template version — without asking the person who set it up.

It is deliberately first and deliberately separate from the write half. Reading is safe
under any answer the decision ticket reaches about the unattended boundary, so this ships
value even if writing turns out to need confirmation for everything.

`compare-routines.sh` already does the hard part: it matches a live routine to a repository
by its **source URL, never its name** (names are what drift) and reports drift per field.
This ticket is mostly presentation over an existing reader, plus the honest reporting of
what could not be determined.

## Policies

- `workaholic:design` / `policies/user-experience.md` — the output is read by someone who does not already know the answer; it must be legible without the context of whoever configured it.
- `workaholic:implementation` / `policies/observability.md` — "could not reach the routines API" must never render as "no routines configured".
- `workaholic:implementation` / `policies/command-scripts.md` — the reader is a script; the command orchestrates.

## Key Files

- `plugins/workaholic/skills/workaholify/scripts/compare-routines.sh` - the existing reader, matching by source URL
- `plugins/workaholic/skills/workaholify/routines/` - the templates a live routine is compared against
- `plugins/workaholic/skills/workaholify/scripts/check-slack-channel.sh` - the model for reporting `checked: false` rather than a false negative
- `plugins/workaholic/commands/` - where the command surface lives

## Implementation Steps

1. Take the repository name as an argument, defaulting to the current repository.
2. Report per routine: name, schedule, target repository, template version, and whether it
   has drifted from the template — reusing `compare-routines.sh` rather than re-reading the
   API.
3. Distinguish **unreachable** from **empty**, following `check-slack-channel.sh`'s
   precedent: a locked or unreachable store reports `checked: false`, never `exists:
   false`. Telling a new developer "nothing runs against this repo" when the truth is "I
   could not look" is the failure this command exists to prevent.
4. Report `unknown` entries as deliberate one-offs, never as problems — that is the
   existing convention and this command must not invent a stricter one.
5. Read-only: this ticket creates, deletes and refreshes nothing.

## Quality Gate

**Acceptance criteria**

- The command lists the routines configured for a named repository with schedule, target and template version.
- An unreachable routines API reports that it could not be checked, distinctly from a repository with no routines — the two are never the same output.
- A drifted routine is reported per field, not as a single boolean.
- The command writes nothing and creates nothing.
- A developer with no prior context can read the output and know what runs.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green, with hermetic cases over a stubbed reader for: a repository with routines, one with none, and an unreachable API — asserting the third is distinguishable from the second.
- Run it against this repository and read the output as if new to the project.

**Gate**

- The unreachable case is distinguishable from the empty case, and a test pins it. That conflation is the exact defect `check-slack-channel.sh` was fixed for, and it would be worse here because the audience is someone who cannot tell it is wrong.

Decided: read-only ships first as its own ticket — it is safe under every answer the decision ticket might reach about the unattended boundary, and it is the whole of the mission's stated Experience (developer may override at /drive).

## Considerations

- `compare-routines.sh` surveys every repository that carries a workaholic routine, not just this checkout. Scoping the output to one repository is a presentation choice; keep the wider survey reachable, since one defect replicated seven times is still one defect.
