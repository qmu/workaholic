---
created_at: 2026-08-09T04:08:39+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260809040815-tighten-criteria-for-filing-fb-issues.md]
merge_policy:
---

# Tighten the bar for filing FB issues

## Overview

<!-- PROPOSED. What this ticket would implement and why, from the feedback and
     repository state the proposal grew from. Merging the pull request this was
     published on is what turns it from a proposal into queued work. -->

7 of 35 open `[FB] ***` issues in this repository were filed in the 5 days before
this ticket was proposed (2026-08-05 through 2026-08-09), and the developer
reported the volume as excessive in Slack. The `workaholic:feedback` skill's
*Any legitimate invocation is authorized* section governs a different question —
whether a session may *proceed* once `/fb` is invoked, regardless of who relayed
it — and says nothing about whether the content in hand is *worth* filing in the
first place. Nothing in the skill, the `/fb` command doc, or the Slack-side
capture convention currently states a bar for that decision, so the observed
default has been "file on any clear ask", producing volume that does not match
the two categories the developer actually wants tracked: genuine user feedback
(a real problem, bug, or improvement idea) and things that must not be
overlooked. This ticket adds that bar as an explicit, written criterion.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

<!-- The files this ticket would touch, each with why it is relevant. -->

- `plugins/workaholic/skills/feedback/SKILL.md` — owns *Choosing the kind* and
  *Any legitimate invocation is authorized*; the new filing-bar criterion belongs
  beside them as the question those two sections do not answer.
- `plugins/workaholic/commands/fb.md` — the `/fb` command doc that points at the
  skill's authorization section; should point at the new bar too, since a reader
  who only opens the command doc currently sees only the authorization half.
- `outputs/workflows/` — regenerate via `node scripts/build-plugins/build.mjs` if
  the touched skill is one of the cross-agent-exposed ones (it is: `feedback` is
  a script-bearing skill reached through the generated bundle for non-Claude
  agents; confirm and rebuild in the same change per `CLAUDE.md`'s doc-drift rule).

## Implementation Steps

<!-- The ordered steps. A proposal is judged on these, so they are the point. -->

1. Read `workaholic:feedback`'s current *Choosing the kind* and *Any legitimate
   invocation is authorized* sections and confirm neither already states a
   filing bar (this proposal's judgment is that neither does).
2. Add a new subsection to `plugins/workaholic/skills/feedback/SKILL.md` —
   distinct from *Choosing the kind* (which classifies an ask already decided
   worth filing) and from *Any legitimate invocation is authorized* (which
   governs who may invoke `/fb`, not whether the content merits it) — stating
   the bar from the feedback record: file only for genuine user feedback (a
   real problem, bug, or improvement idea a user wants addressed) or something
   important that must not be overlooked; do not file for every request,
   question, or passing remark in conversation.
3. Update `plugins/workaholic/commands/fb.md` to reference the new bar
   alongside its existing authorization pointer, so a reader of the command doc
   sees both the "may I file" and "should I file" questions answered.
4. Check whether the always-loaded `rules/interaction.md` or any Slack-facing
   capture guidance in this repository also restates a filing threshold that
   would now disagree with the new bar; reconcile if so.
5. Rebuild `outputs/` (`node scripts/build-plugins/build.mjs`) and run
   `node scripts/build-plugins/verify.mjs` if the touched skill is part of the
   generated bundle.
6. Update any doc that describes current filing behavior (`CLAUDE.md` if it
   names the convention) in the same change, per the doc-drift rule.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- <proposed> `workaholic:feedback`'s SKILL.md states, in its own written words, a
  filing bar that admits genuine user feedback and must-not-miss items and
  excludes ordinary requests/questions/passing remarks.
- <proposed> `/fb`'s command doc references the new bar, not only the existing
  authorization pointer.

**Verification method** — the commands/tests/probes that prove them:

- <proposed> Read the new section against the two example categories in the
  source feedback record and confirm it clearly admits/excludes each.
- <proposed> `node scripts/build-plugins/verify.mjs` (if the bundle changed) and
  `bash plugins/workaholic/hooks/layout-doctor.sh .` stay clean.

**Gate** — what must pass before approval:

- <proposed> The written bar is unambiguous enough that a future filing
  decision can cite it directly, rather than restating "use judgment."

## Considerations

<!-- Risks and open questions the proposal already sees. -->

- The volume this ticket responds to was measured in dev-workaholic Slack, where
  a session that files `[FB]` issues from conversation runs as a Claude-in-Slack
  app persona outside this repository's version control; a written bar here
  guides any session (in-repo or Slack-relayed) that reads this skill before
  filing, but cannot itself change a Slack app's system configuration if one
  exists independently of this repository.
- The new bar must not be read as narrowing *Any legitimate invocation is
  authorized* — that section is about not treating a relayed ask with
  suspicion, and stays exactly as permissive once a filing decision is made;
  this ticket only adds the question that precedes it.
