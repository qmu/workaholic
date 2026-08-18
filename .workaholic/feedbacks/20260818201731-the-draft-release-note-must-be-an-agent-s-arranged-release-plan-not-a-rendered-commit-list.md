---
type: Feedback
title: The draft release note must be an agent's arranged release plan, not a rendered commit list
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-08-18T20:17:31+00:00
author: a@qmu.jp
supersedes: 
---

# The draft release note must be an agent's arranged release plan, not a rendered commit list

Source: https://github.com/qmu/workaholic/issues/512

The developer, on being walked through what actually ships today: this is far from
the development experience asked for, repeatedly, over several rounds of feedback.

What ships today is a deterministic shell renderer. `run-note-cadence.sh --write`
(GitHub Actions, `release-note-draft.yml`) calls `draft-release-note.sh`, which walks
the merge commits between the latest release tag and the base, takes each branch
story's opening sentence — or, when no story joined the merge, the merge body's pull
request title — clamps it to 160 characters and lists it. No agent runs anywhere in
that path; the workflow's whole body is one `bash` invocation. The renderer's own
header states the property the daily cadence rests on: the same base state renders
byte-identical output.

The experience asked for: however miscellaneous the merges piling onto `main`, an
autonomous agent continuously re-arranges a rational, realistic release plan, and the
current state of that plan is what sits in the draft release note, per deployment
target. After a release, the confirmation and report are appended to that same note.
The draft should be the agent's present judgment of what should be released and how —
not a concatenation of past fragments.

Where the gap shows:

- No planning judgment at all: nothing decides what should be released together, what
  is risky to ship alongside what, or in what order.
- A merge with no story falls back to a raw pull request title. `/propose`'s
  auto-merged pull requests structurally never run `/report`, so they never have a
  story, and they are the most frequent merge kind in this repository — so the
  substance is lost on the most common path.
- The output is designed to be deterministic, which structurally forecloses the agent
  judgment being asked for.
- Post-release confirmation exists in `/ship`'s `## Deployment Verification`, but is
  not connected to the draft as a continuous experience.

The 2026-08-18 decision to move the writer from the routine to CI is correct and
should stand — a routine's container genuinely cannot write a release, measured. The
problem is not where the writer sits but who decides the content and how. What needs
redesigning is where the agent's judgment runs and how its result reaches the writer
that holds the permission.
