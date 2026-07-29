---
name: propose
description: Headless proposal batch — read feedback newly merged to main and either stay silent or register draft missions with feedback traceability, pushed to main and announced to Slack.
skills:
  - workaholic:propose
  - workaholic:feedback
  - workaholic:mission
  - workaholic:gather
  - workaholic:commit
---

# Propose

**Notice:** When user input contains `/propose` — whether "run /propose", "run the proposal batch", "check for new feedback", or similar — they likely want this command. It is also the entry the 15-minute cron invokes headlessly (see `docs/proposal-loop-runbook.md`).

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

This command is **headless by contract** (`workaholic:propose` — read its Headless section first): it never issues `AskUserQuestion`, silence is a valid outcome, and every abort reports a machine-readable reason. It runs the batch once; looping is the cron's job.

## Workflow

1. **Guard.** Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check.sh` and `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-workspace.sh`. Abort (report `{"proposed": 0, "reason": "not_on_main"}` / `"dirty_workspace"`) unless on `main` with a clean tree. Then bring main current: `git fetch origin main` and fast-forward only — a non-ff state aborts with `"diverged"` (never merge or prompt here).

2. **Cursor.** `bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/cursor.sh read`. On `initialized: true`, report the bootstrap and stop — pre-existing feedback is already-seen by design (skill: Cursor contract).

3. **Window.** `bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/new-feedback.sh <cursor-commit>`. Empty → advance the cursor to the current tip (`cursor.sh advance <tip>`) and report silence.

4. **Dedup.** `bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/list-proposed-refs.sh`; drop window records already referenced by any mission. Nothing left → advance + silence.

5. **Judge** each remaining record (read it in full) against the skill's **judgment bar** — propose only actionable direction warranting a bounded batch; when unsure, stay silent. Group records that ask for one direction into one proposal.

6. **Draft** each warranted proposal:
   - `bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/scaffold-draft.sh "<title>" <feedback-filename>...`
   - Fill `## Goal` / `## Scope` / `## Experience` and a **proposed** `## Acceptance` sketch from the feedback content (Edit on the scaffold; clearly provisional — `/mission approve <slug>` interrogates it to drive-ready, never this batch). Never flip `status` and never seed `assignees` or `merge_policy`.

7. **Commit and push** via the commit skill — subject `Propose mission <slug>` (one commit per draft), then `git push`. A failed push aborts the run **without advancing the cursor** (the next tick re-reads the same window; the drafts stay local and the retry's scaffold finds them via `reason: "exists"` — resolve by hand if it persists).

8. **Notify** per draft: `bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/notify-slack.sh "<message>"` — title, slug, this repo's label (`bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh`), the mission path on main, and "review via `/mission <slug>`". Record each `notified` result; a no-op/failure never fails the run (skill: Notifier contract).

9. **Advance** the cursor to the pushed tip (`cursor.sh advance <tip>`) — only now, after every draft is safely on main.

10. **Report** one line per outcome: silence (with window size), or each draft's slug + path + notified flag.
