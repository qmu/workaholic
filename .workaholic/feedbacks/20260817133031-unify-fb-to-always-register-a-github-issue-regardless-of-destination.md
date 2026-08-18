---
type: Feedback
title: Unify /fb to always register a GitHub issue regardless of destination
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-08-17T13:30:31+00:00
author: a@qmu.jp
supersedes: 
---

# Unify /fb to always register a GitHub issue regardless of destination

The ask: `/fb`'s behavior should be **one shape regardless of destination** — every invocation
registers the feedback as a **GitHub issue**, not just the ones that name another repository. Today
the command has two forms: an input naming another repo opens an `[FB] `-marked issue on the target
through the crossing (`open-issue.sh`, with the verbatim confirmation and the masking judgment),
while an input naming no destination writes one immutable record into this repository's
`.workaholic/feedbacks/` and stops.

Two reasons given. (1) The Slack (Claude Tag) route that files an FB issue and `/fb` should be
equivalent — different entrances, same result: the feedback arrives as an issue. (2) The deliverable
changing shape by destination (a file for here, an issue for elsewhere) is cognitively inconsistent;
the caller should not have to remember which one they get.

Expected completion state, as stated: a `/fb` with no destination opens an `[FB] `-marked issue on
this repository, in a form the receiving `[Propose]` routine ingests exactly as it does today; the
direct-write path into `.workaholic/feedbacks/` is replaced by that issue-originated flow (and if a
record is to be kept alongside the issue, that design decision is written down); the feedback
skill's `SKILL.md` and the crossing section are updated to the single new behavior. The ask also
requires the issue to be **assigned** — to the invoking identity when nothing else is specified.

Three facts about the current mechanism bear on how this is built, and none of them is a reason to
decline the ask:

- **The assignment requirement is load-bearing, not a nicety.** `[Propose]`'s clock-fired discovery
  (`list-inbound-issues.sh`) lists only issues **assigned to the session's own identity** — assigned
  to nobody is deliberately never offered, so N developers' hourly copies do not race for it. An
  unassigned in-repo `[FB]` issue would therefore be ingested by no one.
- **Writing both the issue and a local record naming its URL would silence the loop.** The same
  discovery excludes any issue a feedback record already names (`already_captured`, keyed on the
  `/issues/<N>` line the record carries). A `/fb` that opened the issue *and* wrote the record would
  suppress its own ingestion, which is the opposite of reason (1). That is the mechanical fact the
  ask's open "keep the record alongside?" question runs into.
- **The crossing's gates exist for the boundary, not for issue-opening as such.** `open-issue.sh` is
  written and documented as the crossing to *another* repository; the masking judgment, the
  non-skippable verbatim confirmation and `check-outbound-body.sh`'s self-name backstop are there
  because the content leaves this project. It also takes no assignee today. Which of those apply on
  the in-repo path — and how the writer gains `--assignee` — is the substance of the change.

`/fb` is not the only writer of the stream: `/propose` registers the record for each ask it takes in
hand, and `/ship`'s `extract-deferred-concerns.sh` persists deferred concerns. Both are untouched by
this ask.

Source: https://github.com/qmu/workaholic/issues/478
