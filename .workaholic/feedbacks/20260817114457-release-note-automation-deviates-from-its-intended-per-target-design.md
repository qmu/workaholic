---
type: Feedback
title: Release note automation deviates from its intended per-target design
kind: instruction
source: discussion
subject: observer_ai:claude[bot]
created_at: 2026-08-17T11:44:57+00:00
author: a@qmu.jp
supersedes: 
---

# Release note automation deviates from its intended per-target design

A failure report against the release-note automation, filed in Japanese as issue #472. The
trial implementation configured through `/setup-repo-routines` — "run `/ship` once an hour
and update the release notes" — behaves far from what was intended, showing up as
fragmented notifications into each Slack channel. The issue restates the intended design so
the implementation can be corrected to it.

**The intended design, as given.**

1. *Derive the deploy targets first.* Targets are recorded under `deployments/`. Where that
   has not been derived, the repository structure is inspected first to establish which
   deploy targets exist and which software environment each corresponds to. Only once that
   mapping is known does per-target release-note generation follow.
2. *Per-target draft release notes.* For each target (software component), precompute from
   the pull requests and branches merged into the default branch what the release note
   would read like if the appropriate component were deployed, and hold that as a draft.
3. *The note is also the record of the release.* It states the confirmation steps and
   release procedure required after release, and it records that the AI completed the
   confirmation work.
4. *Dual recording.* The content lives both in GitHub's release-notes feature and under
   `.workaholic`, and the two are kept always identical.
5. *Cadence.* The GitHub release note is generated daily and updated as the release
   progresses through its stages.

Expected work, as listed: survey `deployments/` and derive the target↔environment mapping;
implement per-target draft generation; structure the note for confirmation steps and the
AI's completion record; sync the GitHub and `.workaholic` copies; implement the cadence;
and replace the current fragmented Slack notification with the above.

**What the report is measuring against, stated so the correction starts from the truth.**
The deviation is real and it is traceable to a documented decision, not to an
implementation slip. The ask recorded on ticket `20260814064854-add-the-hourly-release-note-repo-routine`
was the same one — "run `/ship` once per hour to update the release notes" — and on
2026-08-14 its Open Decision was resolved the other way: `workaholic:ship` §7, *Why this is
a reader*, refuses all three unit-less writer designs (refreshing a merged note on `main` is
self-referential, because for a target declaring no `paths:` the refresh's own commit
increments the `unreleased_count` it reports; pushing into an open pull request's branch
races the claim protocol; running `/ship` hourly merges pull requests nobody expected).
What shipped was `[Release Status]`, a reader that posts one gated `📦 Release status` line
and writes nothing, and §7 states the shortfall in the open: "the release notes are not
updated by any tick." A residue of the original intent survives in the prose —
`workaholic:workaholify` §5 still calls the repository-scoped routine `[Release Notes]`.

So the correction is not "fix a bug"; it is to answer those three refusals with the design
above or to change the design where they still bind. Two facts that bear on it: the daily,
per-target, GitHub-Releases-first shape sidesteps the hourly commit treadmill the first
refusal describes, and this repository's own `marketplace` target declares no `paths:`, so
a note committed to `main` still counts its own commit unless that is designed around.

Current state, measured: `deployments/` holds exactly one target record (`marketplace.md`),
`.workaholic/release-notes/` holds branch-story-derived notes, and `.workaholic/releases/`
does not exist yet in this repository.

Source: https://github.com/qmu/workaholic/issues/472
