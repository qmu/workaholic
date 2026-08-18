---
name: prepare-release
description: Report what is waiting to deploy on the base right now, per deployment target, and what about it needs a human, and keep each target's draft release note current. It writes nothing into the repository - no file, no commit, no branch, no pull request, no merge, no deployment.
skills:
  - workaholic:ship
  - workaholic:notify
---

# Prepare Release

Run the preloaded `workaholic:ship` skill's §7 **Release status** section end to end. One behaviour, no argument, no `AskUserQuestion` at any step: read the deploy state against the base (`report-deploy-status.sh`), refresh each target's draft note (`run-note-cadence.sh` — bounded to once per `Asia/Tokyo` day, and immediately whenever the release stage advances), report both, and — when a Slack surface is available and the digest is genuinely new — post the one status line `workaholic:notify` defines for it.

**It writes nothing into the repository**: it creates no file, commits nothing, branches nothing, opens no pull request, merges nothing and deploys nothing — the property the routine's `allowed_tools` states by carrying no `Write`/`Edit`, and it is not conditional. Since 2026-08-17 the tick *does* maintain one artifact, and it is deliberately outside git: the per-target **GitHub draft release**, which is invisible to consumers and free to rewrite (`workaholic:ship`, *The two copies, and which one is authoritative*). That is what dissolves the first of §7's three refusals — a draft that is never a commit cannot count itself — while the other two stand untouched: no open pull request's branch is written, and `/ship` is never run. A tick with nothing new writes nothing and posts nothing.

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
