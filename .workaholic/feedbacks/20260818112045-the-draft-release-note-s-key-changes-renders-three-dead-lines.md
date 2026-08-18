---
type: Feedback
title: The draft release note's Key Changes renders three dead lines
kind: instruction
source: discussion
subject: observer_ai:a@qmu.jp
created_at: 2026-08-18T11:20:45+00:00
author: a@qmu.jp
supersedes: 
---

# The draft release note's Key Changes renders three dead lines

Source: https://github.com/qmu/workaholic/issues/496

Rendering the `marketplace` draft release note through
`ship/scripts/draft-release-note.sh` produced a `## Key Changes` section whose
every entry read `no branch story on the base`:

```
- Pull request #441 (`work-20260813-124452`) — no branch story on the base.
- Pull request #439 (`work-20260813-121701`) — no branch story on the base.
- Pull request #437 (`work-20260813-113107`) — no branch story on the base.
```

The section is the note's one summary of what is actually shipping, and in this
state it carries no information at all for a reader.

The cause is a selection problem rather than missing stories. All three of those
merges are `/propose` proposal merges (`Propose the ship deploy-plan drafting
mission`, `Record the notify thread-lookup miss`, and so on). A proposal pull
request is published through the publish tree and auto-merges without ever
running `/report`, so it structurally never has a `.workaholic/stories/` file --
and proposal merges are the most frequent kind of merge in this repository. The
renderer takes the most recent merges regardless of kind, so it keeps selecting
exactly the merges that cannot have stories. Meanwhile 171 of the `work-*`
branches on the base do have stories, so the corpus is not the problem.

It should prefer merges that have a story when choosing what to list, and fall
back to the merge's own commit subject when none does, rather than emitting a
line whose only content is the absence of a story.
