---
created_at: 2026-09-08T12:41:52+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-slack-intake-incremental-across-messages-threads-and-mentions
merge_policy:
verification_handoff: 
claim: work-20260910-125058
---

# Resolve QFS Slack first and type every connector fallback

## Overview

Make a validated QFS Slack binding a startup invariant and allow connector fallback only after a typed QFS capability, authorization, reachability, or availability failure.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/work/` — startup validation before the first Slack effect.
- `plugins/workaholic/skills/transport/` — QFS preference, typed degradation, and fallback.
- `plugins/workaholic/skills/qfs-slack/` — live mount, channel, identity, and map probes.

## Implementation Steps

1. Reproduce the silent connector fallback against declared and undeclared QFS bindings.
2. Enumerate live connections, describe the selected mount and paths, and verify private-channel read/write/reply reachability.
3. Verify sender identity when scopes allow and preserve exact uncertainty when they do not.
4. Bind connector fallback to typed QFS failure while preserving channel and thread identity, then revalidate before effects after changes or failures.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Reachable declared QFS bindings carry all Slack reads and writes under the declared sender.
- Every connector fallback names its QFS failure and preserves the declared destination and thread.

**Verification method** — the commands/tests/probes that prove them:

- Test QFS success, channel membership failure, missing reply map, missing identity scope, QFS unavailable, and connector fallback.

**Gate** — what must pass before approval:

- A successful connector read cannot certify that the preferred QFS sender is configured.

## Considerations

Operator-facing profile names and QFS account labels are separate identifiers and must never be treated as aliases without evidence.
