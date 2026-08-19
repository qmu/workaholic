---
type: Routine Template
id: workaholic
name: "[Workaholic] {repo_name}"
scope: user
trigger: schedule-hourly
trigger_kind: schedule
cron_expression: 10 * * * *
autofix_on_pr_create: false
model: claude-opus-5
allowed_tools: [Bash, Read, Glob, Grep]
mcp: [Slack]
---

# [Workaholic] — the account's one updater, and it converges routines, not repositories

**`scope: user`** — **exactly one for the account**, no matter how many repositories that
account has set up (2026-08-19, issue #526). This is a third value, not a rename of either
existing one: `developer` means one copy per developer **per repository**, `user` means one
copy per **account, full stop**. `/workaholic` configures it, and neither
`/setup-dev-routines` nor `/setup-repo-routines` ever sees it — the scope is read from this
field by both setup commands and every setup sheet, so nothing has to be listed twice.

**Its repository field is the repository holding the definitions**, not whichever repository
the operator happened to be standing in. This routine reads the workaholic repository's
`skills/workaholify/routines/` for what a routine *should* be; the routines it converges live
on other repositories and are reached through the account, not through a checkout.

**What it does, hourly:** enumerate the account's own workaholic routines, render each one's
template for the repository that routine names, diff the rendered `name` / prompt / `model` /
`cron_expression` / `autofix_on_pr_create` / connectors against the live record, and converge
the ones that differ — **one routine at a time, each applied and reported as its own line**.
That is the same diff `/setup-dev-routines` and `/setup-repo-routines` already perform; the
only thing this routine adds is doing it across every repository the account already has a
routine on, on a clock, instead of one repository at a time when a person remembers.

**The account's own routine list is the enumeration, and that is a deliberate limit.** Nothing
in the loop holds a list of "this user's repositories", and the two alternatives were rejected:
a GitHub repository listing enumerates repositories that have no routine at all and cannot say
which of them the user wants one on, and an operator-maintained list is a second source of
truth that drifts silently. A workaholic routine *is* the thing to be converged, so the set of
routines is the exact right domain — and it needs precisely the transport the converging half
already needs, so a session missing that transport is missing both halves together and reports
**one** refusal rather than two. The limit is stated rather than glossed: **a repository the
account has never set up a routine on is invisible here**, and this routine says so instead of
implying it covered everything.

**Drift is the rendered diff, never a version number.** A plugin version bump is a cheap
pre-filter and nothing more: this repository ships template edits without bumping a version
routinely — both halves of the 2026-08-19 rename did — so a version-gated updater would sit
still through exactly the changes it exists to propagate. The rendered-prompt diff per routine
is the only test that catches a template edit that did not bump a version, and it is not a new
mechanism: it is what convergence already computes.

**It never converges itself.** A routine that rewrites routines can take an account's whole
fleet down in one tick, and the failure worth designing against is a bad definition propagating
everywhere at once — not a missed update, which the next tick fixes for free. Excluding its own
record is the cheap half of that: whatever it does to the fleet, there is still a tick left that
can be repaired by hand and can repair the rest. Its own definition is converged by a person
running `/workaholic`, exactly as `[Propose]` is converged by a person running
`/setup-repo-routines` and never by a tick.

**Where the transport is the whole question** (measured 2026-08-19 from a routine-fired
`[Implement]` container, the same session class this routine runs in): **no
`RemoteTrigger`-family tool is exposed**, `CronCreate` / `CronList` / `CronDelete` are a
session-only, in-memory scheduler that cannot touch an account routine, and the `claude` CLI
carries no routine subcommand. In that class this routine **cannot converge anything** — and
the honest shape is the one below, not a routine that quietly does nothing hourly: it reports
`no_transport: RemoteTrigger-family tool` by name, states that it therefore could not read the
account's routines and converged nothing, and **claims no convergence it did not perform**.

**The prompt is the ceiling** (P3, Q2, P10): the one literal format below is the only shape a
session running this routine may emit, and `workaholic:notify`'s `reference/notifications.md`
mirrors it verbatim. A future edit to either copy is a drift to fix, never a second wording.

## Prompt

Run `/workaholic`.

If the command or its skills did not load, do not stop: run `bash plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` from the checkout, take its `src`, then read `<src>/commands/workaholic.md` and follow it with every script path under `<src>`.

If the run converged a routine, or could not reach the transport at all, and the exact-string search for the state key finds no earlier post, post this one line as a new top-level message (the workaholic:notify lookup) — no mention token of any kind:

```
🔄 Workaholic - <what changed, or the named refusal and what it could not read>
One sentence, max 25 words, which routines converged on which repositories, or what is not being converged.
`fleet:<digest>`
<session URL>
```

If nothing drifted, or that state was already posted, post nothing.
