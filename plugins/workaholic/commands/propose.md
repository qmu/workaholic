---
name: propose
description: Judge the ask in hand and emit, in one publish-tree pull request, the feedback record together with whatever it warrants — a mission with its ticket set, a loose ticket, or the record alone.
skills:
  - workaholic:propose
  - workaholic:feedback
  - workaholic:mission
  - workaholic:gather
  - workaholic:commit
---

# Propose

**Notice:** When user input contains `/propose` — whether "run /propose", "propose this", "turn this into work", or similar — they likely want this command. It is also what the `[Propose]` capture routine runs in the session that receives a reported ask (see `docs/proposal-loop-runbook.md`).

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

**This command proposes from what is in hand** (`workaholic:propose` — read its *Propose at the capture seam* section first): the ask this session received and the feedback record it wrote from it. It reads nothing from a window and keeps no cursor; the repository's own state is a constraint it reads from the base. It is **unattended by contract** — it never issues `AskUserQuestion`, and every abort reports a machine-readable reason.

**What "in hand" means.** Any of: an ask given as this command's argument, a feedback record this session just wrote, or a record named explicitly by the caller. With **none** of those, report `{"proposed": 0, "reason": "nothing_in_hand"}` and stop — there is nothing to judge, and sweeping the repository for something to propose is exactly the design the 2026-08-04 ruling retired.

## Workflow

1. **Take the ask in hand.** An argument, the record this session just wrote, or a record the caller named. Nothing in hand → `nothing_in_hand`, stop (above).

2. **Open the publish tree.** `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/open-publish-tree.sh`. On `ok: false`, abort reporting its reason. Everything written from here lands **inside** the path it returns — a checkout of `origin/main` — so the caller's branch and uncommitted work are untouched, and steps 3–4 read the base rather than the caller's tree.

3. **Register the record**, inside the publish tree: `printf '%s\n' "<body>" | bash ${CLAUDE_PLUGIN_ROOT}/skills/feedback/scripts/create.sh "<title>" <kind> <source> [supersedes]`. Classify by the feedback skill's deciding rule — **an ask is `instruction`**; a `concern` is a worry with no ask attached. This session decides both the `kind` and the judgment, so a misclassification here silences its own proposal (`workaholic:feedback`, *Choosing the kind*). The record is written **whatever step 6 concludes**.

4. **Read the constraints**, from the publish tree: `bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/survey-state.sh` — the missions, the todo queue, and recent base commits, with `since_reason` naming how the commit range was chosen. These **constrain** the judgment; they never trigger one.

5. **Dedup.** `bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/list-proposed-refs.sh` — the records every existing mission and ticket already answers. An ask that restates one of them is **record-only**: stop after step 3's record and go to step 9. Read this **before** scaffolding, since what this session writes joins the set immediately.

6. **Judge** the ask against the skill's **judgment bar**, with the step-4 state in hand, and **decide the form** (skill: *The form follows the work's shape*): a direction that decomposes into **two or more** units is a mission with its ticket set (steps 7 and 8); an **atomic** one is a **single loose ticket** (step 8's loose form, no mission); one that is neither is **record-only**. Never dress an atomic ask as a one-ticket mission, and never reach for the loose form to publish something that should have been decomposed. When unsure, record-only — and name what made you unsure in step 9's PR body.

7. **Draft the mission** (mission form only), in the publish tree:
   - `bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/scaffold-draft.sh "<title>" <feedback-filename>...` — the filename from step 3.
   - Fill `## Goal` / `## Scope` / `## Experience` and a **proposed** `## Acceptance` sketch from the ask (Edit on the scaffold; clearly provisional — whoever reviews the pull request interrogates it to drive-ready via `/mission <instruction>`). Never touch `status` and never seed `assignees` or `merge_policy`.

8. **Emit the tickets**, in the publish tree.

   For a **mission** proposal, emit its whole set — **two or more, always**; a set of one is not a mission:
   - `bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/scaffold-proposed-ticket.sh "<title>" <mission-slug> [type] [layer]`, once per ticket, in the order they would be driven.
   - Then stamp the links: `bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/link-acceptance.sh <slug> <item-selector> <ticket-filename>` once per acceptance item the set satisfies — the pairing you decided in step 6, never inferred.
   - Then the floor: `bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/check-floor.sh <slug>`. A non-zero exit means this is **not** published as a mission — fall back to a loose ticket or to record-only, and report the script's `alternative`.

   For an **atomic** direction, emit exactly one loose ticket instead — no mission, no wrapper:
   - `bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/scaffold-proposed-ticket.sh "<title>" --loose [type] [layer] --feedback <record>...`
   - The `--feedback` refs are **mandatory** here (`no_feedback` otherwise): with no mission to hold the relation, they are the only record of what the ticket answers.

   Either way, fill each ticket's Overview, Key Files, Implementation Steps, and the provisional Quality Gate, and leave `merge_policy` empty (absent reads as `review`).

9. **Publish it all as one pull request.** `WORKAHOLIC_PR_TITLE="[Proposal] <title>" WORKAHOLIC_NOTIFY_TARGET="<thread url or empty>" bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/publish-tree-pr.sh "<title>" "<why>" "<changes>" "<concerns>" "<insights>" "<verify>"` — **one call**, carrying the record and whatever the judgment added. The record and the work it warrants are one decision; two pull requests would let a reviewer accept half of it. Name the commit subject for what it carries — `Propose mission <slug>`, `Propose ticket <slug>`, or `Register feedback <stem>` for record-only — and give the **pull request** the same words behind the `[Proposal]` prefix (`[提案]` for a Japanese title). The two are separate on purpose: the subject obeys the commit rule (no `[bracket]` prefix), the title carries the prefix the `[Implement]` routine's trigger filters on. Set `WORKAHOLIC_NOTIFY_TARGET` to the thread the ask arrived in when the caller handed you one, and **leave it unset otherwise** — an absent line is the next routine's documented fallback, and an invented one would suppress it. On `ok: false`, report the reason; `pr_failed` means the artifact **is** pushed, so open the PR by hand rather than re-publishing (which would duplicate it).

10. **Close the publish tree.** `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/close-publish-tree.sh`. Run it whether or not the publish succeeded; it refuses rather than destroying recoverable state.

11. **Notify.** `bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/notify-slack.sh "<message>"` — the title, this repo's label (`bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh`), the **PR URL**, and how to pick it up once merged (`/mission <slug>` for a mission; a loose ticket simply joins the backlog). A no-op or failure never fails the run (skill: Notifier contract). Inside the `[Propose]` routine the thread root is posted by the routine itself through the account's Slack connector; do not post twice.

12. **Report** one line: the form chosen (mission with N tickets / loose ticket / record-only) with its reason, the record's filename, the PR URL, and the `notified` flag.
