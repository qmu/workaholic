---
created_at: 2026-08-01T18:55:01+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission: make-scheduled-routines-a-configurable-inspectable-part-of-a-repository
merge_policy: auto
---

# Decide where routine configuration lives and what an agent may apply

## Overview

The mission's substance is two decisions, and both must land before any command is
written, because each one changes what the command can be.

**Where routine configuration lives.** `.workaholic/` is a closed layout: a new top-level
artifact directory is a registered amendment in both sources of truth, in the same commit
as the first write, or the guard hard-blocks it. But there is a real question before that
one — the existing `workaholify` design says the plugin holds **one set of templates**
applied to whichever repository the command runs in, deliberately so that *no
per-repository routine file exists and `.workaholic/` gains nothing*. This mission asks to
record per-repository configuration, which is in tension with that. Resolve the tension
explicitly rather than adding a directory beside a design that says not to.

**What an agent may apply unattended.** Both loop runbooks say "do not install the crontab
from an agent session" — the very capability the issue asks for. And routines are Claude
Code Web routines reached through `RemoteTrigger`, not cron, where `workaholify` already
confirms each create or refresh **verbatim, one at a time**, because a routine is a
standing outward-facing process. Decide whether `/setup-routines` inherits that bar, and
say why.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — a new artifact area is a deliberate amendment, registered in the same change.
- `workaholic:operation` / `policies/deployment-pipeline.md` — a routine is a standing outward-facing process; what may change it unattended is an operational boundary.
- `workaholic:safety` — an agent that can create scheduled outward-facing processes without confirmation is a different risk surface from one that cannot.

## Key Files

- `plugins/workaholic/skills/workaholify/SKILL.md` - the existing routine model, including the one-template-set rule this mission is in tension with
- `plugins/workaholic/skills/workaholify/routines/` - the templates
- `plugins/workaholic/skills/workaholify/scripts/compare-routines.sh` - matches a live routine to a repo by source URL, never by name
- `plugins/workaholic/hooks/workaholic-layout-allowlist.txt` and `plugins/workaholic/rules/workaholic.md` - the two lockstep sources of truth
- `docs/drive-loop-runbook.md`, `docs/proposal-loop-runbook.md` - both carry the do-not-install-from-an-agent rule

## Implementation Steps

1. Read `workaholify/SKILL.md`'s routine section first and state the tension in writing:
   it argues that no per-repository routine file should exist. Either this mission
   overrides that with a reason, or configuration lives somewhere that is not
   `.workaholic/` — the plugin, or the account, with the repository merely inspecting it.
2. Decide, and name the rejected alternatives.
3. Decide the unattended boundary separately: list what `/setup-routines` may do without
   confirmation (almost certainly: read and report) and what it may not (almost certainly:
   create, delete, or re-point a standing routine).
4. Record both decisions in the feedback stream and in `workaholify/SKILL.md`.
5. If the answer introduces a `.workaholic/` directory, register it in both sources of
   truth in the same commit as the first write.

## Quality Gate

**Acceptance criteria**

- Where routine configuration lives is decided and written down, with the rejected alternatives named — and the tension with `workaholify`'s one-template-set rule is addressed explicitly rather than ignored.
- What an agent may apply unattended is decided and written down, reconciled with the runbooks' existing prohibition and with `workaholify`'s verbatim-confirmation bar.
- If a new `.workaholic/` area is introduced, both lockstep sources of truth carry it in the same commit as the first write, and `layout-doctor.sh .` reports conforming.
- No command implementation in this ticket.

**Verification method**

- Read-through against `workaholify/SKILL.md` and both runbooks, confirming no document is left contradicting the decision.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` if the layout changed.

**Gate**

- The `workaholify` tension is resolved in writing. Adding a per-repository routine file next to a design that explicitly rejects one is the drift the closed-layout policy exists to catch.

Decided: both decisions live in one ticket because they constrain each other — where the configuration lives determines what applying it unattended even means (developer may override at /drive).

## Considerations

- `compare-routines.sh` already surveys live routines **across every repository** that carries one, matching by source URL rather than name. Whatever is decided, it is the existing reader and should not be duplicated.
