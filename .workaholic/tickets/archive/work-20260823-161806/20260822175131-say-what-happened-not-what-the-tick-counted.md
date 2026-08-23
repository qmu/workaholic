---
created_at: 2026-08-22T17:51:31+09:00
status: done
author: a@qmu.jp
assignees: 
depends_on:
mission: make-the-tick-s-root-earn-its-hour
merge_policy:
verification_handoff: 
---

# Say what happened, not what the tick counted

## Overview

Each root line is a step's own log summary, rendered verbatim. Those summaries were written for
the tick log — an audit trail a maintainer reads when diagnosing the tick — and they read like
one:

```
inbound-sweep: GitHub read since <ts>: 1 updated, 0 already captured, 1 to judge; slack/gmail/drive left for the agent to probe
doc-drift: no new documentation drift since <sha> (0 finding(s) already filed by an earlier tick)
```

`1 to judge`, `0 already captured`, `0 finding(s) already filed by an earlier tick` are the
tick's internal counters. And `no new documentation drift` reports that **nothing happened** —
rendered, by the change diff, as a change.

The audit trail is not the wrong artifact; it is the wrong audience. A person scanning the
channel needs the repository's events. The log keeps everything else, and keeps it already.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — renders one line per
  changed step from the log summary; the split between log text and post text lands here.
- `plugins/workaholic/skills/moderate/scripts/step-*.sh` — every step's `summary` field; if a
  post-facing phrase is added it is added here, beside the log-facing one.
- `plugins/workaholic/skills/moderate/scripts/log-append.sh` — the log's only writer; its
  append-only contract must survive whatever is added.
- `plugins/workaholic/skills/moderate/SKILL.md` — states what a root line carries.

## Implementation Steps

1. **Reproduce.** Take the rendered root from a real tick and mark, line by line, which clauses
   name a repository event and which name the tick's own bookkeeping. Do this from the shipped
   output, not from the step headers.
2. **Localize.** Decide where the post-facing phrase comes from: a second field on each step's
   JSON beside `summary`, or a projection in `render-tick-post.sh`. Prefer the second field —
   the step knows what its finding means and the renderer does not — and record the reason.
3. Give each step a post-facing line that names what happened to the repository, with no
   counter that exists only inside the tick.
4. A step whose finding is "nothing happened" must produce **no line at all** — it is not a
   change, and after the sibling ticket lands it will not be reported as one either. Guard this
   independently, so a regression in the diff cannot resurrect it here.
5. Keep the log's own summaries exactly as they are: the audit trail loses nothing.
6. State the two-audience split in `SKILL.md`, mirror any root-shape wording into
   `notify/reference/notifications.md` and `workaholify/routines/moderate.md` in the same
   commit, and update `CLAUDE.md`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No rendered line contains a counter that exists only inside the tick.
- A step reporting that nothing happened renders no line, independently of the change diff.
- The tick log's summaries are unchanged and still append-only.
- The root's shape matches `notify/reference/notifications.md` and the routine template
  byte-for-byte.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-moderate`
- A hermetic tick with one real finding and one nothing-happened step, asserting exactly one
  rendered line and the log carrying both.

**Gate** — what must pass before approval:

- All four criteria hold and the suite plus the moderate drill are clean.

## Considerations

- Do not solve this by shortening the log summaries. They are the audit trail an operator reads
  when the tick misbehaves, and this mission exists because that trail was the only place the
  truth was.
- Drive this last in the mission: with changes rare and the gate ruled, what remains is the
  wording, and it is easiest to judge against a root that now posts rarely.

## Final Report

### The reproduction, from the shipped output (step 1)

A real tick rendered, line by line, marked for what each clause names:

```
inbound-sweep: GitHub read since <ts>: 1 updated, 0 already captured, 1 to judge; slack/gmail/drive left for the agent to probe
doc-drift: no new documentation drift since <sha> (0 finding(s) already filed by an earlier tick)
```

Of those two lines, the repository events are "1 new ask arrived" and **nothing**. Everything else
— `1 updated`, `0 already captured`, `1 to judge`, `0 finding(s) already filed by an earlier tick`,
the surfaces left to probe — is the tick's own bookkeeping, and the second line reports that
**nothing happened** while the change diff renders it as a change.

### Where the post-facing phrase comes from (step 2), and why

**A second field on each step's JSON, `event`, beside `summary`** — the preference the ticket
states, taken for its stated reason: **the step knows what its finding means and the renderer does
not**. A projection in `render-tick-post.sh` would have to re-derive each step's meaning from its
prose, which is the free-text dependency this skill has already been bitten by twice.

`run.sh` carries it through into the rows; `render-tick-post.sh` renders it. **The diff still reads
`summary`** — that is what tells this hour from the last one, and it is the richer signal; diffing
the event instead would hide a real change behind a phrase that happens to be worded the same.

**A step with no event renders no line, and is not counted.** That is the independent guard step 4
asks for: a "nothing happened" step cannot reach the root even if the diff calls it changed. Both
halves matter — counting it while rendering nothing would make the header say `2 change(s)` above
one line. A step that has not been given an event yet is silent too, deliberately: silence is the
safe failure, and the log keeps its line regardless.

### Measured after the change, on this repository's own tick

```
inbound-sweep      1 new inbound ask(s) arrived on GitHub
strategy-pace      1 direction(s) will not arrive by their date at this pace
stalled-units      5 claimed unit(s) have not moved for a day or more
closable-missions  2 mission(s) are finished and still open
```

and `doc-drift`, `issue-triage`, `merge-conflicts`, `stuck-prs`, `release-status`, `note-cadence`
render nothing, because nothing happened in them.

**The tick log is untouched.** Every summary is exactly as it was, still append-only — the audit
trail loses nothing, which the Considerations required. The root's shape moved by one line
(`<step>: <summary>` → the event), mirrored byte-for-byte into
`notify/reference/notifications.md` and `workaholify/routines/moderate.md`.

**Verification**: `node scripts/test-workflow-scripts.mjs` — 3418 passed, 0 failed, including a new
case that a changed step with an empty event is neither counted nor rendered, and a pin that no
line carries a `<step>: ` prefix. `build.mjs` + `verify.mjs` clean.
