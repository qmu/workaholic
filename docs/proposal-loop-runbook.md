# Proposal Loop Runbook

How to stand up the 15-minute proposal loop: the **`[Propose]` Claude Code Web
routine** that runs `/propose` headlessly, so feedback merged to `main` becomes
proposed missions behind pull requests, announced in Slack
(`docs/loop-engineering-workflow.md` §6.3).

**Cron was the retired predecessor.** Decision C1 said "server cron first,
Claude Code Web later"; the *later* arrived and the crontab never did. It was
deliberately a human act to install, so it was never installed anywhere, and the
loop had no runner at all — the only place `/propose` ran was inside the `[FB]`
routine's session, where the record it had just written was still on an unmerged
branch and invisible to its own window by design. The cron shape below is kept
only as history; the live deployment is the routine.

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
`{"notified": false, "reason": "no_token"}` per proposal instead of posting.

**Two notification paths, and they do not overlap.** `notify-slack.sh` is the
bot-token path a shell or CLI invocation uses, configured here. The `[Propose]`
routine posts through the **account's Slack connector** instead — its cloud
container carries no env file — so a routine that lacks that connector is
reported as drift by `compare-routines.sh`. Neither path is load-bearing: a
proposal that opened its pull request is a success whether or not anyone was
told.

## 3. Schedule the routine (every 15 minutes)

The batch runs **in the repository, on `main`**, in an isolated cloud session
started by the `[Propose]` routine. The routine's prompt is the shipped template
`plugins/workaholic/skills/workaholify/routines/propose.md`; its cadence is that
template's `cron_expression` (`*/15 * * * *`), which is where you change it.

Provision it from an interactive session in the repository:

```
/setup-routines          # what runs against this repo, and what is missing
/workaholify             # the same survey inside the full standards pass
```

Either command renders the template, shows you the **full prompt and schedule**,
and creates the routine only after you confirm that exact content — one routine
at a time, never batched. That bar is enforced in code
(`plan-routine-change.sh` stamps a `confirm_digest`;
`authorize-routine-change.sh` refuses a tampered plan or a mismatched digest),
because a routine is a standing outward-facing process acting on the repository
unattended.

Two things the routine needs before it can work:

- **The web bootstrap.** Each cloud session starts in a fresh container where
  `enabledPlugins` installs nothing, so without `.claude/hooks/session-start.sh`
  and its `SessionStart` entry the routine fires on time and stops at its own
  "the workaholic plugin must be loaded" precondition — looking healthy in the
  routines list while doing nothing. `/workaholify` checks this first.
- **The Slack connector and the `dev-<repo>` channel**, for the one post the
  routine makes when it opens a proposal.

**An agent never creates or re-points a routine on its own** (generalized
2026-08-03 from the cron rule): it reads freely, and every create, refresh or
removal is confirmed verbatim by a human, one routine at a time
(`skills/workaholify/SKILL.md` §5). An unattended run cannot do it at all.

Several runners are now safe — the cursor is a shared pushed ref advanced under
`--force-with-lease`, so overlapping ticks resolve by push (§4). Decision C1's
"one runner per repository" constraint went with the runner-local cursor.

### The retired cron shape (history)

```cron
*/15 * * * * . "$HOME/.workaholic-proposal.env" && claude -p "/propose" --cwd /path/to/repo >> "$HOME/.workaholic-proposal.log" 2>&1
```

Kept for the record only. If you ever run the batch this way, the env file holds
the token at `0600` and never the crontab line itself — but prefer the routine:
a machine's crontab is invisible to everyone but its owner, which is the problem
routines replace rather than a mechanism to copy.

## 4. Cursor bootstrap and replay

The cursor is the **pushed ref `refs/workaholic/proposal-cursor` on origin** —
shared by every runner, invisible to branch listings and to the claim scan (it
lives outside `refs/heads/`), and read through a local ref of the same name.

- **Cold start** — the first `read` in the *repository's* life creates the ref
  at the current `origin/main` tip and pushes it, reporting
  `initialized: true`. Pre-existing feedback is treated as already-seen, which
  is deliberate: a fresh runner must not spam proposals for months of history.
  Every later read — including the first read of a brand-new container — finds
  the ref and reports `initialized: false`. Initialization is **once per
  repository**, never once per runner.
- **Replay** — `git push --force origin <older-sha>:refs/workaholic/proposal-cursor`
  re-opens a window. It is a **human act** and stays unscripted; dedup
  (`feedback:` refs on existing missions and proposed tickets) keeps a replay
  from double-proposing.
- **Advance is race-arbited by push** — `advance` pushes under
  `--force-with-lease` against the value the batch read, so two runners that
  overlap resolve by push and never by clock. The loser reports
  `{"advanced": false, "reason": "raced"}` and does nothing; the winner already
  covered that window.
- **The cursor advances only after a successful push** — an aborted run
  (dirty tree, diverged main, rejected push) re-reads the same window next
  tick, so no feedback is ever silently skipped. An unreachable origin degrades
  the *read* (`fetched: false`, last-known value) and fails the *advance*
  loudly, which is the same asymmetry the claim protocol uses.
- **Migration** — a legacy runner-local `.workaholic/proposal-cursor` file is
  folded into the ref on the next `read` (it seeds the bootstrap when the ref
  is absent) and then removed. Nothing needs to be done by hand.

## 5. Observability

- **Proposals** are open pull requests titled `Propose mission <slug>` —
  `gh pr list --search 'Propose mission'` is the loop's ledger, and each one is
  waiting on a human, since merging it *is* the approval.
- **Silence** is normal. Each session's own report records the window size and
  the reason, and posts nothing to Slack.
- **The cursor is the liveness signal.** `git ls-remote origin
  refs/workaholic/proposal-cursor` moving forward means ticks are running;
  a value that has not moved while feedback has merged is the thing to
  investigate.
- **Notifications** — a run records `notified` per proposal. The routine's own
  posts land in `dev-<repo>`; a quiet channel plus a moving cursor means the
  batch is working and judging to silence, which is the expected steady state.

## 6. Failure modes

| Symptom | Cause | Fix |
| ------- | ----- | --- |
| the routine fires but does nothing, every tick | the web bootstrap is missing, so the workaholic plugin is not loaded in the container | run `/workaholify` and install `.claude/hooks/session-start.sh` + its `SessionStart` entry |
| `{"reason": "no_token"}` on a CLI run | env file missing/unsourced | check the `. …/.workaholic-proposal.env` prefix and file perms (the routine uses the Slack connector instead, §2) |
| `{"reason": "slack_token_revoked"}` / `slack_invalid_auth` | token rotated/revoked | reissue the bot token, update the env file |
| `{"reason": "slack_channel_not_found"}` / `slack_not_in_channel` | channel archived or bot not invited | re-invite the bot / fix `WORKAHOLIC_SLACK_CHANNEL` |
| run aborts `"dirty_workspace"` / `"diverged"` | the checkout was used for other work | `git status` / reconcile by hand — never let the batch clean it |
| `{"advanced": false, "reason": "raced"}` | another runner advanced the cursor first | nothing to do; the winner covered that window |
| `{"advanced": false, "reason": "push_failed"}` | origin unreachable, or no write access to the cursor ref | fix access; the cursor deliberately did not advance, so the window is re-read next tick |
| run aborts on push, repeats next tick | branch protection or a race | resolve by hand; the cursor deliberately did not advance |
| same feedback proposed twice | the cursor was force-pushed backwards **and** the first proposal's `feedback:` refs were removed | dedup needs either the cursor or the refs; restore one |
