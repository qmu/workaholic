---
created_at: 2026-09-02T04:31:17+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-a-routine-tick-from-parking-on-a-permission-prompt
merge_policy:
verification_handoff: 
---

# Remove the prompt-raising read at its source in the propose path

## Overview

PROPOSED. The operator's instruction is explicit about where the repair goes: **at the
source** — restructure the command's own reads and acts so no prompt is ever raised, or rule
on the specific allow entry a person can approve. Not a retry, not a fallback, not leaving
the tick to park hourly.

This ticket takes the candidate the diagnosis ticket named and removes it, choosing between
the two sanctioned repairs on evidence rather than preference.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the run completes or fails; it does not wait

## Key Files

- `plugins/workaholic/commands/propose.md` — where a rule the run needs is inlined, if that
  is the repair chosen.
- `plugins/workaholic/skills/propose/SKILL.md`, `reference/loop.md` — the references that
  make a session reach.
- `plugins/workaholic/rules/shell.md`, `plugins/workaholic/rules/general.md` — the rules
  that already say what a run may reach for; if they are not being obeyed, the repair is
  structural rather than another sentence.
- `.claude/settings.json` — `permissions.allow`, if the ruled repair is an allow entry.
- `plugins/workaholic/skills/workaholify/SKILL.md`, *Where an unattended run's prompt policy
  is configured* — the configuration a run inherits; a per-repository allow entry belongs
  in the same place the policy is already recorded.

## Implementation Steps

1. Take the named candidate. Decide between the two repairs the operator sanctioned, and
   write the decision down with its reason:
   - **Restructure**, when what the run needs is content the command can carry itself, so
     nothing has to be fetched at run time. This is the preferred repair because it removes
     the reach rather than permitting it.
   - **An allow entry**, when the run genuinely must touch that path and the shape is one an
     allowlist can name exactly. Ruled once, recorded where the prompt policy is recorded,
     and never a wildcard that permits more than the named shape.
2. Apply the chosen repair. Where it is a restructure, the content moves into the surface
   the session actually reads, so the reach never happens; where it is an allow entry, add
   exactly the shape and nothing wider.
3. Do not add a retry, a timeout, or a fallback around the prompt. A run that works around
   a prompt still spends its fire; the instruction is that the prompt is never raised.
4. If the diagnosis named two candidates it could not separate, take both — the cost of
   removing one reach that was not the cause is a smaller run, and the cost of guessing
   wrong is another hour of parked ticks.
5. Verify against the same evidence the diagnosis used: the reach that would have been
   composed is no longer available to compose, or the shape is now named by the allowlist.
6. Update `plugins/workaholic/rules/shell.md`, `rules/general.md`, `workaholic:workaholify`
   and `CLAUDE.md` in the same change wherever the repair changes what those documents say.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The named cause is removed at its source, by restructure or by a named allow entry.
- No retry, timeout or fallback around a prompt was added.
- The decision between the two repairs is recorded with its reason.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- A `/propose` run in a container reaches its report without a prompt.

**Gate** — what must pass before approval:

- The end-to-end run above completes; a run that still parks is not this ticket done.

## Considerations

- An allow entry is the weaker repair: it permits the reach rather than removing it, and it
  is a per-account or per-repository record that a fresh container may not carry. Prefer the
  restructure and say why whenever the entry is chosen instead.

## Drive Findings — 2026-09-06

### The decision between the two repairs, and its reason

**Restructure.** The allow entry was rejected, and the reason is recorded in two durable places
(`rules/shell.md`, *And it is read at the CHECKOUT's path, never at `<src>`*, and
`workaholic:workaholify`, *Where an unattended run's prompt policy is configured*) rather than
only here:

- The entry that would be needed is `Read(//root/.claude/plugins/cache/**)` — a path **inside**
  the directory the harness classifies as sensitive. The prompt was classified as *an edit of a
  sensitive file*, so it is **not established** that a path-keyed Read entry satisfies the rule
  that actually fired; adding one would be a guess dressed as a fix. That is the same reasoning
  `workaholify/SKILL.md` already recorded for the 2026-09-02 case, applied unchanged.
- It is a **per-account** record a fresh routine container may not carry, so it fixes nothing
  reliably in the place the parking was measured.
- It would permit reading **every** plugin's cache in order to fix one file class.
- The ticket's own Considerations rank it the weaker repair and ask for the restructure wherever
  the reach can be removed. Here it can.

### What was removed, and the mechanism

The 2026-09-02 repair (issue #865) moved the reach off `sed`/`grep`/`cat`/`head` — which
`.claude/settings.json` allows by **prefix, with no path term** — and onto the Read tool, which
the same file allows **only under `Read(//home/**)`**. It removed a prompt-raising shape and
replaced it with one the allowlist covers **less**, which is why `[Propose]` went on parking
after it shipped. The diagnosis ticket's evidence 1-4 is exactly this gap; this ticket closes it.

The repair separates the two reaches **by their permission class**, which is the class the
container actually distinguishes:

- **`bash` keeps `<src>`.** `Bash(bash:*)` is a prefix rule with no path term, and the diagnosis
  measured (evidence 7) that scripts under `/root/.claude/plugins/cache/...` run with no prompt.
  The newest-tree resolution is untouched: the code that executes is still the newest on the
  machine.
- **A `Read` takes the checkout's own path** (`plugins/workaholic/…`) — inside the workspace,
  needing no allowlist entry and not classified sensitive. A plugin markdown file is prose and
  the same bytes are there.

Changed at the source, not around it — no retry, no timeout, no fallback wraps a prompt:

1. `plugins/workaholic/rules/shell.md` — the rule's home gains the path half.
2. `plugins/workaholic/rules/general.md` — the harness-binding bullet said *read … from that
   `src`*; it now says `bash` from `src`, Read from the checkout. **This bullet was the
   authority the routine prompts and ceilings were obeying**, so leaving it would have made the
   repair a contradiction rather than a rule.
3. `plugins/workaholic/commands/{implement,specificate,propose,moderate}.md` — one wording,
   byte-identical, beside the sentence it completes.
4. `plugins/workaholic/skills/workaholify/routines/{implement,moderate,propose}.md` — the load
   fallback now reads the command body from the checkout; scripts still take `<src>`.
5. `plugins/workaholic/skills/check-deps/SKILL.md` — the source-resolution contract states the
   split, so the two documents cannot drift.
6. `plugins/workaholic/skills/workaholify/SKILL.md` — the decision and the refused lever.
7. `CLAUDE.md` — updated in the same change.

### Candidate B — verified already removed, by a different change

The diagnosis ranked B (a Slack connector write in the `/propose` path) below A and asked for
both. **It is already gone at its source**: the Slack turn moved to `/infinite-development` on
2026-09-03, and `/propose` posts and reads nothing there. Verified in this tree — `grep` for
`mcp__`, `slack_send`, `slack_read`, `add_reaction`, `inbox_tray` and `受理` across
`commands/propose.md` and `skills/propose/**` returns **no call site**; the single textual match
is a comment in `list-unannounced-closed-asks.sh`, which the **tick** calls, not `/propose`. The
command ceiling already states *It posts nothing to Slack.* Nothing was added for B: removing a
reach that no longer exists would be a change with no subject.

### Candidate C — closed

`skills/propose/reference/loop.md` said *Write the body to a file* and named no directory — a
shape nobody had enumerated. It now names the repository as the destination and cites the
confinement guard. Cheap, as the diagnosis said.

### Verification

- `node scripts/test-workflow-scripts.mjs` — **6645 passed, 0 failed** (in this worktree, and
  the same on the main checkout with the identical patch). The suite pins the new wording
  byte-identically across the four ceilings, that no routine prompt sends a Read to `<src>`, and
  that every prompt still runs its scripts from `<src>`.
- `node scripts/build-plugins/build.mjs && verify.mjs && validate-metadata.mjs` — clean, and
  `outputs/` regenerates with **no diff**.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` — `conforming: true`.

**One unreproduced failure is reported rather than buried.** The first worktree run of the suite
printed `6644 passed, 1 failed`; its stderr was not retained, so the row was not captured. The
immediate re-run with stderr captured printed `6645 passed, 0 failed`, as did the main-checkout
run of the identical patch. The suite documents a clock-dependent row of exactly this kind at
`test-workflow-scripts.mjs` (the `03-03` zero-width window note), which is the most likely
explanation, but **this run did not establish which row failed** and does not claim to.

**What this run could NOT verify, and it is the gate's third line**: *A `/propose` run in a
container reaches its report without a prompt.* That needs a routine-fired container, which this
session is not. It is the unit's declared handoff and the reason its pull request stays open.

## Final Report

**Outcome: implemented.**

- *The named cause is removed at its source, by restructure or by a named allow entry.* — Done,
  by restructure. Candidate A's reach is gone from every surface that directed it: no routine
  prompt and no command ceiling now points a Read at `<src>`, and `rules/general.md`, which
  authorized the shape, was corrected rather than left to contradict the repair. Candidate B was
  verified already removed at its source by the 2026-09-03 Slack move; candidate C is closed.
- *No retry, timeout or fallback around a prompt was added.* — None. The change is which path a
  read names.
- *The decision between the two repairs is recorded with its reason.* — In `rules/shell.md` and
  `workaholify/SKILL.md`, with the rejected lever and all four of its costs, plus the one residue
  it does not reach.

**The residue is stated rather than designed away.** A **consuming** repository that installs the
plugin without vendoring it has no `plugins/workaholic/` in its workspace, so `<src>` is the only
tree carrying the command body and the Read of it cannot be moved. There the operator's own allow
entry is the remedy, recorded where the prompt policy is recorded. This repository adds none,
because here the reach is gone and an entry would permit one that no longer happens.

**A note for the reader of this unit's route.** The unit takes the `handoff` route on a **derived**
declaration — `verification-handoff.sh` reads a `## Key Files` entry naming `.claude/`, and this
ticket lists `.claude/settings.json` under a conditional *if the ruled repair is an allow entry*.
The ruled repair was **not** the allow entry, so no `.claude/` path was edited by this work at all.
The derivation is doing its job conservatively and is not being worked around; it is named here
because the pull request's `## Handoff` will quote a reason this change did not, in the end, meet.
