---
type: Mission
title: Make scheduled routines a configurable, inspectable part of a repository
slug: make-scheduled-routines-a-configurable-inspectable-part-of-a-repository
status: draft
merge_policy:
created_at: 2026-07-31T16:05:30+00:00
author: noreply@anthropic.com
assignees: []
assignee:
predicted_hours:
actual_hours:
feedback: [20260731160449-support-a-setup-routines-skill-that-manages-a-repository-s-scheduled-routines.md, 20260731160517-routine-configuration-has-no-source-of-truth-in-the-repository.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# Make scheduled routines a configurable, inspectable part of a repository

## Goal

Scheduled routines are how this project actually runs — a routine files feedback issues, a
routine announces merges, and a routine is expected to drive the queue — yet a routine is the
one moving part the repository knows nothing about. `grep -rn "setup-routines"` matches nothing,
and no artifact records a routine's schedule, prompt, target repository, or Slack channel. The
configuration lives in one person's Claude Code Web account, and the only way to learn what runs
against this repo is to ask them.

The reporter asks for `/setup-routines [repository name]`: list which routines are configured
for a named repository, pull the latest version of each template when creating or updating one,
and add, remove, or refresh a routine from its template. The reporter also asks that it be
designed for a future they expect — each developer configuring their own routines on joining a
project, so one developer's feedback routes to a second developer's implementation while a
routine sends the resulting PR to a third for review. A design that assumes one configurator
would have to be rebuilt to reach that.

## Scope

Proposed as a mission rather than a ticket because the work decomposes into related units that
are incoherent apart, and because the first of them is a real decision rather than an
implementation step:

1. **Decide where routine configuration lives.** A skill that lists routines needs something to
   list from. `.workaholic/` is a closed structure — 11 permitted top-level directories fixed in
   `hooks/workaholic-layout-allowlist.txt` and the `rules/workaholic.md` table, amended only
   deliberately and in the same commit that first writes there. So the options (a new registered
   artifact area, a file inside an existing one, or a deliberate decision to keep configuration
   outside the repository and have the skill read it live) must be settled first: the answer
   decides whether the skill can be read-only at all, and discovering it late costs a layout
   amendment or a guard block.
2. **Decide what an agent may apply.** Both loop runbooks close with the same rule — "Do not
   install the crontab from an agent session — applying a standing outward-facing process is the
   developer's act." Capability 3 (add/remove/refresh) is that act. The mission must draw the
   line for a hosted routine: what the skill applies unattended, what it may only propose for a
   developer to apply, and why the answer differs from the crontab rule (or does not).
3. **Write the three routines down as templates.** "[FB] PR Creation / Issue Close" and "Merged
   PR Notification" exist only as live configuration; capturing them as versioned templates is
   what makes "pull the latest version" mean anything. The existing `docs/proposal-loop-runbook.md`
   and `docs/drive-loop-runbook.md` are the nearest prior art, but they describe a different
   mechanism (a server `crontab` invoking headless `claude -p`) and name none of the three.
4. **Build the skill** over units 1-3: list, pull, update — with the per-repository argument the
   reporter asked for.

A fifth unit is proposed but explicitly severable: **the "Auto Drive and Report" routine**, which
does not exist yet. It is the one template that must be authored rather than captured, and it
overlaps the existing `docs/drive-loop-runbook.md` decision (G4) about driving on a schedule; it
should not block the four units above.

Out of scope: implementing the multi-developer routing itself. The reporter asked for a design
that does not preclude it, which is a constraint on the configuration shape (routines keyed per
person, not per repository alone), not a feature to build now.

## Experience

A developer who has just joined the project runs `/setup-routines workaholic` and sees which
routines run against that repository, on what schedule, and which template version each was
created from — without asking the person who configured them. They can refresh one from its
current template, and they can add or remove one, with the boundary between "the skill did it"
and "you must apply this yourself" stated explicitly rather than discovered by watching what
happens. Reading the repository is enough to answer "what runs against this repo, and who
configured it" — the question that has no answer today.

## Acceptance

PROPOSED sketch for discussion, not a plan. `/mission approve` replans this to drive-ready.

These items are markerless because this batch has no tickets to link to yet — the condition
recorded in `make-acceptance-ticking-measure-satisfaction-not-marker-shape`.

- [ ] Where routine configuration lives is decided and written where the layout convention
      already lives, with the rejected alternatives named; if it is a new `.workaholic/` area, it
      is registered in both sources of truth in the same commit that first writes there
- [ ] The line between what an agent applies and what a developer must apply is written down for
      hosted routines, and reconciled with the "do not install the crontab from an agent session"
      rule the two runbooks state
- [ ] The two existing routines are captured as versioned templates that a script can read, not
      prose only a human can follow
- [ ] `/setup-routines [repository name]` lists the routines configured for that repository,
      including which template version each came from
- [ ] The skill can pull the latest template and refresh, add, or remove a routine within the
      boundary decided above
- [ ] The configuration shape is keyed so that per-developer routines are addable without
      redesign — the reporter's three-developer routing scenario is walked through in the design
      record rather than asserted to be possible
- [ ] The "Auto Drive and Report" routine is either delivered or split out as its own artifact,
      with the decision recorded rather than left implicit
- [ ] Whatever the skill ships with is exercised by `node scripts/test-workflow-scripts.mjs`
      hermetically, with no network and no live routine touched

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
