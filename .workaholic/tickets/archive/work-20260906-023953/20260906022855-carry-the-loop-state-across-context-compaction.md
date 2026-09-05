---
created_at: 2026-09-06T02:28:55+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: report-each-tick-in-the-originating-codex-chat
merge_policy:
verification_handoff: 
---

# Carry the loop state across context compaction

## Overview

The native-parent branch holds its state in the parent's own turn: the startup anchor, the
role-to-child map, and which outcomes have already been reported. A long-running conversation
is compacted, and a coordinator that lost those three would re-derive a fresh anchor (moving
the phase), re-dispatch roles that are still running (duplicating work the claim protocol would
then have to refuse), and re-report outcomes the operator has already read.

Compaction stops nothing: a running child keeps running. Inferring otherwise is the error this
ticket forbids by name.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the running loop's own reporting and recovery

## Key Files

- `plugins/workaholic/skills/work/SKILL.md` — the native-parent branch, where the surviving
  state and the rediscovery step belong.
- `plugins/workaholic/commands/infinite-development.md` — the tick body, whose per-tick
  decisions read that state.

## Implementation Steps

1. Name the three things that must survive compaction: the **startup anchor**, the **running
   child identifiers** with their roles, and the **outcomes already reported**. Nothing else is
   carried — this is not a new store for the loop's whole state.
2. On resuming after compaction, **rediscover the actually running work** through the harness's
   own listing before dispatching anything, and reconcile it with the carried map.
3. **Never infer that compaction stopped a child.** A child not found by the rediscovery is
   reported as unresolved and asked about; it is not assumed finished and its role is not
   re-dispatched on that assumption alone.
4. Keep the anchor across compaction so the phase does not move; a rediscovered anchor is the
   original one, never a fresh derivation from the resume time.
5. Do not re-report an outcome already reported; the carried set is what makes *report each
   completion once* hold across a compaction.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The three carried items are named, and nothing else is carried.
- Rediscovery runs before any dispatch after a resume.
- A child that rediscovery cannot find is reported unresolved, never assumed finished.
- The anchor after a resume equals the anchor before it.
- No outcome is reported twice across a compaction.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- No new file, field or store is introduced to hold the carried state.

## Considerations

- A duplicate dispatch is bounded by the claim protocol, which refuses a taken unit — but the
  wasted run and the duplicated report are real costs, which is why rediscovery precedes
  dispatch rather than relying on that refusal.

## Final Report

Development completed as planned.

`work/SKILL.md` gains *What survives a compaction, and what is rediscovered*, placed inside the
native-parent branch: the three carried items and nothing else, rediscovery before any dispatch,
the refusal to infer that compaction stopped a child, the anchor preserved, and the once-only
reporting that the carried outcome set is what makes hold across a resume.
`commands/infinite-development.md` §2 says the same where the per-tick dispatch decision is made.

**The gate held**: no new file, field or store was introduced. All three items live in the
coordinator's own turn, and the only reader consulted on a resume is the harness's own listing —
which already exists and is the same one the concurrency rule reads.

### Discovered Insights

- **Insight**: the three carried items fail in three different ways, which is why the list is
  closed rather than "whatever the loop knows".
  **Context**: a re-derived anchor moves the phase silently; a lost role map duplicates work the
  claim protocol then refuses noisily; a lost outcome set duplicates a report to a person. Only
  the middle one has a safety net, and it is the one whose loss is cheapest — so the two without
  a net are the reason the rule exists.
- **Insight**: *rediscovery precedes dispatch* is a deliberate refusal to lean on the claim
  arbiter.
  **Context**: the arbiter would in fact catch a duplicate dispatch, and reaching for it would
  make the coordinator's own bookkeeping optional — which is how a bound stops being maintained
  and then stops holding when the thing behind it changes.
