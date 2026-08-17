---
type: Feedback
title: Add a standup daily per-strategy status summary routine
kind: instruction
source: discussion
subject: observer_ai:claude[bot]
created_at: 2026-08-17T11:51:47+00:00
author: a@qmu.jp
supersedes: 
---

# Add a standup daily per-strategy status summary routine

The ask: add a `/standup` routine command, configured as part of `/setup-repo-routines`,
running daily at 09:00 (the repository's working timezone, or UTC if unspecified — the ask
itself says to clarify with the requester if needed), that summarises recent development
status and progress **per strategy** in the repository. For each strategy tracked in the
repo it should surface a concise summary of relevant recent activity — commits, pull
requests, changes — so stakeholders get a daily pulse without digging through history.

Two facts about the current repository decide how much of this is buildable and in what
order, and neither is a reason to decline the ask:

- **Nothing links work to a strategy.** The `strategy:` relation on a mission and the
  ownership hop it fed were deliberately **not** revived when the strategy artifact
  returned on 2026-08-13 (`workaholic:mission`, *What did not return*): a mission's owner is
  on the mission, a strategy's owner is on the strategy, and a legacy `strategy:` key in an
  old artifact is tolerated history "read by nothing". `/drive` never surveys strategies,
  and the only citation the artifact carries runs **strategy → feedback**, one way. So a
  per-strategy summary has no data path today, and building one means either reviving a
  relation that was removed on purpose or deriving attribution some other way. That is the
  first thing to settle, not an implementation detail.
- **The repository holds zero strategies** (`strategy/scripts/list.sh` → `{"count": 0}`), so
  the routine is a no-op on the day it ships and stays one until the operator authors a
  strategy. Worth knowing before it is measured as broken.

Two mechanical constraints on the schedule as stated: the routines API rewrites a bare `:00`
minute to server jitter, so "09:00" has to be expressed with an explicit non-zero minute;
and the container's clock is UTC while the workspace's timezone is `Asia/Tokyo`, so "daily
at 09:00" is ambiguous by roughly a working day until the timezone is fixed — which is the
clarification the ask itself flags.

The scope named — `/setup-repo-routines` — is the right one and is worth stating as
deliberate: a per-strategy summary describes the repository, not a developer, so N copies
would post the same digest N times each morning. `[Release Status]` is the existing
precedent for a repository-scoped, read-only tick.

Source: https://github.com/qmu/workaholic/issues/473
