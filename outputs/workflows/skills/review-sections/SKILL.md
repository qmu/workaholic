---
name: review-sections
description: Generate the branch story's review content (a Motivation past-context paragraph, Outcome, Concerns, Successful Development Patterns) from archived tickets and deferred concern verdicts. Used by the report workflow when assembling a PR story.
---

# Review Sections

Guidelines for generating the branch story's review content from archived tickets: the past-context paragraph that folds into Motivation, plus the Outcome, Concerns, and Successful Development Patterns sections.

**Omit, never pad.** The rule is stated once, in `report`'s *Omit, never pad*: a section with nothing to report is **absent** from the story, not rendered as "None". Two of the fields below are empty far more often than not, and returning an empty string is the correct, expected answer — the report workflow then writes no section at all. Never invent content to fill a heading, and never refer to a section by number: numbers are assigned sequentially over whichever sections survive.

**Budget, then omit.** Omitting alone was measured not to work: the sections this skill writes grew 25-115% in length while the number of items in them held steady, because their only limits were "one paragraph" and "bullet points" — phrases with no number in them. Each section below now states a **line budget** (blank lines and heading included), and the budgets are `report`'s single source — *Every section has a line budget* carries the table and the reason. A section over budget is **cut**, never justified with an extra sentence.

## Input

- Branch name
- List of archived ticket paths
- Deferred concern verdicts file path — a per-run path the report workflow supplies (e.g. `$RUN_DIR/deferred-concern-verdicts.json`, under a `mktemp -d` dir unique to that run; optional — empty/missing if no active deferred concerns). Never a constant `/tmp/...` path shared across runs.
- Collected commit bodies (the `collect-commits.sh` output): each commit's structured body may carry `Concerns:` and `Insights:` keys recorded at commit time. These are a resilient secondary source for sections 6 and 7 — they survive even when a ticket is sparse or has been pruned.

## Analysis Process

1. **Read all archived tickets** for the branch using Glob pattern
2. **Extract relevant content** from each ticket:
   - Overview section for accomplishments
   - Related History section for patterns
   - Considerations section for concerns
   - Final Report section (if present) for outcomes
3. **Read deferred concern verdicts** from the verdicts file path (context only — resolved verdicts tell you what this branch fixed, which often belongs in section 4/5 prose). Open stream concerns are **not** re-surfaced in section 6: the feedback stream itself is the durable memory, and section 6 records this branch's own concerns only (the `(carried from PR #N)` convention retired with the concern→feedback merger, 2026-07-28).

## Section Guidelines

### `historical_context` — a paragraph inside Motivation, not a section

Past context is part of the **why**, so it reads as a closing paragraph of the story's
Motivation rather than as a Historical Analysis section that must be filled. Return the
paragraph itself, with no heading.

- Draw it from the tickets' Related History sections: what similar problem was solved
  before, and how that shaped this approach.
- One paragraph. If it needs more, it is a concern or an outcome, not context.
- **Return `""` when the tickets carry no related history** — which is the common case.
  The report workflow then appends nothing, and Motivation reads exactly as it would have.
  Do not write "No significant historical patterns identified."; that sentence is the
  padding this field exists to stop.

### Outcome — 5 lines

Summarize what was accomplished across all tickets.

- List key deliverables and features implemented
- Focus on user-visible or architecturally significant changes
- Use bullet points for clarity
- Include metrics if available (files changed, tests added, etc.)
- **Five lines.** This section says what the branch achieved; the Changes section already
  said what each ticket did, so anything here that re-narrates a ticket is a duplicate to
  delete rather than a line to spend

### Concerns

Risks, trade-offs, limitations, and forward-looking suggestions discovered during implementation. Each concern is one insight expressed as a title, a description, and how to fix it — with a severity label. Emit one `###` block per concern using this exact structure (it is parsed by `extract-deferred-concerns.sh` on `/ship`):

```markdown
### <Concise title>

- **Severity:** moderate
- **Description:** <what the problem/risk is> (see [hash](url) in path/to/file.ext)
- **How to Fix:** <the concrete fix or improvement>
```

Compose the section from three sources, in this order:

2. **New concerns** — extracted from the Considerations sections of this branch's tickets **and** the `Concerns:` keys of the collected commit bodies. Deduplicate where a ticket Consideration and a commit Concern describe the same issue.
3. **Confirmed documentation drift** — drift the release-readiness role confirmed while assessing release readiness (its `doc-drift.sh` candidates judged real in `report`'s `## Assess Release Readiness`). Render each as a block above: title the concern after the stale doc (e.g. `Documentation drift: CLAUDE.md skill index`), set Description to which structural change landed without the doc being updated, and How to Fix to the specific edit the doc needs. Default `severity: moderate`. Use only the drift the release-readiness role already confirmed — do **not** re-run or re-judge the script here (this skill stays script-free so it keeps resolving cross-agent via the `skills` CLI).

For new concerns:

- **Severity** is a label, not a number: `urgent` (act now), `moderate` (should fix), `low` (nice-to-have). Choose based on impact and urgency; default `moderate`.
- Frame the risk and the constructive suggestion together (risk in Description, suggestion in How to Fix) — they are two angles on the same insight.
- Put the commit_hash from ticket frontmatter (if present) and the file path inside the Description.
- **Seven lines per block**, heading and severity included — about two lines of Description and two of How to Fix. The previous wording was "one paragraph each", and blocks drifted to 11 lines while the number of concerns per story did not move at all: the growth was words per concern, not concerns. Trim the words; never drop a concern to hit the budget.
- **Grade honestly in both directions.** Severity rides on the extracted record *and*
  decides whether the reviewer sees the block: the story file keeps every severity, and
  the PR body drops the `low` ones (`report`, Concerns section). A deflated
  `moderate` is a real risk hidden from review; an inflated `low` is noise in front of it.

If both sources are empty, return `""` — the report workflow then writes no Concerns
section. Never write "None".

### Successful Development Patterns — 6 lines, one per pattern

Capture effective patterns discovered during this branch's development. **This is the
section most easily padded**, because a plausible-sounding pattern can be written about
any branch — so the bar is deliberately high, and the expected answer on most branches is
an empty string.

The high bar was already written here and it did not hold: the section appeared in **every
single** story measured on both sides of the change, and doubled in length. Treat both
limits as real — the empty string is the normal answer, and when a pattern is genuinely
found it is **one line**, because a pattern that needs a paragraph to state is an insight
for the ticket's Final Report, not a reusable practice.

- Extract positive observations from ticket Considerations sections
- Extract "what went well" insights from Final Report sections and the `Insights:` keys of the collected commit bodies
- Identify effective approaches from Implementation Steps that proved successful
- Look for recurring successful strategies across multiple tickets
- Categories to consider:
  - Architectural decisions that worked well
  - Testing strategies that caught issues
  - Refactoring approaches that improved code quality
  - Collaboration or workflow patterns that were effective
  - Tooling or automation choices that saved effort
- Each pattern should include reasoning for why it worked
- A pattern qualifies when it is specific enough to change what someone does next time
  **and** came out of *this* work — not a restatement of a standard the repository already
  documents
- **Return `""` unless a pattern was really found.** Never write "None"

## Output Format

Return JSON with the following structure:

```json
{
  "historical_context": "One paragraph of past context for Motivation, or \"\"",
  "outcome": "Bullet list of accomplishments...",
  "concerns": "One ### block per concern, or \"\"",
  "development_patterns": "Effective patterns, or \"\""
}
```

Each field carries markdown-formatted content ready to be inserted into the story file.

**An empty string means the section is omitted, and that is a normal result.** Only
`outcome` is always written; `historical_context` folds into Motivation when present, and
`concerns` and `development_patterns` each become a section only when non-empty. The field
formerly named `historical_analysis` is gone — past context is a Motivation paragraph now,
not a section — so a caller reading that key will find nothing.
