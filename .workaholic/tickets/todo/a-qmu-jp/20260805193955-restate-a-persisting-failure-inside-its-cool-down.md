---
created_at: 2026-08-05T19:39:55+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
feedback: [20260805191634-a-persistent-drive-failure-goes-silent-for-a-day-under-the-alert-dedup-cool-down.md]
merge_policy:
---

# Restate a persisting failure inside its cool-down

## Overview

The red-alert dedup rule (`workaholify` SKILL, *A red failure alert is deduped…*) suppresses
a repeat of the same failure signature for 24 hours. It was written against a measured
failure — one near-identical red post per hour for two days — and that half is right. What
it did not anticipate is a signature that **persists for the whole cool-down**: the operator
sees one alert in the morning and then a channel that looks exactly like a working fleet
with nothing to do, for the rest of the day.

Measured 2026-08-05: the hourly `[Drive]` routine fired at 11:56, 12:56, 13:56 and 14:56 JST
with two claimable tickets queued and produced nothing — no claim, no post, no PR — because
each tick stopped at the superseded-plugin gate whose alert had been posted once at 08:01.
It was noticed only because a developer asked what was running.

The gap is between *this failure was already reported* and *this failure is still
happening*. The rule already distinguishes those in the session log, deliberately — but
nobody reads the session log of a tick that posted nothing.

The fix keeps the suppression and adds one signal that costs almost no attention: while a
signature is suppressed, the tick **replies in the existing alert's thread** rather than
staying silent. The channel gets no new top-level line; the alert a developer already
scrolled past grows a visible reply count, and opening it shows how long the condition has
persisted.

## Policies

- `workaholic:design` / `policies/ux.md` — a notification's job is to leave the reader with an accurate picture, and silence is a message
- `workaholic:operation` / `policies/observability.md` — a monitoring signal that cannot distinguish "healthy" from "broken and already reported" is not a monitoring signal
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/SKILL.md` — the *A red failure alert is deduped by
  reading the channel* subsection, which owns the rule since the `[Drive]` template was
  slimmed on 2026-08-05. The change is written here and referenced, never restated.
- `plugins/workaholic/skills/workaholify/routines/drive.md` — step 5 points at the rule; it
  should keep pointing and not grow a restatement.
- `scripts/test-workflow-scripts.mjs` — the ten assertions that pin the rule's clauses
  (`testRoutineAnnouncementScoping`, asserted against the SKILL since the relocation). The
  new clause needs one of its own.

## Implementation Steps

1. Amend the rule in `workaholify/SKILL.md`: a suppressed tick posts **a threaded reply on
   the existing alert**, not a new top-level line. State what the reply carries — that the
   condition is still present and since when — and keep it to one line.
2. State the ordering explicitly, because it is the part a later edit will get wrong: the
   **top-level** post is what the cool-down suppresses; the **thread reply** is what
   replaces it. A changed signature still posts a new root immediately, and the first
   report of any signature is still a root. The reply is never a substitute for either.
3. Keep the fail-open direction unchanged: a channel history that cannot be read still
   posts the alert as a root, because silence must never be produced by a failure of the
   mechanism that decides to be silent. A reply that cannot be posted is not an error —
   Slack is never load-bearing.
4. Decide and record whether the reply repeats every tick or is itself rate-limited. State
   the choice and its reason in the SKILL rather than leaving it to the session: an hourly
   reply on one thread is 24 replies a day, which is either an honest heartbeat of a
   persisting outage or the same noise the rule exists to prevent, and the answer depends on
   which is being optimised for.
5. Add the assertion to the existing block in `test-workflow-scripts.mjs`, beside the ones
   that pin the signature, cool-down and fail-open clauses.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The SKILL states that a suppressed tick replies in the existing alert's thread, and states
  the reply's rate.
- The suppression of the **top-level** post is unchanged: same signature, same 24-hour
  window, same immediate post on a changed signature, same first-report guarantee.
- The fail-open clause is unchanged and still asserted.
- `routines/drive.md` gains no restatement of the rule — it still points at the SKILL.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`, including a new assertion for the reply clause.
- `wc -l plugins/workaholic/skills/workaholify/routines/drive.md` stays in the other two
  templates' range.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`.

**Gate** — what must pass before approval:

- The change is to the rule's text and its test only; no live routine is created or
  refreshed by the driving session.

## Considerations

- **This does not fix the failure it makes visible.** The superseded-plugin binding is a
  separate ticket. This one only ensures that a persisting outage stops reading as a healthy
  idle fleet — and it is worth doing on its own, because the next persisting failure will
  have a different cause and the same silence.
- **A daily top-level restatement was considered and is the alternative** if a threaded
  reply proves too quiet — a thread nobody opens is barely louder than silence. It was not
  chosen first because it reintroduces exactly the shape the dedup rule was written to
  remove, and the threaded form can be strengthened later without undoing anything.
- **The routine template must not grow this back.** It was slimmed to a thin pointer hours
  before this was written; adding "and reply in the thread when suppressed" to the prompt
  would recreate the second source of truth that slimming removed.
