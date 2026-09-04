---
created_at: 2026-09-03T10:13:21+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-maintenance-tick-s-channel-presence-help-the-work-along
merge_policy:
verification_handoff: 
---

# State an impairment once, in the root or the digest and not in both

## Overview

The same three `⚠` impairment lines appeared in the root and again, verbatim, at the bottom of
the `📣` digest thirty-eight minutes later. And the one line worth breaking silence for —
`base-health` unable to read `main`'s checks — was the fourth bullet of a digest, in the same
weight as a commit count. Say an impairment once, in the place a reader acts on it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/user-experience.md` — the reader of the post is the user here

## Final Report

**Outcome**: implemented.

The rule is stated where the duplication happened — `commands/moderate.md`, the surface that composes
the post from `render-tick-post.sh`'s payload. **An impairment is stated once, on the root, and never
again in the digest.** The root is where a reader can act on it, because it is the message the
impairment itself can open; the digest reports where the work stands and carries no `⚠️` line at all.

**On a morning tick both are in the same root**, so the ordering was made explicit rather than left
to chance: the digest renders **above** the impairment lines, and the reader meets each fact once.
That also answers the second half of the measurement — `base-health` unable to read the base's checks
arrived as the fourth bullet of a digest, in the same weight as a commit count; on the root it sits
in the `⚠️` block, which is the only place on the post reserved for a reading the tick could not make.

**Nothing mechanical changed.** `render-tick-post.sh` still derives `impaired[]` on every exit path
including the silent ones, the changed-impairment gate is untouched, and `WORKAHOLIC_IMPAIRED_MAX`
still bounds the named set with the rest counted. What moved is where the composed post may repeat it.

**Verified**: `node scripts/test-workflow-scripts.mjs`.
