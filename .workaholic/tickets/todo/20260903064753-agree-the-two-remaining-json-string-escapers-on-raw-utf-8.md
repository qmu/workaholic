---
created_at: 2026-09-03T06:47:53+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260903053327-draft-deploy-plan-sh-renders-non-ascii-target-titles-as-escape-sequences.md]
merge_policy:
verification_handoff: 
---

# Agree the two remaining JSON-string escapers on raw UTF-8

## Overview

Ticket `20260903053345` repaired `escape_json` in the three `ship/` scripts so a non-ASCII
deployment title reaches Markdown as text. Two other scripts carry the same escape with the same
defect and were left alone because they are outside that ticket's stated sweep — it named
deployment record fields and the release-note render, and these carry neither.

Both escape a string into a JSON value through `python3 -c '... json.dumps(...)[1:-1]'`, which
ASCII-escapes, with a `sed` fallback that does not escape non-ASCII at all. So the two paths of
one function disagree about the same input, and which answer a caller gets depends on whether
`python3` is installed:

- `gather/scripts/merge-commit-body.sh` — composes the **squash merge title and body** every
  `/implement` merge passes to `-f commit_title=` / `-f commit_message=`. A Japanese story title
  therefore lands on the trunk's permanent record as `リポ...`, which is exactly the
  hand-decoding the originating report objected to, one artifact over.
- `drive/scripts/run-verification-probe.sh` — carries a probe's **captured output** into the
  `## Handoff` section and the `🟡 Handoff` Slack post, both read by a person.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout

## Key Files

- `plugins/workaholic/skills/gather/scripts/merge-commit-body.sh` — `json_escape()`
- `plugins/workaholic/skills/drive/scripts/run-verification-probe.sh` — its own copy of the same
- `plugins/workaholic/skills/ship/scripts/read-deployments.sh` — the repaired `escape_json()`,
  which is the shape to match

## Implementation Steps

1. Reproduce: feed a non-ASCII string through each `json_escape()` on a machine with `python3`
   and again with it forced to fail, and record that the two answers differ.
2. Apply the repaired shape — `ensure_ascii=False` with binary I/O — and make the `sed` fallback
   agree with it rather than leaving the two paths to disagree.
3. Confirm the emitted JSON still parses, since both scripts splice the escaped value into a
   `printf`-built object.
4. Pin a hermetic case per script asserting a non-ASCII value survives as characters.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A non-ASCII value passed through either `json_escape()` comes back as characters, not `\uXXXX`.
- The python3 path and the `sed` fallback return the same bytes for the same input.
- Each script's stdout is still parseable JSON.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` with the new hermetic cases.

**Gate** — what must pass before approval:

- Both escapers are covered; repairing one and reporting the other is the state this ticket exists
  to end.

## Considerations

- These were deliberately left out of `20260903053345` rather than overlooked: its sweep was
  scoped to the deployment record's own fields, and widening a ticket mid-drive is how a unit stops
  reconciling to its queue.
- `report-deploy-status.sh` and `read-deploy-state.sh` were checked in that run and need nothing —
  their `sed`-based escapers already pass non-ASCII through raw.
