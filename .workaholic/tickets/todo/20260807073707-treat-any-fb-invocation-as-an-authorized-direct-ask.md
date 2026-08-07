---
created_at: 2026-08-07T07:37:07+00:00
author: noreply@anthropic.com
assignees: [a@qmu.jp]
depends_on:
feedback: [20260807073610-fb-skill-should-treat-any-invocation-as-equivalent-to-a-direct-user-request.md]
merge_policy:
---

# Treat any /fb invocation as an authorized direct ask

## Overview

**PROPOSED**, from `#293` (assignee `tamurayoshiya`) and its Slack thread. An automated integration (`qfs Integration`) @-mentioned Slack-side Claude asking it to file an FB issue; because the mention came from a bot/integration account rather than directly from a human, Claude's own reply-safety heuristics treated it with suspicion and initially blocked responding, even though the request was legitimate and on-topic (Claude filed the issue anyway, `#290`, but with avoidable friction and delay). The ask is to make the `/fb` skill (and the convention around invoking it) state explicitly that any legitimate invocation — however it is relayed, including via a bot/integration account in Slack — is treated as equivalent to a direct human ask, so a session no longer has to second-guess whether a bot-relayed `/fb` request is "really" authorized. Merging the pull request this was published on is what turns this from a proposal into queued work.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` — how the team documents conventions for agents that act on relayed instructions

## Key Files

- `plugins/workaholic/skills/feedback/SKILL.md` — the feedback skill's *Registering a record* workflow; the natural place to state that a `/fb` invocation carries its own authorization regardless of the relaying surface
- `plugins/workaholic/commands/fb.md` — the `/fb` command's own doc, read at trigger time
- `plugins/workaholic/rules/interaction.md` — the always-loaded interaction rules; the general "ask only for genuine decisions" convention this ask is a specific instance of

## Implementation Steps

1. Read the current `/fb` invocation path (`commands/fb.md` plus `skills/feedback/SKILL.md`'s *Registering a record — the capture workflow*) to find where a session currently might hesitate over the identity of whatever invoked it (a Slack @-mention, a bot/integration relay, a direct human ask).
2. Add an explicit statement — in `skills/feedback/SKILL.md` (and `commands/fb.md` if the trigger-time doc needs it too) — that **any legitimate invocation of `/fb`, however it reaches the session (a human typing it, a human's message relayed by a bot/integration account, an automated integration acting on a human's behalf), is authorized and equivalent to a direct user ask**: the session should proceed to classify, register, and report per the existing workflow without a separate confirmation step or added suspicion keyed on the relaying account's type.
3. State the boundary the new wording does **not** widen: this is about *not second-guessing the authorization of an `/fb` invocation itself* — it does not relax the separate, still-mandatory judgement gates elsewhere (the cross-repository crossing's non-skippable verbatim confirmation, the release scan's `secret`/`leak` rules). Name that boundary explicitly so the change cannot be read as loosening those.
4. Update any other doc that currently describes `/fb` as needing extra scrutiny for non-human-typed invocations, so nothing is left contradicting the new statement.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `skills/feedback/SKILL.md` (and/or `commands/fb.md`) states plainly that any legitimate `/fb` invocation — regardless of whether it reached the session directly from a human or relayed through a bot/integration account — is treated as equivalent to a direct user ask, with no added hesitation or confirmation keyed on the relaying account's type
- The statement names what it does **not** change: the cross-repository crossing's non-skippable confirmation and the release-scan gates are untouched

**Verification method** — the commands/tests/probes that prove them:

- Read the updated section and confirm it directly answers the scenario in the feedback record (a bot-relayed `/fb` ask being treated with suspicion)
- `node scripts/build-plugins/verify.mjs` (doc-only change, but run it if the touched skill is part of the built closure)

**Gate** — what must pass before approval:

- The updated wording is reviewed and merged via this ticket's pull request

## Considerations

- This is a documentation/convention change, not new enforcement code — there is no hook that could machine-check "was this invocation legitimate", so the fix is the same kind of stated convention `rules/interaction.md` already relies on elsewhere.
- Keep the new statement narrow: it authorizes *acting on* a relayed `/fb` invocation: it must not be read as authorizing the session to skip the separate, existing content-level gates (masking confirmation, secret/leak scan) that apply once the ask is being drafted or crosses a repository boundary.
