---
name: write-release-note
description: Release note content structure and guidelines for GitHub Releases.
user-invocable: false
---

# Write Release Note

Generate concise release notes from a branch story for GitHub Releases.

## Content Structure

```markdown
---
type: Release Note
branch: <branch-name>
released_at: <date -Iseconds output>
targets: [<deploy-target slug>, ...]
---

# <Story Title>

## Summary

<2-3 sentence overview extracted from story section 1>

## Key Changes

- <Highlight 1 from story>
- <Highlight 2 from story>
- <Highlight 3 from story>

## Changes

### Added
- <Entry from story Section 4 where ticket category is "Added">

### Changed
- <Entry from story Section 4 where ticket category is "Changed">

### Removed
- <Entry from story Section 4 where ticket category is "Removed">

## Metrics

- **Tickets Completed**: <tickets_completed from frontmatter>
- **Commits**: <commits from frontmatter>
- **Duration**: <duration_days from frontmatter> days (<duration_hours from frontmatter> hours)
- **Velocity**: <velocity from frontmatter> commits/<velocity_unit from frontmatter>

## Deployment Plan

<Written by the ship flow's drafting phase — see "The Deployment Plan" below.
Never hand-authored: the section is regenerated from the consolidation, so
anything typed into it is lost on the next refresh.>

## Deployment Verification

<Appended, one attempt per instructed deployment — see "Recording the
verification" below. Append-only: a later attempt never rewrites an earlier one.>

## Links

- [Pull Request](PR-URL)
- [Branch Story](.workaholic/stories/<branch-name>.md)
```

## Guidelines

1. **Summary**: Extract the essence of section 1 (Overview) from the story. Keep it under 50 words.

2. **Story Title (H1)**: Extract the first highlight from section 1 (Overview). Use the same derivation logic as PR title: first highlight text, appending "etc" if multiple highlights exist.

3. **Key Changes**: Use the highlights from section 1. If fewer than 3 highlights, summarize the most impactful changes from section 4 (Changes).

4. **Changes**: Group entries from story Section 4 by category (Added, Changed, Removed). The commit's `Category:` git trailer is the source — log-native, and it survives ticket pruning; read it via `git log --format='%(trailers:key=Category,valueonly)'`. (The ticket `category` frontmatter field is retired, 2026-08-07; tickets archived before then may still carry one, usable as a fallback for that history.) Each entry should be a concise one-line summary; omit empty subsections.

5. **Metrics**: Extract from story frontmatter:
   - `tickets_completed` field
   - `commits` field
   - `duration_hours` field (round to 1 decimal place)
   - `duration_days` field (use when available)
   - Format duration as: "N days (N hours)" when both fields exist, "N hours" when only hours exist
   - `velocity` field (round to 1 decimal place)
   - `velocity_unit` field
   - Format velocity as: "N commits/<unit>"
   - Omit velocity line when fields are absent

6. **Links**: The PR URL is provided as input (by the `workaholic:ship` Ship Flow, from its `pre-check.sh` output). Always include it.

7. **Frontmatter**: Always start the file with the YAML frontmatter block shown above — the non-empty `type` key makes the committed note readable as an [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf) concept document. It never reaches GitHub: the ship flow's `publish-release.sh` strips frontmatter before creating the Release. `targets` names the deployment targets the note carries a plan for; it is **stamped by the drafting phase**, not typed — a hand-written value is overwritten on the next refresh.

## The Deployment Plan

The note holds **two tenses in one document**. Summary / Key Changes / Changes are
retrospective: what the branch did. `## Deployment Plan` is prospective: per deployment
target, what is waiting to deploy and the verification that would be required. Its first
line says which it is, because a reader who cannot tell "this shipped" from "this is
proposed to ship" is worse off than a reader with no plan at all.

**Why the note and not another document** (resolved 2026-08-13, the ask's own word is
"Release Note"). `.workaholic/releases/<release-branch>.md` is the batch-level ship
record and is documented as derived from git and never hand-authored, so a drafted plan
cannot live there; a third artifact would compete for the same name with the two that
already exist. The note is written at the ship seam, which is exactly where the plan is
drafted — one document, one seam, no new area to register.

**Mutability, stated once.** Within a branch, the plan section is *regenerated in place*
on every refresh: it is a draft and drafts are rewritten. Across branches nothing is
rewritten — each ship writes its own note, so the tree stays append-only history and the
`.workaholic/` convention holds. A merged note's plan is the permanent record of what
was planned at that ship.

**One target's entry** carries only values the consolidation returned — the target's
title and slug, its environment, its deploy model (with how that model was resolved),
how many commits are waiting and from which boundary (with the `since_reason` and the
attribution), plus **references** to the record's `## Procedure` and `## Confirmation`
rather than copies of them. Referencing rather than pasting is what keeps the plan from
drifting away from the contract `/ship` actually executes. A target that declares no
confirmation method is written as such — that target halts the ship at §1-4, and the
plan saying so is more useful than the line being absent.

**For a deploy-on-merge target the entry says so explicitly**: the merge is that
target's deployment, so what is pending is the release publish for the version, not the
commits. Listing commits as "to deploy" there would be actively misleading.

**The refresh is idempotent, and that is a contract.** The section carries no clock —
its datum is the base's commit sha — so re-running against an unchanged base leaves the
file byte-identical and a periodic caller commits nothing. Anything time-stamped here
would turn an hourly agent into a commit machine.

**Who assembles it.** The `workaholic:ship` skill owns the mechanics: its drafting
phase reads the per-target consolidation and writes this section, and this skill stays
prose-only — no shell of its own, so it remains readable on an agent that has no such
tooling. Where the ship skill's scripts are unavailable, assemble the section by hand to
the shape above; the fields are the consolidation's, whoever gathers them.

## Recording the verification

`## Deployment Verification` is the other half of the loop: a plan that says what
verification is required and never records whether it ran degrades into a wish. One
block per **attempt**, appended — a second attempt adds a block and never rewrites the
first, matching the rule that a failed confirmation deletes nothing.

Each block names the target, the method as the record declares it, the exact check that
ran, the observed result, and one of four statuses:

| Status | Meaning |
| ------ | ------- |
| `pass` | the check ran and confirmed the deployment |
| `fail` | the check ran and did not confirm it |
| `not_run` | no check ran — the environment cannot execute the declared method |
| `bypassed` | a developer's recorded accepted-risk merge without confirmation |

`not_run` and `fail` are deliberately distinct: "we could not check" and "we checked and
it was wrong" call for different acts, and a plan that conflates them makes an
unverified deployment look like a verified one.

The same evidence also lands in the branch story's `## Deployment Evidence` block — same
evidence, two audiences: the story is the branch's permanent record for reviewers, the
note is where the reader holding the plan looks. One writer fills both — the
`workaholic:ship` skill's evidence recorder — so they cannot disagree, and its refusal
to write a secret-shaped result guards both destinations.

## Output Location

This skill runs at **ship time** (the `workaholic:ship` Ship Flow generates the note before merging), so one branch can produce several notes across multiple ships:

- **First release on a branch**: `.workaholic/release-notes/<branch-name>.md`
- **Additional releases on the same branch** (subsequent ships): `.workaholic/release-notes/<branch-name>-<N>.md` (`-2`, `-3`, …), so each ship's release record is preserved separately.

Pick the next free `-<N>` suffix when `<branch-name>.md` already exists.

## Writing Style

- Use active voice
- Focus on user-facing impact
- Keep total length under 200 words
- No emojis
- No technical jargon unless necessary
