# The loop off Claude Code: what was measured, what was substituted, what was lost

**Asked 2026-09-03**: can the loop-premised `/work` command run under Codex, and make it loop
there properly. **The answer to the shape was the operator's**: make `/work` a *skill*, so Claude
Code calls it as a command and every other agent calls it as a skill. That is what shipped —
`workaholic:work` is the one contract and `commands/work.md` is a thin alias onto it. **No build
change was needed**: `plugins/workaholic/.codex-plugin/plugin.json` already declares
`"skills": "./skills/"` over the whole plugin, so a skill reaches Codex through the full plugin
the marketplace installs. The diagnosis below was made by the **Codex CLI itself** (`codex-cli 0.149.1`,
run non-interactively against this checkout) and cross-checked against the CLI's own `--help`
and this machine's `~/.codex/`.

## Why it reached no other agent, before this

`/work` was not reachable from Codex at all, and this was a fact about the **manifests**, not a
missing feature: both `plugins/workaholic/.codex-plugin/plugin.json` and
`outputs/workflows/.codex-plugin/plugin.json` expose `"skills"` and nothing else, so
`commands/` reaches Codex as **files that exist in the tree**, never as commands. Measured: the
installed Codex plugin cache carries the whole plugin tree (`commands/` included) and Codex
offers none of it as a command. The generated `outputs/workflows` bundle carried no loop skill either, and
**that has deliberately not changed**. Adding it was tried and reverted: that bundle is the
self-contained subset a foreign agent can run with nothing else present, while the loop's tick
drives `implement`, `propose`, `specificate` and `moderate` — building it there pulled nineteen
skills into the closure and still left five unresolved references (`lib/raced-units.sh`,
`lib/speaking-window.sh`, `lib/tick-thread-key.sh`, two `../bootstrap/session-start.sh`), because
that copier follows a skill's `scripts/` and not its siblings. The loop needs the whole
apparatus, and the whole apparatus is the full plugin — which Codex already installs.

## The four mechanisms, and what Codex has

| Claude mechanism | Codex, measured | Substitution |
| ---------------- | --------------- | ------------ |
| `/loop <interval> <command>` — an in-process recurring timer | **None.** No subcommand across `codex {,exec,agents,features,queue,debug} --help` and no flag in `codex features list`. The nearest, `goals` (stable), is goal *continuation* inside one thread: it keeps a run working toward an aim across turns and never starts a run | `scripts/codex-loop.sh`, an external sequential supervisor |
| slash-command dispatch of `commands/*.md` | **None** (manifests expose skills only) | the loop is a **skill** (`workaholic:work`); the tick reads the other command bodies as files and executes them |
| a **detached** background subagent whose parent ends first | Codex has concurrent subagents (`multi_agent`, `/agent`), but the **parent collects their results** — there is no parent-ends-children-continue lifetime | the work runs **inline, in sequence** |
| `ListAgents` as the live concurrency registry, `TaskStop` to reap | no equivalent across `exec` runs — a fresh run cannot see the previous run's agents | ticks cannot overlap by construction; `flock` refuses a second **supervisor** |
| `${CLAUDE_PLUGIN_ROOT}` | not defined | the tick names `plugins/workaholic` and writes paths out in full |
| `.claude/settings.json` `env` | not read | `codex-loop.sh` reads that same block and exports it, so there is **one** declaration |
| the plugin's `hooks/hooks.json` | not carried by either Codex manifest; Codex hooks are its own configuration | **the gates are absent on Codex** — see *What is lost* |
| Slack MCP connector | supported in general; **none configured on this machine** (`codex mcp list` is empty) | the tick reports `no_slack_transport` by name and still does its work |

## What is lost, stated rather than discovered later

1. **The responsiveness property.** The Claude tick answers a person within five minutes
   *whatever the work is doing*, because the work is detached. A sequential tick answers at its
   own **top**, so the worst case is one tick's work duration. This is the whole reason the
   Claude tick is shaped the way it is, and the port does not get it back.
2. **The hooks.** `guard-git-branch.sh`, `guard-git-commit.sh`, `validate-ticket.sh` and the
   rest are Claude Code `PreToolUse`/`PostToolUse` hooks. On Codex the **script-level** gates
   still hold — `check-subject.sh` runs inside `commit.sh` and `archive.sh`, and the opt-in
   git-native `hooks/git/commit-msg` can be installed — but the tool-level guards do not fire.
   The repair is `sh plugins/workaholic/hooks/install-git-hooks.sh`, not a Codex hook port.
3. **Nothing else.** Every other reader the loop depends on is a POSIX shell script over git and
   REST, which is why the port needed no second store, cursor, field or vocabulary.

## Why one sequential loop rather than two concurrent ones

Splitting the Slack turn from the work would restore responsiveness and was **refused by name**:
this repository retired exactly that shape on 2026-09-03 (`workaholic:loops`) after measuring it
— the propose loop reported `work_waiting` every five minutes for hours while the implement loop
reported nothing claimable, each correct in isolation and neither able to see that five pull
requests had sat conflicted since the previous day. Three places to look and no place that held
the whole loop. One slower loop that can see itself beats two fast ones that cannot.

## Running it

```sh
sh scripts/codex-loop.sh                 # every 5 minutes until stopped
sh scripts/codex-loop.sh --interval 600  # every 10
sh scripts/codex-loop.sh --once          # one tick — what a cron or systemd timer wants
sh scripts/codex-loop.sh --dry-run --once
```

Transcripts land in the git-ignored `.codex-loop/`. `--dangerously-bypass-approvals-and-sandbox`
is passed for the reason the Claude loop passes `--dangerously-skip-permissions`: an unattended
run never waits for a person, the tick pushes branches and calls `gh`, and Codex's
`workspace-write` sandbox refuses both. An allowlist was not attempted for the same reason it
was not there (issue #865) — it would have to enumerate every read the loop will ever make.
