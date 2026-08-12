---
created_at: 2026-08-12T20:41:22+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-a-routine-finish-line-from-vanishing-on-the-script-path
merge_policy:
---

# Make workaholic:notify own the finish-line transport

## Overview

PROPOSED. This is a **failure report**, so it is specified diagnosis-first: the
reporter's fix is a hypothesis, not step 1.

`workaholic:notify` owns the notification model — one thread per feedback item,
the stateless exact-token lookup, the post shapes — but it never says **which
transport** a post goes out on. The call sites fill that gap in the opposite
direction from the routine templates:

- `skills/drive/SKILL.md` (route step) and `skills/drive/reference/routing.md`
  name `bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/notify-slack.sh` for
  `/implement`'s `🟢 Implemented` line.
- `skills/propose/reference/workflow.md` step 12 names the same script.
- `skills/workaholify/routines/fb.md` and `implement.md` say only "post one finish
  line into its reply thread (the workaholic:notify lookup)" — the connector.

A routine session carries the Slack MCP connector and no `SLACK_BOT_TOKEN`, so the
script path returns `{"notified": false, "reason": "no_token"}` and exits 0. The
post silently never exists.

A second property, to confirm during diagnosis: `notify-slack.sh` builds its
payload as `{"channel", "text"}` with **no `thread_ts`**, so even a tokened run
cannot reply into a thread — it can only post a keyed root. If that holds, the
script is not a like-for-like fallback for the connector and the fallback's
contract has to say what it can and cannot do.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/notify/SKILL.md` — owns the model; the transport rule
  belongs here, stated once
- `plugins/workaholic/skills/notify/reference/notifications.md` — the post-shape
  catalog the templates mirror
- `plugins/workaholic/skills/drive/SKILL.md` (route step) and
  `plugins/workaholic/skills/drive/reference/routing.md` — call sites naming
  `notify-slack.sh` for the `/implement` finish line
- `plugins/workaholic/skills/propose/reference/workflow.md` step 12 and
  `plugins/workaholic/skills/propose/SKILL.md` *Notifier contract* — the same
- `plugins/workaholic/skills/propose/scripts/notify-slack.sh` — the fallback; its
  payload carries no `thread_ts`
- `plugins/workaholic/skills/workaholify/routines/fb.md`, `implement.md` — the
  connector-side wording the skills must agree with
- `docs/proposal-loop-runbook.md` *Two notification paths* — the operator page
- `scripts/test-workflow-scripts.mjs` — where a drift assertion would live

## Implementation Steps

1. **Reproduce.** Run `notify-slack.sh "probe"` with no `SLACK_BOT_TOKEN` and
   confirm `{"notified": false, "reason": "no_token"}` with exit 0 — the silent
   no-op, in the exact shape a routine session hits it.
2. **Localize the choice.** Grep every caller of `notify-slack.sh` under
   `plugins/` and list, per call site, whether it names the script or the notify
   lookup. Confirm the split described in the Overview and record any call site the
   Overview missed.
3. **Confirm the threading limit.** Read `notify-slack.sh`'s payload construction
   and confirm whether it can pass a `thread_ts` at all. The answer decides whether
   the fallback is "posts a keyed root" or "posts into the thread".
4. **Check the four cited runs** (PRs #392, #389–#391, #402) against the channel to
   confirm which surface each used, so the transport rule is written against
   measured behavior rather than the reporter's summary.
5. **Write the rule once, in `workaholic:notify`**: the connector is the primary
   surface wherever it exists; the tokened script is the machine fallback for a
   shell/CLI caller with no connector; and state plainly what the fallback cannot
   do (thread, per step 3).
6. **Convert the call sites** in `drive/SKILL.md`, `drive/reference/routing.md`,
   `propose/reference/workflow.md` step 12 and `propose/SKILL.md` to defer to that
   rule instead of naming the script as *the* way to post.
7. **Update the docs in the same change** — `docs/proposal-loop-runbook.md` *Two
   notification paths*, and `CLAUDE.md` if the claim-protocol bullet on per-unit
   finish lines still reads as script-first.
8. Regenerate `outputs/` (`node scripts/build-plugins/build.mjs`) and add an
   assertion to `scripts/test-workflow-scripts.mjs` that no skill markdown names
   `notify-slack.sh` as the primary finish-line transport, so the split cannot
   silently return.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `workaholic:notify` names the transport ordering explicitly, and states the
  fallback's threading limitation as found in step 3.
- No call site under `plugins/` presents `notify-slack.sh` as the way a routine
  posts its finish line.

**Verification method** — the commands/tests/probes that prove them:

- `grep -rn "notify-slack.sh" plugins/ docs/ CLAUDE.md` — every remaining hit is
  the fallback stated as a fallback.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs` — including the new drift assertion.

**Gate** — what must pass before approval:

- The measured evidence from steps 1–4 is written into the branch story, so the
  rule is traceable to observation rather than to the report's summary.

## Open Decisions

- Whether the tokened fallback should learn to thread — options: (A) teach
  `notify-slack.sh` a `thread_ts` argument, which also requires it to run the
  exact-token search and therefore a `search:read` scope the bot token does not
  have today; (B) keep it a keyed-root-only fallback and say so in the rule. The
  ask names the script as "the machine fallback" without settling how faithful the
  fallback must be, and (A)'s scope expansion is a real cost this session cannot
  weigh against the operator's appetite for it.

## Considerations

- `workaholic:notify`'s *The prompt is the ceiling* rule stands: this ticket
  changes **how** a sanctioned post is transported, never which events post.
- The connector is an account-level selection nothing in the plugin can verify, so
  the rule must degrade rather than assume — which is what ticket
  `20260812204216` exists to make visible.

## Final Report

Development completed as planned, diagnosis first.

**Measured evidence (steps 1-4).**

1. Reproduced: `bash plugins/workaholic/skills/propose/scripts/notify-slack.sh "probe"` with no
   `SLACK_BOT_TOKEN` prints `{"notified": false, "reason": "no_token"}` and exits **0** — the
   silent no-op in the exact shape a routine session hits it.
2. Localized: five markdown call sites named the script, four of them as *the* way to post
   (`drive/SKILL.md` route step, `drive/reference/routing.md`, `propose/reference/workflow.md`
   step 12, `propose/SKILL.md` *Notifier contract*), while `workaholify/routines/fb.md` and
   `implement.md` name only the connector lookup. The Overview's split is confirmed; no call site
   was missed. `drive/scripts/claim.sh` also reaches for the script, but as the separate
   bot-notice surface the notify skill deliberately leaves alone.
3. Threading limit **confirmed**: `notify-slack.sh` builds its payload as
   `{"channel", "text"}` from one text argument — no `thread_ts` parameter exists and the script
   runs no search, so it can post a keyed root only, never a reply into a thread. It is therefore
   not a like-for-like fallback for the connector, and the rule now says so.
4. Checked live against `#dev-workaholic` (standing consent, private-inclusive search): every
   `🔵 Proposed` / `🟢 Implemented` line in the channel — including #402's, threaded under
   `thread_ts` 1786562079.274919 — was posted **as the user through the connector**, never as the
   bot the script would have used. Several finish lines (#403, #404, #405, #363, #365, #366) sit
   as top-level roots with no `thread_ts`, the shape a failed or unavailable in-thread post
   leaves behind. No post in the channel was produced by the script path.

**Open Decision resolved — (B), the fallback stays keyed-root-only and says so.** Option (A),
teaching `notify-slack.sh` a `thread_ts`, also obliges it to run the exact-token search, which
needs a `search:read` scope this bot token does not have: an account-level provisioning change,
not a plugin one, whose appetite only the operator can weigh. (B) costs nothing and is already
sanctioned by the model — the lookup's own not-found branch posts a keyed root, and "two roots
with one key is repairable, a keyless post is not". (A) is recorded as a deferred decision, not
foreclosed.

### Discovered Insights

- **Insight**: a transport named at the call site is a transport *selected* for every session
  that reads it. The four call sites did not disagree with the routine templates in wording — they
  disagreed in which surface a reader would reach for, and only a session lacking that surface
  could tell.
  **Context**: the same shape as the plugin-binding and `gh`-GraphQL findings of the same week —
  a capability the writing environment had and the running one did not. The repository's answer is
  consistent: state the rule once in the owning skill, have call sites defer, and pin the
  relationship (not the phrasing) with a drift assertion.
- **Insight**: the channel's own history distinguishes the transports without any instrumentation
  — a connector post carries the operator's user identity, a bot-token post would not.
  **Context**: this makes "which surface posted this line" answerable months later from Slack
  alone, which is what let step 4 be measured rather than assumed.
