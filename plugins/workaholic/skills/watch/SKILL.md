---
name: watch
description: The lightweight development loop — a script watches Slack with no model in the loop, and the session wakes only on a new human message to answer it or start /implement in the background.
metadata:
  internal: true
---

# Watch

`/work` on Claude Code. Three parts, and only the middle one spends tokens:

1. **Watch** (no model). Start `${CLAUDE_PLUGIN_ROOT}/skills/watch/scripts/watch-slack.sh --root <repo>`
   once with the **Monitor** tool (persistent). Every interval (default 120s,
   `WORKAHOLIC_WATCH_INTERVAL`, or the interval `/work` was given) it reads the declared channel
   through `transport/scripts/observe-channel.sh` and prints one JSON line per new **human**
   message, nothing when quiet. The loop's own posts are dropped by the script.
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

- **One watcher per repository.** If a Monitor running `watch-slack.sh` already exists in this
  session, start nothing.
- **Replies** go through `workaholic:transport` to the binding declared in `AGENTS.md`; follow
  `rules/interaction.md` for language (Japanese on the channel).
- **Never poll by hand.** No sleep loops, no re-reading the channel between events: the Monitor
  is the only clock, and a completed background runner re-invokes the session by itself.
- **Nothing else runs in this loop.** Proposing, moderation, stale-claim repair and release work
  are their own commands (`/propose`, `/moderate`, `/prepare-release`), run on demand or on their
  own schedule.
- To stop, stop the Monitor.

The earlier coordinator loop (`/infinite-development`, `workaholic:work`, `work/scripts/codex-loop.sh`)
remains for Codex and CLI supervisors; `/work` on Claude Code no longer runs it.
