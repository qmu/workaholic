---
created_at: 2026-08-17T11:37:51+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260817113750-add-the-housekeep-command-and-skill.md
mission: add-the-housekeep-hourly-operations-routine
merge_policy:
verification_handoff: 
---

# Implement the inbound sweep steps

## Overview

Steps 2 and 3 of the ask: check Gmail, Google Drive, Slack and GitHub for updates, and
check workload logs on any environment whose credentials are available; where something
matters, reflect it into the repository as a GitHub issue through `/fb`.

The filing path already exists and must be reused rather than reinvented: `/fb` registers
an immutable record, and its **cross-repository mode** is the only sanctioned way to open
an issue elsewhere — behind a verbatim human confirmation, which an unattended tick cannot
give. For this repository, the honest analogue of "file it" is a **feedback record**, which
`[Propose]`'s next tick then judges. The two must not be conflated, and this ticket has to
pick one; see Open Decisions.

## Policies

- `workaholic:safety` / `policies/information-security.md` — reading a mailbox and a drive pulls content of unknown sensitivity into a repository
- `workaholic:design` / `policies/data-handling.md` — what may be recorded, and at what granularity
- `workaholic:operation` / `policies/observability.md` — a skipped connector is reported, never silently empty

## Key Files

- `plugins/workaholic/skills/housekeep/SKILL.md` and its `reference/workflow.md` — steps 2
  and 3's contract.
- `plugins/workaholic/skills/feedback/scripts/create.sh` — the only sanctioned writer of a
  record; `--subject` is **mandatory and never defaulted to the runner**. A finding the
  tick observed itself is `observer_ai:<identity>`; a message a person wrote is
  `person:<them>`.
- `plugins/workaholic/skills/feedback/scripts/open-issue.sh` and the crossing flow in
  `feedback/SKILL.md` — the confirmation-gated path this tick may not take unattended.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the GitHub half of the sweep.
- `plugins/workaholic/skills/notify/SKILL.md` — the Slack half: **exact-string search only,
  at most two queries per lookup, no full-channel read at any point.** A sweep that reads
  channel history breaks that bound.
- `plugins/workaholic/hooks/guard-repo-confinement.sh` — every write lands inside this
  repository; the crossing is the one exception.

## Implementation Steps

1. Enumerate the surfaces the session actually has: the Slack connector, `gh-rest.sh`, and
   whatever Gmail/Drive connector the account carries. **Probe, never assume** — a missing
   connector is reported by name (`no_surface: gmail`), which is not the same answer as
   "nothing new".
2. For each available surface, read only what is bounded: for Slack, exact-string searches
   under the two-query bound, never channel history; for GitHub, the repository-scoped REST
   endpoints (a bound session is refused `search/*`, so filter locally).
3. Apply a **materiality bar** before recording anything — the feedback skill's own
   *Whether this merits filing*: a genuine problem or improvement idea, or something that
   must not be overlooked. A passing remark is not filed. Without this the tick fills the
   stream with plausible noise every hour.
4. Record what passes the bar through `create.sh` with a truthful `subject`, and let
   `[Propose]`'s next tick judge it — or take the Open Decision's other branch.
5. Log per surface: probed, read, filed, skipped-with-reason.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Each surface is probed and its outcome reported by name; an unavailable surface is never
  reported as empty.
- No Slack full-channel read; at most the documented number of exact-string queries.
- Nothing is written outside this repository without the crossing flow's human
  confirmation.
- Every record written carries a non-runner `subject`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A dry run with each connector deliberately absent — the report names each as
  `no_surface`, and the run still completes.
- `bash plugins/workaholic/hooks/layout-doctor.sh .`

**Gate** — what must pass before approval:

- The Open Decisions resolved and recorded in the Final Report.

## Open Decisions

1. **Record, or issue?** The ask says "reflect the changes into the repository via GitHub
   Issues using `/fb`". On *this* repository `/fb` writes a record, not an issue; opening an
   issue is the cross-repository mode and it is gated on a verbatim human confirmation an
   unattended tick cannot give. There is a second, measured reason not to auto-file an
   assigned issue here: `list-inbound-issues.sh` excludes issues a feedback record already
   names, and a record written *before* the issue can never name it — so a self-filed
   assigned issue is re-discovered by `[Propose]` every tick, forever (this is exactly why
   issue #443's auto-file option was ruled out on 2026-08-14). Decide: write records, or
   widen the crossing's confirmation rule for self-directed issues.
2. **How much of a mailbox may a repository's log quote?** Step 2 reads Gmail and Drive.
   Any excerpt written into `.workaholic/` is committed to a repository whose history is
   durable and whose leak scan matches only a hand-maintained denylist — a `pass` there
   never means "no sensitive content". Decide the quoting rule (pointer-only, subject-line
   only, or full excerpt) before the first tick reads a mailbox.

## Considerations

- Gmail and Google Drive connectors are not part of this plugin and may be absent for every
  developer; the step must be a clean no-op then, not a failure.
- The materiality bar is where this step either earns its place or becomes the "channel
  full of plausible noise" the propose bar already warns about. Prefer under-filing.
