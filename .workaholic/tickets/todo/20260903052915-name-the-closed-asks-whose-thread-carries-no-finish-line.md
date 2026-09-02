---
created_at: 2026-09-03T05:29:15+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: announce-an-ask-that-landed-outside-a-unit-route-in-its-own-thread
merge_policy:
verification_handoff: 
---

# Name the closed asks whose thread carries no finish line

## Overview

An ask swept off the channel becomes an `[FB]` issue and a feedback record. When that issue
closes, the item is finished — but nothing anywhere answers *which finished items were never
announced*. `moderate/scripts/reconcile-candidates.sh` answers a neighbouring question and
cannot answer this one: it enumerates **merged or closed pull requests on `work-*` branches**,
so an ask that landed through a session working it directly produces no `work-*` branch and
therefore no candidate. This ticket adds the reader for the item grain.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/reconcile-candidates.sh` — the neighbouring
  reader, and the shape to follow: repository-derived candidates, `gh-rest.sh` only, `ok: false`
  with a reason and exit 0 rather than an empty list.
- `plugins/workaholic/skills/drive/scripts/unit-feedback-stems.sh` — how an artifact resolves
  to the `fb:<stem>` thread key; reuse it rather than deriving a second key.
- `plugins/workaholic/skills/propose/scripts/list-swept-slack-refs.sh` — the sweep's own ledger
  and the `slack-ref:` marker each captured record carries.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the one GitHub transport.

## Implementation Steps

1. Reproduce the gap before designing for it: take a recently closed `[FB]` issue whose work
   landed outside `/implement`, and confirm `reconcile-candidates.sh` returns no candidate for
   it. Record which term excluded it (`work-*` branch enumeration), so the new reader is
   justified by a measurement rather than by the ask's framing.
2. Add `plugins/workaholic/skills/propose/scripts/list-unannounced-closed-asks.sh`: list this
   repository's **closed** issues through `gh-rest.sh`, keep those whose body header names a
   `slack-ref:` (the sweep captured them) or whose feedback record on the base names the
   issue's `/issues/<N>` URL, and resolve each to its feedback stem.
3. Emit one JSON line: `{"ok", "slug", "limit", "read", "truncated", "candidates": [{"number",
   "url", "title", "stem", "slack_ref", "closed_at"}], "unresolved": [{"number", "reason"}]}`.
   A candidate resolving to no stem lands in `unresolved` under `stems_unresolvable` — it has
   no thread to announce into — and is never invented a key.
4. Bound the read with `WORKAHOLIC_ANNOUNCE_CLOSED_MAX` (default 10), newest-first, reporting
   `truncated` rather than silently cutting.
5. Never scan the channel: the candidate set is repository- and issue-derived only, matching
   the bound `workaholic:notify` places on every thread lookup.
6. An unreadable read is `{"ok": false, "reason": "gh_unavailable"|"list_failed", "detail"}`
   with **exit 0** — never an empty candidate list, which reads as *nothing to announce*.

## Quality Gate


**Acceptance criteria** — the checkable conditions that must hold:

- The reader names a closed `[FB]` issue whose work landed outside `/implement`, with its
  feedback stem resolved.
- A candidate with no resolvable stem appears in `unresolved`, never in `candidates`.
- An unreadable read answers `ok: false` with a named reason and exits 0.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` with a hermetic case per condition above.
- A manual run against this repository naming at least the measured 2026-09-02 item.

**Gate** — what must pass before approval:

- The script reads GitHub only through `gather/scripts/gh-rest.sh`, and makes no channel read.

## Considerations

- The exclusion this reader must not re-derive: an item already announced is ticket
  *Post the finish line from the tick, once per ask*'s question, answered from the thread, not
  from the repository. This reader answers *which items to look at* and nothing more — the same
  split `reconcile-candidates.sh` states in its own header.
