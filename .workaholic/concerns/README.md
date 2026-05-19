# Concerns

Carry-over corpus of unresolved Concerns and Ideas surfaced in branch stories.

Each story produced by `/report` contains sections 6 (Concerns) and 7 (Ideas). When that branch is shipped via `/ship`, those bullets are persisted here — one file per bullet — so future runs can revisit them, judge whether they remain relevant, and emit housekeeping tickets for ones that linger.

Concerns and ideas live in the same directory under the umbrella name **"concerns"** because an idea is the constructive counterpart of a concern. The two are distinguished by a `kind:` frontmatter field, not by directory placement.

## Lifecycle

1. **Write (on `/ship`)** — After the PR is merged, `plugins/core/skills/ship/scripts/extract-carryover.sh` parses the just-shipped story, splits sections 6 and 7 into individual bullets, and writes one file per bullet into this directory.
2. **Read + judge (on `/report`)** — Before generating the next story, the `work:carryover-judge` subagent lists every file with `status: active`, judges whether it has been resolved by current-branch work, and returns verdicts. Resolved files are updated in place (status flipped, resolving PR recorded). Active items remain untouched.
3. **Surface (in section 6/7)** — The section-reviewer pulls active carry-overs and prepends them to the new story's Concerns/Ideas sections, prefixed with `(carried from PR #N)`.
4. **Promote to ticket** — Active carry-overs that survive more than one PR cycle become housekeeping tickets under `.workaholic/tickets/todo/` so the work queue stays loaded with accumulated risks and improvement ideas.

Resolved items are **marked, not deleted** — the audit trail survives misclassifications.

## Filename Convention

```
<pr-number>-<slug>-<kind>.md
```

- `<pr-number>` — Origin PR number (numeric).
- `<slug>` — Short kebab-case description (5-8 words max).
- `<kind>` — Either `concern` or `idea`.

Examples:

```
42-pathspec-exclusion-modern-git-concern.md
42-pathspec-exclusion-modern-git-idea.md
```

When Concern N and Idea N in the story refer to the same surfaced insight (the idea is the constructive counterpart of the concern), they share the `<pr-number>-<slug>` prefix; only the trailing `-concern` / `-idea` differs.

**Why not `YYYYMMDDHHmmss-*.md`?** Because `plugins/work/hooks/validate-ticket.sh` rejects ticket-shaped filenames written outside `.workaholic/tickets/`. The PR-number prefix sidesteps the hook while still keeping files sortable by origin.

## Frontmatter Schema

```yaml
---
kind: concern               # concern | idea
origin_pr: 42
origin_pr_url: https://github.com/qmu/workaholic/pull/42
origin_branch: work-20260417-092936
origin_commit: 7eab801
created_at: 2026-05-19T11:06:56+09:00
status: active              # active | resolved
resolved_by_pr:             # filled when status flips to resolved
resolved_by_commit:
paired_slug: 42-pathspec-exclusion-modern-git
housekeeping_ticket_emitted: false
---
```

### Fields

- **kind** — `concern` for risks/trade-offs (from section 6), `idea` for forward-looking suggestions (from section 7).
- **origin_pr / origin_pr_url / origin_branch / origin_commit** — Provenance recorded by `extract-carryover.sh`. Never edited after creation.
- **created_at** — ISO 8601 timestamp at extraction time.
- **status** — `active` while still open; `resolved` once the judge confirms the item has been addressed elsewhere.
- **resolved_by_pr / resolved_by_commit** — Filled only when status flips to `resolved`.
- **paired_slug** — `<pr-number>-<slug>` prefix shared with the sibling item (the matching idea for a concern, or vice versa). Optional — present only when the story emitted Concern N and Idea N symmetrically.
- **housekeeping_ticket_emitted** — Idempotency guard. Flipped to `true` once `emit-housekeeping-tickets.sh` has created a ticket for this item.

### Body

The original bullet copied verbatim from section 6 (concerns) or section 7 (ideas) of the story, including its `(see [hash](url) in path/to/file.ext)` reference. Preserving the bullet verbatim lets future judges and readers see the original phrasing.

## Where Things Are Written

| Lifecycle step | Script | Skill |
| -------------- | ------ | ----- |
| Extract on ship | `plugins/core/skills/ship/scripts/extract-carryover.sh` | `core:ship` |
| List active for judging | `plugins/core/skills/report/scripts/list-active-carryovers.sh` | `core:report` |
| Apply verdicts | `plugins/core/skills/report/scripts/apply-carryover-verdicts.sh` | `core:report` |
| Emit housekeeping tickets | `plugins/core/skills/report/scripts/emit-housekeeping-tickets.sh` | `core:report` |

All multi-step parsing and JSON munging lives in scripts, not in skill markdown, per the Shell Script Principle in `CLAUDE.md`.
