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
