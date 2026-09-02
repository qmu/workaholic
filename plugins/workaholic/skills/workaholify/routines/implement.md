---
type: Routine Template
id: implement
name: "[Implement] {repo_name}"
scope: developer
trigger: schedule-hourly
trigger_kind: schedule
cron_expression: 30 * * * *
autofix_on_pr_create: true
model: claude-opus-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]
mcp: [Slack]
sources: [{repo}]
---

# [Implement] — the unattended executor

**`scope: developer`** — every developer needs their own copy, so `/setup-dev-routines`
converges it and `/setup-repo-routines` never sees it. The scope is the template's own
field because both commands and both setup sheets have to read one source
(`workaholic:workaholify` §5, *Two scopes, two commands*).

**Fires on a fixed hourly schedule (:30 — the API floor is one hour)** — FB `20260810085032`/issue #336:
loop-engineering cadence over instant reaction on the merge event. Every developer's
copy fires independently, and the **data** decides whose work it is: a proposal
carries the triggering issue's assignee as its `assignees`, so a runner whose work
this is not surveys, sees `owned_by_other`, takes nothing, and ends `ok`. No prompt change is needed for this — the survey already filters ownership, and the survey
itself (not a trigger payload) is what decides what gets driven this tick — a
schedule fire carries no PR/issue context at all, unlike the retired merge-event
trigger. **The tradeoff this reintroduces**: `[Implement]` no longer starts the
instant a `[Proposal]` PR merges — a merged proposal now waits up to 30 minutes for
the next tick, same as any other claimable backlog item (`workaholic:workaholify`
SKILL, *Routines*; `reference/routines.md`, *The trigger surface, measured*). The
wiring is entered by hand in the routines UI; the `trigger_kind`/`cron_expression`
keys declare the design, not a stored field a session can read back (no
`RemoteTrigger`-family tool is exposed to this session — verified empty by
`ToolSearch`, ticket `20260810085351`).

**The prompt names the command and nothing else** (2026-09-01, the developer's instruction).
Everything a session running this routine may do — the post shapes, the transports, what it may
read, and what it must never emit — lives in `plugins/workaholic/commands/implement.md`, versioned
with the plugin and shipped with it. A routine record is an **account-level** object no
repository can edit, so every rule that lived in this prompt had to be re-pasted into every
developer's copy in every project before it took effect, and a prompt that drifted from the
plugin was invisible from the repository. A rule written in the command reaches every account's
routine on its next run with no routine edit at all.

**The command is the ceiling** (`workaholic:notify`, *The command is the ceiling*): the shapes
that command's own notification section names are the only ones a session running this routine
may emit, and `workaholic:notify`'s `reference/notifications.md` mirrors each of them verbatim,
so a drift between the two is a defect to fix rather than a second wording. What stays in the
prompt is the one instruction the command cannot carry — the load fallback that finds and reads
the command when the plugin did not bind.

## Prompt

Run `/implement`.

If the command or its skills did not load, do not stop: run `bash plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` from the checkout, take its `src`, then read `<src>/commands/implement.md` and follow it with every script path under `<src>`.
