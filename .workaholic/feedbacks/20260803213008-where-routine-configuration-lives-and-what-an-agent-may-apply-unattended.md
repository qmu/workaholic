---
type: Feedback
title: Where routine configuration lives and what an agent may apply unattended
kind: insight
source: discussion
created_at: 2026-08-03T21:30:08+09:00
author: a@qmu.jp
supersedes: 
---

# Where routine configuration lives and what an agent may apply unattended

Two decisions the routine mission turns on. They are recorded together because each one
determines what the other can mean: where the configuration lives decides what "applying it"
even is.

## 1. Where routine configuration lives

**Decision.** Three places, one kind of fact each, and the repository declares nothing new.

- The **plugin** owns what a routine *should* be — `skills/workaholify/routines/*.md`, one set
  of templates applied to every repository. Unchanged.
- The **account** owns what a routine *is* — the live routine, reachable only through
  `RemoteTrigger`. It is the source of truth for the running fleet, and `list` reads it back.
- The **repository** owns *nothing new*. Every per-repository fact a routine needs — `{repo}`,
  `{repo_slug}`, `{repo_name}` — is already derivable from the checkout's own git remote. There
  is no third fact left to declare, so a declaration file could only hold a copy of what the
  account already knows.

This resolves the tension with `workaholify`'s one-template-set rule by **agreeing with it**.
The mission asked to make routines "a configurable, inspectable part of a repository"; the half
that was actually missing is *inspectable*. A developer could not answer "what runs against this
repo" — not because the repository lacked a config file, but because nothing read the account
back to them. So the answer is a reader, not a directory: `/setup-routines` asks the account and
reports, live, or says plainly that it could not look.

**No `.workaholic/` area is introduced**, and therefore no closed-layout amendment is needed.

**Rejected alternatives, and why.**

- *Per-repository declarations (`.workaholic/routines/<id>.md`).* One copy per repository of a
  file that is byte-identical everywhere except its own URL, each free to drift, none of them
  authoritative — the account still decides what runs. This is exactly the design `workaholify`
  refused, and nothing measured since has changed the fact it rests on.
- *A selection manifest (`.workaholic/routines.yml`) naming which templates this repo wants.*
  The one genuinely per-repository fact, and the closest call. Rejected on evidence: the
  selection is uniform across the fleet today except for `[Drive]`, which is still a pilot, so a
  manifest would freeze an unsettled pilot into repository-level policy. The survey already
  reports what is `missing` without anyone declaring it. If a repository ever legitimately must
  *never* carry a template, that is the moment to amend the layout — by decision, not by mkdir.
- *A committed snapshot of the live routines, so the repository reads offline.* A snapshot goes
  stale silently, and a stale snapshot that reads as healthy is the precise failure the web
  bootstrap check exists to catch. Reporting "could not check" is worth more than answering from
  a cache.

## 2. What an agent may apply unattended

**Decision.** The boundary is read/write, not command/command.

- **Reading is unattended-safe.** Listing, rendering, comparing, and reporting drift may run in
  any session, including `/drive` and a cloud routine. They reach nothing and change nothing.
- **Every mutation needs a human looking at the exact body.** Create, refresh, and remove are
  confirmed verbatim, one routine at a time, in an interactive session. Never batched into one
  yes, never inferred from a drift report, never performed by an unattended run.

**Reconciliation with the runbooks.** Both loop runbooks say "do not install the crontab from an
agent session — applying a standing outward-facing process is the developer's act". That rule
survives intact; the crontab was incidental to it. Generalized: *an agent may not bring a
standing outward-facing process into existence, or re-point one, without a human seeing exactly
what it will be.* What changes is only the sanctioned path — the confirmation is now mediated by
a script instead of being done entirely by hand, which makes it checkable rather than merely
instructed.

**Enforced in code, not in prose.** The confirmation is a digest gate: the planner renders the
exact content a routine will carry and emits its digest; the authorizer re-derives that digest
from the body about to be sent and refuses on any mismatch. An agent that skipped the
confirmation has no matching digest to present, and a "yes" to one body cannot authorize
another. The digest deliberately covers what a human can verify by eye — action, target
repository, name, trigger, schedule, model, enabled state, and the full prompt — and not the
account plumbing (environment id, connector uuid) that nobody reads.

**"Remove" means disable.** The routines API has no delete. Removal is therefore an update
setting `enabled: false`, reported as such, together with the fact that permanent deletion is a
human act at <https://claude.ai/code/routines>. Silently doing nothing is not an option, and
neither is pretending a routine is gone.
