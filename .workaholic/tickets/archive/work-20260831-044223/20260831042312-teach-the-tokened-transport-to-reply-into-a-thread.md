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

# Teach the tokened transport to reply into a thread

## Overview

PROPOSED. `notify-slack.sh` builds `{"channel", "text"}` and takes one text
argument, so it can post a keyed root and nothing else — which is the stated
reason `workaholic:notify` calls it a fallback no call site may pick. That
restriction is what keeps the one transport with a non-operator identity away
from the one post shape whose whole purpose is to reach a person.

Give it a `--thread-ts` so the connector can resolve the thread and the bot can
reply into it. Slack's `chat.postMessage` accepts `thread_ts` under the same
`chat:write` the script already requires — no new scope, no account-level
provisioning change — and the search half of the lookup stays on the connector,
where it already is.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/specificate/scripts/notify-slack.sh` — the tokened
  transport; its argument parsing and payload builder are what change.
- `plugins/workaholic/skills/notify/SKILL.md` — *The transport*, whose "no
  `thread_ts` parameter" sentence is a statement about this script.
- `plugins/workaholic/skills/drive/scripts/claim.sh` — an existing caller (the
  bot notice), whose behaviour must not move.
- `scripts/test-workflow-scripts.mjs` — where the payload shape is pinned.

## Implementation Steps

1. **Confirm the mechanism before changing it.** Read the payload construction
   and record what it sends today; confirm from Slack's own `chat.postMessage`
   documentation that `thread_ts` needs no scope beyond `chat:write`. Record
   both readings in the branch story — the ask names the shape of the repair
   and this ticket proves it rather than inheriting the framing.
2. Add `--thread-ts <ts>` to the argument parsing, ahead of the positional text,
   refusing a malformed value by its own name rather than dropping it silently.
3. Include `thread_ts` in the JSON payload **only when given**. With no flag the
   payload is byte-identical to today's.
4. Leave every existing refusal untouched (`no_text`, `no_token`, `no_channel`,
   `http_<code>`, `slack_<error>`, `curl_failed`, and exit 0 on all of them), and
   keep the token read at call time and never persisted or echoed.
5. Extend the hermetic coverage in `test-workflow-scripts.mjs` over the stub
   endpoint: one row proving the key rides the payload when the flag is passed,
   one proving it is absent when it is not.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- With `--thread-ts <ts>`, the posted payload carries that `thread_ts` verbatim.
- With no flag, the payload is byte-identical to the pre-change payload.
- Every existing refusal word and every exit code is unchanged.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the two new rows, over the local
  stub endpoint (`WORKAHOLIC_SLACK_API_URL`); no network, no real token.

**Gate** — what must pass before approval:

- The suite passes, and a byte-comparison of the no-flag payload against the
  pre-change one shows no difference.

## Considerations

- This ticket adds a **capability, not a policy**: nothing here makes any call
  site choose the bot. Which shape rides which transport is the next ticket's
  question, kept separate so a capability cannot be read as a licence.
- A bot must be a member of the channel to post into it. That is provisioning
  rather than code, and it belongs to this mission's handoff ticket.

## Final Report

**Outcome:** implemented.

**Step 1 — the mechanism, confirmed before it was changed.** `notify-slack.sh` built its
payload as `{"channel": <WORKAHOLIC_SLACK_CHANNEL>, "text": <argv[1]>}` and nothing else,
through one `python3 -c` line, and took exactly one positional argument. Slack's
`chat.postMessage` takes `thread_ts` as an ordinary argument of the **same method** — it is
not a different endpoint and carries no scope of its own, so the `chat:write` the script has
always required is the whole requirement. That is the half of the 2026-08-12 reading that
was wrong: it concluded "teaching it to thread would require `search:read`", which is true
of *finding* a thread and not of *posting into* one. The two halves are separable, and
separating them is the repair.

**What changed.** `--thread-ts <ts>` (and `--thread-ts=<ts>`) parsed ahead of the positional
text; `thread_ts` in the payload only when the flag was given. A malformed or empty value is
refused `bad_thread_ts` at exit 1 — the script's existing malformed-invocation class, beside
`no_text` — rather than dropped, because a root posted silently where a reply was asked for
is invisible from the caller's side. Every graceful no-op (`no_token`, `no_channel`,
`http_<code>`, `slack_<error>`, `curl_failed`, exit 0) is untouched, and the token is still
read at call time and never persisted or echoed.

**Gate.** `node scripts/test-workflow-scripts.mjs` — 5434 passed, 0 failed, including 12 new
rows under `propose/notify-slack.sh`. The payload is captured through a `curl` **stub on
PATH** rather than a listener: no socket, no port to race, and the assertion is on the bytes
that would have gone out. The no-flag payload was byte-compared against the pre-change
builder's output and is identical (`{"channel": "C123", "text": "hello world"}`); the suite
pins that comparison as a literal string so a later refactor cannot drift it.

**Documentation corrected in the same change.** `workaholic:notify` *The transport* claimed
"no `thread_ts` parameter and no search"; the search half stands and is now stated as the
reason the connector is the only transport that can run the lookup, while the threading half
is corrected with the measurement above. Four call-site sentences that gave "cannot thread"
as the reason a fallback post is a keyed root now give the accurate one — it cannot
**search**, and on the one path that reaches it the connector that would have run the lookup
is exactly what is absent, so no thread was ever resolved. Behaviour statements are unchanged
everywhere; only the reason moved.

**Deliberately not done.** No call site picks this transport for its identity. This ticket
adds a capability; which shape rides which transport is the next ticket's question, and the
skill says so in as many words so a capability cannot be read as a licence.
