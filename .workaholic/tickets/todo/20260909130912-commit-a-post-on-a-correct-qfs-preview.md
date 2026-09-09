---
created_at: 2026-09-09T13:09:12+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-declared-slack-route-speak-be-seen-and-be-named
merge_policy:
verification_handoff: 
---

# Commit a post on a correct QFS preview

## Overview

PROPOSED. `transport/scripts/adapters/qfs-native.sh:63` guards the commit of a `post_root` /
`post_reply` on

```sh
jq -e '.committed == false and (.preview.rows|type)=="array" and .total_affected > 0' "$tmp/preview"
```

QFS answers the preview with the count nested one level down, at `.preview.total_affected`, as
`{"exact": 1}`. The top-level `.total_affected` is `null`, `null > 0` is `false`, and the guard
therefore fails on a **correct** preview. Every post the loop attempts on the declared route
returns `deferred qfs_preview_refused`, and the commit on line 65 is unreachable.

Measured on `osbrjp/coop-planner` against `/slack-yodex`, 2026-09-09: a one-word body and a body
carrying emoji and links both refuse identically, while `(.preview.total_affected.exact // 0) > 0`
on the same preview answers `true`. Because the route never commits, every post falls through to
the connector — which is how the loop came to speak as a person.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/transport/scripts/adapters/qfs-native.sh` — the guard at line 63 and
  the commit at line 65.
- `plugins/workaholic/skills/transport/scripts/adapters/qfs.sh` — the sibling guard
  (`.ok != false`), whose header records why a jq truthiness mistake reads as an acceptance.
- `plugins/workaholic/skills/transport/scripts/perform.sh` — where `qfs_preview_refused` is
  classified as an authorization failure and licenses the fallback.
- `plugins/workaholic/skills/transport/SKILL.md` — the preview-before-commit contract.
- `scripts/test-workflow-scripts.mjs` — the embedded-jq compile row and where a hermetic preview
  fixture belongs.

## Implementation Steps

1. **Reproduce first.** Capture a real QFS preview body for a `post_root` on the declared route and
   record its exact shape. Do not take the record's quoted shape as established: run the guard
   against the captured body and show it answering `false`.
2. Localize: confirm the failure is the path expression alone and not the `committed` or
   `preview.rows` terms, so the repair is one reading and not a rewritten guard.
3. Read the count where the provider answers it, tolerating both nestings rather than swapping one
   guess for another; a shape neither expression can read stays `qfs_preview_refused`, which is the
   honest word for *the preview did not say what was affected*.
4. Keep the refusal semantics: an absent, malformed or zero-affecting preview still refuses and
   still writes nothing. Only a preview that positively states an affected row may commit.
5. Add a hermetic fixture per shape — nested, flat, absent, zero — asserting commit versus refusal,
   with no network and no `qfs` binary.
6. Re-check `adapters/qfs.sh`'s guard against the same captured body while the evidence is in hand;
   report rather than change it if it is correct.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A preview whose count is nested at `.preview.total_affected.exact` commits.
- A preview stating no affected row, or none this reading can find, still refuses
  `qfs_preview_refused` and writes nothing.
- The `committed == false` and `preview.rows` terms are unchanged.
- A hermetic fixture covers each shape.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the new preview-shape rows.
- A captured live preview body, with the guard's verdict shown before and after.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

## Considerations

- The commit is a real Slack post. Verify against a scratch destination, never by posting the
  fixture into the declared channel.
- This ticket does not touch the fallback ordering. That a refused preview licenses the connector
  is `perform.sh`'s typed contract and is a sibling ticket's subject.
