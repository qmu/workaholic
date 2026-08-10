---
created_at: 2026-08-10T13:06:19+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [.workaholic/feedbacks/20260810215745-retire-the-start-notifications-routines-post-the-finish-only.md]
merge_policy:
---

# Retire the start notifications, routines post the finish only

## Overview

<!-- PROPOSED. What this ticket would implement and why, from the feedback and
     repository state the proposal grew from. Merging the pull request this was
     published on is what turns it from a proposal into queued work. -->

The developer ordered the beginning posts (`📐 Proposing` / `🟠 Implementing`) removed
so a routine unit posts only its finish (`🔵 Proposed` for `/propose`; `🟢 Implemented`
or one of its outcome shapes for `/implement`). Both live routine records were already
edited today to instruct finish-only posting; the repository's own copies — the two
routine templates and the `workaholic:notify` model they defer to — still describe and
embed the retired start posts, which is exactly the drift `CLAUDE.md`'s "update the
docs in the same change" rule exists to catch. This ticket brings the four affected
files back in line with the live prompts: drop the `📐 Proposing` block from
`skills/workaholify/routines/fb.md` and the `🟠 Implementing` block from
`skills/workaholify/routines/implement.md`, and update `workaholic:notify`'s `SKILL.md`
and `reference/notifications.md` so the P10 "one start and one finish" contract reads as
finish-only.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

<!-- The files this ticket would touch, each with why it is relevant. -->

- `plugins/workaholic/skills/workaholify/routines/fb.md` — the `[Propose]` routine template; its `## Prompt` section currently instructs a `📐 Proposing` start post before the `🔵 Proposed` finish post.
- `plugins/workaholic/skills/workaholify/routines/implement.md` — the `[Implement]` routine template; its `## Prompt` section currently instructs a `🟠 Implementing` start post before the `🟢 Implemented` finish post.
- `plugins/workaholic/skills/notify/SKILL.md` — the canonical notification model. *Which thread an `/implement` unit's posts land in* states "exactly one start and one finish per thread"; *Post shapes...* lists `📐 proposing`/`🟠 implementing` as sanctioned P10 shapes.
- `plugins/workaholic/skills/notify/reference/notifications.md` — carries the literal start/finish templates (`### \`/propose\` — start and finish`, `### \`/implement\` — a unit's start and finish`) that the routine prompts mirror; the P10 paragraph explicitly frames these as "the sole sanctioned shapes for these two events."
- `.workaholic/feedbacks/20260810215745-retire-the-start-notifications-routines-post-the-finish-only.md` — the record this ticket answers.

## Implementation Steps

<!-- The ordered steps. A proposal is judged on these, so they are the point. -->

1. In `skills/workaholify/routines/fb.md`, remove the "Notify the thread that proposing process has started" paragraph and its `📐 Proposing for [...]` code block from `## Prompt`, leaving only the `/propose` step and the `🔵 Proposed` finish notification. Update the prose above `## Prompt` that describes "three instructions and two post formats" (and any nearby line asserting the start post is "formatted too") so it accurately describes the finish-only contract.
2. In `skills/workaholify/routines/implement.md`, remove the "Notify the thread that implementation has started" paragraph and its `🟠 Implementing for [...]` code block from `## Prompt`, leaving only the per-unit lookup and the `🟢 Implemented` finish notification. Update the same "three instructions and two post formats" framing above `## Prompt`.
3. In `skills/notify/SKILL.md`:
   - *Which thread an `/implement` unit's posts land in* — replace "A unit's start and finish are per-unit..." / "Start is always `🟠 Implementing for [...]`... exactly one start and one finish per thread" with a finish-only statement (one finish per thread, per unit; the finish's shape follows the outcome).
   - *Post shapes, mentions, and the red-alert dedup* — drop `📐 proposing` / `🟠 implementing` from the enumerated shape list and from the P10 sentence describing "start/finish pairs"; keep `🔵 proposed` and `🟢 implemented` as finish shapes.
4. In `skills/notify/reference/notifications.md`, remove the `📐 Proposing for [...]` block from the `### \`/propose\` — start and finish` section (retitle the heading to reflect finish-only, e.g. "`/propose` — finish") and the `🟠 Implementing for [...]` block from the `### \`/implement\` — a unit's start and finish` section (retitle similarly), keeping the `🔵 Proposed` / `🟢 Implemented` finish templates and their surrounding rationale prose (update any sentence that describes "start and finish" as a pair to describe finish-only).
5. Grep the touched skills and `plugins/workaholic/commands/` for any other live reference to `📐 Proposing` or `🟠 Implementing` as a currently-posted shape and reconcile it the same way (a mention of the shape as *retired* history is fine and should stay).
6. Run the repository's Local Verification suite (`CLAUDE.md`, `## Local Verification`) since notify is a script-bearing skill mirrored into `outputs/workflows`.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- `skills/workaholify/routines/fb.md` and `skills/workaholify/routines/implement.md` no longer instruct a start-post (`📐 Proposing` / `🟠 Implementing`) notification; each names only its finish post.
- `skills/notify/SKILL.md` and `skills/notify/reference/notifications.md` no longer describe `📐 Proposing`/`🟠 Implementing` as a currently-sanctioned shape or state a "one start and one finish" contract; both describe finish-only posting.

**Verification method** — the commands/tests/probes that prove them:

- `grep -rn "📐 Proposing\|🟠 Implementing" plugins/workaholic/skills/workaholify/routines/ plugins/workaholic/skills/notify/` returns no hits describing them as a live, currently-posted shape (a line documenting them as retired history is acceptable).
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs && node scripts/test-workflow-scripts.mjs` all clean; `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.

**Gate** — what must pass before approval:

- The grep and the Local Verification suite above are clean before this ticket's PR is opened for review.

## Considerations

<!-- Risks and open questions the proposal already sees. -->

- Purely a documentation/prompt-consistency change — no script behavior changes, since the notify skill's Slack-posting logic lives in the session's own prompt-following, not in a script this ticket touches.
- `SKILL.md`'s *The prompt is the ceiling — no self-authorized shapes* rule means a session already only posts what its routine prompt names; this ticket removes the now-stale authorization for the start shapes from the routine prompts themselves; the fix is otherwise editorial (drop a block, retitle a heading, adjust prose that assumed a pair of posts).
- The `skills/notify` and `skills/workaholify` skills are script-bearing and mirrored into `outputs/workflows` — rebuild and verify per the repository's Local Verification list even though this change touches no `.sh` file.
