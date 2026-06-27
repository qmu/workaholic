---
created_at: 2026-06-28T00:20:49+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 1h
category: Changed
depends_on: [20260628002047-gate-commit-and-branch-via-pretooluse-bash.md]
---

# Stop emitting a `Co-Authored-By: Claude` trailer by default

## Overview

`skills/commit/scripts/commit.sh` hardcodes `TRAILERS="Co-Authored-By: Claude <noreply@anthropic.com>"`
and the documented examples in `skills/commit/SKILL.md` and `skills/drive/SKILL.md` show the same
trailer. So even the *sanctioned* commit path stamps every commit with a Claude co-author line.
Meanwhile the agent harness carries its own default ("end commits with `Co-Authored-By: Claude
…`"), in a *different* spelling — so commits made via raw Bash get the harness's variant. The net
effect is two conflicting Claude-attribution conventions, neither chosen deliberately, both landing
in consumer history that does not want them.

This ticket makes the attribution decision **once, in the plugin, and enforces it** so a harness
default cannot override it: emit **no** Claude co-author trailer by default, strip any Claude
co-author trailer in the commit gate, and remove it from the documented examples. The `Category:`
trailer (machine-read by `/report`) stays — only the Claude attribution goes.

## Policies

The standard engineering policies that govern this ticket. The implementing session **MUST** read
each linked policy hard copy before writing code.

- `workaholic:implementation` / `policies/coding-standards.md` — single source of truth for trailer rendering; remove the hardcoded default cleanly rather than conditionalizing around it (applies to all code work).
- `workaholic:implementation` / `policies/policy-conformance-audit.md` — **central:** the decision is enforced (gate strips/rejects the trailer), not merely documented, so it cannot silently regress.
- `workaholic:implementation` / `policies/command-scripts.md` — if attribution ever becomes configurable, `commit.sh` and the gate read the **same** setting; no second source.
- `workaholic:operation` / `policies/ci-cd.md` — a smoke test asserts the rendered message carries no Claude co-author line, locking the decision in CI.

Repo-own rules (CLAUDE.md): the `commit` skill is the canonical message-format source; **POSIX sh**
for any script edits; commit/skill content is Claude-only except `commit.sh` whose shipped behavior
is exercised by the smoke harness — keep the test green.

## Key Files

- `plugins/workaholic/skills/commit/scripts/commit.sh` — remove `Co-Authored-By: Claude <noreply@anthropic.com>` from the `TRAILERS` block (around the Category-trailer assembly). Keep the `Category:` trailer path intact. When the resulting trailer block is empty, render the body without a trailing trailer paragraph (no empty trailer line).
- `plugins/workaholic/skills/commit/SKILL.md` — delete the `Co-Authored-By: Claude …` line from the message example; if useful, add a one-line note that the plugin emits no AI co-author trailer by default.
- `plugins/workaholic/skills/drive/SKILL.md` — remove the co-author trailer from its documented commit example so `/drive` stops modeling it.
- `plugins/workaholic/hooks/guard-git-commit.sh` (from `20260628002047`) — extend: reject a direct Bash `git commit` whose inline message contains `Co-Authored-By:` with `Claude` / `noreply@anthropic.com`, so a harness-default trailer is blocked at the agent surface.
- `scripts/test-workflow-scripts.mjs` — add a `commit.sh` rendering assertion: the message has **no** `Co-Authored-By` line and still carries the `Category:` trailer when `--category` is passed.

## Related History

Past tickets that touched similar areas:

- [6a1a4fc promote-category-to-git-trailer](.workaholic/tickets/archive/work-20260627-153246/20260627210217-promote-category-to-git-trailer.md) - Built the `Category:` trailer block this ticket must preserve while removing the co-author line; note git parses only the last paragraph as trailers.
- [24e5b37 restructure-commit-body-for-report](.workaholic/tickets/archive/work-20260627-153246/20260627210216-restructure-commit-body-for-report.md) - Established the current `commit.sh` body/trailer rendering this ticket edits.

## Implementation Steps

1. **Remove the default trailer** from `commit.sh`; ensure an empty trailer block renders no dangling paragraph and that `--category` still appends `Category: <value>` as the last paragraph (git-trailer-parseable).
2. **Scrub the docs:** drop the co-author line from the `commit` and `drive` SKILL.md examples.
3. **Enforce in the gate:** in `guard-git-commit.sh`, block direct Bash commits carrying a Claude co-author trailer, naming the policy in the block message.
4. **Lock it with a test:** assert the rendered message has no `Co-Authored-By` and retains `Category:` when set.
5. **Verify.** `node scripts/test-workflow-scripts.mjs` green; `node scripts/build-plugins/verify.mjs`; rebuild `outputs/` only if `commit.sh` is in a shipped closure (it is — `commit` is in the drive/ship closure), so run `node scripts/build-plugins/build.mjs` and commit the regenerated `outputs/` in lockstep, then confirm Outputs Freshness is clean.

## Considerations

- **Decision is "emit none by default."** Do not add a config knob now (YAGNI). If a real consumer later wants attribution, add `git config workaholic.coAuthor true` read identically by `commit.sh` and the gate — never a model-side convention that a harness can shadow.
- **Outputs coupling:** `commit.sh` lives in the shipped drive/ship closure, so editing it requires a `build.mjs` rebuild and an `outputs/` commit in the same change, or Outputs Freshness CI fails. This differs from the hooks in `20260628002047` (which have no `outputs/` footprint).
- **Existing history is out of scope.** This ticket changes future commits only; already-merged trailers in consumer repos are not rewritten here (history rewrite is a separate, repo-owner decision).
- **Don't touch `Category:`** — it is machine-read by `/report`/`write-release-note`. Only the Claude attribution line is removed.
