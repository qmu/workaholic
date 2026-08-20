---
name: review-sections
description: Generate the branch story's review content (a Motivation past-context paragraph, Outcome, Concerns, Successful Development Patterns) from archived tickets and deferred concern verdicts. Used by the report workflow when assembling a PR story.
---

# Review Sections

Guidelines for generating the branch story's review content from archived tickets: the past-context paragraph that folds into Motivation, plus the Outcome, Concerns, and Successful Development Patterns sections.

Two rules govern every field, both stated canonically in `story`:

- **Omit, never pad** (*Omit, never pad*): a section with nothing to report is **absent** from the story, never rendered as "None". Two of the fields below are empty far more often than not, and returning an empty string is the correct, expected answer. Never invent content to fill a heading, and never refer to a section by number — numbers are assigned sequentially over whichever sections survive.
- **Budget, then omit** (*Every section has a line budget* carries the table and the reason): each section states a line budget, blank lines and heading included. A section over budget is **cut**, never justified with an extra sentence.

## Input

- Branch name
- List of archived ticket paths
- Deferred concern verdicts file path — a per-run path the report workflow supplies (e.g. `$RUN_DIR/deferred-concern-verdicts.json`, under a `mktemp -d` dir unique to that run; optional — empty/missing if no active deferred concerns). Never a constant `/tmp/...` path shared across runs.
- Collected commit bodies (the `collect-commits.sh` output): each commit's structured body may carry `Concerns:` and `Insights:` keys recorded at commit time — a resilient secondary source that survives a sparse or pruned ticket.

## Analysis Process

1. Read all archived tickets for the branch.
2. Extract from each: Overview (accomplishments), Related History (patterns), Considerations (concerns), Final Report (outcomes).
3. Read the deferred concern verdicts file (context only — resolved verdicts tell you what this branch fixed, which often belongs in Outcome prose). Open stream concerns are NOT re-surfaced in Concerns: the feedback stream is the durable memory, and Concerns records this branch's own concerns only.

## Section Guidelines

### `historical_context` — a paragraph inside Motivation, not a section

Past context is part of the **why**, so it reads as a closing paragraph of the story's Motivation. Return the paragraph itself, with no heading.

- Draw it from the tickets' Related History sections: what similar problem was solved before, and how that shaped this approach.
- One paragraph. If it needs more, it is a concern or an outcome, not context.
- Return `""` when the tickets carry no related history — the common case. Do not write "No significant historical patterns identified."; that sentence is the padding this field exists to stop.

### Outcome — 5 lines

Summarize what was accomplished across all tickets, as bullets.

- Key deliverables; user-visible or architecturally significant changes; metrics if available
- Five lines: the Changes section already said what each ticket did, so anything here that re-narrates a ticket is a duplicate to delete

### Concerns

Risks, trade-offs, limitations, and forward-looking suggestions discovered during implementation. Emit one `###` block per concern using this exact structure (parsed by `extract-deferred-concerns.sh` on `/ship`):

```markdown
### <Concise title>

- **Severity:** moderate
- **Description:** <what the problem/risk is> (see [hash](url) in path/to/file.ext)
- **How to Fix:** <the concrete fix or improvement>
```

Compose the section from two sources, in this order:

1. **New concerns** — from the Considerations sections of this branch's tickets and the `Concerns:` keys of the collected commit bodies. Deduplicate where a ticket Consideration and a commit Concern describe the same issue.
2. **Confirmed documentation drift** — drift the release-readiness role confirmed (its `doc-drift.sh` candidates judged real in `story`'s `## Assess Release Readiness`). Title the concern after the stale doc (e.g. `Documentation drift: CLAUDE.md skill index`), Description = which structural change landed without the doc updating, How to Fix = the specific edit needed. Default `severity: moderate`. Use only drift already confirmed — do NOT re-run or re-judge the script here (this skill stays script-free so it keeps resolving cross-agent via the `skills` CLI).

For new concerns:

- Severity is a label, not a number: `urgent` (act now), `moderate` (should fix), `low` (nice-to-have); default `moderate`.
- Frame the risk (Description) and the constructive suggestion (How to Fix) together — two angles on one insight.
- Put the commit hash (if present in ticket frontmatter) and the file path inside the Description.
- Seven lines per block, heading and severity included — about two lines of Description and two of How to Fix. Trim the words; never drop a concern to hit the budget.
- Grade honestly in both directions: the story file keeps every severity, and the PR body drops the `low` ones (`story`, Concerns section) — a deflated `moderate` is a real risk hidden from review; an inflated `low` is noise in front of it.

If both sources are empty, return `""` — the report workflow then writes no Concerns section. Never write "None".

### Successful Development Patterns — 6 lines, one per pattern

Capture effective patterns discovered during this branch's development. This is the section most easily padded — a plausible-sounding pattern can be written about any branch — so the bar is deliberately high and the expected answer on most branches is an empty string. A pattern that is genuinely found is one line; one that needs a paragraph is an insight for the ticket's Final Report, not a reusable practice.

- A pattern qualifies when it is specific enough to change what someone does next time AND came out of *this* work — not a restatement of a standard the repository already documents
- Extract from ticket Considerations (positive observations), Final Reports and commit-body `Insights:` keys (what went well), and Implementation Steps that proved effective
- Include the reasoning ("why it worked"), not just the action
- Return `""` unless a pattern was really found. Never write "None"

## Output Format

Return JSON:

```json
{
  "historical_context": "One paragraph of past context for Motivation, or \"\"",
  "outcome": "Bullet list of accomplishments...",
  "concerns": "One ### block per concern, or \"\"",
  "development_patterns": "Effective patterns, or \"\""
}
```

Each field carries markdown-formatted content ready for the story file. An empty string means the section is omitted, and that is a normal result — only `outcome` is always written.

## Caveats

- The `(carried from PR #N)` convention is retired (concern→feedback merger, 2026-07-28): never prepend open stream concerns to this branch's Concerns.
- The `historical_analysis` output field is retired — past context is a Motivation paragraph, not a section; a caller reading that key finds nothing.
- The line budgets replaced count-free phrasing ("one paragraph", "bullet points") after sections were measured growing 25-115% with item counts flat — keep budgets numeric.
