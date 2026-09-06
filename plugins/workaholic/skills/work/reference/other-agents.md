# The loop off Claude Code: what was measured, what was substituted, what was lost

**Corrected 2026-09-04**: the 2026-09-03 diagnosis below measured **Codex CLI**, not every
Codex surface. The ChatGPT desktop app has Scheduled tasks that can return to an existing chat
on a minute interval and work in a local project. That is the preferred clock when the loop is
started from a desktop Codex chat; the external supervisor remains the CLI/IDE fallback. The
tick contract stays shared with Claude Code.

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
| `/loop <interval> <command>` — an in-process recurring timer | **Desktop app:** chat-bound Scheduled tasks support minute intervals. **CLI/IDE:** no Scheduled management interface | a Scheduled task in the current chat for desktop; the installed work skill's `scripts/codex-loop.sh` for CLI/IDE |
| slash-command dispatch of `commands/*.md` | **None** (manifests expose skills only) | the loop is a **skill** (`workaholic:work`); the tick reads the other command bodies as files and executes them |
| a **detached** background subagent whose parent ends first | Codex has concurrent subagents (`multi_agent`, `/agent`), but the **parent collects their results** — there is no parent-ends-children-continue lifetime | a **detached process**: `codex-loop.sh --dispatch <role>` starts one and returns. A process outlives the run that started it where a subagent does not |
| `ListAgents` as the live concurrency registry, `TaskStop` to reap | no equivalent across `exec` runs — a fresh run cannot see the previous run's agents | a per-role **lock**: `--dispatch` refuses `already_running`, and `--status` names each role's state. A lock is visible to a run that cannot see the previous run's agents. Nothing is reaped — a worker is a process that ends |
| `${CLAUDE_PLUGIN_ROOT}` | not defined | the tick names `plugins/workaholic` and writes paths out in full |
| `.claude/settings.json` `env` | not read | `codex-loop.sh` reads that same block and exports it, so there is **one** declaration |
| the plugin's `hooks/hooks.json` | not carried by either Codex manifest; Codex hooks are its own configuration | **the gates are absent on Codex** — see *What is lost* |
| Slack MCP connector | Scheduled tasks can use the chat's available plugins; the measured CLI run had none configured (`codex mcp list` was empty) | use the chat's connector when available; otherwise report `no_slack_transport` by name and continue |

## What is lost, stated rather than discovered later

1. **Nothing about responsiveness, since 2026-09-05.** The sequential form did lose it, and that
   is what issues #984 and #985 measured: `codex exec` ran the whole tick inline and the
   supervisor then slept a further interval, so the real period was *tick duration + interval*
   and a tick still running six minutes into a five-minute loop pushed the next channel turn past
   the eleventh minute. Both terms were repaired rather than one — the clock is anchored to
   startup and the work is dispatched as detached workers — so the channel turn now happens on
   the interval whatever the work is doing. A chat-bound Scheduled task still restores the one
   thing the external CLI supervisor cannot: its final report returns to the chat.
2. **The hooks.** `guard-git-branch.sh`, `guard-git-commit.sh`, `validate-ticket.sh` and the
   rest are Claude Code `PreToolUse`/`PostToolUse` hooks. On Codex the **script-level** gates
   still hold — `check-subject.sh` runs inside `commit.sh` and `archive.sh`, and the opt-in
   git-native `hooks/git/commit-msg` can be installed — but the tool-level guards do not fire.
   The repair is `sh plugins/workaholic/hooks/install-git-hooks.sh`, not a Codex hook port.
3. **Nothing else.** Every other reader the loop depends on is a POSIX shell script over git and
   REST, which is why the port needed no second store, cursor, field or vocabulary.

## One coordinator with workers, and why that is not the retired three-loop premise

Splitting the Slack turn from the work was **refused here until 2026-09-05**, on the strength of
the shape this repository retired on 2026-09-03 (`workaholic:loops`): the propose loop reported
`work_waiting` every five minutes for hours while the implement loop reported nothing claimable,
each correct in isolation and neither able to see that five pull requests had sat conflicted
since the previous day. That refusal was **too wide**, and the operator's #984/#985 named the
cost it was paying.

What was retired was three **clocks**, three **views** and three places to look. What ships now
is one coordinator holding the only clock and the only view, dispatching workers that hold
neither: a worker decides no cadence, reads no channel, starts no other worker, and records its
finish into the **same tick log** the coordinator reads to decide what is due. There is still one
place that sees the whole loop. That is the Claude Code shape — a main agent with detached
subagents — reached with processes, because processes are what Codex has.

The one thing a process gives that a Codex subagent does not is the lifetime: `--dispatch`
returns and its child survives, where a parent collecting subagent results cannot end first.

## Where a report goes, per entrypoint — and where it does not

**A report written into a local transcript is not a delivered report** (2026-09-06, mission
`finish-the-backlog-without-handing-it-back-to-the-operator`). Each entrypoint's reporting
destination is fixed here and **named at startup by the launcher itself**, because the failure this
closes is not a broken transport but a **missing** one being mistaken for a working one.

| Entrypoint | The tick's report reaches | A dispatched worker's report reaches | The initiating chat receives |
| ---------- | ------------------------- | ------------------------------------ | ---------------------------- |
| Claude Code `/loop 5m /infinite-development` | the session that is running the loop | the parent session, as the subagent's result | the session itself — it *is* the chat |
| Codex desktop Scheduled task | the chat the task was created in | `.codex-loop/<stamp>-<role>.md` | the tick's report only |
| `scripts/codex-loop.sh` (CLI / IDE) | `.codex-loop/<stamp>.md` and the supervisor's own stdout | `.codex-loop/<stamp>-<role>.md`, with `.codex-loop/dispatch-<role>.log` holding the child's stdout | **nothing** |

**The last cell is the honest one and is stated rather than worked around.** `--dispatch` returns
`started pid=…` the instant the child is detached, and the child outlives the run that started it —
which is exactly the lifetime the port needed and exactly why no result can come back through the
process that returned. **A shell launcher cannot promise a callback into the initiating chat
without an actual return transport**, and inventing one would mean holding the coordinator open
across the work, which is the cadence failure #984/#985 named. So the launcher **names the absence
at startup** — `chat_return: none (detached workers report to <dir>)` — and an absent delivery path
is never substituted for one that delivers somewhere else.

**The periodic report is composed from what the workers reported**, not from the coordinator's own
guess: each role's last recorded outcome is read back from the tick log's `loop-attempt-<role>`
line, the record that carries the four facts apart (*the process terminated*, *the role executed*,
*the work completed*, *the notification was delivered*). A role with no recorded attempt is named
as unrecorded, never rendered as a healthy one.

**The completion report rests on the tree, not on the tick's own bookkeeping.** *Everything is
done* is a claim about merged work, a drained queue and a reconciled set of open pull requests —
three readings this repository already owns (`plan-units.sh`, `list-claims.sh`,
`list-stranded-publications.sh`) — and never about what this session believes it did. A tick that
cannot make those readings reports them as unreadable and claims no completion.

**A delivery that failed is retried once and never duplicated.** The shape already exists and is
composed rather than re-derived: `story/scripts/record-unposted-line.sh` carries a refused line on
the unit's own story, `list-unposted-lines.sh` offers it to a later tick, and
`clear-unposted-line.sh` clears it on a landed send — idempotent, one `## Unposted Line` section
replaced rather than stacked. A still-refused send leaves the record standing and is reported as
unposted. **An unresolvable thread posts a new keyed root** rather than nothing: that is the
stateless lookup's own case 4, never a similarity match and never recency.

## Who owns the channel

**The coordinator owns the channel *turn*, and that is a narrower thing than *Slack*** (2026-09-06,
mission `finish-the-backlog-without-handing-it-back-to-the-operator`). This is the one statement of
the boundary; `codex-loop.sh`'s per-role prompt cites it and does not restate it.

The **turn** is four acts, and they are the coordinator's alone: reading the inbound channel
**window**, answering a message in it, filing an inbound **ask**, and posting the receipt for
one. A worker performs none of them, so there is still exactly one inbound owner and no second
reader of the window.

**Reading or replying to a thread a step already identified is not the turn.** `/moderate`'s
`question-answers` reads one thread per outstanding question **at a coordinate it already holds**,
and `thread-reconcile` replies into an item's own thread found by the stateless lookup;
`/implement` posts its per-unit finish line into the thread that same lookup resolved. None of
those reads the window, none discovers a message, and none can file an ask — each acts on a thread
its own step named first.

**What the conflation cost, measured**: one generic worker prompt carried *do not read or answer
the inbound channel* for every role, which disabled both `/moderate` steps outright. The same
prompt named `commands/<role>.md` and nothing else, so a dispatched `propose` ran `/propose`
alone — never the propose-**then**-specificate sequence the routine contract names — and the
proposal it opened was ingested by nothing. Each role's prompt now carries its own clause,
**derived from the command body it names** so there is one source rather than a paraphrase that
drifts, while the four acts above stay refused for every worker.

## Running it in the ChatGPT desktop app

Create a Scheduled task **inside the current chat**, choose this repository's **local project**
(not a fresh scheduled-task worktree), and set the requested cadence. For a ten-minute loop, use
ten minutes and this prompt:

> Run the `workaholic:work` skill. This scheduled invocation is the clock: execute exactly one
> development-loop tick in the current local project, apply the non-Claude substitutions, return
> the tick's report block to this chat, and end. Do not start `scripts/codex-loop.sh`, do not create
> another schedule, and do not wait for the next tick.

The local-project choice is load-bearing: the tick already isolates implementation and
publication writes in its own worktrees, while its git-ignored cadence log must persist between
runs. Keep the computer and desktop app running when the task needs those local files. Do not run
this schedule and the external supervisor against the same repository at once.

If this connector-owning chat deliberately delegates a tick to a nested CLI worker, it remains in
the turn and runs the installed launcher with `--relay --once`. The worker returns the v1 envelope
from [codex-slack-relay.md](codex-slack-relay.md); this chat validates it, performs its ordered
Slack operations with the connector, and returns a complete acknowledgement with `--ack`. The
worker receives neither the connector nor OAuth material. A detached or continuously sleeping CLI
process has no owning chat to call back into and therefore cannot use this path.

## Running it from Codex CLI or the IDE

The launcher ships beside this skill, so it works when the plugin is installed into an otherwise
empty repository. Resolve the directory containing this `SKILL.md`, then run:

```sh
sh <work-skill-directory>/scripts/codex-loop.sh                 # every 5 minutes until stopped
sh <work-skill-directory>/scripts/codex-loop.sh --interval 600  # every 10
sh <work-skill-directory>/scripts/codex-loop.sh --once          # one tick for cron/systemd
sh <work-skill-directory>/scripts/codex-loop.sh --dry-run --once
sh <work-skill-directory>/scripts/codex-loop.sh --status        # read state; start nothing
sh <work-skill-directory>/scripts/codex-loop.sh --relay --once  # parent waits for JSON intents
sh <work-skill-directory>/scripts/codex-loop.sh --ack <file>    # validate parent outcomes
sh <work-skill-directory>/scripts/codex-loop.sh --dispatch implement   # start one worker, return
sh <work-skill-directory>/scripts/codex-loop.sh --worker implement     # run one in this process
```

`--dispatch <role>` is what the coordinator's tick calls for each **due** role. It starts a
detached worker and returns immediately; a role already running reports `already_running` and is
not started twice, which is the guarantee `ListAgents` gives the Claude tick. `--worker <role>`
is what that detached process runs — it holds the role's lock, executes `commands/<role>.md`
once, and records `loop-finish-<role>` into the tick log so the cadence readers see it. An
unknown role is `bad_role` and a missing body is `plugin_command_missing`; neither starts
anything. `--status` names each role's state beside the supervisor's own.

In this source repository, `sh scripts/codex-loop.sh` is a compatibility shim onto that same
implementation. Startup reports `clock_wrapper_missing`, `plugin_skill_missing`,
`plugin_command_missing`, `repository_missing`, or `codex_cli_missing` for the precise missing
layer. Only missing plugin-owned files recommend updating or reinstalling the plugin.

Startup is ready only after its first tick returns a readable report through an available report
transport. The current atomic reading is `.codex-loop/status.json`: it distinguishes `ready`,
`tick_failure`, `report_missing`, `transport_absent`, and `work_blocked`, and carries the immutable
report/transcript paths plus the next due time. Later tick failures remain non-destructive to the
supervisor and replace that same reading; they never leave an earlier green verdict under a new
timestamp. Transcripts land in the git-ignored `.codex-loop/`.

Relay mode adds `relay_pending`, `relay_malformed`, and `relay_incomplete`. Status retains the
envelope and acknowledgement paths, while every intent stays undelivered until the parent returns
a matching acknowledgement. Normal CLI mode remains explicit `no_slack_transport`; it never
assumes that the process which launched it is a connector-owning chat.

`--dangerously-bypass-approvals-and-sandbox`
is passed for the reason the Claude loop passes `--dangerously-skip-permissions`: an unattended
run never waits for a person, the tick pushes branches and calls `gh`, and Codex's
`workspace-write` sandbox refuses both. An allowlist was not attempted for the same reason it
was not there (issue #865) — it would have to enumerate every read the loop will ever make.
