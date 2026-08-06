# Proposal Loop Runbook

How the proposal loop runs: the **`[Propose]` Claude Code Web routine**, which
fires on an inbound report, writes the feedback record, judges it, and opens
**one** pull request carrying the record together with whatever the judgment
warranted — a mission with its ticket set, one loose ticket, or the record alone
(`docs/loop-engineering-workflow.md` §6.3; `plugins/workaholic/skills/propose/SKILL.md`).

**Merging that pull request approves both halves.** There is no second approval
step and no second seat: the session that receives the ask is the one that
proposes.

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

**Two notification paths, and they do not overlap.** `notify-slack.sh` is the
bot-token path a shell or CLI invocation uses, configured here. The `[Propose]`
routine posts the item's **thread root** through the **account's Slack
connector** instead — its cloud container carries no env file — so the connector
must be selected when the routine is created, and nothing in the plugin can
verify that it was. Neither path is load-bearing: a proposal that opened its pull request is a success whether or
not anyone was told.

## 3. Schedule the routine

The loop runs **in the repository**, in an isolated cloud session started by the
`[Propose]` routine, which fires on a **GitHub event**: an issue assigned to the developer
being opened. That wiring is configured in the routines web UI and **nowhere else** — the
record carries no event field, so it can be neither read nor set from a session
(`skills/workaholify/SKILL.md`, *What a routine can be triggered by*). It runs on the
inbound report, which is also the moment its judgment has the most context available.
Its prompt is the shipped template
`plugins/workaholic/skills/workaholify/routines/fb.md` (template id `fb`).

Provision it from an interactive session in the repository:

```
/setup-routines          # what runs against this repo, and what is missing
/workaholify             # the same survey inside the full standards pass
```

Either command renders a **copy-paste setup sheet** — the name, model, repository,
the prompt verbatim, and the web-UI steps for the trigger — and you create the
routine yourself at <https://claude.ai/code/routines>. The plugin does not create
it: a routine's GitHub trigger is configurable in the web UI only, and the API
record carries no event field, so the wiring can be neither set nor verified from
a session.

Two things the routine needs before it can work:

- **The web bootstrap.** Each cloud session starts in a fresh container where
  `enabledPlugins` installs nothing, so without `.claude/hooks/session-start.sh`
  and its `SessionStart` entry the routine fires on time and stops at its own
  "the workaholic plugin must be loaded" precondition — looking healthy in the
  routines list while doing nothing. `/workaholify` checks this first.
- **The Slack connector and the `dev-<repo>` channel**, for the thread root the
  routine posts when it opens the pull request.

**An agent never creates or re-points a routine on its own** (generalized
2026-08-03 from the cron rule): it reads freely, and every create, refresh or
removal is confirmed verbatim by a human, one routine at a time
(`skills/workaholify/SKILL.md` §5). An unattended run cannot do it at all.

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
   mission with its ordered ticket set, one loose backlog ticket, or the record
   alone.
5. Publishes everything in **one** `publish-tree-pr.sh` call and posts the
   thread root.

**Record-only is a judgment, not a mechanism.** The session can always see the
record — it wrote it — so an empty proposal means "this ask warrants no work",
and the pull request says why. That distinction is the whole point of §6's
history.

## 5. Observability

- **Proposals** are open pull requests titled `Propose mission <slug>` /
  `Propose ticket <slug>`; `gh pr list --search 'Propose'` is the loop's ledger,
  and each one is waiting on a human, since merging it *is* the approval.
- **Record-only** pull requests carry the record alone and are just as normal an
  outcome; they merge the same way.
- **The channel is the liveness signal.** Every session that opens a pull
  request posts a thread root to `dev-<repo>`. A reported ask with no root and no
  PR is the thing to investigate — most often the web bootstrap (§6).
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
