---
created_at: 2026-08-26T04:20:21+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: attribute-an-inbound-ask-to-the-direction-it-answers
merge_policy:
verification_handoff: 
---

# Write the ask's feedback line in one place

## Overview

PROPOSED. The `feedback:` header line on an inbound ask has exactly one reader —
`read-ask-feedback-refs.sh` — and, today, exactly one writer, inlined in
`propose/scripts/open-proposal.sh` beside the `strategy:`/`move:` marker. Two more writers
are about to want it (the Slack sweep and `/fb`), and that reader's own header states the
rule this repository has already paid for twice: two parsers of one field eventually
disagree. The writing side deserves the same single-writer treatment *before* it is
multiplied, exactly as `file-inbound-ask.sh` is the one writer of the `slack-ref:` marker.

This ticket extracts the line's emission into one script and rewires `open-proposal.sh` to
it, changing nothing a reader can observe: the issue body `/propose` opens must stay
byte-identical.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/feedback/scripts/` — where the new writer belongs: the
  `feedback:` relation is the feedback skill's, and both future callers already reach
  across into it
- `plugins/workaholic/skills/propose/scripts/open-proposal.sh` — today's inline emitter;
  its three-header block and the reasoning behind each line live in its own header
- `plugins/workaholic/skills/specificate/scripts/read-ask-feedback-refs.sh` — the reader
  whose normalisation (inline-list and bare-scalar forms, first line-initial match only)
  the writer's format must satisfy
- `scripts/test-workflow-scripts.mjs` — where the writer → reader round trip is pinned

## Implementation Steps

1. Add `feedback/scripts/ask-feedback-line.sh` — takes the refs (variadic or
   comma-separated), emits the single `feedback: <ref>, <ref>` line, and emits **nothing**
   for an empty ref set (a caller with no direction must produce no line, not an empty
   one). Its header states that it is the one writer of the line
   `read-ask-feedback-refs.sh` reads, and names that reader.
2. Rewire `open-proposal.sh` to call it for line 3, leaving lines 1 and 2 where they are.
3. Prove the body is unchanged: render an issue body before and after with the same refs
   and diff them.
4. Extend the hermetic suite with a writer → reader round trip — refs in, line out, reader
   recovers exactly those refs; the empty case emits no line and reads back
   `line_found: false`.
5. Rebuild `outputs/` (`node scripts/build-plugins/build.mjs`) — the script closure moved.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `ask-feedback-line.sh` exists, is the only place the `feedback:` line is formatted, and
  emits nothing for an empty ref set
- `open-proposal.sh`'s rendered issue body is byte-identical to before the change for the
  same inputs
- The round trip writer → `read-ask-feedback-refs.sh` is pinned in the hermetic suite

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- A diff of `open-proposal.sh`'s composed body before and after, on the same refs

**Gate** — what must pass before approval:

- No second formatter of the `feedback:` line survives anywhere under `skills/`
- `outputs/` is regenerated and the `Outputs Freshness` CI diff is empty

## Considerations

- The line belongs to the **feedback** skill rather than `propose/`, because two of its
  three eventual callers sit outside `propose/`; `file-inbound-ask.sh` already reaches into
  `feedback/scripts/open-issue.sh`, so the direction is established.
- Byte-identity is the whole gate here. This ticket is deliberately a no-op for every
  observable surface — what it delivers is that the next two tickets add a *caller* rather
  than a parser.
