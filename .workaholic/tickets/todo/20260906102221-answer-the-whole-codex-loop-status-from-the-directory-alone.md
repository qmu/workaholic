---
created_at: 2026-09-06T10:22:21+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: record-each-codex-worker-s-state-and-last-outcome-as-data
mission: finish-the-codex-external-process-and-make-its-state-inspectable
merge_policy:
verification_handoff: 
---

# Answer the whole Codex loop status from the directory alone

## Overview

The reading the ask actually wants: **one question, one answer, from the state directory**.
Today `--status` gives two half-answers from two sources — `show_status` reads `status.json`
and returns 0/4/5, then `show_workers` probes each role's lock live — so the coordinator's
state and the workers' states are neither composed nor readable by anything that is not this
script. A later tick, `/moderate`, or a person with a shell and no `codex` CLI cannot ask "is
the Codex loop turning, and what is it doing" and get one answer.

With the supervisor record (ticket 2) and the per-role records (ticket 3) in the directory,
this composes them into a single reading — supervisor, every worker, and the last tick — that
is derivable from files alone. **Composed, never re-derived**: this ticket adds no new state
and no second derivation of a reading either previous ticket owns.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — one reading, named where it is degraded

## Key Files

- `plugins/workaholic/skills/work/scripts/codex-loop.sh` — `show_status` (~line 98) and
  `show_workers` (~line 115), the two half-answers, and the `--status` branch (~line 140) that
  returns before the `codex` presence check.
- `scripts/codex-loop.sh` — the shim a person invokes.
- `plugins/workaholic/skills/work/reference/other-agents.md` — the documented `--status`
  surface and the command list, which this changes.
- `plugins/workaholic/commands/work.md` — names the read-only `--status` surface.

## Implementation Steps

1. Compose one reading over the supervisor record, the per-role records and `status.json`.
   Read each through whatever ticket 2 and ticket 3 established; derive nothing a second time.
2. Emit it in a form a machine can consume as well as a person — the existing human lines stay,
   with a JSON form beside them, so a later tick can read it without parsing prose.
3. Name every part that could not be read, by its own reason, in place. A missing supervisor
   record, an unreadable role record and a malformed `status.json` are three distinct
   readings, and none of them may render as healthy or be silently omitted.
4. Keep `--status` free of the `codex` CLI requirement and free of side effects: it starts
   nothing, writes nothing, and takes no lock.
5. Update `other-agents.md` and `commands/work.md` to state the composed surface and what each
   degraded reading means.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- One invocation answers supervisor state, every worker's state and last outcome, and the last
  tick, from the directory alone.
- Each unreadable part is named by its reason; none renders as healthy and none is omitted.
- `--status` requires no `codex` CLI, starts nothing, writes nothing and takes no lock.
- The reading is consumable by a machine without parsing the human lines.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/codex-loop.sh --status` against: a never-started directory, a running supervisor,
  a stopped one, and one with a failed worker — output recorded for each.
- The same with the `codex` CLI removed from PATH.
- Hermetic cases in `scripts/test-workflow-scripts.mjs` covering the degraded readings.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes.
- The four readings above are recorded in the branch story as evidence, which is the ask's own
  standard of proof: observable state rather than a live chat.

## Considerations

- The JSON form is a surface other things will read; it is worth naming its shape in
  `other-agents.md` at the same time rather than leaving it to be inferred.
- This ticket completes the mission's acceptance but does not itself prove the loop turns —
  what it proves is that the question is answerable from the directory.
