---
type: Routine Template
id: specificate
name: "[Specificate] {repo_name}"
scope: developer
trigger: schedule-hourly
trigger_kind: schedule
cron_expression: 15 * * * *
autofix_on_pr_create: true
model: claude-opus-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]
mcp: [Slack]
---

# [Specificate] — turn a reported ask into a record and the work it warrants

**This routine was `[Moderate]` until 2026-08-19, and the rename owes the operator one
manual act** (issue #526). Behaviour did not move: it still runs `/specificate`, still fires at
`:15`, still declares `autofix_on_pr_create: true`, still names the same two post formats.
Only `name:` moved — and convergence matches an account's routines **by name**, so the next
`/setup-dev-routines` run **creates a second routine** rather than renaming the existing
one, and a routine is an account-level record no other account can list or delete. An
account already running `[Moderate] <repo>` must **rename that routine in the web UI** to
`[Specificate] <repo>`, not create a second. The instruction is carried mechanically rather
than by prose somebody must remember: `renamed_from:` above, rendered by
`render-setup-sheet.sh` as the sheet's first note and stated by `/setup-dev-routines`'
report. The field is **deleted from this template once the fleet has cut over**, because it
describes a migration rather than a routine. `[Prepare Release]` carried the first one
(2026-08-18, issue #485); this is the second and the precedent was copied, not reinvented.

**The rename is one half of a swap, and the other half takes this name.** The maintenance
tick becomes `[Moderate]` — so an account that creates `[Specificate]`
without first renaming its live `[Moderate]` ends up with two routines called `[Moderate]
<repo>`, one firing `/specificate` at `:15` and one firing `/moderate` at `:50`, which
convergence cannot tell apart. **Rename this one first**; the cutover is ordered, not merely
"do not create a second".

**`scope: developer`** — every developer needs their own copy, so `/setup-dev-routines`
converges it and `/setup-repo-routines` never sees it. The scope is the template's own
field because both commands and both setup sheets have to read one source
(`workaholic:workaholify` §5, *Two scopes, two commands*).

**Fires on a fixed hourly schedule (:15 — the API floor is one hour)** — FB `20260810085032`/issue #336,
ticket `20260810085347`, 2026-08-10: loop-engineering cadence over instant webhook
reaction, for both `[Specificate]` and `[Implement]` (the developer's explicit correction
— an earlier draft of this ticket kept `[Specificate]` event-triggered on the reasoning
below; the developer asked for both). Every developer's copy fires independently on
its own tick, and the **data** decides whose work it is exactly as before: `/specificate`
reads whatever ask is in hand and reports `not_mine` when it is not theirs.

**A schedule fire carries nothing in hand, so `/specificate` discovers its own asks**
(developer's instruction, 2026-08-12, closing the cost the schedule migration first
stated as unresolved): a tick that starts with no argument, no fresh record and no
trigger payload runs the propose skill's *Clock-fired discovery* —
`list-inbound-issues.sh` lists the open GitHub issues on this repository assigned to
the session's own identity, minus those a feedback record already names — and takes
each returned issue as an ask in hand, oldest-first, one full run per issue. This is
**not** the retired `[Propose Batch]` sweep (`reference/routines.md`, *The retired
routines*): that read the repository's own backlog for something to propose; this
reads the inbound ask channel — the issues the retired event trigger used to hand
over one at a time — and feedback stays the only input that can originate a proposal.
A tick whose discovery returns nothing still reports `nothing_in_hand` and ends —
the honest answer, now meaning "the inbox is empty" rather than "I could not look".

**The prompt names the command and nothing else** (2026-09-01, the developer's instruction).
Everything a session running this routine may do — the post shapes, the transports, what it may
read, and what it must never emit — lives in `plugins/workaholic/commands/specificate.md`, versioned
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

Run `/specificate`.

If the command or its skills did not load, do not stop: run `bash plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` from the checkout, take its `src`, then read `<src>/commands/specificate.md` and follow it with every script path under `<src>`.
