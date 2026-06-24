---
title: Stories
description: Branch development narratives that serve as PR descriptions
category: developer
modified_at: 2026-01-26T14:30:00+09:00
commit_hash: 5452b2d
---


# Stories

This directory contains comprehensive story documents that serve as the single source of truth for PR descriptions. Each story synthesizes archived tickets and CHANGELOG entries into a complete PR-ready document.

## Purpose

Stories are PR descriptions stored as files. When creating a pull request, the `/pull-request` command generates a story file and copies its content directly to GitHub. This eliminates duplication between story generation and PR description assembly.

Stories serve multiple purposes:

- **PR description**: Content is copied directly to GitHub PR body
- **Historical record**: Preserved in repository for future reference
- **Reviewer context**: Explains the "why" behind a body of work

## Story Format

Stories contain YAML frontmatter for metrics, followed by seven sections that form the PR body:

```markdown
---
branch: <branch-name>
started_at: YYYY-MM-DDTHH:MM:SS+TZ
ended_at: YYYY-MM-DDTHH:MM:SS+TZ
tickets_completed: <count>
commits: <count>
duration_hours: <number>
velocity: <number>
---

Refs #<issue-number>

## Summary

[Numbered list of changes from CHANGELOG]

## Motivation

[Why this work was needed]

## Journey

[How the work progressed]

## Changes

[Detailed explanation of each change]

## Outcome

[What was accomplished]

## Performance

[Metrics, pace analysis, decision review]

## Notes

[Additional context for reviewers]
```

## Stories

- [work-20260623-181237.md](work-20260623-181237.md) - Triage the carry-over concerns corpus (canonicalize 21 → 7, archive 14 chained duplicates with accept/defer/resolve dispositions) and resolve the 4 actionable concerns: a verify.mjs cross-skill reference lint, a /ship pre-deploy confirmation-capability check, the build.mjs orphan-cleanup guarantee, and deploy-model docs - 4 tickets
- [work-20260623-235347.md](work-20260623-235347.md) - Unify /trip and /drive on the ticket abstraction: trip Planning-phase Decomposition gate (design → tickets), Coding phase reworked into a per-ticket drive with three-agent QA, /report convergence, and context-aware /trip (a populated queue runs queue-execute — the ticket → trip direction); plus the sources × executors docs - 5 tickets, 8 commits
- [work-20260621-192132.md](work-20260621-192132.md) - Tighten workflow boundaries and policy instrumentation: scope the /trip Agent Teams members in frontmatter so non-trip flows never invoke them, make /ship's ticket guard non-blocking, add Night Trip (autonomous unattended /trip night), keep the feature branch on merge (gh pr merge --delete-branch=false), add a real (non-mock) policy-lens injection test, and record a mandatory `## Policies` section in tickets that /drive and /trip read before implementing - 6 tickets, 12 commits
- [work-20260618-182253.md](work-20260618-182253.md) - Make the four-pillar policy lens actually load during workflows: generate hooks/policy-index.md from the pillar SKILL.md `## Policies` sections and inject it via policy-lens.sh (bring /drive into the lens), with a CI guard against a stale committed index; add a deterministic /report doc-drift check (doc-drift.sh + release-readiness judging); and catch the /trip surface up to recent architecture (policy lens, merge-last Trip Ship order, relabeled script homes) - 4 tickets
- [work-20260618-115347.md](work-20260618-115347.md) - Add an always-triggered policy-lens UserPromptSubmit hook that injects the planning/design/implementation/operation lens into /ticket, /report, and /ship (replacing drifted per-command prose that still gated on the merged-away standards plugin and omitted the planning pillar), and fix the README (broken Mermaid lifecycle diagram, missing planning pillar in the policy index, undocumented policy-sync workflow) - 2 tickets
- [work-20260618-003119.md](work-20260618-003119.md) - Fix the carry-over pipeline (apply-carryover-verdicts.sh now accepts the {verdicts} object; extract-carryover.sh dedups concerns by canonical identity across PR prefixes) and add a secret-scrubbing guard to record-evidence.sh so deployment evidence can't leak credentials into the public PR - 2 tickets, night-drive batch
- [work-20260617-231848.md](work-20260617-231848.md) - Fix /ship ordering: the PR merge is now the LAST step, gated on a passing pre-merge production confirmation (deploy + confirm from the branch, record evidence, then merge); adds catchup-main.sh + record-evidence.sh and this repo's own .workaholic/deployments/marketplace.md contract - 1 ticket
- [work-20260617-210627.md](work-20260617-210627.md) - Make /ship require an established deployment-confirmation method (new .workaholic/deployments/ convention + reader; invert silent-skip into a halt-and-ask hard gate that executes the confirmation after deploy) and make night /drive run the whole queue with no per-ticket checkbox (one group-inclusion question only on distinct topic groups) - 3 tickets, night-drive batch
- [work-20260617-082241.md](work-20260617-082241.md) - Post-merge follow-ups: fix the check-deps regression blocking /ticket+/drive, rewrite the stale /release command for the single-plugin layout, and rewrite CLAUDE.md/README/command-Notice architecture narrative (incl. the stale Plugin Boundary Rule) - 3 tickets
- [work-20260617-000311.md](work-20260617-000311.md) - Consolidate core+standards+work into one workaholic plugin; move release-note generation to /ship and publish GitHub Releases on ship (deferring to CI); add autonomous night-drive mode to /drive; rename dist/ → outputs/ - 5 tickets, implemented in one night-drive batch
- [work-20260528-122941.md](work-20260528-122941.md) - Cross-agent distribution hardening and multi-developer ergonomics: sync plugin versions through marketplace.json with Codex-metadata CI validation, split standards into design/implementation/operation policy-index skills, add hermetic workflow-script smoke tests, partition the todo queue per developer, and add a plugin-boundary guard against stale-install spelunking and obsolete-namespace guessing - 6 tickets, 8 commits
- [work-20260528-091259.md](work-20260528-091259.md) - Replace /ship cloud.md deploy convention with CLAUDE.md as a hard cutover (rename find-claude-md.sh, rewrite ship SKILL.md, regenerate dist/workflows), and document the actual Codex install commands in the README - 1 ticket, 3 commits
- [work-20260518-235327.md](work-20260518-235327.md) - Cross-agent distribution: package core/standards skills via the Agent Skills standard, flatten report/drive/ticket orchestration onto general-purpose subagents, build a CI-guarded committed dist/workflows for Codex and the skills CLI, add a carry-over concerns pipeline, decouple core:ship from trip - 17 tickets, 33 commits
- [work-20260417-092936.md](work-20260417-092936.md) - Eliminate manager tier, redraw core/work plugin boundary, thin six work-side umbrellas (drive, report, trip, ticket, ship, discover) into core-skill aliases, rewrite leading skills in viewpoint prose - 16 tickets, 27 commits
- [work-20260415-163724.md](work-20260415-163724.md) - Consolidate 7 lead domains to 4 (validity, availability, security, accessibility), rewrite policies in priority-based tone, soft dependency fix - 0 tickets, 4 commits
- [work-20260408-001129.md](work-20260408-001129.md) - Lead skill architecture maturation: four-tier structure, domain consolidation, drive abandon fix, dependency tracking - 3 tickets, 15 commits
- [work-20260406-193458.md](work-20260406-193458.md) - Housekeeping and structural improvements: directory rename, skill removal, release note fix, discoverer refactor, trip worktree fix - 5 tickets, 13 commits
- [drive-20260403-230430.md](drive-20260403-230430.md) - Unified drivin and trippin into work plugin, unified branch naming, reset lead policies, added development patterns to story format - 10 tickets, 15 commits
- [drive-20260329-173608.md](drive-20260329-173608.md) - Plugin architecture reorganization: core consolidation, dependency declarations, i18n deprecation, skill consolidation, story template simplification - 10 tickets, 21 commits
- [drive-20260326-183949.md](drive-20260326-183949.md) - Agent discipline enforcement, standards plugin extraction, worktree lifecycle management, workspace safety guards, and developer experience improvements - 7 tickets, 14 commits
- [drive-20260312-102414.md](drive-20260312-102414.md) - Trip-drive workflow integration: quality differentiation, worktree detection guards, cross-command compatibility, trip plan state persistence, and strip-frontmatter extraction - 6 tickets, 11 commits
- [drive-20260311-125319.md](drive-20260311-125319.md) - System-wide configuration safety harness, agent personality spectrum rewrite, core plugin creation with unified /report and /ship commands, phase rollback mechanism, concurrent Planning Phase and Coding Phase execution - 10 tickets, 21 commits
- [drive-20260310-220224.md](drive-20260310-220224.md) - Trip workflow hardening, agent quality enhancements, multi-plugin README rewrite, complete delivery lifecycle commands (/report-drive, /report-trip, /ship-drive, /ship-trip) with cloud.md convention, shared ship script extraction, capitalization bugfix, and deployment confirmation - 16 tickets, 31 commits
- [drive-20260302-213941.md](drive-20260302-213941.md) - Multi-plugin marketplace architecture: renamed core to drivin, created trippin plugin skeleton, implemented /trip command with Agent Teams, enforced ticket context in drive approval prompts - 4 tickets, 8 commits
- [drive-20260213-131416.md](drive-20260213-131416.md) - Absolute path enforcement, schema restructuring, and archive reliability: codified path rule in CLAUDE.md, replaced relative paths across 39 files, nested Goal and Responsibility under Role in agent schemas, fixed unstaged ticket deletions by mandating archive.sh usage - 4 tickets, 10 commits
- [drive-20260212-122906.md](drive-20260212-122906.md) - Naming hygiene, workflow reliability, and developer experience: renamed manage-branch to branching and policy skills to principle, fixed duplicate Japanese specs and double version bumps, added constraint file convention, improved effort validation enforcement and drive approval UX - 9 tickets, 22 commits
- [drive-20260210-121635.md](drive-20260210-121635.md) - Manager tier introduction, commit message restructuring, cross-cutting policies, and workflow enforcement: created 3 managers (project, architecture, quality) with constraint-setting workflow, expanded commit format to 5 sections for lead consumption, added leaders-policy and managers-policy skills - 9 tickets, 20 commits
- [drive-20260208-131649.md](drive-20260208-131649.md) - Lead architecture migration: created define-lead schema, transformed all 10 analyst subagents to domain-specific leads, consolidated 4 viewpoint analysts into architecture-lead, migrated scanner into /scan command, added automatic version bumping, reformed badge system - 17 tickets, 29 commits
- [drive-20260205-195920.md](drive-20260205-195920.md) - Documentation traceability, drive workflow enforcement, scan architecture overhaul from 3-level to 2-level nesting with 17 parallel analysts, legacy spec migration, dual-mode scanning, effort validation, shell script hardening, and Mermaid rendering fixes - 17 tickets, 40 commits
- [drive-20260204-160722.md](drive-20260204-160722.md) - Documentation hygiene, workflow safety, and infrastructure: term document restructuring, translation removal from story-writer, git safeguards, centralized commit skill, release-note-writer subagent, GitHub URL transformation, script path fixes - 8 tickets, 24 commits
- [drive-20260203-122444.md](drive-20260203-122444.md) - Documentation workflow refinement: extracted /scan command from /report, fixed memory leaks in /ticket, added unified diff patches to tickets, renamed /story to /report, refactored ticket-organizer with cleaner naming - 9 tickets, 24 commits
- [drive-20260202-203938.md](drive-20260202-203938.md) - Reliability and consistency improvements: fixed release action trigger to use version comparison, standardized notice section format across commands, added code implementation prohibition to /ticket, configured Opus model for all Task tool invocations - 6 tickets, 12 commits
- [drive-20260202-134332.md](drive-20260202-134332.md) - Parallel subagent orchestration and workflow improvements: enabled subagent-to-subagent parallel invocation, ticket-organizer with 3 parallel discovery agents, story-writer orchestrating 7 documentation agents, continuous drive loop, revision tracking with Discussion section, approval skills consolidation - 14 tickets, 31 commits
- [drive-20260201-112920.md](drive-20260201-112920.md) - Architecture refinement and release workflow fixes: simplified /ticket command to thin orchestrator with ticket-organizer subagent, removed driver subagent from /drive to preserve implementation context, fixed release versioning to default to patch bumps - 3 tickets, 35 commits
- [drive-20260131-223656.md](drive-20260131-223656.md) - Systematic hardening for developer experience: nine focused improvements strengthening command execution and configuration management, defensive programming layers guide Claude toward correct behavior, terminology alignment (fail-to-abandoned, drive-/trip- standardization), validation guards prevent common errors - 9 tickets, 22 commits
- [feat-20260131-125844.md](feat-20260131-125844.md) - Architectural refinement with skill modularization and parallel optimization: skill-to-skill nesting, drive-workflow decomposition into four skills, driver agent for isolated context, performance-analyst moved to Phase 1 parallel execution, generate-changelog merged, intelligent ticket prioritization, structured commit messages, selective options enforcement, and dependency graph restructuring - 19 tickets, 36 commits
- [feat-20260129-023941.md](feat-20260129-023941.md) - Core infrastructure improvements and release automation: pragmatic release-readiness assessment, parallel source discovery in /ticket command, ticket validation hook, SDD terminology clarification in README, GitHub Actions release workflow, path reference fixes, and Mermaid diagram rendering improvements - 10 tickets, 21 commits
- [feat-20260128-220712.md](feat-20260128-220712.md) - TiDD philosophy framework, command simplification, and discovery tooling: README rewritten with TiDD philosophy, /report renamed to /story, directory structure flattened, branch creation integrated into /ticket, history-discoverer subagent added, command-flows specification created, approval loop simplified - 8 tickets, 15 commits
- [feat-20260128-012023.md](feat-20260128-012023.md) - Documentation clarity, workflow enhancement, and technical optimization: Motivation section added to README, Cultivating Semantics terminology, numbered headings formalized, Abandon workflow with failure analysis, Haiku subagent optimization - 9 tickets, 20 commits
- [feat-20260128-001720.md](feat-20260128-001720.md) - Skill consolidation: merged 8 utility skills into primary counterparts, extracted create-branch and create-ticket skills, documented architecture nesting policy, added story translation and markdown linking - 14 tickets, 27 commits
- [feat-20260126-214833.md](feat-20260126-214833.md) - Subagent architecture with concurrent execution, git -C prohibition via settings.json deny, skill extraction, bundled scripts for permission-free plugins, story format enhancements (11 sections with release readiness), and infrastructure improvements (POSIX sh, topic tree flowchart, ticket directory reorganization) - 42 tickets, 101 commits
- [feat-20260126-131531.md](feat-20260126-131531.md) - Workaholic directory standardization and conventions
- [feat-20260124-200439.md](feat-20260124-200439.md) - Ticket metadata and single source of truth consolidation
- [feat-20260124-105903.md](feat-20260124-105903.md) - Rule modularization and PR workflow improvements
- [feat-20260123-032323.md](feat-20260123-032323.md) - Documentation experience improvements and .workaholic/ directory restructuring
