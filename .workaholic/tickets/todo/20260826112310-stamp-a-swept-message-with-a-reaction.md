---
created_at: 2026-08-26T11:23:10+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: answer-what-is-waiting-and-stamp-what-was-accepted
merge_policy:
verification_handoff: 
---

# Stamp a swept message with a reaction

## Overview

PROPOSED. Since 2026-08-26 (PR #627) the inbound sweep replies a `📥 受理` receipt into
each captured message's own thread. That closed half the gap and left the other half
open: a reply lives inside a thread, so from a channel scroll a captured ask and an
ignored one still look identical — you have to open the thread to find out. The source
record asks for a **reaction stamp** on the message itself, which is what makes
acceptance legible where the message is.

Add the reaction beside the existing thread reply. It is a second, cheaper signal on the
same event, not a replacement: the reply carries the issue link, the reaction carries
"this was received" at a glance.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/SKILL.md` — *And every capture is acknowledged where
  it was written*: the section that owns the receipt. The reaction is added there, under
  the same never-load-bearing rule.
- `plugins/workaholic/skills/notify/reference/notifications.md` — `### /propose — the
  inbound sweep's receipt`: the catalog entry, which must name the reaction emoji so the
  routine template can be pinned byte-identical against it.
- `plugins/workaholic/skills/workaholify/routines/propose.md` — the routine prompt is the
  **ceiling** on what the routine may emit to Slack; a reaction it does not name cannot
  be added.
- `plugins/workaholic/skills/propose/scripts/file-inbound-ask.sh` — READ ONLY. It is the
  writer of the `slack-ref: <channel>:<ts>` marker, and that marker *is* the reaction's
  coordinate, so no lookup is needed and none may be added.
- `scripts/test-workflow-scripts.mjs` — the drift pin between the template's post
  vocabulary and the notify catalog.
- `CLAUDE.md` — the `/propose` row's receipt sentence.

## Implementation Steps

1. Read the `📥 受理` receipt section of `workaholic:propose` and the notify catalog entry
   it is pinned against, whole. The reaction must obey the same three rules the reply
   already does, and those rules are stated there, not here.
2. Choose one emoji and state it once, in the notify catalog, so template, skill and test
   read a single source. Prefer the one the receipt already speaks with (`inbox_tray`,
   the `📥` of the reply) — one event, one vocabulary.
3. Add the reaction to the sweep's per-message flow, **after** `file-inbound-ask.sh`
   returns `ok: true`, using the `slack-ref` it just wrote as `<channel>:<ts>`. No
   lookup, no search, no second query.
4. Hold it to the receipt's existing bounds: **only a message this run filed** (an
   already-swept one gets nothing — its receipt is on the issue that exists), and
   **never load-bearing** — the issue is open before the reaction is attempted, so a
   failure is reported per message and changes nothing about the filing, the dedup
   marker or what `/specificate` ingests.
5. Report it per message beside the reply's own outcome, so a landed reaction and a
   failed one are two facts. Reuse the `ack_failed: <reason>` shape rather than minting
   a parallel vocabulary.
6. Extend the routine template's named post vocabulary to include the reaction, and
   update the drift pin in `scripts/test-workflow-scripts.mjs` so template and catalog
   cannot diverge.
7. Update `SKILL.md`, the notify catalog and `CLAUDE.md` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A message the sweep files this run carries the reaction on the message itself.
- An already-swept message gets no reaction and no reply — one receipt, ever.
- A reaction that fails is reported by name and changes nothing about the issue, the
  `slack-ref` marker or the run's other work.
- The routine template names the reaction, and the template's vocabulary is byte-identical
  to the notify catalog's.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the template/catalog drift pin covers the
  reaction; a case asserts the dedup rule excludes an already-swept ref.
- `sh scripts/e2e/loop-drill.sh verify-propose` still passes with no network.

**Gate** — what must pass before approval:

- The full local verification block in `CLAUDE.md` passes.
- No new lookup, no second Slack query, and the two-query bound untouched.

## Considerations

- **The ask's premise is partly stale and the ticket says so rather than inheriting it.**
  It reads "leaves nothing in the thread of the comment it came from"; that was true when
  the message was written and was fixed hours later by PR #627. What survives, and what
  this ticket implements, is the reaction — the part that makes acceptance legible from
  the channel without opening anything.
- A reaction is invisible to anyone reading the issue rather than the channel, so it is a
  second signal for a second audience, never a substitute for the reply.
- Adding a reaction is a Slack **write**, and the routine's prompt is the ceiling on what
  it may emit. Extending the ceiling is part of the work, not a precondition to it.
