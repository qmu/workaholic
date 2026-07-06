# Concerns

Carry-over corpus of unresolved insights surfaced in branch stories.

Each story produced by `/report` contains section 6 (Concerns) — risks, trade-offs, limitations, and forward-looking suggestions. When that branch is shipped via `/ship`, each concern is persisted here as its own file, so future runs can revisit them and judge whether they remain relevant.

A "concern" here is a single insight — a problem framed as a title, a description, and how to fix it, tagged with a severity label. The risk and the constructive suggestion are two angles on the same thing, kept together in one file.

## Directory Layout

```
.workaholic/concerns/
  <pr-number>-<slug>.md          # active concerns
  archive/
    <pr-number>-<slug>.md        # resolved concerns, preserved for audit
```

## Lifecycle

1. **Write (on `/ship`)** — After the PR is merged, `plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh` parses each `###` concern block in section 6 of the just-shipped story and writes one file per concern into this directory.
2. **Read + judge (on `/report`)** — Before generating the next story, a `general-purpose` deferred-concern-judge subagent lists every file at the top level of `.workaholic/concerns/` (excluding `archive/`), judges whether it has been resolved by current-branch work, and returns verdicts. Resolved files have status/resolver fields recorded and are then moved to `archive/`. Active items stay at the top level.
3. **Surface (in section 6)** — The section-reviewer pulls active carry-overs and prepends them to the new story's section 6, prefixed with `(carried from PR #N)`.
4. **Address one by one** — Active concerns are picked up through ordinary development work, not auto-promoted into tickets. Once a concern is addressed and the next `/report` runs, the carry-over judge detects the fix and moves the file to `archive/`.

Resolved items are **archived, not deleted** — the audit trail survives misclassifications.

## Filename Convention

```
<pr-number>-<slug>.md
```

- `<pr-number>` — Origin PR number (numeric).
- `<slug>` — Short kebab-case description (5-8 words max).

Example:

```
42-pathspec-exclusion-modern-git.md
```

**Why not `YYYYMMDDHHmmss-*.md`?** Because `plugins/workaholic/hooks/validate-ticket.sh` rejects ticket-shaped filenames written outside `.workaholic/tickets/`. The PR-number prefix sidesteps the hook while still keeping files sortable by origin.

## File Format

```markdown
---
type: Concern               # OKF concept type (non-empty)
mission:                    # optional — slug of the mission this concern advances (inherited from the story)
tickets: [20260417092936-foo.md]   # tickets this concern arose from (inherited from the story; [] when none)
origin_pr: 42
origin_pr_url: https://github.com/qmu/workaholic/pull/42
origin_branch: work-20260417-092936
origin_commit: 7eab801
created_at: 2026-05-19T11:06:56+09:00
severity: moderate          # urgent | moderate | low
status: active              # active | resolved
resolved_by_pr:             # filled when status flips to resolved
resolved_by_commit:
---

# <Title>

## Description

<What the problem/risk is, including the (see [hash](url) in path/to/file.ext) reference.>

## How to Fix

<The concrete fix or improvement.>
```

### Frontmatter Fields

- **type** — Always `Concern`. The non-empty `type` is what makes the file an [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf) concept document; written first.
- **mission** — Optional. The `slug` of the mission this concern advances, inherited from the shipped story's `mission:` frontmatter. Empty when the story carried no mission. This is the machine-readable concern→mission relation, so a deferred concern is traceable to its mission, not only to its origin PR.
- **tickets** — The archived ticket filenames the concern arose from, inherited from the shipped story's `tickets:` list (the concern→tickets relation). `[]` when the story listed none.
- **origin_pr / origin_pr_url / origin_branch / origin_commit** — Provenance recorded by `extract-deferred-concerns.sh`. Never edited after creation.
- **created_at** — ISO 8601 timestamp at extraction time.
- **severity** — A label, not a number: `urgent` (act now), `moderate` (should fix), `low` (nice-to-have). Assigned by the section-reviewer when the concern is first written; defaults to `moderate`.
- **status** — `active` while still open; `resolved` once the judge confirms the item has been addressed elsewhere.
- **resolved_by_pr / resolved_by_commit** — Filled only when status flips to `resolved` (at which point the file is moved to `archive/`).

### Body

Three parts: a **title** (`#`), a **Description** of the problem (carrying the `(see [hash](url) in path)` reference), and **How to Fix** it. `extract-deferred-concerns.sh` builds this from the matching `###` block in the story's section 6.

## Where Things Are Written

| Lifecycle step | Script | Skill |
| -------------- | ------ | ----- |
| Extract on ship | `plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh` | `workaholic:ship` |
| List active for judging | `plugins/workaholic/skills/report/scripts/list-active-deferred-concerns.sh` | `workaholic:report` |
| Apply verdicts (move resolved → archive/) | `plugins/workaholic/skills/report/scripts/apply-deferred-concern-verdicts.sh` | `workaholic:report` |

All multi-step parsing and JSON munging lives in scripts, not in skill markdown, per the Shell Script Principle in `CLAUDE.md`.
