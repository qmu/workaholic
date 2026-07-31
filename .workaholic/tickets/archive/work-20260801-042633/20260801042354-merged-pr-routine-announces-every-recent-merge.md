---
created_at: 2026-08-01T04:23:54+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 1h
commit_hash:
category: Changed
depends_on:
mission:
merge_policy: review
claim: work-20260801-042633
---

# The Merged PR routine announces every recent merge, so two merges close together produce four Slack messages

## Overview

Observed 2026-08-01 04:19 JST in `#dev-workaholic`: PRs #135 and #137 were merged about four seconds apart, and **four** messages arrived — each PR announced twice, in visibly different wording.

There is only **one** `Merged PR workaholic` routine (`trig_01EqetqdavV83cHviwnCswZs`), so this is not duplicate configuration. Two merge events started two sessions, and **each session announced both merges**. The different wording is the tell: two independent sessions each composed their own message for the same PR.

The cause is in the prompt:

> Post short notification to the slack channel "dev-[project name]" **about the pull request** by the format below

"The pull request" is never identified. A cloud session starts with no state and no memory of what has already been announced, so it looks at what recently merged, finds two, and reports both. With N merges landing before the sessions run, N sessions each report N merges — N² messages, N per PR.

A single merge in isolation looks correct, which is why this survived: the defect only appears when merges land close together, and that is exactly what a productive drive loop does.

## Policies

- `workaholic:implementation` / `policies/objective-documentation.md` — a notification that says a merge happened twice is a report that misstates the observable facts; the announcement must correspond one-to-one with the event
- `workaholic:operation` / `policies/ci-cd.md` — the merge announcement is the project's delivery signal; a signal that duplicates under load is one people learn to ignore, which costs more than no signal

## Key Files

- `plugins/workaholic/skills/workaholify/routines/merged-pr.md` — the template carrying the defective prompt; the canonical copy the fix lands in
- `plugins/workaholic/skills/workaholify/routines/fb.md` and `drive.md` — the same "post when X happens" shape; check both for the same ambiguity rather than fixing only the reported one
- `plugins/workaholic/skills/workaholify/scripts/compare-routines.sh` — how the corrected template reaches the live routines (as drift, then an update)

## Related History

The three routine templates were captured verbatim from the live routines on 2026-08-01 (PR #138) precisely so a fix could be made once and applied everywhere. This is the first use of that: the correction is made in the template, and every repository's routine picks it up as drift.

## Implementation Steps

1. **Scope the announcement to the triggering merge.** Rewrite the `merged-pr` prompt so it reports **exactly one** pull request — the one whose merge started this session — and states that plainly rather than saying "the pull request".
2. **Say what to do when it cannot be identified: post nothing.** Silence is the correct failure mode for a notification. A session that cannot tell which merge triggered it must not fall back to "announce whatever merged recently", because that fallback *is* the bug.
3. **Forbid the multi-report shape explicitly.** State that the session must never announce more than one pull request, even when it can see several recent merges — the constraint has to survive a model that "helpfully" reports them all.
4. **Check `fb.md` and `drive.md` for the same ambiguity.** Both post on an event ("when PR created", "on a PR"); if either can see more than one candidate, it has the same defect and gets the same treatment.
5. **Apply to the live routines** through `/workaholify`, which reports the corrected template as drift on every repository that has the routine.
6. **Update the docs in the same change** and rebuild `outputs/`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The `merged-pr` prompt names the triggering pull request as its subject, states that exactly one is announced, and states that nothing is posted when it cannot be identified.
- `fb.md` and `drive.md` are checked for the same ambiguity, and either corrected the same way or recorded as not affected with the reason.
- The corrected template is applied to the live `Merged PR workaholic` routine.
- **Two pull requests merged within a minute of each other produce exactly two Slack messages, one per PR.**

**Verification method** — the commands/tests/probes that prove them:

- Hermetic: the suite asserts the template's prompt contains the one-PR scoping and the post-nothing fallback, and that no routine template says "about the pull request" without identifying which.
- Live: merge two PRs in quick succession and count the messages in `#dev-workaholic`. This is the only check that proves the fix, because the defect lives in a model's reading of a prompt, not in a script.

**Gate** — what must pass before approval:

- The suite is green **and** the live two-PR test produces exactly two messages. A green suite alone does not close this: the hermetic test pins the prompt's wording, not the behavior it produces.

## Considerations

- **The fix is prompt wording, so only a live run can confirm it.** A test can assert that the instruction is present and unambiguous; it cannot assert that a session obeys it. The two-PR reproduction is the acceptance criterion for that reason, and it must be re-run after any later edit to this prompt (`plugins/workaholic/skills/workaholify/routines/merged-pr.md`).
- The routines were edited live at 19:12–19:14 UTC on 2026-07-31 (`{{#if blocker}}` became `{{#if high_severity_concerns}}`, and the Drive prompt was substantially rewritten). The committed templates predate that, so this change should re-capture from live first or it will overwrite those edits (`compare-routines.sh` reports the difference either way).
- Whether the platform passes the triggering PR to the session at all is unverified. If it does not, "identify the triggering merge" may be unsatisfiable and the honest fallback — post nothing — becomes the normal path, which would make the routine useless rather than noisy. Confirm what the session can actually see before assuming step 1 is implementable.

## Final Report

Development completed as planned, plus two amendments the developer made mid-flight: the
`⚠️ Attention` block is removed from **both** the PR-opened and PR-merged formats, and the
corrected templates were applied to **every** routine in the account, not just this
repository's.

Applied live: 15 routines — 7 `[FB]`, 7 `Merged PR`, 1 `[Drive]`, across workaholic,
research, qmu-co-jp, plgg, qfs, data-platform and coop-csnet. Two pre-existing drifts were
corrected on the way: `Merged PR qmu-co-jp` and `[FB] coop-csnet` had no `model` set while
every sibling pinned `claude-opus-5`.

### Discovered Insights

- **Insight**: The duplicate was not duplicate configuration — there is exactly one
  `Merged PR workaholic` routine. Two merge events started two sessions, and each
  announced **both** recent merges, because the prompt's subject was "the pull request"
  with no antecedent. A stateless session cannot know which event started it unless the
  prompt says so, and it cannot know what a *sibling* session already posted at all.
  **Context**: The differing wording between the two message pairs is what identifies this
  — identical duplicates would suggest one session retrying, different prose means two
  sessions each composing independently. That distinction is worth checking first the next
  time a notification doubles.

- **Insight**: The failure scales as N², and only shows up under load. N merges landing
  before their sessions run gives N sessions each reporting N merges. A single merge in
  isolation looks perfectly correct, which is why this survived from the routine's
  creation until a drive loop merged twice within four seconds.
  **Context**: Any event-driven notification whose prompt does not name its triggering
  event has this shape. `fb` and `drive` were checked for the same ambiguity and scoped
  the same way, even though both announce their own output and could not actually
  misfire — because "the pull request" reads identically in all three and the next editor
  should not have to work out which case they are in.

- **Insight**: `[FB] data-platform` carries `- Speak/Write Japanese`, which the template
  comparison reports as drift. It was **kept**, not normalized away: a project's output
  language is a property of that project, not a deviation to be corrected. Applying a
  template must not silently overwrite a deliberate local choice.
  **Context**: This is the first case where "one template set" met a legitimate per-repo
  difference, and it shows the comparison cannot decide by itself — it reports, a human
  decides which differences are drift and which are configuration.
