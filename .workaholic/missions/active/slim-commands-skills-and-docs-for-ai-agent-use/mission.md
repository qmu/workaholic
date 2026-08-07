---
type: Mission
title: Slim commands, skills, and docs for AI-agent use
slug: slim-commands-skills-and-docs-for-ai-agent-use
status: active
merge_policy:
created_at: 2026-08-06T12:49:35+00:00
author: noreply@anthropic.com
assignees: []
assignee:
predicted_hours:
actual_hours:
feedback: [20260806124808-ai.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260807-102500
---

# Slim commands, skills, and docs for AI-agent use

## Goal

The plugin's primary audience shifts from developers to AI agents (Claude Code
Web Routine and the like); developer use stays supported but secondary. Commands
carry processing bodies they should not, skills have accreted formalized rules
and past-incident scar tissue, bold is overused, and tests and shell scripts
have multiplied. Cut the volume by deleting what is no longer needed — not by
compressing — so an agent reads the shape, not the history.

## Experience

Commands are a few lines of skill-alias each (including the `/propose` and
`/implement` routine instructions, whose real work lives in their skills). Every
SKILL.md — `drive/SKILL.md` included — reads under ~100 lines: obsolete rules
gone, past-incident notes folded into a short caveat list, bold only where it
earns its weight. Tests and scripts are pared to what is load-bearing, the
ticket front matter drops `type`/`layer`/`effort`/`commit_hash`/`category`, and
the README-reachable docs are reorganized to match the current spec.

## Acceptance

<!-- PROPOSED criteria, THREE ITEMS OR FEWER - a sketch for discussion, not a
     plan. Approval replans this mission to drive-ready; only then may it be
     authorized. -->

- [x] Every command is a thin skill-alias and every SKILL.md (drive/SKILL.md
      included) sits under ~100 lines with obsolete rules, scar-tissue prose, and
      non-essential bold removed. (#20260806125031-cut-every-skill-md-under-the-line-target.md)
- [x] Tests, shell scripts, and the ticket front matter are pared to what is
      needed — `type`/`layer`/`effort`/`commit_hash`/`category` dropped. (#20260806125031-drop-obsolete-ticket-front-matter-fields.md)
- [x] README-reachable docs are restructured to the current spec and the plugin
      is framed for AI-agent use first, developer use second. (#20260806125031-reframe-the-plugin-for-ai-agent-use-first.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-07 — ticket archived — 20260806125031-make-every-command-a-thin-skill-alias.md
- 2026-08-07 — ticket archived — 20260806125031-drop-obsolete-ticket-front-matter-fields.md
- 2026-08-07 — ticket archived — 20260806125031-cut-every-skill-md-under-the-line-target.md
- 2026-08-07 — ticket archived — 20260806125031-pare-tests-and-shell-scripts-to-the-load-bearing-set.md
- 2026-08-07 — ticket archived — 20260806125031-reframe-the-plugin-for-ai-agent-use-first.md
- 2026-08-07 — ticket archived — 20260806125031-restructure-readme-reachable-docs-to-the-current-spec.md
- 2026-08-07 — ticket archived — 20260807105800-let-final-report-edits-pass-on-foreign-authored-tickets.md
