---
name: prepare-release
description: Report what is waiting to deploy on the base right now, per deployment target, what about it needs a human, and where each target's draft release note stands. It writes nothing into the repository - no file, no commit, no branch, no pull request, no merge, no deployment - and nothing outside it either: the draft release is written by the Release Note Draft workflow.
skills:
  - workaholic:ship
  - workaholic:notify
---

# Prepare Release

Run the preloaded `workaholic:ship` skill's §7 **Release status** section end to end. One behaviour, no argument, no `AskUserQuestion` at any step: read the deploy state against the base (`report-deploy-status.sh`), report each target's draft-note state (`run-note-cadence.sh`, called **without** `--write`), and — when a Slack surface is available and **both** the digest and the day token are genuinely new — post the one status line `workaholic:notify` defines for it.

**The post is bounded to once per `Asia/Tokyo` day per distinct ask** (2026-08-18, ticket `20260818214615`): measured, the tick posted nine times in nine consecutive hours for one request, because `unreleased_count` moves the digest whenever a commit lands. The `deploy-day:<day_token>` search is the second gate; `deploy:<digest>` is unchanged in derivation and format, and a **new kind** of ask still posts the same hour (`workaholic:ship` §7, *The rate the digest did not bound*).

**It writes nothing into the repository**: it creates no file, commits nothing, branches nothing, opens no pull request, merges nothing and deploys nothing — the property the routine's `allowed_tools` states by carrying no `Write`/`Edit`, and it is not conditional. **A network *read* is permitted, and since 2026-08-18 one is made**: `report-deploy-status.sh` freshens the base branch and tags before deriving the boundary from them (bounded, best-effort, `WORKAHOLIC_DEPLOY_FETCH_TIMEOUT=0` opts out), because otherwise the count came from whatever refs the container happened to hold — measured, one unchanged repository reported 2721, then 2950, then the true 4 as refs were fetched, with the `deploy:<digest>` moving each time. That fetch touches `refs/remotes/*` and `refs/tags/*` and nothing else: no file, no index entry, no commit. When it cannot run, the read says so (`refs: stale|skipped`) and a boundary that stale refs collapsed to is reported `doubtful` — and the line posts the degradation with the **count withheld** rather than a number the read has just flagged. Since 2026-08-18 it writes nothing **outside** the repository either. The per-target **draft release** is written by the `Release Note Draft` workflow, never by this command: a routine's container cannot write a release by any transport (`gh release` is refused as GraphQL, and REST answers *"Creating, editing, or deleting releases is not permitted for this session type"*), so the capability lives in CI, which already publishes this repository's releases. The 2026-08-17 sentence that this tick maintains the draft was **true when written and is now wrong**; it is corrected here rather than left standing. §7's three refusals are unaffected: CI commits nothing to `main`, writes no open pull request's branch, and never runs `/ship`. A tick with nothing new writes nothing and posts nothing.

**It is the repository's routine, not a developer's**: `[Prepare Release]` carries `scope: repository` and is configured by `/setup-repo-routines` from one account, because N copies would post the same line N times an hour into the same thread.

**On the name** (renamed from `/fullfill`, 2026-08-18, issue #485 — which was itself renamed
from `/release-status` a day earlier): the name says what the command does. It prepares a
release — it reads what has landed on the base and not yet reached a target, and keeps each
target's draft note current so a human can cut one. **This supersedes the one-word command
convention** that produced `/fullfill` on 2026-08-17, and that convention is not the project's
stated naming rule any more: `/setup-dev-routines`, `/setup-repo-routines` and `/mission-close`
were already multi-word, and with this rename nothing is left holding the line. Behaviour did
not move under either rename — the command is still a pure reader.

**This is the second rename of the same command in two days**, and the cost is paid by every
operator who has the routine configured. Unlike 2026-08-17, the routine record moved with the
command this time, so a one-time cutover is owed to anyone already running the old one:
`/setup-repo-routines` and its setup sheet state it (`skills/workaholify/routines/prepare-release.md`).

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
