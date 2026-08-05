---
type: Feedback
title: Retire /request; cross-repo asks become /fb issues on the target
kind: instruction
source: discussion
created_at: 2026-08-05T10:13:19+09:00
author: a@qmu.jp
supersedes: 
---

# Retire /request; cross-repo asks become /fb issues on the target

Ruled by the developer on 2026-08-05. /request — the command that writes a ticket file into another repository's checkout — is retired. A cross-repository ask now travels as a GitHub issue: /fb, given a target repository, composes the ask in the target's vocabulary and opens an issue there, which the target's [Propose] routine ingests exactly like any inbound report — recording the feedback and judging the proposal inside the target's own loop. The boundary crossing becomes an artifact the target's owners see natively (an issue), not a file appearing in their tree. What survives unchanged: the one verbatim confirmation (destination, visibility, exact body — non-skippable), the masking judgment that no matcher can replace (the request skill §1 rationale moves with it, never deleted), and the release-scan second layer. What goes away: submit-request.sh's file write and the command surface. The repo-confinement guard keeps blocking every other route; the issue path becomes the only sanctioned crossing.
