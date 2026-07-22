---
created_at: 2026-07-22T09:18:12+09:00
author: a@qmu.jp
type: enhancement
layer: [Application]
effort: 2h
commit_hash:
category: Added
depends_on: 20260722091809-concern-corpus-wide-judge.md
mission:
---

# Staleness decay: propose (never auto-close) concerns whose paths are gone and last_seen is old

## Overview

Split off from `20260722004500` (mechanism 5). More than half an audited corpus was `low` severity with aging `last_seen` and no expiry pressure, crowding the view. When a concern's `last_seen` has not been refreshed for N ships *and* its referenced paths no longer exist, have the (corpus-wide) judge emit a `close-stale` **proposal** — never an auto-close without evidence. Optionally a policy knob for low-severity expiry review. Depends on the corpus-wide judge (`20260722091809`), which supplies the default-branch path-existence check.

## Policies

- `workaholic:development` / `qa-engineering` — a stale-close is judge-proposes/developer-decides unless it is fully evidence-backed (paths gone), and even then it writes its rationale.
- `workaholic:implementation` / `objective-documentation` — every close records the staleness evidence (age + missing paths).

## Key Files

- The corpus-wide judge surface from `20260722091809` — where the staleness proposal is emitted.
- `plugins/workaholic/skills/report/scripts/close-concern.sh` — the existing evidence-recording close mutator to reuse.

## Quality Gate

- **Acceptance**: a concern with an old `last_seen` and referenced paths that no longer exist yields a `close-stale` proposal (not an auto-close) on a fixture; the proposal names the age and the missing paths.
- **Verification**: `node scripts/test-workflow-scripts.mjs` green with the fixture; `verify.mjs` passes.
- **Gate**: no auto-close without recorded evidence; `accepted` closures still require confirmation.

## Considerations

- Staleness pressure must not hide risk: a still-referenced pattern is never stale regardless of age.

## Abandonment

Abandoned 2026-07-22 by developer decision. These four mechanisms attacked the deferred-concern pile-up from the **disposal** side (auto-close / auto-verify / auto-shelve an already-large corpus). The correct fix proved to be **prevention** — the concern promotion floor (commit `856bf9e1`, ticket `20260722122105`): the story keeps every concern, but only `moderate`+/`Keep` ones enter the tracked corpus, so the pile never grows to need this machinery. The `verify_command` mechanism was additionally a code-execution surface we chose not to build. Shrinking an *existing* bloated corpus is handled by a separate developer-confirmed demotion ticket, not by these.
