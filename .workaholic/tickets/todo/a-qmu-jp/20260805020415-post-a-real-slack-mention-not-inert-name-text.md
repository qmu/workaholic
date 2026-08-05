---
created_at: 2026-08-05T02:04:15+00:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
depends_on:
feedback: [20260805020401-routine-slack-posts-name-the-developer-as-inert-text-so-nobody-is-notified.md]
merge_policy:
claim: work-20260805-180653
---

# Post a real Slack mention, not inert name text

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it
     into queued work. -->

The three routine templates write the acting developer into their Slack lines through a literal `@<developer>` placeholder, which the routine session fills with the person's name as plain text. Slack notifies only on the `<@U…>` mention token; plain `@name` renders as ordinary text, so five message formats appear to call someone out while pinging nobody. Nothing in the repository turns an identity a routine session has in hand — a GitHub login, a git author email — into a Slack user id, and no code constructs the token.

The fix is one rule and its application: state, once, how a routine session resolves the person it is naming to a Slack user id and what it does when resolution fails, then replace the placeholder in all five formats with that token. It is the same shape as the threading model already in the `workaholify` SKILL — stated once, referenced by each template, never restated per template.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/ux.md` — a notification's job is to reach the person it names

## Key Files

- `plugins/workaholic/skills/workaholify/SKILL.md` — where the mention rule and its fallback belong, beside *One thread per feedback item* and *Slack is the only surface*, which the templates already reference rather than restate.
- `plugins/workaholic/skills/workaholify/routines/fb.md` (line 51) — `[Propose]`'s "🟢 Proposed to @<developer>".
- `plugins/workaholic/skills/workaholify/routines/merged-pr.md` (line 42) — `[Consent]`'s "🟣 Proposal merged by @<developer>".
- `plugins/workaholic/skills/workaholify/routines/drive.md` (lines 96, 102, 115) — `[Drive]`'s "🟢 Merge Requested for @<developer>", "🟣 Merged by @<developer>" and "🟡 Handoff @<developer>". The "🚀 Auto Merge by Claude" variant names no person and stays as it is.

## Implementation Steps

1. Write the mention rule into `workaholify/SKILL.md` as a short subsection of the notification model: a post that names a person resolves them to a Slack user id through the Slack connector the routine already loads (`slack_search_users` on the name or email the session has; `slack_read_user_profile` to confirm) and writes `<@U…>` in place of the `@` placeholder.
2. State the fallback in the same place, with the precedence the session-URL rule already sets: when the id cannot be resolved, post the line with the plain name rather than not posting. A missing ping beats a missing notification, and a resolution failure must never block or delay the post.
3. Say what identity each session starts from, since the three routines differ: `[Consent]` and `[Drive]`'s merge lines have the merging GitHub user, `[Propose]` has the repository's developer, and `[Drive]`'s handoff line names whoever the unit is handed to. Name which lookup key applies where a session holds only a GitHub login versus a git author email.
4. Replace the `@<developer>` placeholder in the five formats in the three templates with the resolved-token form, each referencing the SKILL's rule rather than repeating it.
5. Leave the archived stories, tickets and mission that quote the old formats untouched — they are history, not live surfaces. No other document quotes them; `workaholify` does not ship into `outputs/`, so no rebuild is involved.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No `@<developer>` placeholder remains in any of the three routine templates; each of the five person-naming formats carries the mention token.
- The resolution rule and its fallback appear exactly once, in `workaholify/SKILL.md`, and every template points at it rather than restating it.
- The fallback is written as non-blocking: a routine session that cannot resolve an id still posts.

**Verification method** — the commands/tests/probes that prove them:

- `grep -rn "@<developer>" plugins/workaholic/skills/workaholify/routines/` returns nothing.
- `grep -rn "<@U" plugins/workaholic/skills/workaholify/` shows the rule once in the SKILL and the token in each of the five formats.
- `node scripts/test-workflow-scripts.mjs` and `bash plugins/workaholic/hooks/layout-doctor.sh .` still pass.

**Gate** — what must pass before approval:

- The change touches templates and the SKILL only; no live routine is created, refreshed or re-pointed by the driving session.

## Considerations

A lookup at post time is the default here because it needs no new committed state and no per-person maintenance. If it proves unreliable — a display name that does not match, a workspace that withholds email — the next step is a maintained mapping of developer identity to Slack user id, and this ticket deliberately does not add one on speculation.

Editing a template makes every live routine drift by construction. The rollout is a separate human act, confirmed one routine at a time through `/setup-routines`; the driving session must not attempt it, and until it happens the posted lines keep their current wording.
