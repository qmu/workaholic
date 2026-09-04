---
created_at: 2026-09-04T14:31:52+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: [20260904143152-return-slack-intents-from-codex-worker-ticks.md, 20260904143152-execute-relayed-slack-operations-in-the-owning-chat.md, 20260904142405-record-each-codex-tick-outcome-and-next-due-time.md]
mission: prove-codex-loop-progress
merge_policy:
verification_handoff:
---

# Report an unavailable Codex relay without pretending delivery

## Overview

Integrate relay availability and acknowledgements into the Codex loop readiness and durable status
from issue #974. When a scheduled worker has Slack intents but no connector-owning parent is
present, startup or the completed tick must say so visibly and must never describe those intents
as delivered while the supervisor continues silently.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — unavailable and stale relay states are visible
- `workaholic:leading-availability` — scheduled execution degrades without false health

## Key Files

- `scripts/codex-loop.sh` — startup verdict and per-tick relay failure handling.
- `plugins/workaholic/skills/work/SKILL.md` — visible report and parent-presence contract.
- `plugins/workaholic/skills/notify/SKILL.md` — outcome vocabulary that must remain distinct.
- `scripts/test-workflow-scripts.mjs` — readiness and stale-acknowledgement matrix.

## Implementation Steps

1. Add parent-present, parent-absent, acknowledgement-pending, partially-delivered, and completed
   relay states to the readiness vocabulary established for issue #974.
2. Gate a parent-relayed start on proof that the invoking conversation can consume the first
   envelope; report a clear unavailable-relay failure when it cannot.
3. Persist each operation's acknowledgement, the aggregate tick outcome, blocked reason, and next
   due time so a later status query does not depend on terminal scrollback.
4. Keep `no_slack_transport`, `post_refused`, and `thread_unresolved` distinct and never turn an
   unacknowledged intent into `notified: true`.
5. Test parent disappearance before a tick, between operations, and after work lands but before its
   finish line is delivered.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A missing parent is a visible readiness or tick failure with all undelivered intents named.
- Work completion remains truthful even when its non-load-bearing notification is pending or failed.

**Verification method** — the commands/tests/probes that prove them:

- Run the supervisor/relay state matrix and `node scripts/test-workflow-scripts.mjs`.

**Gate** — what must pass before approval:

- No tested path equates supervisor liveness or emitted intent with successful Slack delivery.

## Considerations

A continuously scheduled CLI process cannot manufacture a chat-bound connector. If no parent can
be kept present by the product, the supported result is an explicit unavailable relay, not hidden
credential duplication or a claim that the same delivery guarantees exist.
