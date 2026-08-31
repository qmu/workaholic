---
type: Routine Template
id: moderate
name: "[Moderate] {repo_name}"
scope: repository
trigger: schedule-hourly
trigger_kind: schedule
cron_expression: 50 * * * *
autofix_on_pr_create: true
model: claude-opus-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep]
mcp: [Slack]
---

# [Moderate] — the maintenance tick, one copy for the repository

**This routine was renamed on 2026-08-19, and its cutover was the ordered half of a swap**
(issue #526; the names it held are in this file's git history). Behaviour did not move: it
still runs `/moderate`, still fires at `:50`,
still declares `autofix_on_pr_create: true` and `scope: repository`, still names the same two
post formats. Only `name:` moved — and it moved **into a name that was live until the same
change**. The routine that held it, running `/specificate` at `:15`, is now `[Specificate]`.

**The cutover is done, and `renamed_from:` is gone with it** (2026-08-19). This routine
passed briefly through `[Propose]` — a name `[Specificate]` was vacating the same day,
which made the two migrations ordered: converging this one before the other was renamed would
have left two routines with one rendered name, indistinguishable to a convergence that matches
by name. The field existed to carry that instruction into the sheet and both setup commands'
reports. The fleet has cut over, so it is **deleted from this template**, exactly as the rule
requires — it described a migration, not a routine. The mechanism is unchanged and documented
in `workaholic:workaholify` §5 for the next rename that needs it.

**Nothing is deduped by a routine's name**, so no post changes frequency or threading under
this rename: nothing searches a heading or a routine name. (The printed key lines were removed
from every post on 2026-08-22 — case 2 searches the record filename the root already links, and
the tick and question keys were searched by nothing at all.) This is stated
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
inboxes it could and could not see. The `unanswered-asks` step added on 2026-08-26 reads the
repository's **own** channel rather than anyone's inbox, so it belongs to this scope and not to a
personal one; it degrades by the same rule (`no_slack_transport`, `channel_unreadable` — never an
unread channel reported as a quiet one). If the operator wants both, the faithful shape is a split
(a developer-scoped inbound routine and this repository-scoped one), which is a template to add
rather than a line to change. Moving this one is a **one-line** change to `scope:`; both setup
commands and both setup sheets read this field, so nothing else has to move with it.

**Fires at :50** — the API's minimum interval is one hour, a bare `:00` minute is rewritten to
server jitter, and `15` / `30` / `45` are taken by `[Specificate]`, `[Implement]` and
`[Prepare Release]`. Landing last in the hour is deliberate: the tick reads what the other three
have just done.

**`autofix_on_pr_create: true`, and `Write`/`Edit` are granted rather than inherited.** This
routine is not a pure reader like `[Prepare Release]`: it writes its own tick log under
`.workaholic/moderations/`, and filing a finding means writing a feedback record or a ticket —
which publishes behind a pull request, exactly as `/specificate` does. A pull request this routine
opened and then left red is a stuck artifact nobody owns, so the flag is `true` for the same
reason it is true on `[Specificate]`.

**Its container is discarded, so the tick publishes its own log.** A routine tick runs in a fresh
clone; a log left in that checkout would take every dedup's memory with it and leave an hourly
unattended process with no audit trail. `persist-log.sh` is the tick's closing act and it
publishes to the log's **own ref** — `refs/heads/workaholic/moderation-log`, never `main` —
leaving the checkout byte-identical and creating no branch (`workaholic:moderate`, *Where the log
lives, and why it is not `main`*). The one thing this routine still puts on `main` is a **feedback
record** it wrote, which is knowledge the `feedback:` relation has to resolve; a tick that wrote
none commits to the base at all.

**What it never does**, and none of it is left to the prompt: it never merges a pull request,
never pushes into a branch the claim protocol owns (step 4 reports conflict state and the claim
holder resolves it), never edits a live strategy, never closes an issue, never rewrites a
document on `main` — a feedback record it wrote is the single exception, stated above, and its
own tick log no longer reaches `main` at all — and
never calls `AskUserQuestion` — step 9 asks humans **in Slack**. Every one of those rules lives
in `workaholic:moderate` and its `reference/workflow.md`, which is why this prompt does not
restate them.

**The prompt names the command and nothing else** (2026-09-01, the developer's instruction).
Everything a session running this routine may do — the post shapes, the transports, what it may
read, and what it must never emit — lives in `plugins/workaholic/commands/moderate.md`, versioned
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

**Every shape here is addressed to somebody, because a status line addressed to nobody is noise** (2026-08-19, the developer's
instruction). This routine used to emit a second, `🔧 Needs a decision`, and the merged-in
release tick a third, `📦 Release Preparation`; both were top-level roots carrying no mention
token. Measured on `#dev-workaholic` the same day: ten `📦` lines in ten consecutive hours for
one unchanged request, none answered by anyone. Both are retired. A finding this tick cannot
turn into a question addressed to somebody does not reach Slack at all — it stays in the tick
log and, where it is work, becomes a ticket.

## Prompt

Run `/moderate`.

If the command or its skills did not load, do not stop: run `bash plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` from the checkout, take its `src`, then read `<src>/commands/moderate.md` and follow it with every script path under `<src>`.
