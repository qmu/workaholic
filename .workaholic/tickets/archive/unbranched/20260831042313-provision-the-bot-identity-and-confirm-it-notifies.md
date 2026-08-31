---
created_at: 2026-08-31T04:23:13+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: notify-the-person-a-directed-question-addresses
status: abandoned
merge_policy:
verification_handoff: a Slack bot token with chat:write, installed in the repository's channel and set on the routines' cloud environment, plus the operator confirming they received the notification
---

# Provision the bot identity and confirm it notifies

## Overview

PROPOSED. The preceding six tickets make the loop *able* to notify the operator;
none of them can prove it does. The ask's own "done means" is a person receiving
a notification without rereading the channel, and that needs a Slack bot token
with `chat:write`, the bot invited to the repository's channel, the token set on
the cloud environment the routines select, and the operator confirming the
notification arrived.

Every one of those is a credential or a human observation an unattended run does
not have, which is why this ticket declares `verification_handoff:` at creation:
the unit's pull request opens and stays open, the claim stands, and the operator
performs the one act that is theirs.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/SKILL.md` — *Where a routine's
  environment variables live*: a routine declares none; they live on the cloud
  environment it selects, and for a **credential** that is the only home, with
  the documented visibility caveat that anyone using the environment can read it.
- `plugins/workaholic/skills/specificate/scripts/notify-slack.sh` — the reader of
  `SLACK_BOT_TOKEN` and `WORKAHOLIC_SLACK_CHANNEL`.
- `docs/proposal-loop-runbook.md` — where the provisioning and failure modes for
  the tokened transport are already documented.

## Implementation Steps

1. Write the provisioning procedure where the runbook already carries the
   tokened transport's: which scope (`chat:write` and nothing wider), that the
   bot must be invited to the repository's channel, and that the token is set on
   the **cloud environment** the routines select — never in a template, never in
   the repository, never in a commit.
2. State the account-level cost plainly: an environment is shared by every
   session and routine that selects it, so this token is readable by all of them.
   That is the accepted trade for the one home a credential has.
3. **The operator's act, which no run may perform**: create or reuse the bot,
   grant `chat:write`, invite it to the channel, set `SLACK_BOT_TOKEN` on the
   environment.
4. **The operator's confirmation**: after the next `[Moderate]` tick that has a
   question, confirm the notification arrived without rereading the channel, and
   that the mention resolves to them.
5. Record the confirmation in the branch story, naming what was observed. A
   handoff that reports itself satisfied without a person's words is the soft
   landing the field exists to prevent.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- The provisioning procedure is written where the transport's other modes are.
- The token's home is named as the cloud environment, with its visibility cost.
- The operator confirms one directed question notified them without rereading.
- The confirmation names what was observed, in the operator's own words.

**Verification method** — the commands/tests/probes that prove them:

- The operator performs the provisioning and reports the observation; there is
  no command that can substitute for it.
- `sh scripts/e2e/loop-drill.sh verify-all` still green, unchanged by this
  ticket — the mechanical half is already proved by the drill ticket.

**Gate** — what must pass before approval:

- The operator's confirmation is recorded. Nothing here is closed on a run's own
  assertion that the mechanism looks right.

## Considerations

- This ticket carries `verification_handoff:`, so the **whole mission** takes the
  handoff route: the pull request opens and stays open, the claim stands and is
  not re-surveyed, and `/moderate`'s `handoff-units` question names the declared
  reason to the claim holder. That is the intended outcome, not a stall — the
  operator has to supply the token in any case, and a merge that shipped the
  mechanism with nobody told is the exact failure this mission repairs.
- The `[Propose]` routine already holds the Slack connector but no bot token;
  nothing about its receipt shape changes here.
