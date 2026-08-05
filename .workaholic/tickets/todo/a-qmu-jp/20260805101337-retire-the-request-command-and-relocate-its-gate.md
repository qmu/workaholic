---
created_at: 2026-08-05T10:13:37+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
depends_on: 20260805101337-give-fb-a-cross-repo-issue-mode.md
mission: cross-the-repo-boundary-as-an-issue
merge_policy:
---

# Retire the request command and relocate its gate

## Overview

With the /fb issue mode live (sibling ticket), retire `/request`: delete the
command and fold the request skill into the feedback skill — **relocating, not
deleting**, its load-bearing knowledge. The §1 rationale (why no matcher can
replace the human gate, with the four measured leaked sentences), the
identifier-not-substring mask check, `remote-url.sh`'s every-URL-form reading,
and `resolve-target.sh`'s visibility reporting all survive under the feedback
skill. `submit-request.sh`'s file write into a target checkout is the one thing
that actually dies.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` / documentation policies — a retired surface is removed with its rationale recorded and its knowledge relocated

## Key Files

- `plugins/workaholic/commands/request.md` — delete
- `plugins/workaholic/skills/request/` — fold into `skills/feedback/` (scripts: `resolve-target.sh`, `lib/remote-url.sh`, the identifier matcher move; `submit-request.sh` deleted); check `computeClosure` so the bundle carries the moved scripts
- `plugins/workaholic/rules/general.md` — "only through /request" → the /fb issue path
- `plugins/workaholic/hooks/guard-repo-confinement.sh` — its refusal text names /request; re-point at /fb
- `CLAUDE.md`, `README.md`, `plugins/workaholic/rules/workaholic.md`, `.workaholic/README.md` — command table row, Repository-confinement section, every /request mention becomes the /fb issue path (historical/measured passages keep the old name with a dated note)
- `scripts/test-workflow-scripts.mjs` — the request-suite assertions move with the scripts (including "the four real leaked sentences pass unflagged" and the confinement pins); `submit-request`-specific cases die with it

## Implementation Steps

1. Move the scripts and their tests into the feedback skill's `scripts/`;
   update every `${CLAUDE_PLUGIN_ROOT}` reference; rebuild `outputs/` and
   confirm `verify.mjs` sees the closure.
2. Port `request/SKILL.md` §1-3 (gate rationale, masking judgment, vocabulary
   rule) into `feedback/SKILL.md`'s crossing section — verbatim where the prose
   is measured history, tightened where it duplicated what the sibling already
   wrote.
3. Delete `commands/request.md` and the emptied `skills/request/`; update the
   policy-lens sentinel list if /request carried it.
4. Re-point the docs: rules/general.md, guard-repo-confinement.sh message,
   CLAUDE.md (command table + Repository confinement section), README. The
   guard's behavior is unchanged — only its advice text moves.
5. Grep gate: `grep -rn "/request" plugins/ docs/ CLAUDE.md README.md` returns
   only dated history.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No live surface offers /request; the guard's refusal names the /fb issue path
- The gate rationale, identifier matcher, URL-form reading, and visibility reporting all still exist and are exercised by tests at their new home
- The bundle rebuild is clean with the moved closure

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green; `verify.mjs`/`validate-metadata.mjs` clean
- The grep gate over live docs

**Gate** — what must pass before approval:

- Both mission acceptance items satisfiable from this branch's evidence

## Considerations

- History stays: archived tickets/stories naming /request are never rewritten;
  CLAUDE.md's measured incident passages keep the name with "retired 2026-08-05".
- If the marketplace or cross-agent bundle references the request skill,
  update the manifests in the same change.
