---
created_at: 2026-08-27T23:22:22+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: finish-the-retirement-the-loop-cannot-complete
merge_policy:
verification_handoff: 
---

# Reproduce the refused branch delete and name it

## Overview

**Diagnosis only — this ticket ships no fix.** `retire-claim.sh`'s Act 2
(`git push --quiet origin --delete "$BRANCH"`) fails on every tick, and the script's
own comment attributes it to a 2026-08-05 reading ("a cloud container may PUSH but
not DELETE a branch"). That reading is a **hypothesis**, not a measurement of today:
a branch-protection rule, a missing token scope and a session-type refusal all
produce the identical visible symptom (`REMOTE_STATE="failed"`, no message kept).
The three need different repairs, so the refusal is measured before anything is
coded against it.

Confirmed as of 2026-08-27: `work-20260819-063001`, `work-20260821-035855` and
`work-20260818-205051` all still answer `PRESENT` to `git ls-remote --heads origin`
while their pull requests read `closed` — Act 1 succeeded, Act 2 did not.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a failure names itself

## Key Files

- `plugins/workaholic/skills/drive/scripts/retire-claim.sh` — Act 2 discards the
  refusal (`>/dev/null 2>&1`), which is why nothing knows what it was.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the sanctioned transport,
  should the REST branch-delete endpoint be measured beside the git push.
- `docs/loop-drill-runbook.md` — where a measured failure-reason table belongs.

## Implementation Steps

1. **Reproduce.** Against a claim already proved `superseded` on this repository,
   attempt the delete in the container the loop actually runs in (a routine-fired
   tick, not an interactive session — the two are different execution classes and
   the distinction is the point). Capture stderr rather than discarding it.
2. **Localize.** Record the exact refusal: the git transport's message, and
   separately what `DELETE /repos/{owner}/{repo}/git/refs/heads/{branch}` answers
   through `gh-rest.sh` — status code and message body. Two transports, two answers,
   both recorded.
3. **Distinguish the three candidates** from what came back: a session-type refusal
   (a message naming the session type), a protection rule (`422`, a message naming
   the rule), or a missing scope (`403`, a permissions message). Do not infer from
   the exit status alone — that is what collapsed them in the first place.
4. **Record the finding** where the next ticket can act on it: the measured status,
   the message verbatim, which of the three it is, and whether the two transports
   agree. A finding that names no message is not a diagnosis.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The refusal's exact status and message are recorded from a run in the loop's own
  container, for both the git push and the REST endpoint.
- The refusal is classified as exactly one of session-type, protection rule, or
  missing scope, with the evidence naming which.
- No behaviour changed by this ticket: `retire-claim.sh`'s output is byte-identical.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (unchanged behaviour).
- The recorded transcript of the reproduction, quoted in the ticket's story.

**Gate** — what must pass before approval:

- The recorded message is quoted verbatim, not paraphrased.

## Considerations

- The 2026-08-05 session-type reading is the reporter's hypothesis and is recorded
  here as one, never as step 1's design — it may well be right, and this ticket
  exists because "may well be" is not what the next three tickets can be built on.
- The container that reproduces this must be the routine-fired one. An interactive
  session measurably holds capabilities a clock-fired container does not, so a
  successful delete from a terminal proves nothing about the tick.

## Final Report

Development completed as planned. **Diagnosis only — no behaviour changed by this ticket;
`retire-claim.sh`'s output is byte-identical to before it.**

### The reproduction

Run in a **routine-fired container** (this ticket's own `[Implement]` tick, 2026-08-27), against
`work-20260818-205051` — a claim already proved `superseded` on this repository, whose pull
request reads closed and whose branch still answered `PRESENT` to `git ls-remote --heads origin`.
Both transports were attempted and both refusals captured verbatim rather than discarded.

**Transport 1 — the git push `retire-claim.sh` Act 2 actually makes:**

```
$ git push origin --delete work-20260818-205051
error: RPC failed; HTTP 403 curl 22 The requested URL returned error: 403
send-pack: unexpected disconnect while reading sideband packet
fatal: the remote end hung up unexpectedly
Everything up-to-date
(exit 1)
```

**Transport 2 — the REST ref-delete endpoint through `gh-rest.sh`:**

```
$ gh-rest.sh api repos/qmu/workaholic/git/refs/heads/work-20260818-205051 --method DELETE
{"message":"Write access to this GitHub API path is not permitted through this proxy.",
 "documentation_url":"https://docs.anthropic.com/en/docs/claude-code/github-actions"}
gh: Write access to this GitHub API path is not permitted through this proxy. (HTTP 403)
(exit 1)
```

### The classification

**Session-type refusal**, on both transports, and the two **agree**.

- **Not a protection rule.** A branch-protection refusal answers `422` and names the rule. Both
  answers are `403`, and neither names a rule.
- **Not a missing scope.** A scope refusal answers with a permissions message naming the scope.
  The REST body names *this proxy* and *this GitHub API path*, which is the execution class, not
  the token.
- **It is the delete specifically.** An ordinary `git push -u origin <branch>` succeeded in this
  same container minutes earlier (this unit's own claim push), so the credential and the transport
  both work; what is refused is the deletion.

The 2026-08-05 comment in `retire-claim.sh` — "a cloud container may PUSH but not DELETE a branch"
— was a hypothesis and is now a measurement. It was right, and the next three tickets no longer
rest on "may well be".

### Discovered Insights

- **Insight**: the refusal is enforced at the **proxy**, not at GitHub, and the two transports fail
  in different vocabularies for the same reason — git sees a bare `HTTP 403` from the CONNECT
  layer, REST sees a JSON body that names the proxy explicitly.
  **Context**: only the REST answer is diagnosable. A future reader who measures only the git push
  will see `403` and be unable to tell a session-type refusal from a protection rule or a missing
  scope — which is exactly the collapse this ticket existed to undo. Measure both, or measure REST.
- **Insight**: the GitHub connector, checked in the same container, exposes `create_branch` and
  `list_branches` and **no ref- or branch-delete tool at all**.
  **Context**: this closes ticket 3 by construction rather than by argument — there is no third
  surface to try, so the mission lands on its reporting half. Recorded here because a later session
  reaching for a `rules/shell.md`-style retry needs the enumeration, not a re-derivation.
