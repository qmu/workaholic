---
created_at: 2026-08-01T01:21:29+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 2h
commit_hash:
category: Changed
depends_on:
mission:
merge_policy: review
claim: work-20260801-022239
---

# Cap mission size, drop the Scope section, and hold /propose's drafts to the same ceiling

## Overview

Missions have grown formal enough that they are hard to finish. The diagnosis is specific: the problem is not that the gates are too strict, it is that **nothing bounds how much a mission may say**. An unbounded `## Acceptance` becomes an exhaustive audit list, and a mission whose acceptance list is an audit list can never be honestly closed.

Three changes, all subtractive:

1. **`## Scope` is removed from the template** — deleted, not made optional. No validator, script, or hook reads it; it is pure authoring cost.
2. **`## Acceptance` is normatively three items or fewer**, holding only *the minimum conditions under which the work can be called done*. Exhaustive lists and future audit items do not belong in a mission.
3. **A size ceiling** — roughly 60 lines / 2 KB for the whole `mission.md`, and `/propose`'s scaffolded drafts are held to the same ceiling.

Feedback records get the same treatment: the author's own words plus the measurement, one paragraph.

**The approved floor is unchanged and must stay unchanged**: an owner, a real `## Experience`, at least one `## Acceptance` item. This ticket lowers the ceiling; it does not lower the floor.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — the template lives in `mission/scripts/create.sh` and the prose in `mission/SKILL.md`; both change together or they drift
- `workaholic:implementation` / `policies/objective-documentation.md` — "three items or fewer" and "60 lines / 2 KB" are verifiable, which is what makes them enforceable rather than aspirational; the ticket must decide for each whether it is a norm (prose) or a gate (script), and say so
- `workaholic:implementation` / `policies/coding-standards.md` — any new check is POSIX `#!/bin/sh -eu` per `rules/shell.md`

## Key Files

- `plugins/workaholic/skills/mission/scripts/create.sh` - writes the mission template, including the `## Scope` heading to be removed
- `plugins/workaholic/skills/mission/SKILL.md` - documents the body sections and the interrogation that fills them; the Acceptance guidance lives here
- `plugins/workaholic/skills/mission/scripts/close.sh` - references `## Scope`; must not break when the heading is gone from new missions
- `plugins/workaholic/skills/propose/scripts/scaffold-draft.sh` - writes the draft's provisional sections; inherits the same ceiling
- `plugins/workaholic/hooks/validate-mission.sh` - holds the approved floor (owner / Experience / at least one Acceptance item), which this ticket must leave intact
- `plugins/workaholic/skills/mission/scripts/progress.sh` - computes `checked ÷ total`; a shorter acceptance list changes what progress means, not how it is computed
- `plugins/workaholic/skills/feedback/scripts/create.sh` - the feedback writer, for the one-paragraph norm

## Related History

Missions were built with a deliberately rich body (Goal, Scope, Experience, Acceptance, Changelog) so that a mission carried enough context to drive from. The four missions currently active all sit at 0 of 7–9 acceptance criteria, which is the measurement behind this ticket: acceptance lists sized like audit lists do not get ticked.

## Implementation Steps

1. **Remove `## Scope`** from the template in `create.sh` and from the section list in `mission/SKILL.md`. Grep the plugin for readers of the heading first (`close.sh` names it) and make each tolerate its absence — existing missions keep theirs, and nothing retro-blocks them.
2. **Rewrite the Acceptance guidance** in `mission/SKILL.md` to state the three-item norm and what belongs there: the minimum conditions for calling the work done. Say explicitly what does *not* belong — exhaustive coverage, future audit items, per-file checklists.
3. **Decide norm vs gate for each rule, and record the reason.** The three-item count and the 60-line / 2 KB ceiling are both mechanically checkable; whether they *block* a write or merely guide the interrogation is a real choice. A gate that fires on a legitimate long mission is worse than a norm nobody reads. Write the decision down where the rule lives.
4. **Apply the ceiling to `/propose`** in `scaffold-draft.sh`, so a generated draft cannot arrive over the limit the interrogation is held to.
5. **Apply the one-paragraph norm to feedback records** in the feedback skill's guidance.
6. **Leave the approved floor untouched.** `validate-mission.sh` keeps requiring an owner, a real `## Experience`, and at least one `## Acceptance` item. Add a test asserting the floor still fires, so a later reader cannot mistake this ticket for a loosening.
7. **Update the documentation in the same change** — `CLAUDE.md` where it describes the mission body, `mission/SKILL.md`, and `propose/SKILL.md`.
8. **Rebuild** with `node scripts/build-plugins/build.mjs`; the mission and propose skills ship into `outputs/workflows`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A mission created by `create.sh` contains no `## Scope` heading, and every existing mission that still has one is read without error by `close.sh`, `progress.sh`, `list.sh`, and `mission-lens.sh`.
- `mission/SKILL.md` states the three-item Acceptance norm and the size ceiling, each marked as either a norm or a gate, with the reason recorded.
- A draft scaffolded by `/propose` is within the ceiling.
- `validate-mission.sh` still rejects an `approved` mission missing an owner, a non-empty `## Experience`, or at least one `## Acceptance` item — proven by a test, not by inspection.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green, with new cases for the Scope-less template, a legacy mission that still carries `## Scope`, and the three approved-floor rejections.
- `node scripts/build-plugins/verify.mjs` and `node scripts/build-plugins/validate-metadata.mjs` pass.
- A mission created in-session is under 60 lines and 2 KB.

**Gate** — what must pass before approval:

- The suite is green, the approved floor is demonstrably intact, and the documentation listed in step 7 tells the truth.

## Considerations

- Removing a heading that existing missions still carry is a compatibility question, not a deletion: the four active missions all have `## Scope`, and `close.sh` names it (`plugins/workaholic/skills/mission/scripts/close.sh`). Readers must tolerate both shapes rather than migrating history.
- A hard byte ceiling on `mission.md` can be defeated by a mission that says less but means less — the ceiling shapes the artifact, not the thinking. The three-item Acceptance norm is the rule doing the real work; the byte count is a backstop (`plugins/workaholic/skills/mission/SKILL.md`).
- Shortening acceptance lists changes what `checked ÷ total` reports without changing how it is computed, so historical progress percentages are not comparable across the change (`plugins/workaholic/skills/mission/scripts/progress.sh`).
- The mission lens prints the next unchecked acceptance item every turn; with three items or fewer the lens gets sharper, which is a second, unstated benefit worth confirming after the change (`plugins/workaholic/hooks/mission-lens.sh`).

## Final Report

Development completed as planned. All eight steps landed, and step 3's norm-vs-gate
decision was made and recorded rather than left implicit.

### Discovered Insights

- **Insight**: The norm/gate question has a principled answer that depends on *who holds
  the pen*, not on how important the rule is. For a human-authored mission the size norms
  report (`size.sh`) and the interrogation shows the measurement, because the author is
  present and exercising judgment and a hard refusal would fire on legitimately larger
  work. For a `/propose` draft the same ceiling is enforced, because the batch writes
  unattended with no judgment to exercise and nobody to show a measurement to — guidance
  there is just an unenforced wish.
  **Context**: This split is worth reusing whenever a rule must cover both an interactive
  and a headless writer. Asking "is this important enough to gate?" produces the wrong
  answer; asking "is there a judgment being exercised at the point of writing?" produces
  the right one.

- **Insight**: The `## Scope` removal exposed a claim in the prose that the test suite
  immediately disproved. The skill said `close.sh` would still carry a legacy `## Scope`
  into a successor — but the successor is scaffolded from the template, which no longer
  has that heading, so the carry rule could never fire. The correct behavior is not to
  carry it (a carry must not re-introduce a retired section into a *new* mission), so the
  dead awk rule was removed and the prose corrected.
  **Context**: When removing a section from a template, the carry/copy paths that
  reference it become dead silently — the awk rule matched nothing rather than erroring.
  The existing test asserting the old behavior is what surfaced it.

- **Insight**: `hooks/posix-lint.sh` flags any `[[` sequence as a shell bashism, which
  false-positives on awk regexes like `[[:space:]]` and `\[[ xX]\]`. The fix is to spell
  the awk patterns without a doubled bracket (`[ \t]`, `\[.\]`) rather than to add a
  linter exception.
  **Context**: A lint rule you have to argue with at each call site is worth less than a
  slightly different spelling. Worth knowing before writing any awk in this repo.
