---
type: Routine Template
id: housekeep
name: "[Propose] {repo_name}"
renamed_from: "[Housekeep] {repo_name}"
scope: repository
trigger: schedule-hourly
trigger_kind: schedule
cron_expression: 50 * * * *
autofix_on_pr_create: true
model: claude-opus-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep]
mcp: [Slack]
---

# [Propose] — the maintenance tick, one copy for the repository

**This routine was `[Housekeep]` until 2026-08-19, and its cutover is the ordered half of a
swap** (issue #526). Behaviour did not move: it still runs `/housekeep`, still fires at `:50`,
still declares `autofix_on_pr_create: true` and `scope: repository`, still names the same two
post formats. Only `name:` moved — and it moved **into a name that was live until the same
change**. The routine that held it, running `/propose` at `:15`, is now `[Specificate]`.

**So the operator's act here is ordered, and that is the whole risk.** Convergence matches an
account's routines by rendered name. An account that has not yet renamed its live
`[Propose] <repo>` to `[Specificate] <repo>` and lets `/setup-repo-routines` converge this one
ends up with **two routines called `[Propose] <repo>`** — one firing `/propose` at `:15`, one
firing `/housekeep` at `:50` — which no convergence can tell apart and which no other account
can list or delete. **Rename the old `[Propose]` first** (`/setup-dev-routines`' cutover), then
this one. `renamed_from:` above carries the instruction into the sheet and both setup commands'
reports; the field is deleted from this template once the fleet has cut over.

**Nothing is deduped by a routine's name**, so no post changes frequency or threading under
this rename: the Slack keys are `` `fb:<stem>` ``, `` `stuck:<digest>` ``, `` `deploy:<digest>` ``
and `` `standup:<date>` ``, and nothing searches a heading or a routine name. This is stated
here rather than left to be re-derived — the 2026-08-17 release-tick rename was reversed the
next day on exactly that mistaken assumption.

**`scope: repository`** — the repository needs exactly **one** of this routine, configured by
one designated person or a project/service account through `/setup-repo-routines`.

**The ask said `/setup-dev-routines`, and that sentence is answered rather than dismissed**
(resolved 2026-08-17, issue #471). It was written before the nine steps were decomposed. Once
they were, seven of the nine read the **repository**, not the developer: issue triage,
auto-merge reminders and documentation drift produce identical findings from every copy, and
the check-in would ask five questions per copy per hour. N copies firing hourly is the exact
failure the `repository` scope was introduced for on 2026-08-14 (issue #451), and the plugin
**cannot detect it** — a routine is an account-level record no other account can list. The
argument that pointed the other way was step 8 (proposals), where per-developer copies would at
least be racing under their own identities; that argument is moot, because step 8 ships
**gated** and emits nothing until the operator rules on it.

Two steps genuinely are personal — the inbound sweep's Gmail, Drive and Slack connectors belong
to whichever account runs the tick — and they degrade **honestly** rather than silently: each
surface is reported by name (`no_surface: gmail`), so a single account's copy says exactly whose
inboxes it could and could not see. If the operator wants both, the faithful shape is a split
(a developer-scoped inbound routine and this repository-scoped one), which is a template to add
rather than a line to change. Moving this one is a **one-line** change to `scope:`; both setup
commands and both setup sheets read this field, so nothing else has to move with it.

**Fires at :50** — the API's minimum interval is one hour, a bare `:00` minute is rewritten to
server jitter, and `15` / `30` / `45` are taken by `[Specificate]`, `[Implement]` and
`[Prepare Release]`. Landing last in the hour is deliberate: the tick reads what the other three
have just done.

**`autofix_on_pr_create: true`, and `Write`/`Edit` are granted rather than inherited.** This
routine is not a pure reader like `[Prepare Release]`: it writes its own tick log under
`.workaholic/housekeeping/`, and filing a finding means writing a feedback record or a ticket —
which publishes behind a pull request, exactly as `/propose` does. A pull request this routine
opened and then left red is a stuck artifact nobody owns, so the flag is `true` for the same
reason it is true on `[Specificate]`.

**Its container is discarded, so the tick commits its own log.** A routine tick runs in a fresh
clone; a log left in that checkout would take every dedup's memory with it and leave an hourly
unattended process with no audit trail. `persist-log.sh` is the tick's closing act and the one
thing this routine puts on `main` — an append to its own log, through the publish tree, leaving
the checkout byte-identical and creating no branch (`workaholic:housekeep`, *The tick log*).

**What it never does**, and none of it is left to the prompt: it never merges a pull request,
never pushes into a branch the claim protocol owns (step 4 reports conflict state and the claim
holder resolves it), never edits a live strategy, never closes an issue, never rewrites a
document on `main` — its own append-only tick log is the single exception, stated above — and
never calls `AskUserQuestion` — step 9 asks humans **in Slack**. Every one of those rules lives
in `workaholic:housekeep` and its `reference/workflow.md`, which is why this prompt does not
restate them.

**The prompt is the ceiling** (P3, Q2, P10): the two literal formats below are the only shapes a
session running this routine may emit, and `workaholic:notify`'s `reference/notifications.md`
mirrors both verbatim. A future edit to either copy is a drift to fix, never a second wording.

## Prompt

Run `/housekeep`.

If the command or its skills did not load, do not stop: run `bash plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` from the checkout, take its `src`, then read `<src>/commands/housekeep.md` and follow it with every script path under `<src>`.

If pull requests are waiting on a human and the exact-string search for the state key finds no earlier post, post this one line as a new top-level message (the workaholic:notify lookup) — no mention token of any kind:

```
🔧 Needs a decision - <the step's headline: how many pull requests, and what is blocking them>
One sentence, max 25 words, what the decision is (resolve a conflict, review it, fix a check).
`stuck:<digest>`
<session URL>
```

For each question the check-in step is cleared to ask, post one message into the thread of the item it concerns, addressed to the resolved person:

```
❓ Question <@U…> - <what this tick could not decide>
One sentence, max 25 words, the question itself, with the two options when there are two.
`ask:<key>`
<session URL>
```

If nothing is waiting on a human, or that state was already posted, post nothing. If no question clears the check-in gate, ask nothing.
