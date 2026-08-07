---
created_at: 2026-08-06T12:50:31+00:00
author: noreply@anthropic.com
assignees: [noreply@anthropic.com]
type: housekeeping
layer: [Config]
effort:
commit_hash:
category: Changed
depends_on:
mission: slim-commands-skills-and-docs-for-ai-agent-use
merge_policy:
---

# Restructure README-reachable docs to the current spec

## Overview

<!-- PROPOSED. Sharpened by the mission's approval interrogation. -->

FB item 6: the documents reachable from `README.md` have drifted and grown ad hoc.
Reorganize them into a coherent structure that matches the current spec — the loop
model, the commands, the claim protocol, the routines — removing stale pages and
merging overlapping ones, so a reader (agent or developer) can navigate from the
README to an accurate, non-redundant set.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `README.md` — the entry point and its links.
- `docs/*` — the reachable set to reorganize/prune.
- `CLAUDE.md` — cross-check that its descriptions match the reorganized docs.

## Implementation Steps

1. Map every doc reachable from the README and mark each as current, stale, or overlapping.
2. Merge overlapping pages, delete stale ones, and give the set a clear top-level structure.
3. Rewrite the README's navigation to the new structure.
4. Run `doc-drift.sh` (via `/report`) to confirm no described area is out of date.

## Quality Gate

**Acceptance criteria:**

- Every README-linked doc is current and non-redundant.
- The doc set has a clear, navigable structure.

**Verification method:**

- Manual link-walk from the README; `doc-drift.sh` reports no drift.

**Gate:**

- No dangling links; retired docs are removed, not orphaned.

## Considerations

<!-- Scope which docs are in the "README-reachable" set versus deep-reference; the
     approval interrogation should draw the line. -->

## Final Report

Development completed as planned. The README linked no docs/ page at all — the whole tree was orphaned. It now carries a Documentation section (CLAUDE.md as the agents' operating manual → the decision log → the two operator runbooks → the OKF dependency record → the artifacts hub). One stale page deleted (gate-audit-shape-dependent-green.md — a dated audit of a tree that no longer exists, its durable findings already in feedback records); the decision log repositioned as append-only history; both runbooks kept (test-pinned, cited by name) and trimmed of drifted restatements; README/.workaholic-README stale spots fixed (fourteen commands, /mission-close, J4 publish path, M1 stamp rule, the /implement-only Slack scoping, the retired routine-management surface). All links resolve repo-wide.

### Discovered Insights

- **Insight**: The docs had drifted invisibly because nothing reached them — an unlinked page cannot be caught by a link walk.
  **Context**: The new README navigation makes doc-drift.sh's reachable set meaningful.
