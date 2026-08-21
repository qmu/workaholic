# Story structure — template, budgets, frontmatter, index

The story content IS the PR description. The governing rules — *Omit, never pad*, the per-section budgets, the Handoff and Concerns contracts — are stated in the SKILL.md; this file carries the template and the per-section detail.

## Per-section line budgets

Each section carries a budget in lines, blank lines and heading included. These are the measured per-section means from before a 25% length regression on identical work — the length these sections had when the story read fine. "1-3 sentences" and "one paragraph" carry no number and were measured drifting (a "paragraph" to 15 lines, a concern block to 11).

| Section | Budget | Notes |
| ------- | -----: | ----- |
| Overview | 12 | the 2-3 sentence summary plus at most 3 one-line highlights |
| Motivation | 9 | +3 more when the section-reviewer returned a past-context paragraph |
| Changes — the journey diagram | 16 | the whole fence; the 3-5 subgraph ceiling is unchanged; full path only (>2 tickets) — omitted entirely on the lite path |
| Changes — each `### 3-N.` ticket block | 9 | heading plus the 1-3 sentence summary |
| Outcome | 5 | |
| Concerns — each `###` block | 7 | heading, severity, Description, How to Fix |
| Successful Development Patterns | 6 | when it appears at all; one line per pattern |
| Notes | 4 | |

The budget is a writing instruction, not a validator — nothing rejects a story for exceeding it — so the discipline is to reread and delete, never to append a sentence explaining why this branch needed more. Content that genuinely will not fit belongs somewhere that holds detail: a concern, the ticket's Final Report, or a doc. `## Handoff` and `## Deployment Evidence` are exempt (evidence, not prose — shortening evidence deletes a record); Concerns are budgeted per block so the count of concerns is never trimmed, only the words spent on each.

Measure a story with:

```bash
bash ../gather/scripts/story-sections.sh --table .workaholic/stories/<branch>.md
```

## Handoff (conditional, first, unnumbered)

Written ONLY for a unit `/drive` classified `handoff`. It comes before Overview and carries no number — the numbered sections are the branch's narrative, this is an instruction to the reader, and a handoff met after eight sections has failed at its only job. `shrink-pr-body.sh` treats it as non-droppable. Fixed content, four elements:

```markdown
## Handoff

**This branch is unfinished. Someone must continue it.**

- **Done:** <what is complete and pushed>
- **Not done:** <what remains, named as tickets where they exist>
- **Next step:** <the single concrete action for whoever takes this>
- **Attempted:** <the exact command that was run and its raw output, or "Nothing was
  attempted for the remaining work — the run ended first">
```

"Attempted" is raw output, never a verdict: `deploy.sh → exit 127: gh: command not found` is actionable; "deployment seemed human-only" is not.

**The declared-handoff variant.** A unit routed here by `verification_handoff:` (`drive`
§6) has finished its work and cannot prove it, so the lead line states that instead — the elements
and their order do not move:

```markdown
## Handoff

**This branch is complete but unverified here. Someone must verify it before it merges.**

- **Done:** <what is complete and pushed>
- **Not done:** <the declared verification, quoted verbatim from `verification_handoff:`>
- **Next step:** <run it where the credential/device/account exists, then merge>
- **Attempted:** Not attempted — declared unrunnable in an unattended environment at
  ticket creation (`verification_handoff:` on <ticket or mission>).
```

A lead line claiming the branch is unfinished when the code is done would send the reader hunting
for missing work; naming the verification is what makes the pull request actionable.

## Template

````markdown
## 1. Overview

[overview-writer `overview`: 2-3 sentence summary.]

**Highlights:**

1. [highlights[0]]
2. [highlights[1]]
3. [highlights[2]]

## 2. Motivation

[overview-writer `motivation` paragraph.]

[Then, ONLY when the section-reviewer returned a non-empty `historical_context`: one closing
paragraph placing this work against what was solved before. Past context is part of the why —
there is no Historical Analysis section to fill.]

## 3. Changes

[ONLY on the full path (>2 archived tickets, Phase 2): the journey fence below. On the lite
path (≤2 tickets) no journey is generated — omit both lines entirely and open directly on the
per-ticket subsections.]

```mermaid
[overview-writer `journey.mermaid`]
```

[overview-writer `journey.summary`]

### 3-1. <Ticket title> ([hash](<repo-url>/commit/<hash>))

<1-3 sentence summary of what this ticket changed and why — intent and scope, not files.>

### 3-2. <Next ticket title> ([hash](<repo-url>/commit/<hash>))

<1-3 sentence summary.>

## 4. Outcome

[What was accomplished. Reference key tickets for details.]

## 5. Concerns

[One ### block per concern — format below. Omit the whole section when empty.]

## 6. Successful Development Patterns

[Bullet list, one line per pattern. Omit unless a pattern was really found.]

## 7. Release Preparation

[Omit when the release-readiness role reports releasable: true with no concerns and no
instructions. Otherwise:]

**Verdict**: [Ready for release / Needs attention before release]

- **Concern:** [something that gives pause about releasing]
- **Before release:** [a step to take before releasing]
- **After release:** [a step to take after releasing]

## 8. Notes

[Additional context that fits nowhere else. Omit when there is none.]
````

Changes guidelines: one subsection per ticket (not grouped by theme), chronological by ticket creation time. The commit hash MUST be a clickable link — `([abc1234](<repo-url>/commit/abc1234))`, never plain `(abc1234)`.

## Concerns block format

Parsed verbatim by `extract-deferred-concerns.sh` on `/ship` — follow it exactly, one `###` block per concern:

```markdown
### <Concise title>

- **Severity:** moderate
- **Description:** <what the problem/risk is> (see [hash](<repo-url>/commit/<hash>) in path/to/file.ext)
- **How to Fix:** <the concrete fix or improvement>
```

Example:

```markdown
### Inline shell invocations in drive

- **Severity:** moderate
- **Description:** `drive` still calls `ls -1` inline, violating the Shell Script Principle (see [7eab801](<repo-url>/commit/7eab801) in `plugins/workaholic/skills/drive/SKILL.md`)
- **How to Fix:** Extract the inline invocations into dedicated navigator scripts under the drive skill's `scripts/` directory
```

Reference the commit hash from the Changes section and the file path to investigate inside the Description. Severity: `urgent` = act now; `moderate` = a real risk you hit or clearly foresee; `low` = nice-to-have or passing observation. Every severity is extracted into the feedback stream at ship time; severity also decides whether the reviewer sees the block (the PR body drops `low`), so grade honestly in both directions. A legacy `- **Keep:** true` line is tolerated and ignored.

## Successful Development Patterns

A pattern qualifies when it is specific enough to change what someone does next time and came out of *this* work — not a restatement of a standard the repository already documents. Most branches have none; that is the expected outcome. One line per pattern, reasoning included ("why it worked"). Extract from ticket Considerations (positive observations), Final Reports (what went well), and Implementation Steps that proved effective. A pattern needing a paragraph belongs in the ticket's Final Report.

## Release Preparation rendering

Flatten the release-readiness JSON's `concerns[]`, `instructions.pre_release[]`, and `instructions.post_release[]` into the single labelled list, in that order. When all three are empty and `releasable` is true, write no section at all.

## Story Frontmatter

```yaml
---
type: Story
branch: <branch-name>
description: <one line summarising the branch work — the stories index entry>
tickets_completed: <count of tickets>
mission: [<slug-a>, <slug-b>]       # optional — every mission this branch advances (empty when none)
tickets: [<ticket-a.md>, <ticket-b.md>]   # the archived ticket filenames this story covers
---
```

`type: Story` is what makes the story readable as an OKF concept document — keep it first and never omit it. Both relations are derived in Phase 3 from the archived tickets:

- `tickets:` — the archived ticket filenames (basenames of `.workaholic/tickets/archive/<branch>/*.md`), so a mission can roll them up mechanically. `[]` when none.
- `mission:` — the union of the covered tickets' `mission:` slugs, de-duplicated, first-seen order; `[]` when none carry one. A single mission is spelled `[<slug>]`; a legacy bare `mission: <slug>` reads as one. `/ship` propagates this into any deferred concern extracted from the story. **Never ask the developer to choose** — tickets naming different missions are not a conflict: a branch really can advance two missions, and picking one would silently drop the work from the other's computed progress.

## Writing guidelines

- Third person ("The developer discovered...", never "I")
- Connect tickets into a narrative arc, not a list; highlight decision points and trade-offs
- Journey summary: 50-100 words

## The stories index writes itself

**Do not edit `.workaholic/stories/index.md`** (2026-08-19). Write the story's `description:` frontmatter — one line summarising the branch work — and the entry appears when `okf/scripts/refresh-index.sh` runs, which `/story` already does at its knowledge-commit seam. `stories/` is a generated flat area like every other one: the description comes from that field, falling back to whatever the prior region already carried for the link, so no existing entry degrades to a bare link on the first regeneration.

Writing a bullet by hand as well is actively harmful, not merely redundant: the region is regenerated, so a hand-inserted line is either overwritten or duplicated depending on where it landed.

`index.md` is the OKF reserved index filename. Everything outside the `<!-- okf:generated:begin -->` / `<!-- okf:generated:end -->` markers — the area's intro paragraph and its `README.md` link — is hand-owned and survives verbatim. Entries come out newest-first by filename, and `README.md` is not one of them.
