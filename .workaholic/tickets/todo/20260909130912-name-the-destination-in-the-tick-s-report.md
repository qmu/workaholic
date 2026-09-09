---
created_at: 2026-09-09T13:09:12+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-declared-slack-route-speak-be-seen-and-be-named
merge_policy:
verification_handoff: 
---

# Name the destination in the tick's report

## Overview

PROPOSED. `commands/infinite-development.md`'s report contract asks for *the declared binding this
tick resolved*. It does not say the destination must be named, and nothing checks that it was — so
a session satisfies the line with `ok:true / declared:true / conflicts:[]`, which reports that *a*
binding resolved rather than **which**, and the report reads as complete while carrying no
destination.

Measured on `osbrjp/coop-planner`, 2026-09-09: roughly fifty consecutive ticks called the reader as
`read-declared-binding.sh --root . | jq -c '{ok,declared,conflicts,reason}'`. That projection drops
`binding`, so the channel name never entered the session's context from the authoritative source.
Asked later where its reports were being delivered, the session answered with a channel name it had
never read — plausible, and wrong.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/commands/infinite-development.md` — the binding read near the top and the
  report contract line *the declared binding this tick resolved*.
- `plugins/workaholic/skills/transport/scripts/read-declared-binding.sh` — the one reader, whose
  `binding` object carries `workspace`, `channel` and `channel_id`.
- `plugins/workaholic/skills/notify/SKILL.md` — the post shapes and where a destination belongs in
  a reported effect.
- `plugins/workaholic/skills/work/SKILL.md` — the sibling report contract, so the two do not drift.
- `scripts/test-workflow-scripts.mjs` — where a byte-identical wording is pinned across ceilings.

## Implementation Steps

1. **Localize first.** Read the two report contracts and record exactly what each asks for today,
   so the change is an addition to a named gap rather than a restatement.
2. Make the obligation name the destination: the workspace and channel — and `channel_id` when the
   declaration carries one — taken from the reader's own `binding`, never from memory, a directory
   name or a repository name.
3. State the enforcement the way this repository states an act no script can see: a report that
   names no destination is **non-conformant on its face**. Nothing new is checked at run time.
4. Keep the degraded answers exactly as they are: `binding_contradictory`, `binding_incomplete`,
   `binding_unreadable:<source>` and an ordinary `declared: false` each stay their own reading, and
   an undeclared repository names the environment fallback it used instead.
5. Where the command shows the reader being called, show it in a form that keeps `binding` — a
   projection that drops it is the measured cause.
6. Carry the same wording into the sibling contract and pin the pair, so one surface cannot drift
   from the other.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- The tick report names the workspace and channel it resolved, from the reader's own output.
- A degraded or undeclared reading keeps its existing word and names what was used instead.
- The same wording appears in both report contracts and is pinned.
- No projection in the command's own text drops `binding`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the byte-identical wording row across the contracts.
- A tick report showing the named destination.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

## Considerations

- This is a reporting obligation, not a gate: it must not stop a tick whose binding is undeclared
  or degraded, which is an ordinary and supported state.
- Naming the destination is not proof of delivery. Keep it separate from `preferred_route_verified`
  and from the per-effect route reporting.
