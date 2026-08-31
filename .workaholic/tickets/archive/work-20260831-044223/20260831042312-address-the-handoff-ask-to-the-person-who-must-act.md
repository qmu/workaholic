---
created_at: 2026-08-31T04:23:12+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: notify-the-person-a-directed-question-addresses
merge_policy:
verification_handoff: 
---

# Address the handoff ask to the person who must act

## Overview

PROPOSED. The ask names two carriers for the bot identity: the directed
question, and the **waiting-on-a-person handoff ask**. The handoff finish line
lost its mention on 2026-08-23 for exactly the reason this mission exists — the
token it carried resolved to the account the post is made as — so today it names
nobody at all, and the measured failure was three items waiting on operator
input that the operator found only by asking a session directly.

Give the handoff line back a mention, addressed to the person who must perform
the declared verification, and carry it on the bot so the mention fires.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/notify/reference/notifications.md` — the handoff
  shape, and the record of why its token was dropped.
- `plugins/workaholic/skills/notify/SKILL.md` — *Never mention the identity you
  are posting as*, which this narrows rather than reverses.
- `plugins/workaholic/skills/drive/SKILL.md` — the route that posts the finish
  line, and the run report that names its outcome.
- `plugins/workaholic/skills/drive/scripts/verification-handoff.sh` — the one
  reader of the declared reason; the addressee comes from the unit's assignees,
  not from this script.

## Implementation Steps

1. Read the 2026-08-23 record before changing the shape, and state in the change
   what it got right: a self-mention is decoration. The repair is the identity,
   never the removal.
2. Restore the mention on the handoff finish line, resolved from the unit's own
   `assignees` through `gather/scripts/identity.sh`, and leave it **absent** when
   the address does not resolve rather than stamping one nobody verified.
3. Carry that line on the bot when the addressee resolves to the posting
   identity, per the transport rule; otherwise the connector, unchanged.
4. Keep the declared reason quoted verbatim and the line's other wording exactly
   as the catalog has it; this changes who it names and what carries it, nothing
   else.
5. Report the carrying surface and the mention outcome in the run report beside
   the existing notification outcome, so an unposted or unaddressed line reads as
   what it is.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A handoff finish line names the person who must act, when that person resolves.
- It is carried by the bot when the addressee is the posting identity, and by the
  connector otherwise.
- An unresolved addressee produces no token and is reported, never guessed.
- The declared reason's wording is unchanged.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-handoff-question` — unchanged rows green.
- The drill added by this mission's drill ticket, covering the mention and the
  carrying surface.

**Gate** — what must pass before approval:

- The catalog and the drive route state one shape; the run report names the
  surface and the mention for every handoff line it posts.

## Considerations

- `/moderate`'s `handoff-units` question already asks the claim holder about a
  standing handoff. This is not a duplicate: that question fires hourly from the
  claim oracle, this is the finish line the run itself posts, and the two are the
  same person's business by different routes. Whether one should suppress the
  other is a judgement for the operator, not this mission.
- An attended `/drive` run still posts nothing to Slack, unchanged.

## Final Report

**Outcome:** implemented.

**Step 1 — what the 2026-08-23 record got right, read before anything moved.** The token the
handoff line carried then named the **runner** — the account making the post — so it was
decoration, and dropping it was correct. What the record did not settle is that this shape is
*by definition* waiting on one person's act, so removing the runner left it naming **nobody**,
which is the one thing it cannot afford. `drive/reference/routing.md`'s own declared-handoff
table has read `🟡 Handoff` **naming the assignee** since 2026-08-14, so the route and the
catalog had disagreed for eight days. **The repair is the identity, never the removal.**

**What changed.** The catalog's fenced shape is `🟡 Handoff <@U…> - [#123 …]`; the token is the
**unit's own addressee**, resolved from its `assignees` through `gather/scripts/identity.sh`, and
**omitted rather than guessed** when the address does not resolve — the reader answers
`resolved: false` and echoes its input, and a guess here pages the wrong person about somebody
else's blocked work. It rides the **bot** when that addressee is the posting identity, per the
transport rule the previous ticket wrote; the connector otherwise, unchanged. Everything else is
verbatim: the body sentence, the session URL, the `## Handoff` section's verbatim quoting of the
declared reason, and the rule that this 🟡 **is** the unit's one finish post.

**The rule is satisfied, not excepted.** *Never mention the identity you are posting as* holds
exactly as written — the mention now resolves to somebody other than the author, which is what a
mention is. `notify/SKILL.md`'s own record of that rule says so in place rather than growing a
carve-out.

**Reported, so an unaddressed line reads as one.** `drive/reference/routing.md`'s run-report
contract gains two facts beside the existing notification outcome, deliberately unblended:
**which account spoke** (`bot` / `connector`) and **whom it named** (the resolved address, or
`mention_unresolved: <address>`). *Posted*, *by whom* and *at whom* are three questions, and
three units sat waiting on operator input since 2026-08-18, 2026-08-19 and 2026-08-26 with the
run reporting the post as sent. No artifact gains a field.

**The drift pin moved with the decision, and is the part worth reading.** The suite pinned
*🟡 Handoff carries no token at all*, which was the 2026-08-23 decision's **effect** rather than
its rule; the rule is *not yourself, never nobody*, the same rule the check-in question's
neighbouring row pins. It now pins that the token is back, that the catalog states the addressee
is the unit's assignee rather than the runner, and that an unresolved address omits it. Stated in
the comment: **whom a token resolves to is a runtime fact no wire format can carry**, so the two
prose rows cover the half a fenced shape cannot — rather than leaving the reader to assume the
shape proves more than it does.

**Gate.** `node scripts/test-workflow-scripts.mjs` → 5436 passed, 0 failed (the three replacing
rows green). `sh scripts/e2e/loop-drill.sh verify-handoff-question` → `verdict: pass`, 8
load-bearing rows, 0 failed, 1 breaker — unchanged. `build.mjs && verify.mjs` → all built skills
self-contained.

**Deliberately not done.** Whether this line should suppress `/moderate`'s hourly
`handoff-unit:<unit>` question, or the reverse, is left alone: the two are the same person's
business by different routes — one fires from the claim oracle every hour, one is the finish the
run itself posts — and which should yield is the operator's judgement, not this mission's. An
attended `/drive` run still posts nothing to Slack.
