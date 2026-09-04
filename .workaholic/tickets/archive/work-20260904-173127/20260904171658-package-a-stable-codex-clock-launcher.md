---
created_at: 2026-09-04T17:16:58+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-codex-work-entrypoint-self-contained
merge_policy:
verification_handoff: 
---

# Package a stable Codex clock launcher

## Overview

Place the maintained Codex clock wrapper inside the published plugin or expose a plugin-owned
launcher that works without a repository-local `scripts/codex-loop.sh`.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/runtime-behavior.md` — installed startup has one maintained path

## Key Files

- `scripts/codex-loop.sh` — current maintained supervisor implementation.
- `plugins/workaholic/skills/work/` — published location or launcher surface.
- `scripts/build-plugins/build.mjs` — packaging rules for plugin-owned runtime assets.

## Implementation Steps

1. Measure which runtime files the full plugin package currently publishes.
2. Choose one stable plugin-relative launcher while retaining a repository-local compatibility path.
3. Route both entrypoints through one implementation of locking, environment export, logs, and lifecycle.
4. Rebuild the package and pin the installed layout.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- The documented CLI command works when only the plugin is installed.

**Verification method** — the commands/tests/probes that prove them:

- Build the plugin and invoke the packaged launcher in a temporary repository.

**Gate** — what must pass before approval:

- One maintained supervisor implementation owns both launch paths.

## Considerations

Avoid copying two independently editable supervisor scripts into source and package output.

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: The full plugin already publishes every file below `plugins/workaholic`, so placing
  the maintained launcher beside the work skill requires no second generated bundle.
  **Context**: The repository entrypoint can remain a compatibility shim while installed plugins
  and source checkouts execute one supervisor implementation.
