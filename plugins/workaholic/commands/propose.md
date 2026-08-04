---
name: propose
description: Headless proposal batch — survey the repository state and either stay silent or propose a mission with its ticket set on a work branch behind a pull request, announced to Slack.
skills:
  - workaholic:propose
  - workaholic:feedback
  - workaholic:mission
  - workaholic:gather
  - workaholic:commit
---

# Propose

**Notice:** When user input contains `/propose` — whether "run /propose", "run the proposal batch", "check for new feedback", or similar — they likely want this command. It is also what the scheduled `[Propose]` routine invokes headlessly every 15 minutes (see `docs/proposal-loop-runbook.md`).

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

This command is **headless by contract** (`workaholic:propose` — read its Headless section first): it never issues `AskUserQuestion`, silence is a valid outcome, and every abort reports a machine-readable reason. It runs the batch once; the schedule is the loop.

## Workflow

1. **Guard.** Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/sync-main.sh`. It composes the on-main and clean-tree readers, fetches, and fast-forwards — never merging, rebasing, or prompting. On `ok: false`, abort reporting `{"proposed": 0, "reason": "<its reason>"}`: `not_on_main`, `dirty_workspace`, `diverged`, `no_origin`, or `origin_unreachable`.

2. **Cursor.** `bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/cursor.sh read`. The cursor is a **pushed ref**, so `initialized: true` now means "this repository's cursor was just born and pushed" — report it and **continue**: the window is empty by construction on that very first tick, and the per-container stop this used to perform is exactly what made every fresh-container run a no-op (skill: Cursor contract). A `fetched: false` means origin was unreachable and the value is the last-fetched copy — carry that into the run report, because the window it defines may be stale.

3. **Window.** `bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/new-feedback.sh <cursor-commit>`. Empty → advance the cursor to the current tip (`cursor.sh advance <tip>`) and report silence.

4. **State.** `bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/survey-state.sh <cursor-commit>` — the missions, the todo queue, and the commits since the cursor. These are **constraints on** the judgment, never triggers for it (skill: The judgment bar); a run whose feedback window is empty has already stopped at step 3, no matter what the state shows.

5. **Dedup.** `bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/list-proposed-refs.sh`; drop window records already referenced by any proposed artifact — a mission **or** a loose ticket, queued or archived. Nothing left → advance + silence.

6. **Judge** each remaining record (read it in full) against the skill's **judgment bar**, with the step-4 state in hand — propose only actionable direction, and drop anything an active mission already covers, a queued ticket already specifies, or a recent commit already built. When unsure, stay silent. Group records that ask for one direction into one proposal.

   Then **decide the form** (skill: *The form follows the work's shape*), because it selects which of steps 8–9 runs: a direction that decomposes into **two or more** units is a mission with its ticket set (steps 8 and 9); an **atomic** one is a **single loose ticket** (step 9's loose form, no mission); one that is neither is **dropped with its reason reported**. Never dress an atomic ask as a one-ticket mission, and never reach for the loose form to publish something that should have been decomposed.

7. **Open the publish tree.** `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/open-publish-tree.sh`. On `ok: false`, abort reporting its reason without advancing the cursor. Everything in steps 8–9 is written **inside** the publish tree path it returns, so the caller's checkout is never touched.

8. **Draft** each warranted **mission** proposal (skip to step 9's loose form for an atomic one, which has no mission):
   - `bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/scaffold-draft.sh "<title>" <feedback-filename>...`
   - Fill `## Goal` / `## Scope` / `## Experience` and a **proposed** `## Acceptance` sketch from the feedback content (Edit on the scaffold; clearly provisional — whoever reviews the pull request interrogates it to drive-ready via `/mission <instruction>`, never this batch). Never touch `status` and never seed `assignees` or `merge_policy` — an unowned mission with an empty policy reads as `review`, which is the safe default for anything an unattended batch wrote.

9. **Emit the tickets.**

   For a **mission** proposal, emit its whole set — a proposal without one is a title, and `/drive` drops such a mission as `no_tickets`:
   - `bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/scaffold-proposed-ticket.sh "<title>" <mission-slug> [type] [layer]`, once per ticket, in the order they would be driven. **Two or more, always**; a set of one is not a mission (skill: *The form follows the work's shape*).

   For an **atomic** direction, emit exactly one loose ticket instead — no mission, no wrapper:
   - `bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/scaffold-proposed-ticket.sh "<title>" --loose [type] [layer] --feedback <record>...`
   - The `--feedback` refs are **mandatory** here (`no_feedback` otherwise): with no mission to hold the relation, they are the only thing that keeps the record out of the next tick's window.

   Either way, fill each ticket's Overview, Key Files, Implementation Steps, and the provisional Quality Gate, and leave `merge_policy` empty (absent reads as `review`).

10. **Publish as a pull request.** `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/publish-tree-pr.sh "Propose mission <slug>" "<why>" "<changes>" "<concerns>" "<insights>" "<verify>"` — one call per proposal (`"Propose ticket <slug>"` for a loose one, so the ledger says which form it was). It commits, pushes a fresh `work-*` branch, and opens the PR, emitting `{ok, branch, pr_url}`. On `ok: false`, abort **without advancing the cursor**; note that `pr_failed` means the artifact **is** pushed (open the PR by hand — never re-publish, which would duplicate it).

11. **Close the publish tree.** `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/close-publish-tree.sh`. Run it whether or not the publish succeeded; it refuses rather than destroying recoverable state.

12. **Notify** per proposal: `bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/notify-slack.sh "<message>"` — title, slug, this repo's label (`bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh`), the **PR URL**, and how to pick it up once merged (`/mission <slug>` for a mission; a loose ticket simply joins the backlog and needs no pointer). Record each `notified` result; a no-op/failure never fails the run (skill: Notifier contract).

13. **Advance** the cursor to the base tip the proposal was cut from (`cursor.sh advance <tip>`) — only now, after every proposal's pull request is open. Open, not merged: merging is a human act with no deadline, and a cursor waiting on it would re-propose what is already sitting in an open PR (skill: Headless).

14. **Report** one line per outcome: silence (with window size), or each proposal's slug + PR URL + ticket count + notified flag.
