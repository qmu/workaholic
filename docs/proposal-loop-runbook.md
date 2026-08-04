# Proposal Loop Runbook

How to stand up the 15-minute proposal loop on a server: the cron that runs
`/propose` headlessly so feedback merged to main becomes draft-mission proposals
announced in Slack (`docs/loop-engineering-workflow.md` §6.3; decision C1 —
server cron first, Claude Code Web later; G4's "Drive Every 5 Minutes" is the
phase-3 sibling for execution).

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

## 3. The cron entry (every 15 minutes)

The batch runs **in the repository, on `main`**, via headless claude invoking
the `/propose` command. A working shape (adjust the claude invocation to the
installed CLI):

```cron
*/15 * * * * . "$HOME/.workaholic-proposal.env" && claude -p "/propose" --cwd /path/to/repo >> "$HOME/.workaholic-proposal.log" 2>&1
```

- Keep the token in a `0600` env file (`~/.workaholic-proposal.env` with the
  two exports above), never in the crontab line itself.
- One runner per repository (decision C1): the cursor is **runner-local**
  state, and multi-runner coordination is deliberately the phase-3 claim
  protocol's job — do not point two crons at one repo.
- Do not install the crontab from an agent session — applying a standing
  outward-facing process is the developer's act; this page is the instruction.
  The rule generalized beyond cron on 2026-08-03: an agent may not bring a
  standing outward-facing process into existence, or re-point one, without a
  human seeing exactly what it will be. `/setup-routines` schedules Claude Code
  Web routines under that same bar — it reads freely, and every create, refresh
  or removal is confirmed verbatim, one routine at a time, in an interactive
  session (`skills/workaholify/SKILL.md` §5).

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

- **Proposals** are `Propose mission <slug>` commits on `main` — `git log
  --oneline --grep='^Propose mission'` is the loop's ledger.
- **Silence** is normal and logged by the run report in the cron log (window
  size + reason).
- **Notifications** — each run report records `notified` per draft; grep the
  cron log for `"notified": false` to spot a broken token before anyone
  wonders why Slack went quiet.
- The drafts themselves appear in the bare `/mission` roadmap with
  `ready_reason: "draft"` — awaiting approval, invisible to executors.

## 6. Failure modes

| Symptom | Cause | Fix |
| ------- | ----- | --- |
| `{"reason": "no_token"}` on every run | env file missing/unsourced in cron | check the `. …/.workaholic-proposal.env` prefix and file perms |
| `{"reason": "slack_token_revoked"}` / `slack_invalid_auth` | token rotated/revoked | reissue the bot token, update the env file |
| `{"reason": "slack_channel_not_found"}` / `slack_not_in_channel` | channel archived or bot not invited | re-invite the bot / fix `WORKAHOLIC_SLACK_CHANNEL` |
| run aborts `"dirty_workspace"` / `"diverged"` | the runner checkout was used for other work | keep the runner checkout dedicated; `git status` / reconcile by hand |
| run aborts on push, repeats next tick | branch protection or race on main | resolve by hand; the cursor deliberately did not advance |
| same feedback proposed twice | cursor file deleted **and** the first draft's `feedback:` refs removed | dedup needs either the cursor or the refs; restore one |
