---
created_at: 2026-08-04T22:13:47+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 2h
commit_hash:
category: Changed
depends_on: 20260804221347-judge-and-propose-inside-the-capture-session.md
mission: propose-at-the-capture-seam
merge_policy:
---

# Retire the batch seat and the merged-main window

## Overview

With proposing folded into the capture session, the compensating machinery is
unnecessary and the developer ruled it out: the [Propose Batch] cron template
(never instantiated as a live routine), the shared pushed cursor ref
(`refs/workaholic/proposal-cursor`, shipped earlier the same day), and the
merged-main window reader. Remove them and make every document tell the new
truth — a reversal recorded honestly, not silently.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` / documentation policies — a retired design is removed with its rationale recorded, so the next reader learns why, not just that

## Key Files

- `plugins/workaholic/skills/workaholify/routines/propose.md` — delete the template
- `plugins/workaholic/skills/propose/scripts/cursor.sh`, `new-feedback.sh` — delete (the window machinery); their hermetic tests go with them
- `plugins/workaholic/skills/propose/SKILL.md` — remove the Cursor contract and window sections (the sibling ticket rewrites the flow; this one deletes the leftovers)
- `docs/proposal-loop-runbook.md` — rewrite: the loop is the [Propose] capture routine; the cron and the batch are labelled history with the ruling's date
- `plugins/workaholic/skills/workaholify/SKILL.md`, `routines/drive.md`, `scripts/list-routine-templates.sh` comment, `CLAUDE.md`, `README.md`, `plugins/workaholic/rules/workaholic.md`, `commands/workaholify.md`, `commands/setup-routines.md` — every enumeration drops `[Propose Batch]`/`propose` from the template set
- `scripts/test-workflow-scripts.mjs` — remove cursor/window cases; keep dedup and composition cases

## Implementation Steps

1. Drive the sibling ticket first (`depends_on`); this branch must never lack a
   working propose path.
2. Delete `routines/propose.md`; update every template-set enumeration
   (`fb`/`merged-pr`/`drive` remain).
3. Delete `cursor.sh` and `new-feedback.sh` plus their tests; confirm nothing
   else in the closure references them (`grep -rn "cursor.sh\|new-feedback"`).
4. Rewrite the runbook around the capture-seam flow; keep the notifier env
   section and the private-repo precondition; record the ruling
   (FB `20260804221328`) as the reason the batch chapter is history.
5. Note in the story: the remote ref `refs/workaholic/proposal-cursor` may
   already exist on origin from today's runs — deleting it
   (`git push origin :refs/workaholic/proposal-cursor`) is listed as an
   operator step in the runbook's history note, not performed by the branch.
6. Rebuild `outputs/` (propose skill ships in the bundle).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No template, script, test, or document still offers the batch seat or the window as live
- The reversal's why is present in the runbook and the story, dated, citing the ruling
- The hermetic suite passes with the cursor/window cases removed and no orphan references

**Verification method** — the commands/tests/probes that prove them:

- `grep -rn "Propose Batch\|proposal-cursor\|new-feedback" plugins/ docs/ scripts/` returns only history-labelled prose
- `node scripts/test-workflow-scripts.mjs` green; `verify.mjs` clean

**Gate** — what must pass before approval:

- Both mission acceptance items satisfiable from this branch's evidence

## Considerations

- The cursor ref shipped hours before this reversal; the knowledge (push-as-
  arbiter over a ref) stays recorded in the superseded story and the ruling FB —
  deletion here is of live machinery, never of history.
- `list-proposed-refs.sh` and `survey-state.sh` are NOT retired — the capture
  seam still needs dedup and state constraints.

## Final Report

Development completed as planned. `routines/propose.md`, `cursor.sh` and
`new-feedback.sh` are deleted with their hermetic cases; the propose skill lost
its Cursor contract and window sections (175 → 162 lines); the runbook is
rewritten around the capture-seam flow with the batch chapter as a dated §7 that
cites the ruling and lists both operator cleanups. Every template-set enumeration
now reads three (`fb` = `[Propose]`, `merged-pr` = `[Consent]`, `drive` =
`[Drive]`) across the workaholify SKILL and its table, `routines/drive.md`,
`list-routine-templates.sh`, `CLAUDE.md`, `README.md`, `commands/setup-routines.md`
and the propose rows in both top-level documents. The grep gate returns only
history-labelled prose. Suite green at 2160 (the drop from 2190 is the removed
cursor and window cases).

### Discovered Insights

- **Insight**: Retiring a `.workaholic/` root file is a lockstep amendment in the
  same way adding one is. `proposal-cursor` was allowed at the root by two
  sources of truth (`layout-doctor.sh` and `validate-ticket.sh`) plus
  `rules/workaholic.md`, and its allowance was justified in prose by a fold that
  `cursor.sh` performed — a script this ticket deletes. Leaving the entry would
  have documented a fold that could no longer happen.
  **Context**: The entry was dropped from all three, so a surviving git-ignored
  file is now *reported* by `layout-doctor.sh` instead of silently tolerated.
  Nothing writes that path any more, so no write can be blocked by the change;
  what a developer sees is a finding naming a stale file, with the `rm` in the
  runbook's §7. CI clones fresh, so it never sees one.
- **Insight**: The three template-set assertions in the suite are the thing that
  actually enforces the enumeration. Deleting `routines/propose.md` failed seven
  assertions across four test functions, each naming a different document's idea
  of the set — which is exactly the drift the lockstep rule exists to catch, and
  the reason `list-routine-templates.sh` enumerates by scanning the directory
  rather than by listing ids in code.
