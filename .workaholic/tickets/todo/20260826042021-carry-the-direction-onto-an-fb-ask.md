---
created_at: 2026-08-26T04:20:21+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: attribute-an-inbound-ask-to-the-direction-it-answers
merge_policy:
verification_handoff: 
---

# Carry the direction onto an fb ask

## Overview

PROPOSED. `/fb`'s in-repo path opens an `[FB]` issue on this repository carrying the
`kind`/`source`/`subject` judgment so the receiving `/specificate` inherits it — and no
`feedback:` line. A human filing an ask about a live direction therefore produces work
that cites that direction at nothing, exactly as the swept ask does.

This ticket gives the in-repo path the same line, from the same writer, under the same
judge-then-report rule — and states explicitly that the **crossing does not get it**: a
`feedback:` line naming this project's records has no meaning on somebody else's tracker,
and composing in the target's vocabulary is that path's standing rule.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/fb/SKILL.md` and its `reference/crossing.md` — where the
  in-repo path's body composition and the crossing's gates are stated
- `plugins/workaholic/skills/feedback/scripts/open-issue.sh` — the one issue-opening seam;
  it composes nothing today and must keep composing nothing
- `plugins/workaholic/skills/feedback/scripts/ask-feedback-line.sh` — the single formatter
- `plugins/workaholic/commands/fb.md` — the one-line report
- `scripts/test-workflow-scripts.mjs`

## Implementation Steps

1. In `/fb`'s in-repo path, after the `kind`/`source`/`subject` line, emit the `feedback:`
   line through `ask-feedback-line.sh` when the ask answers a live direction.
   `open-issue.sh` is **not** taught to compose it — it has no destination opinion and no
   identity opinion, and a header opinion would make it a second router.
2. State the judgment once, by reference to the sweep's: an explicit slug → that strategy;
   otherwise judged against the `active` set; no live direction → no line.
3. **State the crossing's exemption in `reference/crossing.md`**: a cross-repository issue
   never carries a `feedback:` line, because it would name records the target cannot
   resolve and would compose in our vocabulary rather than theirs.
4. Add the decision to `/fb`'s one-line report: `direction:<slug>` or
   `direction:unattributed`, beside `assigned`.
5. Extend the hermetic fixtures for both halves — the in-repo body carries the line, the
   crossing body does not.
6. Update `CLAUDE.md`'s `/fb` row and rebuild `outputs/`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An in-repo `/fb` issue answering a live direction carries the `feedback:` line; one
  answering none carries no line and the report says `direction:unattributed`
- A cross-repository `/fb` issue never carries the line, and the reason is written down
- `open-issue.sh` still composes nothing

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A crossing-body fixture diff (must be byte-identical to today's)

**Gate** — what must pass before approval:

- The crossing's four gates — target vocabulary, masking, verbatim confirmation, outbound
  scan — are untouched
- `outputs/` regenerated

## Considerations

- **The exemption is the interesting half.** The ask names `open-issue.sh` as the place the
  line could be emitted; putting it there would give the one crossing seam an opinion about
  our own directions, which is precisely what its header refuses. The composer belongs to
  the caller that knows the destination.
- `/fb`'s fallback record path (`fb-fallback.sh`) is out of scope: it writes a record, not
  an issue, and a record's own `feedback:` relation is a different surface.
