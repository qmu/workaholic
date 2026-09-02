---
name: loops
description: Use when a session runs `/spawn-loops`, or needs to know how the development loop is executed — the local tmux sessions that turn the loop every few minutes on the developer's own server, one clone per loop, with the Claude Code Web routines as the fallback for a machine without tmux.
allowed-tools: Bash
user-invocable: false
metadata:
  internal: true
---

# Loops

**The loop turns on the developer's own server, in minutes** (2026-09-02, the developer's
instruction). Until then it turned as Claude Code Web routines — `[Propose]` at `:15`,
`[Implement]` at `:30`, `[Moderate]` at `:50` — and the routines API's floor is one fire an
hour, so one turn of the loop was one hour, a change to the loop could not be seen working for
most of a day, and whether the loop was healthy at all was a question answered by reading an
hour-old log. The premise is now a set of ordinary interactive Claude Code sessions kept alive
in **tmux**, each driven by `/loop`, each in its **own clone** of the repository. The interval
is minutes; a turn of the loop is a turn of the loop.

## The table

Declared once, in `scripts/lib/loop-table.sh`, and read by every script here:

| Loop | Interval | What `/loop` repeats |
| ---- | -------- | -------------------- |
| `propose` | 5m | `Run /propose, then run /specificate.` |
| `implement` | 5m | `Run /implement.` |
| `moderate` | 30m | `Run /moderate.` |

`/propose` opens with the **Slack turn** — read the inbound channel for what moved since the
last turn, answer what the repository can answer, react to the rest — then the inbound sweep,
then the strategy judgement; `/specificate` ingests what it just supplied in the same session
(`commands/propose.md`, *What this run posts*). `[Moderate]` stays in the loop rather than
leaving it or folding into `propose`: its acts — retirement, closable missions, standing
rulings, findings — are hourly by nature, and a local 30-minute tick reaches them with full
`gh` and full `git`, none of the session-type refusals a Web container pays.

## One clone per loop, and that is the whole isolation

The propose loop and the implement loop fire minutes apart. In one checkout they would be
three writers on one working tree: `/implement` fetches and resets the base and `/ship` checks
it out after a merge, and `/specificate` opens a publish tree at `<root>/.publish`. So each
loop runs in its own clone under `$WORKAHOLIC_LOOPS_HOME/<repo>/<loop>` (default
`~/.workaholic/loops`), and its claim worktrees (`.worktrees/<unit>`) and its publish tree are
its own. **Across loops the remote is the only shared state**, and the claim protocol already
arbitrates that (`workaholic:drive`, *Claims*). **Within a loop, `/loop` turns are
sequential**, so a loop never overlaps itself. This is what *use a worktree where one is
needed* comes to: `/implement` already drives every unit in a claim worktree, `/specificate`
already writes through a publish tree, and the clone is what keeps two loops' trees apart.

## The scripts

- **`scripts/spawn-loops.sh [--dry-run] [--only <loop>,…] [--repo-url <url>]`** — for each
  declared loop: clone (or fetch and reset to `origin/main`), then
  `tmux new-session -d -s wh-<repo>-<loop> -c <clone> "claude --dangerously-skip-permissions
  [--plugin-dir <clone>/plugins/workaholic] '/loop <interval> <prompt>'"`. Idempotent — a
  session already running reports `already_running` and is left alone. `--dry-run` plans and
  prints every command, running nothing (the hermetic test). Refusals by name: `no_tmux`
  (the Web routines are the fallback), `no_claude`, `no_repo_url`, `clone_failed`,
  `fetch_failed`, `tmux_failed`.
- **`scripts/loop-status.sh [--lines <n>]`** — pure read: per loop whether its session is
  running, whether its clone exists, and the last lines of its pane.
- **`scripts/stop-loops.sh [--only <loop>,…]`** — kill each session; clones stay.

**Permission prompts are off in these sessions.** An unattended run never waits for a person
(`rules/interaction.md`); on this server the sessions are the developer's own, in clones the
developer owns, and `--dangerously-skip-permissions` is the honest spelling of that contract —
an allowlist would have to enumerate every read the run will ever make, and the measured
failure of that approach is issue #865. **The plugin loaded** is the clone's own
`plugins/workaholic` when the repository is the plugin (self-development), else whatever the
harness binds (`check-deps/scripts/plugin-src.sh` resolves the newest).

## The fallback

A machine without tmux — or a repository nobody runs a server for — keeps the Claude Code Web
routines: the templates in `workaholify/routines/` and `/setup-dev-routines` /
`/setup-repo-routines` are unchanged, and `spawn-loops.sh` names them in its `no_tmux`
refusal. The two premises must not run against one repository at once: a Web `[Propose]` and
a local propose loop are two claimants for the same inbox, and the dedups hold but the fires
are waste. Disable the routines before spawning the loops, or the reverse.
