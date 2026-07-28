---
created_at: 2026-07-28T21:03:03+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure, Config]
effort: 2h
commit_hash:
category: Added
depends_on: 20260728210302-add-proposal-batch-command-and-skill.md
mission: loop-engineering-proposal-loop
---

# Add the Slack notifier and proposal runbook

## Overview

The outbound half of the proposal loop (`docs/loop-engineering-workflow.md` E2, C1, G4-adjacent): when `/propose` registers a draft mission, the team hears about it in Slack **as the bot** ("here is the mission I intend to run — thoughts?"), and a developer can wire the whole 15-minute loop on a server from one runbook page.

Two deliverables:

1. **`notify-slack.sh`** — a POSIX notifier posting via `chat.postMessage` with a **bot token** (decision E2: AI proposals appear as the bot, distinct from human speech). Config is environment-only for now: `SLACK_BOT_TOKEN` (xoxb, `chat:write` scope) and `WORKAHOLIC_SLACK_CHANNEL` (channel id). **A missing/unset token is a graceful, recorded no-op** (`{"notified": false, "reason": "no_token"}`, exit 0) — the loop must run identically on machines with no Slack wiring, and a notification failure must never fail a proposal that already pushed. The token is read from the environment at call time and never persisted, logged, or echoed.
2. **The runbook** — `docs/proposal-loop-runbook.md`: how to stand up the 15-minute cron on a server with headless claude — token provisioning (bot scopes, channel invite), env wiring, the cron entry invoking headless `/propose` in the repo, cursor bootstrap/replay semantics, and how to observe the loop (the `Propose mission *` commits on main, the notifier's JSON in the run log). This documents decision C1's "server cron first" stage; the Claude Code Web port (phase 4) supersedes the cron entry, not the runbook's model.

## Policies

The standard engineering policies that govern this ticket. Read each linked hard copy before writing code; keep every change defensible against its Goal, Responsibility, and Practices.

- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh -eu` (applies to all code work)
- `workaholic:implementation` / `policies/directory-structure.md` — conventional placement (applies to all code work)
- `workaholic:operation` / `policies/operational-planning.md` — the runbook states the operation, its observables, and its failure modes, not just the happy path
- `workaholic:implementation` / `policies/objective-documentation.md` — every runbook step is executable/checkable as written
- `workaholic:design` / `policies/vendor-neutrality.md` — Slack specifics stay inside the notifier script + runbook (the translation boundary); `/propose` itself calls an interface, so a later channel (another chat, Claude Code Web) swaps the script, not the loop

## Key Files

- `plugins/workaholic/skills/propose/scripts/notify-slack.sh` — NEW: `notify-slack.sh "<text>"` → `chat.postMessage` via `curl` with `SLACK_BOT_TOKEN`/`WORKAHOLIC_SLACK_CHANNEL`; JSON out `{notified, reason}` (`no_token` / `no_channel` / `http_<code>` / `slack_<error>`); exit 0 on every no-op path, non-zero only on malformed invocation. Token never appears in output or errors.
- `plugins/workaholic/commands/propose.md` — wire the call after each successful draft push: message = mission title, slug, repo, the mission path on main, and "review & approve via `/mission <slug>`" (approval mechanics land in phase 3; the message says *review*, promising nothing unbuilt). A `notified: false` result is recorded in the run report, never retried in-loop.
- `plugins/workaholic/skills/propose/SKILL.md` — notifier contract section (env names, no-op semantics, the never-fail-the-proposal rule).
- `docs/proposal-loop-runbook.md` — NEW runbook (see Overview §2 for the required content).
- `scripts/test-workflow-scripts.mjs` — hermetic tests (below; network-free — the suite never calls Slack).
- `CLAUDE.md` (commands table note on `/propose` notification), `README.md` if the loop is surfaced there — same change.

## Implementation Steps

1. Implement `notify-slack.sh` (env-driven, curl, JSON out, secret-safe; `WORKAHOLIC_SLACK_API_URL` override so tests can point it at a local stub).
2. Wire the call into `commands/propose.md` after the push step; record the result in the run report.
3. Document the contract in `propose/SKILL.md`.
4. Write `docs/proposal-loop-runbook.md` (provisioning → env → cron entry → bootstrap/replay → observability → failure modes: token revoked, channel archived, push rejected, cursor drift).
5. Hermetic tests: no token → `{"notified": false, "reason": "no_token"}` exit 0; stub URL → success and `slack_<error>` paths; token never present in stdout/stderr on any path.
6. Docs; argument-less `node scripts/build-plugins/build.mjs`; commit regenerated `outputs/`.

## Quality Gate

Interrogated at mission creation (2026-07-28, decision record E2/C1); verification depth ruling: hermetic suite (network-free, stub-based) + runbook walkthrough, per repo precedent.

**Acceptance criteria**

- `notify-slack.sh` posts as the bot when configured, no-ops with a machine-readable reason when not, and never leaks the token in any output path.
- A proposal run's success is independent of notification success (push already happened; the report records `notified`).
- The runbook alone suffices to wire the 15-minute loop on this server: provisioning, env, cron entry, bootstrap, observability, and failure modes are each stated executably.
- The release-scan secret rules do not fire on the notifier or runbook (env reads are references, never literals; the runbook shows placeholder tokens only).

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green with the stub-based notifier cases; build/verify/validate-metadata green; posix-lint conforming.

**Gate**

- Suite green, and a dry-run demo: `notify-slack.sh "test"` without a token prints the `no_token` no-op; with the stub URL, the success path round-trips.

## Considerations

- Do **not** install the crontab in this ticket — the runbook documents it and the developer applies it (an outward-facing standing process is the developer's act; the H4/private-repo precondition note belongs in the runbook too).
- Environment-only config is deliberate for phase 2 (decided at mission creation): a committed channel-mapping file becomes worthwhile only at multi-repo rollout (phase 4) — resist adding it now.
- Keep the message body free of customer context by construction: it names this repo, the mission title, and the path — nothing else (repository-confinement doctrine applies to outbound text as much as files).

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: The token's only exposure surface is the one `curl` Authorization header with stderr discarded — every failure path (unreachable endpoint, non-200, unparseable body, Slack error) maps to a machine-readable `reason` with the token provably absent from stdout/stderr, which the hermetic suite asserts against a `supersecret` marker token rather than trusting inspection.
  **Context**: `plugins/workaholic/skills/propose/scripts/notify-slack.sh`; testNotifySlack.
- **Insight**: The runbook's failure-mode table doubles as the notifier's error vocabulary spec (`slack_token_revoked`, `slack_channel_not_found`, …) — writing the ops page and the script against the same reason strings keeps "what the log says" and "what the runbook explains" from drifting.
  **Context**: `docs/proposal-loop-runbook.md` §6.
- **Insight**: The release-scan's secret rules stay quiet on the runbook because its token examples are ellipsis placeholders (`xoxb-…`), not literal alphanumeric runs — the value-shape rule working as designed; keep placeholders non-literal in ops docs.
  **Context**: `scan-branch-safety.sh` over this branch (size findings only).

