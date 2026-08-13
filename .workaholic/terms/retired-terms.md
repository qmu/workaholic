---
type: Term
title: Retired Terms
description: Names this project no longer has — kept so a reader meeting one in old history can find out what it was
category: developer
last_updated: 2026-08-13
---

# Retired Terms

**Every name below is retired. Nothing here describes the system as it is today.**

This record exists because deleting a word does not delete the documents that used it. A
reader meeting `drivin` in an archived story from March, or `/scan` in a ticket from May,
needs one place that says what it was, when it went, and what replaced it. The current
vocabulary is in [core-concepts.md](core-concepts.md),
[artifacts.md](artifacts.md), [workflow-terms.md](workflow-terms.md) and
[file-conventions.md](file-conventions.md), and none of them defines a retired name.

**This record is permanently flagged by `report/scripts/area-freshness.sh`, by design.**
That seam reports any glossary record naming a de-listed area or a retired namespace, and
naming them is precisely this file's job. A flag on any *other* record in this area is a
defect; a flag on this one is the seam working as specified. That is the second limb of
the acceptance criterion the audit ticket was written to — flagged zero, *or* every
remaining flag is a deliberate retired-term entry whose record says so in its own text.

## Retired plugin namespaces

The repository shipped a multi-plugin marketplace until the plugins were merged into the
single `workaholic` plugin. Every namespace below is obsolete, and guessing one at
runtime is explicitly forbidden.

| Name | What it was | Retired | Successor |
| ---- | ----------- | ------- | --------- |
| `core` | The original development plugin | 2026-03 | renamed, then merged |
| `drivin` | The ticket-driven development plugin (`core` renamed) | 2026-05 | the single `workaholic` plugin |
| `trippin` | The exploration plugin providing `/trip` | 2026-05 | the single `workaholic` plugin; `.workaholic/trips/` is read-only history |
| `standards` | The engineering-standards plugin | 2026-05 | the six pillar skills inside `workaholic` |
| `work` | An early marketplace name | 2026-03 | `workaholic` |

## Retired `.workaholic/` areas

Three documentation areas were removed on **2026-08-13** (issue #436) for one reason:
each had **no writer in the loop**. An area nothing writes goes stale and then lies — 17
of their 20 files still described the multi-plugin architecture and had not been touched
since 2026-05-14. Content was deleted rather than relocated: git history is the durable
record, and nothing in them was still true.

| Area | What it held | Successor |
| ---- | ------------ | --------- |
| `guides/` | User-facing how-to documentation | the repository's own `docs/` tree |
| `policies/` | Model-written observations of repository practice | the six pillar skills' distributed engineering articles |
| `specs/` | Eight viewpoint-based current-state architecture documents | the repository's own `docs/` tree |
| `constraints/` | Manager-generated boundaries for lead agents | nothing — the agent tier that produced them is retired |

Two ticket directories were retired the same day, folded into the archive as a `status:`
field: `icebox/` and `abandoned/`. Both survive as **states**, not places.

## Retired agents and agent tiers

The repository once shipped a hierarchy of agent files — managers, leads, writers,
analysts. **It now ships no agent files at all**: every fan-out spawns a
`general-purpose` subagent whose prompt names the skill to preload.

| Name | What it was | Successor |
| ---- | ----------- | --------- |
| `scanner` | Subagent orchestrating 17 documentation agents | nothing — the documentation command it served is retired |
| `driver` | Subagent implementing one ticket during a drive | the drive skill's per-ticket workflow, run inline |
| `ticket-organizer` | Subagent performing the whole ticket-creation workflow | the create-ticket skill, run by `/ticket` |
| `spec-writer`, `terms-writer`, `changelog-writer`, `policy-writer` | Documentation writers | nothing — their target areas are retired |
| `viewpoint-analyst`, `policy-analyst` | Per-domain analysis subagents | nothing |
| manager tier (`project-manager`, `architecture-manager`, `quality-manager`) | Strategic agents producing constraint files | nothing — the pillar skills carry the standards instead |
| lead tier (`architecture-lead`, `security-lead`, and the other nine) | Domain agents consuming manager output | nothing |
| `managers-principle`, `leaders-principle` | Cross-cutting principle skills for the two tiers | the six pillar skills |
| `orchestrator` | The name for a command coordinating several agents | still a pattern; no longer a defined term |

## Retired commands

| Command | What it did | Retired | Successor |
| ------- | ----------- | ------- | --------- |
| `/scan` | Regenerated the documentation areas with 17 parallel agents | 2026-08 | nothing — the areas it wrote are retired |
| `/story` | Full documentation scan plus pull-request creation | 2026-03 | split into the retired `/scan` and `/report` |
| `/pull-request` | Created the pull request | 2026-03 | `/report` |
| `/trip` | Launched a three-agent exploration session | 2026-05 | nothing; `.workaholic/trips/` is read-only history |
| `/monitor`, `/carry` | Loop-era predecessors of the executor | 2026-07 | `/drive` and `/implement` |
| `/release` | Bumped the version and published | 2026-06 | a manual version bump; continuous integration publishes |
| `/request` | Opened an issue on another repository | 2026-08 | `/fb <ask> to <owner/name>` |
| `/drive auto`, `/drive night` | Unattended modes of `/drive` | 2026-08 | `/implement` |
| `/mission close`, `/mission summary`, `/mission approve`, `/ticket summary` | Subcommand forks | 2026-08 | `/mission-close`; the rest dropped under one-behaviour-per-command |

## Retired workflow concepts

| Term | What it was | Successor |
| ---- | ----------- | --------- |
| `spec` | Current-state documentation artifact | the repository's own `docs/` tree |
| `viewpoint` | One of eight architectural analysis lenses | nothing |
| `constraint` | A manager-set boundary for lead agents | nothing |
| `principle` | A cross-cutting behavioral rule skill | the pillar skills |
| `trip`, `agent-teams`, `direction`, `model`, `design` (as trip artifacts) | The exploration workflow and its three-agent artifact exchange | nothing; the strategy artifact revived in 2026-08 is unrelated and differently defined |
| `approval` | The per-ticket prompt during a drive | relocated, not removed: a mission is authorized when its pull request merges, a ticket when it is created |
| `abandon` (drive-time option) | Discarding a ticket's work mid-drive | the failure contract's four outcomes; destructive git is now forbidden outright |
| `failure-analysis` | The section written when a ticket was abandoned | a ticket's Final Report and the feedback stream |
| `prioritization`, `severity`, `context-grouping` (as ticket fields) | Ordering inputs read from `type` / `layer` / `effort` frontmatter | dependency ordering plus context grouping, derived and reported, never asked |
| `sync` | Regenerating derived documentation | nothing — no documentation area is machine-derived any more |
| `release-readiness` (as a subagent) | Pre-release verdict producer | the story's Release Preparation section, written by a report worker |
| `format-commit-message` | A separate commit-formatting skill | the commit skill's Message Format section |
| `sh/` | The scripts directory inside a skill | `scripts/` |
| `.workaholic/terminology/` | The glossary's directory name | `.workaholic/terms/` |
| `doc/`, `.work/` | Earlier names for the working-artifact root | `.workaholic/` |
