---
type: Feedback
title: Two routines, one behaviour per command
kind: instruction
source: discussion
created_at: 2026-08-06T18:35:56+09:00
author: a@qmu.jp
supersedes: 
---

# Two routines, one behaviour per command

The developer's ruling, 2026-08-06, closing the day's routine work and setting the next shape (~/memo2.md).

TWO ROUTINES PER DEVELOPER, AND ONLY TWO. A developer configures Propose and Implement in their Claude Code Web account, and nothing else: the per-project configuration burden is the constraint, because every field a person must set by hand multiplies by the number of projects, and a fleet nobody can maintain by hand is a fleet that drifts. [Consent] is retired -- the merge announcement is not worth a third standing process per repository.

/implement IS A NEW COMMAND, AND /drive GOES BACK TO WHAT IT WAS. The unattended executor becomes /implement; /drive returns to its earlier interactive shape with the confirmation dialog. The two forms stopped being one command with a flag.

/propose AND /implement ARE ROUTINE-ONLY SKILLS. They exist for the Claude Code Web routines and are shaped by what a routine needs rather than by what a developer at a terminal needs: the pull request title carries the [Proposal] prefix, and the pull request BODY carries the notification target (the Slack thread URL) so the next routine in the chain can find where to reply without re-deriving it.

EVERY COMMAND TAKES ARGUMENTS AND HAS ONE BEHAVIOUR. Subcommands are abolished across the whole surface -- /ticket, /mission and the rest each do exactly one thing with what they are given. A command whose behaviour forks on a first word is two commands wearing one name.

THE ROUTINE INSTRUCTION IS FOUR LINES. Each routine's prompt says only: read the notification target and the payload out of the triggering artifact; tell the target, in the payload's own language, that work has started; run the one command; then post the result in the given format. Nothing else -- no plugin gate, no procedure, no rules the skills already own.

A SECURITY PRECONDITION RIDES WITH THIS. On a public repository, Issue and Pull request permissions must be set to Collaborators only; otherwise an outsider can start a routine that runs against the repository.
