---
created_at: 2026-08-13T07:26:28+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: refresh-the-outdated-documentation-to-match-current-behavior
merge_policy:
---

# Update the artifact hub and rules docs to current behavior

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it
     from a proposal into queued work. -->

`.workaholic/README.md` is the artifact hub every consuming repository inherits, and
`plugins/workaholic/rules/*.md` are loaded into agent context on every session — a wrong
statement there is executed, not just read.

The ask names no passage, so this ticket **locates the drift first**. Measured against
`origin/main` at `cdcbfe1`:

- `.workaholic/README.md`, the `feedbacks/` entry — names `/fb`, `/ship` and `/report`
  as the stream's writers. `/propose` writes a record on **every** run, whatever it
  judges, and is the highest-volume writer of the three-and-a-half.
- `.workaholic/README.md`, the `missions/` entry — a single ~500-word paragraph carrying
  mission creation, replanning, worktrees, ports, and execution. Whether each clause is
  still true (the port assignment, the `/catch` surfacing, the worktree lifecycle) has to
  be checked clause by clause against the shipped scripts; length is why it drifts unseen.
- `plugins/workaholic/rules/*.md` — 297 lines across six files, always in context. They
  looked correct on the proposal-time pass (`general.md`'s confinement rule, `shell.md`'s
  REST-only transport, `workaholic.md`'s layout table), so this is a verification pass,
  not a known-defect list. `workaholic.md`'s directory table must stay in lockstep with
  `plugins/workaholic/hooks/workaholic-layout-allowlist.txt`.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` / `policies/distribute-policies-as-plugins.md` — the rules ship as plugin context

## Key Files

- `.workaholic/README.md` — the artifact hub.
- `plugins/workaholic/rules/general.md`, `interaction.md`, `shell.md`, `workaholic.md`,
  `typescript.md`, `diagrams.md` — the always-loaded rules.
- `plugins/workaholic/hooks/workaholic-layout-allowlist.txt` — the lockstep source for the layout table.
- `CLAUDE.md` — the reference; the `.workaholic/` runtime conventions and enforcement gates sections.
- `plugins/workaholic/skills/feedback/SKILL.md`, `skills/propose/SKILL.md` — who writes the stream.

## Implementation Steps

1. **Localize before editing.** Read `.workaholic/README.md` and each `rules/*.md`
   against `CLAUDE.md` and the shipped skills/hooks, and list every statement that no
   longer holds. Confirm or drop each item above and add what it missed.
2. Correct the `feedbacks/` entry to name `/propose` among the stream's writers.
3. Walk the `missions/` entry clause by clause against `plugins/workaholic/skills/mission/`
   and `skills/drive/`, correcting what has changed; split it only if a clause cannot be
   corrected without splitting.
4. Verify the `workaholic.md` layout table against `workaholic-layout-allowlist.txt` line
   for line, and correct whichever is behind — noting in the Final Report which one it was.
5. Apply the rest of step 1's list across the rules files, keeping each rule a rule: these
   files are agent context, so added prose costs every session's budget.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `.workaholic/README.md` names the current writers, areas and lifecycles for every artifact kind it lists.
- The `rules/workaholic.md` directory table and `workaholic-layout-allowlist.txt` agree line for line.
- No rules file gained a statement the shipped hooks and scripts do not enforce.

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.
- The table and the allowlist are diffed directly (sorted directory names compared).
- Each corrected claim is traced to the skill, script, or hook that implements it, cited in the Final Report.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` green.
- `node scripts/build-plugins/build.mjs` followed by `verify.mjs` leaves `outputs/` unchanged
  (a rules edit must not silently move the generated bundle).

## Considerations

- `.workaholic/README.md` ships to every consuming repository, so a statement here is
  read by projects that do not track this repo's history: prefer describing current
  behavior over narrating what changed.
- The rules files are loaded into every session. If a correction makes one materially
  longer, say so in the Final Report — context budget is a real cost, and a rule that
  needs a paragraph usually belongs in the skill that owns it, with a pointer left behind.

## Final Report

Development completed as planned. `.workaholic/README.md` and all six `rules/*.md`
were read against `CLAUDE.md` and the shipped skills, scripts and hooks. The
`feedbacks/` drift was confirmed, the `missions/` paragraph was walked clause by
clause and three of its clauses were wrong, the layout table needed no change, and
the rules pass found two gaps the Overview had not predicted.

**1. The `feedbacks/` entry — confirmed.** It named `/fb`, `/ship` and `/report` as
the stream's writers. `/propose` writes a record on **every** run whatever it judges
(`skills/propose/SKILL.md`), making it the highest-volume writer; added and marked as
such.

**2. The `missions/` paragraph — walked clause by clause.** Three clauses were stale:

- *"Execution itself is `/drive`'s and only `/drive`'s"* — there is one executor with
  **two** entry points, `/drive` (attended) and `/implement` (unattended).
- *"routing it by the mission's recorded `merge_policy` (merge stays `/ship`)"* — the
  merge no longer stays with `/ship`. `auto` goes through `/ship`'s deploy-and-confirm
  doctrine; `review` merges its own PR over REST as soon as `/report` opens it and the
  scan passes, a scan finding being the one thing that leaves it open.
- *"a unique local port base (in its `.env`)"* — `create-mission-worktree.sh:202-217`
  writes the port vars to `.env` only when the project already carries one, else to a
  separate `.env.worktree`, and its header records that fabricating a bare root `.env`
  holding only port vars was the exact artifact that caused an earlier defect. Stated
  accurately rather than dropped.

The remaining clauses (the `predicted_hours`/`actual_hours` split, the archive move,
`merge_policy` at creation, the no-worktree-at-creation rule, replan, `/catch`
surfacing, teardown riding the claim) were each traced to their script and are
correct. The paragraph was **not** split: every clause could be corrected in place, and
the ticket made splitting conditional on that failing.

**3. The layout table vs the allowlist — neither was behind.**
`rules/workaholic.md`'s table and `hooks/workaholic-layout-allowlist.txt` list the
same twelve directories in the same order (`deployments`, `feedbacks`, `guides`,
`missions`, `policies`, `release-notes`, `releases`, `specs`, `stories`, `terms`,
`tickets`, `trips`). No correction was needed on either side; recorded here because
the ticket asked which one was behind.

**4. The rules pass — two gaps found.** The Overview expected a verification pass with
no known defects; two statements did not hold:

- `rules/workaholic.md`'s *Frontmatter Requirements* never mentioned the **OKF `type:`
  floor**, though `validate-story.sh`, `validate-feedback.sh` and `validate-mission.sh`
  enforce it on every new write, and its per-directory table listed neither `missions/`
  nor `release-notes/`. Added the floor (with the tickets-are-the-exception carve-out)
  and the two missing rows, and stamped `type:` onto the `feedbacks/` and `stories/`
  rows.
- `rules/general.md`'s *Never commit without explicit user request* listed the
  committing commands as `/drive`, `/report`, `/ship`. It omitted `/commit`, whose
  whole purpose is to commit; `/implement`, the unattended executor; and the five
  publish-tree writers (`/ticket`, `/mission`, `/mission-close`, `/fb`, `/propose`),
  which commit inside `.publish/`. A rule that under-lists the legitimate cases invites
  a session to hand-roll a commit outside the sanctioned scripts, so the sanctioned-
  scripts clause was made explicit in the same line.

`interaction.md`, `shell.md`, `typescript.md` and `diagrams.md` were read and carry no
statement the shipped hooks and scripts contradict. `general.md`'s confinement rule and
plugin-binding rule and `shell.md`'s REST-only transport were all written 2026-08-12
and are current.

**Context budget.** The two rules files grew by 5 lines net (`workaholic.md` +5,
`general.md` +0 — one line rewritten). Both additions are table rows or a single
sentence pointing at the hooks that enforce them, which is the cheapest form the
information can take; neither warranted moving into a skill, since both describe the
`.workaholic/` layout the rule file already owns.

**Ticket minted (out of scope, not fixed here).**
`plugins/workaholic/skills/okf/SKILL.md:15` claims tickets carry
`type: enhancement|bugfix|refactoring|housekeeping`. `CLAUDE.md`, `.workaholic/README.md`,
`validate-ticket.sh` and every shipped ticket say tickets carry no `type:`. That is a
skill, outside this mission's stated scope, so it is queued as
`20260813081500-reconcile-the-okf-skill-s-ticket-type-claim.md` rather than fixed
opportunistically — and the ticket's first step is to confirm the direction of the
error before editing, since the reverse reading would be a schema change.

### Discovered Insights

- **Insight**: the harness-bound `validate-ticket.sh` in this run was the stale 1.0.133
  build and rejected the minted ticket's flat `todo/` path, demanding the per-user
  `todo/<user>/` layout retired by P2 on 2026-08-06. The same hook from the resolved
  1.0.176 `src` accepts the file (exit 0), and the three sibling tickets already sit
  flat.
  **Context**: a concrete instance of what a degraded run does *not* repair — the drive
  skill says the bound hooks stay whatever the harness bound, and here that meant a
  PreToolUse guard enforcing a rule the project had already abandoned. Worth knowing
  that a blocked write in this state can be the guard being wrong, and that the check
  is to re-run the resolved `src`'s copy of the hook rather than to work around it.

- **Insight**: `archive.sh` stages the whole tree, so driving a second ticket's edits
  while a first is being archived folds them into that first commit. The three tickets
  here touched disjoint files, so nothing was lost or misattributed, but the commit
  boundary follows the archive call rather than the ticket.
  **Context**: relevant to anyone reading `tickets/archive/<branch>/` expecting one
  commit per ticket. Finish and archive one ticket before starting the next if the
  per-ticket commit boundary matters for the unit being driven.
