# Proposal Loop Runbook

How the proposal loop runs: the **`[Propose]` Claude Code Web routine**, which
fires on a fixed hourly schedule (`15 * * * *`), takes an ask — one handed to the
session, or one the tick discovered for itself (§3) — writes the feedback record,
judges it, and opens **one** pull request carrying the record together with
whatever the judgment warranted — a mission with its ticket set, one loose ticket,
one strategy, or the record alone
(`docs/loop-engineering-workflow.md` §6.3; `plugins/workaholic/skills/propose/SKILL.md`).

**That pull request merges as soon as it opens** (`WORKAHOLIC_AUTO_MERGE=1`), so
what it publishes is claimable by the next `[Implement]` tick. There is no second
seat: the session that takes the ask is the one that proposes. The human judgment
is not the merge — it is the `merge_policy` recorded on what was published (absent
reads as `review`) and the `release/*` QA window downstream. **Two** things leave
such a pull request open for a person: a release-scan finding, and any proposal
that **wrote under `.workaholic/strategies/`** (§4) — a strategy is the operator's
resolved direction, so the operator's merge is what authors it and what ends it,
and the run reports the open PR as that form's outcome rather than as a failed
merge.

**Precondition (decision I9):** the repository must be **private** wherever the
feedback stream may carry customer material (H4). Do not wire this loop on a
public repository that receives customer context.

## 1. Provision the Slack bot (once per workspace)

1. Create a Slack app, add the **`chat:write`** bot scope, install it to the
   workspace, and copy the bot token (`xoxb-…`).
2. Invite the bot to the repository's channel and note the **channel id**
   (channel details → ID, `C…`).

The bot posts proposals as itself (decision E2 — AI speech is visibly the
bot's, never a person's).

## 2. Wire the environment (per runner)

The notifier reads its config from the environment at call time — nothing is
persisted in the repository:

```sh
export SLACK_BOT_TOKEN=<your bot token>   # chat:write scope
export WORKAHOLIC_SLACK_CHANNEL=<channel id>
```

Both unset is valid: the loop runs identically and records
`{"notified": false, "reason": "no_token"}` instead of posting.

**Two notification paths, and the order between them is fixed** (`workaholic:notify`,
*The transport* — the one place that states it; the skills defer there rather than
naming a script). The **account's Slack connector is primary**: it is what a routine
session carries (its cloud container has no env file), the only surface that can run
the thread lookup, and the only one that can reply *into* a thread — so the connector
must be selected when the routine is created, and nothing in the plugin can verify
that it was. `notify-slack.sh` is the **bot-token fallback** a shell or CLI invocation
uses, configured here; it posts a **keyed root only** (its payload carries no
`thread_ts`). Reaching for the fallback from a connector-only session is how a finish
line disappears: with no token it records `{"notified": false, "reason": "no_token"}`
and exits 0 (measured 2026-08-12, issue #406 — four runs whose posts never existed).
Neither path is load-bearing: a proposal that opened its pull request is a success
whether or not anyone was told — but an unposted message is **reported as unposted**
(`/propose`'s `notified` flag, `/implement`'s per-unit notification outcome), never
left to read as sent.

## 3. Schedule the routine

The loop runs **in the repository**, in an isolated cloud session started by the
`[Propose]` routine, which fires on a **fixed hourly schedule** (`15 * * * *`;
FB `20260810085032` — the loop-engineering cadence, superseding the earlier GitHub
issue-assignment trigger). A schedule fire hands the session nothing, so the run
finds its own input: `/propose`'s *Clock-fired discovery*
(`propose/scripts/list-inbound-issues.sh`) lists the repository's open GitHub
issues **assigned to the session's own identity** (never unassigned ones, never a
title filter), oldest first, skips any a feedback record already names, and takes
each remaining issue as an inbound ask through the full run
(`skills/propose/SKILL.md`). An issue assigned to someone else is `not_mine`; an
inbox that could not be read reports its reason rather than passing for empty. The
schedule wiring is converged by `/setup-routines` on every run where a
`RemoteTrigger`-family tool is reachable, and set by hand in the routines web UI
otherwise (`skills/workaholify/SKILL.md`, *What a routine can be triggered by*). Its prompt is the shipped template
`plugins/workaholic/skills/workaholify/routines/fb.md` (template id `fb`).

Provision it from an interactive session in the repository:

```
/setup-routines          # what runs against this repo, and what is missing
/workaholify             # the same survey inside the full standards pass
```

`/setup-routines` **configures** the routines: it lists the account's routines
through a `RemoteTrigger`-family tool, diffs each against its template (name,
prompt, model, `cron_expression`, `autofix_on_pr_create`, connectors), applies the
create/update that converges them, and reports the per-routine changes. When no such
transport is reachable it reports `no_transport` and falls back to rendering a
**copy-paste setup sheet** — the name, model, repository, the prompt verbatim, and
the web-UI steps — which you then apply yourself at
<https://claude.ai/code/routines>. What still cannot be set or verified from a
session is a *repository-event* trigger: none exists, because the API's whole
trigger surface is `cron_expression` / `run_once_at` / API token.

Two things the routine needs before it can work:

- **The web bootstrap.** Each cloud session starts in a fresh container where
  `enabledPlugins` installs nothing, so without `.claude/hooks/session-start.sh`
  and its `SessionStart` entry the routine fires on time and stops at its own
  "the workaholic plugin must be loaded" precondition — looking healthy in the
  routines list while doing nothing. `/workaholify` checks this first.
- **The Slack connector and the `dev-<repo>` channel**, for the finish line the
  routine posts when it opens the pull request — and, when the stateless lookup
  finds no thread for the item, the description root it posts that line into
  (`workaholic:notify`, *The description root*).

> **Superseded (2026-08-06): "An agent never creates or re-points a routine at
> all — the plugin renders the setup sheet and manages nothing."** That reading,
> generalized 2026-08-03 from the cron rule and taken to its end on 2026-08-06,
> held that every standing outward-facing process must be brought into existence by
> the developer, in their own browser, seeing exactly what it will be. It is
> replaced by the mission `configure-routines-automatically-via-remotetrigger`:
> `/setup-routines` converges the routines itself where a `RemoteTrigger`-family
> tool is reachable (`skills/workaholify/SKILL.md` §5). The rule still stands for a
> **server crontab**, which no agent installs.

Several sessions may run at once. They coordinate through nothing, because they
share nothing: each opens its own publish tree, writes its own record, and opens
its own pull request. The only collision worth knowing about is the branch name,
which is minted per second (§5).

## 4. What one session does

1. Writes the feedback record into a publish tree (a checkout of `origin/main`),
   classifying its `kind` where the context is — **an ask is `instruction`**.
2. Reads the repository's own state from the base as a **constraint**
   (`survey-state.sh`: the missions, the todo queue, and a bounded slice of
   recent commits, with `since_reason` naming how that range was chosen).
3. Vetoes a re-ask against what existing artifacts already answer
   (`list-proposed-refs.sh`, read **before** anything is scaffolded).
4. Judges against the propose skill's conservative bar and picks the form: a
   mission with its ordered ticket set, one loose backlog ticket, one strategy,
   or the record alone. The **strategy form** (2026-08-14) needs all three parts
   present in the ask — a `YYYY-MM-DD` date, a named owner, an aim with no
   decomposable plan — and its pull request is the one proposal that does not
   auto-merge, so the operator's merge stays the act that authors the artifact.
   An ask that instead **announces something about an existing strategy** (created,
   changed, ended) is recognised before the four forms and lands only on the
   strategy it names: identification is by explicit slug, read through
   `strategy/scripts/list.sh`, and an unmatched slug is record-only naming
   `strategy_not_found` rather than a guessed match. *Ended* reaches `close.sh`,
   *changed* is record-only (there is no third writer), and any strategy-touching
   pull request stays un-auto-merged.
5. Publishes everything in **one** `publish-tree-pr.sh` call, then posts the
   `🔵 Proposed` finish line into the item's thread — preceded by a description
   root when the lookup found none, which is the only case that sends two
   messages.

**Record-only is a judgment, not a mechanism.** The session can always see the
record — it wrote it — so an empty proposal means "this ask warrants no work",
and the pull request says why. That distinction is the whole point of §6's
history.

## 5. Observability

- **Proposals** are pull requests titled `[Proposal] …` (set via
  `WORKAHOLIC_PR_TITLE`), carrying `Closes #<N>` when the ask came from an issue.
  They are the loop's ledger, and they are normally **already merged** — a
  *still-open* one is the exception worth looking at, because a release-scan
  finding is what holds it open. Read them over REST
  (`gather/scripts/gh-rest.sh api 'repos/<slug>/pulls?state=all'`) rather than
  `gh pr list`, which is GraphQL-backed and may 403 in a web session.
- **Record-only** pull requests carry the record alone and are just as normal an
  outcome; they merge the same way.
- **The channel is the liveness signal.** Every session that opens a pull
  request posts its one finish line into the feedback item's thread in
  `dev-<repo>`, keying a new root when no thread matches. A reported ask with no
  post and no PR is the thing to investigate — most often the web bootstrap (§6).
- **Notifications** — a run records `notified`. A failed post never fails the
  run.

## 6. Failure modes

| Symptom | Cause | Fix |
| ------- | ----- | --- |
| the routine fires but does nothing | the web bootstrap is missing, so the workaholic plugin is not loaded in the container | run `/workaholify` and install `.claude/hooks/session-start.sh` + its `SessionStart` entry |
| `{"reason": "no_token"}` on a CLI run | env file missing/unsourced | check the `. …/.workaholic-proposal.env` prefix and file perms (the routine uses the Slack connector instead, §2) |
| `{"reason": "slack_token_revoked"}` / `slack_invalid_auth` | token rotated/revoked | reissue the bot token, update the env file |
| `{"reason": "slack_channel_not_found"}` / `slack_not_in_channel` | channel archived or bot not invited | re-invite the bot / fix `WORKAHOLIC_SLACK_CHANNEL` |
| `{"ok": false, "reason": "branch_collision"}` | two publications in the same second; the remote branch name is minted per second | the commit is already made in the publish tree — push it to a fresh `work-*` branch and open the PR by hand; a re-call reports `nothing_to_commit` rather than retrying |
| `{"ok": false, "reason": "pr_failed"}` | the push landed, `gh` could not open the PR | open the pull request by hand on the reported branch — never re-publish, which duplicates the artifact |
| the same ask proposed twice | the first proposal's `feedback:` refs were removed, so the dedup set has nothing to key on | restore the refs; the set is the only dedup mechanism at this seam |

## 7. History: the batch seat and the merged-main window (retired 2026-08-04)

Retired the day it shipped, by the developer's ruling
(`.workaholic/feedbacks/20260804221328-propose-at-the-capture-seam-not-from-a-merged-main-window.md`).

For part of one day the loop had a **second seat**: a `[Propose Batch]` cron
template running `/propose` every 15 minutes over the feedback records merged to
`main` since a shared cursor — the pushed ref `refs/workaholic/proposal-cursor`,
advanced under `--force-with-lease` so overlapping runners resolved by push
rather than by clock. Before it, decision C1 had prescribed a server crontab that
was deliberately a human act to install and so was never installed anywhere.

The reason it existed is the reason it was removed: `/propose` read only feedback
**already merged to `main`**, so the record the capture session had just written
was invisible to it *by construction* — and a sweeper had to exist to pick that
record up later. The window was a defect, and the batch was its compensation.
Folding the judgment into the capture session removes both, and makes
"record-only" mean a judgment rather than a blindness.

**Operator cleanup.** The ref and the legacy file are not deleted by this change,
because deleting a shared ref is an operator's act:

```sh
git push origin :refs/workaholic/proposal-cursor    # if today's runs created it
rm -f .workaholic/proposal-cursor                   # a legacy runner-local file, git-ignored
```

Neither is read by anything any more, so leaving them costs only confusion.

The knowledge those two days produced is kept, not deleted: push-as-arbiter over
a shared ref is recorded in the superseded story and in the ruling above, and
remains the pattern the claim protocol uses.
