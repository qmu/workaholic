---
created_at: 2026-08-26T04:20:21+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: attribute-an-inbound-ask-to-the-direction-it-answers
merge_policy:
verification_handoff: 
---

# Carry the direction onto a swept ask

## Overview

PROPOSED. The inbound Slack sweep (`/propose`, since 2026-08-23) is the loop's own writer
and the majority inbound path — it exists so an ask arrives without anybody tagging a bot
— yet the issue it files carries `kind`/`source`/`subject`, `slack-ref:` and `slack-link:`
and **no `feedback:` line**. Work born on the channel therefore intersects every strategy's
`feedback[]` at nothing.

Measured 2026-08-26 on this repository, and re-confirmed by this proposing run: the
developer's 11:08 JST message became issue #604, `/specificate` emitted
`turn-the-loop-at-mission-granularity` with five tickets, and `attributed-work.sh` reports
that strategy's `waiting_count: 0`. Because `work_waiting` reads that count, the in-flight
brake stood open over a whole queued mission.

This ticket gives `file-inbound-ask.sh` the refs and makes the sweep step decide which
direction each message answers, reporting the decision — `unattributed` included.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/scripts/file-inbound-ask.sh` — the one writer of the
  swept ask's header block; the `feedback:` line joins it there
- `plugins/workaholic/skills/feedback/scripts/ask-feedback-line.sh` — the single formatter
  from the previous ticket
- `plugins/workaholic/skills/propose/SKILL.md` — the sweep's contract and its named
  degradations; the attribution decision and its report line are stated here
- `plugins/workaholic/skills/strategy/scripts/list.sh` — the `active` strategy set the
  judgment reads
- `plugins/workaholic/commands/propose.md` — the run report's shape
- `scripts/test-workflow-scripts.mjs` — the sweep writer's fixtures

## Implementation Steps

1. Add `--feedback <ref> [<ref>…]` to `file-inbound-ask.sh`; it emits the `feedback:` line
   through `ask-feedback-line.sh` inside the same composed block, after `slack-link:`.
   Absent flag → no line at all, byte-identical to today's body.
2. State the judgment in `propose/SKILL.md`'s sweep section: a message naming an explicit
   strategy **slug** is attributed to it — explicit slug only, the rule the lifecycle
   recognition already holds, never a title and never a paraphrase; a message naming none
   is judged against the `active` set read through `strategy/scripts/list.sh`; a message
   that answers no live direction is `unattributed`, an ordinary answer that is never
   forced.
3. The sweep step passes that strategy's own `feedback:` refs — the same refs
   `open-proposal.sh` carries — never a strategy slug and never a new field.
4. Report it per filed issue in `/propose`'s run report: `direction:<slug>` or
   `direction:unattributed`, beside the existing per-message outcome.
5. Extend the sweep's hermetic fixtures: with refs the line is present and recovered by
   `read-ask-feedback-refs.sh`; without refs the composed body is unchanged; the
   `slack-ref:` marker and `list-swept-slack-refs.sh`'s dedup still match either way.
6. Update `CLAUDE.md`'s `/propose` row and rebuild `outputs/`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A swept issue filed for an attributed message carries a `feedback:` line naming that
  strategy's refs, in the shape `read-ask-feedback-refs.sh` reads
- A swept issue for an unattributed message carries no such line, and the run report says
  `direction:unattributed` rather than staying silent
- `slack-ref:` dedup is unaffected: `list-swept-slack-refs.sh` matches both shapes

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A composed-body fixture diff for the no-refs case (must be byte-identical)
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- No artifact gains a field and the retired `strategy:` relation does not return
- The sweep's existing named degradations (`no_slack_transport`, `channel_unreadable`,
  `sweep_dedup_unreadable`) are untouched, and an unreadable strategy set is named too
  rather than read as "no direction"

## Considerations

- **The judgment can be wrong, and that is why it is reported rather than enforced.**
  Nothing is refused for naming no direction; the only new obligation is that the loop say
  which direction it decided, or that it decided none.
- An unreadable `strategy/scripts/list.sh` must not silently become `unattributed` — that
  is the same invisible-loss shape this mission exists to remove. Name it.
- The line carries the strategy's **refs**, not its slug, because `attributed-work.sh`
  intersects `feedback[]` sets and a slug would be the retired relation under a new name.
