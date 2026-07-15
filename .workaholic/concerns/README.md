# Concerns

Carry-over corpus of unresolved insights surfaced in branch stories.

Each story produced by `/report` contains section 6 (Concerns) — risks, trade-offs, limitations, and forward-looking suggestions. When that branch is shipped via `/ship`, each concern is persisted here as its own file, so future runs can revisit them and judge whether they remain relevant.

A "concern" here is a single insight — a problem framed as a title, a description, and how to fix it, tagged with a severity label. The risk and the constructive suggestion are two angles on the same thing, kept together in one file.

## Directory Layout

```
.workaholic/concerns/
  <concern_id>.md          # active concerns
  index.md                 # OKF bundle index (generated; never a concern)
  archive/
    <concern_id>.md        # resolved / accepted / superseded, preserved for audit
```

## Lifecycle

1. **Write (on `/ship`)** — After the PR is merged, `plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh` parses each `###` concern block in section 6 of the just-shipped story and writes one file per concern into this directory.
2. **Read + judge (on `/report`)** — Before generating the next story, a `general-purpose` deferred-concern-judge subagent lists every file at the top level of `.workaholic/concerns/` (excluding `archive/`), judges whether it has been resolved by current-branch work, and returns verdicts. Resolved files have status/resolver fields recorded and are then moved to `archive/`. Active items stay at the top level.
3. **Surface (in section 6)** — The section-reviewer pulls active carry-overs and prepends them to the new story's section 6, prefixed with `(carried from PR #N)`.
4. **Address one by one** — Active concerns are picked up through ordinary development work, not auto-promoted into tickets. Once a concern is addressed and the next `/report` runs, the carry-over judge detects the fix and moves the file to `archive/`.

Resolved items are **archived, not deleted** — the audit trail survives misclassifications.

## Filename Convention

```
<concern_id>.md
```

`<concern_id>` is a stable kebab slug **derived from the concern's title**: markdown links and code spans are unwrapped, everything outside `[a-z0-9 ]` becomes a space, and the first **6** words are joined with `-` (truncated to 60 chars). A leading `(carried from …)` prefix is stripped first, so a carried concern derives the same id as its original.

Example — "The commit-subject rule binds on no path" becomes:

```
the-commit-subject-rule-binds-on.md
```

**The id, not the filename, is authoritative.** Readers key on the `concern_id` frontmatter field; `migrate-concern-identity.sh` renames files to match it. Three writers derive it and they must agree byte-for-byte — `ship/scripts/extract-deferred-concerns.sh` (mints on ship), `report/scripts/merge-concerns.sh` (mints a triage compound), and `report/scripts/migrate-concern-identity.sh` (back-fills and renames). A drift between them fails quietly: the extractor simply fails to find the concern and writes a second file for it.

**Why not `YYYYMMDDHHmmss-*.md`?** Because `plugins/workaholic/hooks/validate-ticket.sh` rejects ticket-shaped filenames written outside `.workaholic/tickets/`.

**Why not the old `<pr-number>-<slug>.md`?** That was the pre-identity scheme, and the PR prefix is what made one concern clone itself into a `carried-from` chain — the same concern re-filed under each new PR number. The identity collapse abolished it; provenance now lives in `origin_pr`, where re-sighting the concern does not change its name. `RESERVED = {README, index}` are never treated as concerns.

## File Format

```markdown
---
type: Concern               # OKF concept type (non-empty)
concern_id: pathspec-exclusion-modern-git   # stable identity, derived from the title
mission:                    # optional — slug of the mission this concern advances (inherited from the story)
tickets: [20260417092936-foo.md]   # tickets this concern arose from (inherited from the story; [] when none)
origin_pr: 42
origin_pr_url: https://github.com/qmu/workaholic/pull/42
origin_branch: work-20260417-092936
origin_commit: 7eab801
created_at: 2026-05-19T11:06:56+09:00
first_seen: 2026-05-19T11:06:56+09:00
last_seen: 2026-07-15T20:55:56+09:00
severity: moderate          # urgent | moderate | low
status: active              # active | resolved | accepted | superseded
compound: true              # only on a triage-minted compound (see merge-concerns.sh)
superseded_by: <concern_id> # only on a member folded into a compound
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
- **concern_id** — The stable identity, derived from the title (see Filename Convention). This field is authoritative; the filename follows it. Every writer must derive it the same way — a hand-chosen id is what let a compound clone itself.
- **origin_pr / origin_pr_url / origin_branch / origin_commit** — Provenance: **where the risk first surfaced**. Recorded by `extract-deferred-concerns.sh` when it mints a concern. Never edited after creation, so re-sighting a concern in a later PR does not rewrite its origin. A triage compound (`merge-concerns.sh`) **inherits these from its earliest-seen member** rather than claiming the triage act as its origin — a compound re-frames risks already on the books, so restarting its clock would break the chain back to the PR that raised it.
- **created_at** — ISO 8601 timestamp of when *this file* was minted (extraction, or the triage act for a compound). Distinct from `first_seen`, which can be older on an inheriting compound.
- **first_seen / last_seen** — The sighting window. `first_seen` is when the risk was first recorded (inherited by a compound from its earliest member); `last_seen` is bumped every time the concern is re-surfaced — by extraction's update-in-place, or by a triage merge, which is itself a sighting.
- **severity** — A label, not a number: `urgent` (act now), `moderate` (should fix), `low` (nice-to-have). Assigned by the section-reviewer when the concern is first written; defaults to `moderate`. There is **no re-grade mutator** — see the active concern `deferred-concern-severity-has-no-re`.
- **status** — `active` while open; `resolved` once addressed; `accepted` for a deliberate, documented won't-fix (both via `close-concern.sh`); `superseded` for a member folded into a compound (via `merge-concerns.sh`). All three non-active states live in `archive/`.
- **compound / superseded_by** — Written only by `merge-concerns.sh`: `compound: true` marks a triage-minted compound, and `superseded_by: <concern_id>` on each member points at it. **`compound: true` is therefore proof a file postdates the identity collapse** — a useful tell when judging whether a defect in a concern file is historical residue or is being produced right now.
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
