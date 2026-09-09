---
created_at: 2026-09-09T13:09:12+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-declared-slack-route-speak-be-seen-and-be-named
merge_policy:
verification_handoff: 
---

# Refuse a post that cannot speak as the sender

## Overview

PROPOSED. The skill prefers the declared QFS route and treats the Slack connector as a later
resort. The preference is stated and not enforced, so on a measured repository the later resort
became the only path — and it speaks as the human operator. Counted in one channel: 94 messages
from the operator's own account, 3 from a bot, and **0** from the declared sender, which has only
ever joined. Most of the 94 are the loop's own shapes (`📝 FB`, `🔴 Blocked`, `⚪ Paused`) carrying
a *Sent using* marker.

The seams exist and are not reached: `resolve-target.sh` refuses `sender_unverified` only when a
caller passes `target.require_verified_sender == true`, and `perform.sh` compares
`expected_sender_id` only when the binding carries one — while `describe-native-qfs.sh` returns
`sender_id: null, sender_verified: false`, so nothing is compared and the fallback posts freely.
Success through a different identity does not satisfy a request that named one.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/transport/scripts/resolve-target.sh` — the
  `require_verified_sender` / `sender_unverified` refusal (line 67).
- `plugins/workaholic/skills/transport/scripts/perform.sh` — the `expected_sender_id` comparison
  and the typed fallback classes.
- `plugins/workaholic/skills/transport/scripts/describe-native-qfs.sh` — `sender_id: null`,
  `sender_verified: false`, and why an account label is never a sender.
- `plugins/workaholic/skills/transport/scripts/adapters/slack-token.sh` — the token route's own
  expected-sender read.
- `plugins/workaholic/skills/transport/scripts/schemas/binding.schema.json` — the declared
  `sender_id`.
- `plugins/workaholic/skills/workaholify/scripts/check-slack-binding.sh` — the advisory
  `unverifiable_sender` finding.

## Implementation Steps

1. **Reproduce and localize.** Take one loop post through `resolve-target.sh` → `perform.sh` on
   this repository and record which identity actually posts and which of the two sender checks
   was reached. Establish, rather than assume, that neither fired.
2. Decide and state the rule in one place: when the binding declares a `sender_id`, a **write**
   that cannot be proved to speak as that sender is refused, and the refusal is a delivery status
   the operator can see — not a silent substitution.
3. Make the loop's own write path carry that requirement, so the refusal is reached without every
   caller opting in. A binding that declares **no** `sender_id` is unchanged: the advisory
   `unverifiable_sender` already names that repository, and this must not turn an undeclared
   sender into a stopped loop.
4. Apply it to the fallback specifically: a connector or token route that would post as a
   different identity refuses and records the pending effect, rather than delivering under a
   person's account. Preserve the destination and the expected sender verbatim across the handoff.
5. Report the refusal where a person sees it — `route`, `degraded_from`, the typed reason, and
   `preferred_route_verified: false` — so an unavailable identity is visible rather than inferred
   from a channel's message counts.
6. Hermetic rows: declared sender proved, declared sender unprovable, no declared sender.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- With a declared `sender_id`, a write that cannot be proved to speak as it is refused and recorded
  as pending, never delivered under another identity.
- A binding declaring no `sender_id` behaves exactly as before, with the advisory finding unchanged.
- The destination and expected sender ride any fallback verbatim.
- The refusal is reported with its route and typed reason.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the three sender rows.
- A recorded post attempt on this repository showing the refusal rather than an operator-account
  delivery.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

## Considerations

- **Open risk, stated rather than hidden.** Enforcing this while the declared route still refuses
  every post would silence the channel entirely. The preview-guard ticket in this mission is the
  reason the two are ordered; drive that one first.
- Do not switch accounts to make a sender effective. That is the failure being repaired, and the
  standing rule already forbids it.
