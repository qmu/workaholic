---
name: watch
description: The lightweight development loop — a script watches Slack with no model in the loop, and the session wakes only on a new human message to answer it or start /implement in the background.
metadata:
  internal: true
---

# Watch

`/work` on Claude Code. Three parts, and only the middle one spends tokens:

1. **Watch** (no model). Run
   `${CLAUDE_PLUGIN_ROOT}/skills/watch/scripts/watch-slack.sh --root <repo> --until-event` with
   Bash `run_in_background: true`. Every interval (default 120s, `WORKAHOLIC_WATCH_INTERVAL`, or
   the interval `/work` was given) it reads the declared channel through
   `transport/scripts/observe-channel.sh`; it exits after the first read that found a new
   **human** message, printing one JSON line per message, and stays silent while the channel is
   quiet — so the session is woken once per change and never while idle. The loop's own posts and
   history older than an hour are dropped by the script. After handling the lines, start it again.
2. **Decide** (only when a line arrives). For each `{"event":"message"}`:
   - a question or a reply to the loop → answer it in the message's thread;
   - a request for a change → answer `📥 受理` in the thread, write it down as a ticket through
     `workaholic:create-ticket` (unattended: no questions; publish behind a PR and merge it), then
     go to step 3;
   - anything else (chatter, a reaction-worthy note) → do nothing.
   `{"event":"observe_failed"}` is printed once per distinct reason: say so in one line and keep
   watching; do not retry by hand.
3. **Implement** (background). Launch one `general-purpose` subagent with
   `run_in_background: true` whose prompt is: run `/implement` in `<repo>` and return the
   finish report. Do not wait for it. At most `WORKAHOLIC_MAX_WORKERS` (default 2) running at once;
   a request arriving while the limit is reached is still ticketed and the next free runner's
   `/implement` survey picks it up. When a runner finishes, post one line with its PR URL in the
   request's thread.

## Rules

- **One watcher per repository.** If a background `watch-slack.sh` already runs in this session,
  start nothing. Restart it only after its output was handled.
- **Replies go in the message's thread** through qfs: for a root message use its own `ts`, for a
  reply use its `thread_ts`:
  `qfs run "insert into <post mount>/<workspace>/<channel_id>/messages/<parent ts>/replies values (text) ('💬 …')" --commit`.
  Preview first (one INSERT), then commit, then read `…/replies` back to confirm. The post mount
  is named in `AGENTS.md`. This needs the machine's qfs to carry an INSERT map for `replies`; the
  shipped Slack declaration has only a read view there, so add it once per machine:
  `qfs run "CREATE MAP INSERT /slack/{ws}/{channel}/messages/{ts}/replies AS INSERT INTO /http/slack/chat.postMessage VALUES ({channel: path.channel, text: row.text, thread_ts: path.ts})" --commit`.
  Never pass `thread_ts` as a column on `…/messages`: that map sends only `channel` and `text`,
  so the reply silently lands in the channel. Open with `💬` so the watcher drops the loop's own
  post, and follow `rules/interaction.md` for language (Japanese on the channel).
- **Never poll by hand.** No sleep loops, no re-reading the channel between events: the watcher
  is the only clock, and a completed background runner re-invokes the session by itself.
- **Nothing else runs in this loop.** Proposing, moderation, stale-claim repair and release work
  are their own commands (`/propose`, `/moderate`, `/prepare-release`), run on demand or on their
  own schedule.
- **Do not use the Monitor tool for the watch**: a Monitor expires after 30 minutes and every
  re-arm wakes the session with nothing to do. A background Bash command has no such deadline.
- To stop, stop the background watcher and do not restart it.

The earlier coordinator loop (`/infinite-development`, `workaholic:work`, `work/scripts/codex-loop.sh`)
remains for Codex and CLI supervisors; `/work` on Claude Code no longer runs it.
