---
created_at: 2026-08-29T04:21:45+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-tick-s-own-findings-become-the-loop-s-work
merge_policy:
verification_handoff: 
---

# Dedup the filing structurally on the step id

## Overview

PROPOSED. One finding must be filed **once**, however many ticks run. The dedup is
**structural** and keyed on the same step id the already-asked gate uses
(`lib/question-id.sh`), so the filing and the asking cannot disagree about what
"the same finding" means — and so a merged repair removes its own candidate rather
than needing a cursor to forget it.

The marker rides the issue itself, in the shape the inbound sweep's `slack-ref` already
uses: a **visible** line the reader in ticket 4 matches on. No new store, no cursor, no
field on any artifact, and no reliance on the tick log surviving a container — the
`<step>-filed` line is at most an optimisation, never the memory (the rule
`filed-records.sh` records: a filed line that the tree does not confirm is **not** a filing).

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/runtime-behavior.md` — derived state over stored state

## Key Files

- `plugins/workaholic/skills/moderate/scripts/lib/question-id.sh` — the one derivation of
  a question id from a key; the dedup key is derived here and nowhere else.
- `plugins/workaholic/skills/propose/scripts/file-inbound-ask.sh` — the one filer and the
  one writer of the `slack-ref:` marker; the finding marker is written the same way.
- `plugins/workaholic/skills/propose/scripts/list-swept-slack-refs.sh` — the reader that
  reads a marker back out of the issues; the pattern to follow.
- `plugins/workaholic/skills/moderate/scripts/filed-records.sh` — the rule that a `-filed`
  log line is not itself proof.
- `plugins/workaholic/skills/moderate/scripts/step-file-findings.sh` — the consumer.

## Implementation Steps

1. Read `lib/question-id.sh` and use it — the id carries a digest of the whole key
   because the 32-character slug it replaced was not injective, and re-deriving the id
   a second way would reintroduce exactly that.
2. Define the marker line the filing writes onto the issue (visible text, one line,
   naming the step id and the finding's id). Write it through `file-inbound-ask.sh`,
   which is already the marker's one writer — extend it as a caller legitimately would,
   never by a second writer.
3. Read the marker back over **open and recently closed** finding issues, so a finding
   whose repair merged an hour ago is not re-filed the same day. State the bound and
   report when the page bound rather than the repository ended the read.
4. Wire it into `step-file-findings.sh`: a candidate whose id is already on an issue is
   dropped and **counted**, never silently.
5. Do not add a store. If the dedup appears to need one, that is the signal the key is
   wrong — say so rather than adding it.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- One finding produces one issue across repeated ticks, with no cursor anywhere.
- The dedup key comes from `lib/question-id.sh`, with no second derivation.
- A `<step>-filed` log line is never the sole evidence of a filing.

**Verification method** — the commands/tests/probes that prove them:

- Ticket 8's drill: two ticks over the same fixture file one issue.
- `node scripts/test-workflow-scripts.mjs` — a pin that the id derivation has one home.

**Gate** — what must pass before approval:

- The suite is green and the two-tick drill files exactly one issue.

## Considerations

- The recently-closed window is the one judgement call here: too short and a merged
  repair is re-filed, too long and a genuinely recurring finding is suppressed. Pick a
  bound, state it, make it configurable, and report when it truncated.
- The marker must survive a person editing the issue title. Key it in the **body**, as
  `slack-ref` already is.

## Final Report

Development completed as planned. The dedup key is `question_slug("finding:<step id>")` from
`lib/question-id.sh` — the one derivation, so the filing and the asking cannot disagree about
what "the same finding" is. It is keyed on the **step id** and nothing else: a summary moves as
the world moves, and keying on it would re-file the same finding whenever its wording changed.

The marker is written by `file-inbound-ask.sh`, already the one writer of a marker, extended as
a caller legitimately would: `--finding <step>:<id>` beside `--slack-ref`, writing one visible
`finding: <step id> / id: <finding id>` line with `source: moderate`. **Exactly one marker per
issue** — `two_markers` refuses an issue claiming to be both a channel message and a tick
finding, which two dedups would otherwise both match. It rides the body, so it survives a person
retitling the issue.

`list-finding-issues.sh` reads it back over **open and closed** finding issues, so a finding
whose repair merged (auto-closing its issue) is not re-filed. **The bound is the listing, not a
date** — the most recent `WORKAHOLIC_FINDING_ISSUE_LIMIT` issues (default 100, newest first),
which is `list-swept-slack-refs.sh`'s own bound and its own reason: `date -d` is GNU-only and
`date -v` BSD-only, and a reader that answers differently on a laptop and in a container is
worse than one bounded by a number both can read. `list_capped` reports when the page bound
rather than the repository ended the read. A candidate already filed is dropped and **counted**.

No store was added. The issues are the memory, so `filed-records.sh`'s rule — that a
`<step>-filed` line is never itself the proof — holds here by construction, because nothing
reads such a line.

Verified: `node scripts/test-workflow-scripts.mjs` — the id is checked against the library's own
derivation rather than a hard-coded digest, a closed issue still dedups while every other
finding is still offered, and a pin asserts no other moderate script writes the marker.

### Discovered Insights

- **Insight**: keying the dedup on the step id makes the brake and the dedup complementary
  rather than redundant.
  **Context**: one issue per step id can exist at a time, and the brake caps the total at one in
  flight. Without the id the brake alone would still bound volume, but a finding whose issue had
  merged an hour ago would come straight back.
- **Insight**: the marker had to be mutually exclusive with `slack-ref`, not merely additional.
  **Context**: `list-swept-slack-refs.sh` and `list-finding-issues.sh` are two dedups reading
  two markers out of one issue store. An issue carrying both would be claimed by both, and the
  sweep would treat a tick finding as an already-captured channel message.
