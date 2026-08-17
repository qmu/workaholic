---
created_at: 2026-08-17T11:37:51+00:00
status: done
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

## Final Report

Development completed as planned. Both Open Decisions were resolved before any code was
written, and both are recorded in `reference/workflow.md` where the next reader meets them:

1. **Record, or issue? — Records.** The tick writes **feedback records** and files no GitHub
   issue. Two reasons, and the second is the decisive one: the crossing flow is gated on a
   verbatim human confirmation an unattended tick cannot give; and a self-filed *assigned*
   issue would be re-discovered by `[Propose]` every hour **forever**, because
   `list-inbound-issues.sh` excludes only issues a feedback record already names and a record
   written before the issue can never name it. That is the same reasoning that refused issue
   #443's auto-file option on 2026-08-14, so the crossing's confirmation rule is left exactly
   where it is rather than widened for self-directed issues.
2. **How much of a mailbox may the repository quote? — Pointer and subject line only.** A
   candidate carries its surface, a stable identifier or permalink, and the title/subject as
   written. Never a message body, an attachment, or a Drive file's contents. `.workaholic/`
   history is durable and the leak scan matches only a hand-maintained denylist, so a `pass`
   there never means "no sensitive content"; a pointer leaves the content behind its own
   access controls, where the person who can read it decides what to quote.

One decision the ticket did not anticipate, made and recorded here: **step 3 executes
nothing.** A deployment record already carries executable prose and `/ship` runs it only on
the developer's instruction (§5-D); an hourly unattended tick that executed a
repository-declared command would move that boundary quietly. The step resolves which targets
are readable *here* — through the new optional, non-secret `log_locator:` and
`log_credential_env:` frontmatter — and hands them to the agent. A test asserts a record's
`command:` is never executed by the tick.

### Discovered Insights

- **Insight**: Of the four surfaces the ask names, exactly one (GitHub) is reachable from a
  shell script; Slack, Gmail and Drive are connectors held by the *session*.
  **Context**: This is why the step returns `probe_connector` entries carrying each surface's
  bound rather than pretending to probe them. It also means the acceptance criterion that
  matters is structural — every surface has a *stated outcome* in the report — rather than
  behavioural, and that is what the test pins.

- **Insight**: The sweep window is derived from the tick log (the previous tick that recorded
  an `inbound-sweep` line), never from clock arithmetic.
  **Context**: `date -d` is GNU-only and `date -v` BSD-only, so any "an hour ago" computation
  behaves differently on the developer's laptop and in the routine's container. The tick id is
  already `YYYYMMDD-HHMMSS`, so converting it to the REST `since` parameter is string surgery —
  and it makes the log the memory for the window as well as for the dedup.

- **Insight**: A skill's scripts must sit exactly one directory below the skill. The build's
  cross-skill reference form is `${SCRIPT_DIR}/../../<skill>/scripts/`, and `verify.mjs` fails
  any reference that is not in it.
  **Context**: The step scripts started in `scripts/steps/` and had to be flattened to
  `scripts/step-<slug>.sh`. The failure the guard prevents is not cosmetic: a deeper reference
  passes a naive read but is invisible to `build.mjs`'s closure detection, which would ship a
  bundle whose scripts are missing rather than fail the build.
