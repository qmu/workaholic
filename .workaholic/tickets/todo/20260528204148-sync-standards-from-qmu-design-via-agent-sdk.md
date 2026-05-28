---
created_at: 2026-05-28T20:41:48+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure, Config]
effort:
commit_hash:
category:
depends_on:
---

# Sync Standards From qmu.co.jp/design via Claude Agent SDK

## Overview

Reflect the qmu.co.jp design-system policy into this repository's `plugins/standards/skills/leading-*/SKILL.md` automatically. An hourly GitHub Action polls `https://qmu.co.jp/design`, detects when its content has changed since the previous run, and — only on change — invokes the Claude Agent SDK in headless mode. The agent fetches the relevant sub-pages, diffs them against the previously-seen snapshot, and proposes edits to the four leading lenses (`leading-accessibility`, `leading-availability`, `leading-security`, `leading-validity`). The agent never pushes to `main`: it commits to a branch and opens a pull request for human review. The previously-seen snapshot is updated **inside the same PR commit**, so an unchanged page never produces git noise and each PR is self-contained.

The motivation is to make the qmu.co.jp design system the upstream source of truth for the project's policy lenses. Today the four `leading-*` skills carry hand-authored policy that nobody systematically reconciles with the corporate site; this change closes that loop with a structurally-bounded agent rather than a manual review cadence.

## Key Files

### Targets the agent is allowed to edit
- [plugins/standards/skills/leading-accessibility/SKILL.md](plugins/standards/skills/leading-accessibility/SKILL.md) - 52 lines; frontmatter `name`/`description`/`user-invocable` only.
- [plugins/standards/skills/leading-availability/SKILL.md](plugins/standards/skills/leading-availability/SKILL.md) - 57 lines; contains the `Deliberate Dependency Coupling` policy this very ticket must satisfy.
- [plugins/standards/skills/leading-security/SKILL.md](plugins/standards/skills/leading-security/SKILL.md) - 37 lines (shortest, most skeletal).
- [plugins/standards/skills/leading-validity/SKILL.md](plugins/standards/skills/leading-validity/SKILL.md) - 84 lines (longest, most mature; use as the structural template).

The agent must edit only these four paths. Any change outside the allowlist is a validator failure.

### Schema contract
- [.claude/rules/define-lead.md](.claude/rules/define-lead.md) - Required sections (`## Role` → `### Goal`/`### Responsibility`, `## Policies`, optional `## Practices`, optional `## Standards`), frontmatter shape (`name` + `description` only), and the four-tier order (Role → Policies → Practices → Standards). The post-edit validator runs against this checklist.

### New files this ticket creates
- `.github/workflows/standards-sync.yml` - Hourly cron workflow. `permissions: contents: write, pull-requests: write` at job scope; `concurrency: group: standards-sync, cancel-in-progress: false`.
- `scripts/standards-sync/fetch-design-page.sh` - Tiny POSIX-sh wrapper that fetches `https://qmu.co.jp/design` with a real browser User-Agent header (Cloudflare blocks the default Agent-SDK `WebFetch` — see Considerations). Writes the raw HTML and a content hash to `runtime/standards-sync/snapshot/`.
- `scripts/standards-sync/run-agent.mjs` - Node entry-point that imports `query` from `@anthropic-ai/claude-agent-sdk`, configures `allowedTools: ["Read", "Edit", "Glob", "Grep"]` (no `Write`, no `Bash`, no `WebFetch` — fetched HTML is delivered as Read-able files), `permissionMode: "acceptEdits"`, `cwd` rooted at the repo, a `PreToolUse` hook that blocks any edit outside `plugins/standards/skills/leading-*/SKILL.md`, and a `PostToolUse` hook that appends every edit to a per-run audit log.
- `scripts/standards-sync/validate-lead-schema.mjs` - Pure function that parses each edited SKILL.md frontmatter + section order against the `define-lead.md` checklist and exits non-zero if any file fails. Reused by the workflow as a separate step *after* the agent runs.
- `scripts/standards-sync/state.json` - Committed marker file. Shape: `{ "url": "https://qmu.co.jp/design", "last_seen_content_hash": "sha256-...", "last_checked_at": "ISO-8601", "last_pr_url": "..." }`. Read at the start of every run; updated only inside the PR commit when a change is detected and applied.
- `scripts/standards-sync/README.md` - Operator doc: what each script does, how to dry-run locally (`ANTHROPIC_API_KEY=... node scripts/standards-sync/run-agent.mjs --dry-run`), how to disable (workflow toggle), and the documented exit strategy.

### Reference patterns from existing CI
- [.github/workflows/release.yml](.github/workflows/release.yml) - Use as the `permissions:` + `GITHUB_TOKEN` + `gh` CLI pattern (lines 9-18, 42-43, 108).
- [.github/workflows/validate-plugins.yml](.github/workflows/validate-plugins.yml) - The PR the bot opens must pass this workflow's `jq` checks, `validate-metadata.mjs`, and `test-workflow-scripts.mjs`. Since the agent only edits `plugins/standards/skills/leading-*/SKILL.md`, none of those should regress, but verify in a dry-run.
- [.github/workflows/dist-freshness.yml](.github/workflows/dist-freshness.yml) - `plugins/standards/` is outside the `build.mjs` closure ([scripts/build-plugins/build.mjs](scripts/build-plugins/build.mjs) line 33 `CORE_SKILLS = plugins/core/skills`), so standards-only PRs do not need `dist/` regeneration and this workflow passes vacuously. Confirm in dry-run.
- [plugins/core/hooks/validate-ticket.sh](plugins/core/hooks/validate-ticket.sh) - Rejects `@anthropic.com` authors. The bot's PR commits must author as `github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com>` with `Co-Authored-By: TAMURA Yoshiya <a@qmu.jp>` — not the SDK's default Claude attribution.

## Related History

This is net-new ground: no existing workflow in `.github/workflows/` uses a `schedule:` trigger, no prior commit introduces an Anthropic SDK / `npx` dependency in CI, and `qmu.co.jp` is referenced nowhere in the repository. The closest reference patterns are listed below.

- [.workaholic/tickets/archive/work-20260417-092936/20260509001216-wire-leads-into-work-flows.md](.workaholic/tickets/archive/work-20260417-092936/20260509001216-wire-leads-into-work-flows.md) - Establishes the four `leading-*` skills as the project's canonical policy surface; defines why those four files matter and why they are load-bearing for `/ticket` and `/drive`.
- [.workaholic/tickets/archive/feat-20260131-125844/20260129123400-auto-release-on-merge.md](.workaholic/tickets/archive/feat-20260131-125844/20260129123400-auto-release-on-merge.md) - The only prior example of a GitHub Action that mutates the repo automatically. Sets the `permissions: contents: write` + `GITHUB_TOKEN` precedent that this workflow extends with `pull-requests: write`.
- [.workaholic/tickets/archive/drive-20260202-203938/20260202204111-fix-release-action-trigger-on-merge.md](.workaholic/tickets/archive/drive-20260202-203938/20260202204111-fix-release-action-trigger-on-merge.md) - Cautionary tale about GitHub Action trigger semantics on merges — relevant to the auto-PR flow this ticket introduces.
- [.workaholic/tickets/archive/drive-20260131-223656/20260201100737-reject-anthropic-email-in-ticket-author.md](.workaholic/tickets/archive/drive-20260131-223656/20260201100737-reject-anthropic-email-in-ticket-author.md) - The hard rule that bot commits cannot author as `@anthropic.com`. The Agent SDK's default attribution must be overridden.
- [.workaholic/tickets/archive/work-20260518-235327/20260527142130-relocate-cross-agent-output-into-dist.md](.workaholic/tickets/archive/work-20260518-235327/20260527142130-relocate-cross-agent-output-into-dist.md) - Defines the `dist/` freshness check pattern. Standards is outside that closure, but the bot's PR must still pass.
- Recent commit `c3796cc` (this branch) - Introduced `publicizeSkillMd`'s `PUBLIC_SUBSTITUTIONS` list. If the qmu.co.jp policy ever asks for terminology changes, the bot must apply them to source skills (Claude reads source) and let the build rewrite the public copies — the same source-vs-generated split applies here.

## Implementation Steps

The pipeline has four layers; each is independently testable. Build them in order, with hermetic tests against fixtures before any live-internet step.

### 1. State and fetch layer (no SDK yet)

1. Add `scripts/standards-sync/state.json` with shape `{"url": "https://qmu.co.jp/design", "last_seen_content_hash": null, "last_checked_at": null, "last_pr_url": null}`. Commit as part of this work.
2. Add `scripts/standards-sync/fetch-design-page.sh`. POSIX `#!/bin/sh -eu`. Args: `<output-dir>`. Uses `curl -fsSL -A "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 ..."` to fetch the page. Writes `<output-dir>/design.html` and `<output-dir>/design.sha256` (sha256 of the HTML). Retries with exponential backoff (3 attempts, 2s/8s/32s) on 5xx and connection errors. Exits 0 on transient failure with a stderr note; exits non-zero only on persistent failure after retries — the workflow can then `continue-on-error: true` and post a `$GITHUB_STEP_SUMMARY` line rather than failing the run.
3. Hermetic test: `scripts/standards-sync/test/test-fetch.sh` runs the fetcher against a local fixture HTTP server (Python `http.server` started in the same script) serving `scripts/standards-sync/test/fixtures/design.html`. Assert exit code, file content, and hash.
4. Add a single change-detection script `scripts/standards-sync/check-changed.sh` that reads `state.json`'s `last_seen_content_hash`, compares to the freshly-fetched hash, and exits 0 (`unchanged`) or 1 (`changed`). The workflow gates the agent step on this exit code so the SDK is only paid for when there's actual work.

### 2. Agent invocation layer

1. Add `package.json` at the repo root with `{ "private": true, "dependencies": { "@anthropic-ai/claude-agent-sdk": "<pinned>" }, "type": "module" }`. Confine the dependency to a single module per the Deliberate Dependency Coupling policy. Pin the version exactly; document an exit strategy in the README that says "replace with ~80 lines of `@anthropic-ai/sdk` Messages API + the schema validator if SDK becomes unmaintained."
2. Add `scripts/standards-sync/run-agent.mjs`. Pattern follows the official docs (`https://code.claude.com/docs/en/agent-sdk/overview`):
   ```
   import { query } from "@anthropic-ai/claude-agent-sdk";
   for await (const message of query({
     prompt: <system + user prompt described below>,
     options: {
       allowedTools: ["Read", "Edit", "Glob", "Grep"],
       permissionMode: "acceptEdits",
       cwd: process.cwd(),
       hooks: {
         PreToolUse: [{ matcher: "Edit|Write", hooks: [blockOutsideAllowlist] }],
         PostToolUse: [{ matcher: "Edit", hooks: [auditEdit] }]
       },
       settingSources: []  // do NOT load .claude/ — the bot runs with no project skills
     }
   })) { /* stream to $GITHUB_STEP_SUMMARY */ }
   ```
3. The `blockOutsideAllowlist` hook rejects any `tool_input.file_path` that does not match the regex `^plugins/standards/skills/leading-(accessibility|availability|security|validity)/SKILL\.md$`. Defense-in-depth (per `leading-security`): the post-run validator catches this too, but the hook fails fast and avoids spurious commits.
4. The `auditEdit` hook appends each edit's `{timestamp, file_path, old_string, new_string}` to `runtime/standards-sync/audit-<run-id>.log` (uploaded as a workflow artifact).
5. Construct the prompt as: (a) the four `leading-*/SKILL.md` paths and their current content (the agent reads them via Read); (b) the previous snapshot under `runtime/standards-sync/snapshot-previous/design.html` (committed marker text from `state.json` plus the file the agent re-fetches); (c) the new snapshot under `runtime/standards-sync/snapshot/design.html`; (d) the lead-schema contract from `.claude/rules/define-lead.md`; (e) an explicit instruction to propose minimal diffs, preserve the "humble trade-off-acknowledging tone" (per the leading-skill commit history `86a048c`), and place new content in the correct tier (Policies vs Practices vs Standards). For Read-able input the agent does NOT need WebFetch — that's why it isn't in `allowedTools`.
6. The agent's prompt also says: edit no other files; do not run Bash; do not change frontmatter; do not bump versions.

### 3. Schema validation layer

1. Add `scripts/standards-sync/validate-lead-schema.mjs`. Pure typed function `validateLeadFile(path) → { ok: boolean, errors: string[] }`. Checks:
   - Frontmatter parses as YAML and contains only `name`, `description`, `user-invocable` keys
   - `name` matches `leading-<speciality>` from the filename
   - Top-level sections appear in the order `## Role` → `## Policies` → (optional `## Practices`) → (optional `## Standards`)
   - `## Role` has `### Goal` and `### Responsibility` H3s
2. Run the validator over every file in the allowlist after the agent step. If any file fails, the workflow opens an issue (`gh issue create`) with the failure summary and the audit log linked, and exits without opening a PR.
3. Add Vitest-or-equivalent hermetic tests against `scripts/standards-sync/test/fixtures/lead-*.md` covering: valid file, missing Policies section, extra frontmatter key, wrong section order, renamed skill.

### 4. PR-open layer

1. After validation passes, the workflow stages: the edited `plugins/standards/skills/leading-*/SKILL.md` files, the new `state.json` (now carrying the freshly-fetched hash and the run timestamp), and nothing else.
2. Commit using `git -c user.name="github-actions[bot]" -c user.email="41898282+github-actions[bot]@users.noreply.github.com"`, message:
   ```
   Sync standards from qmu.co.jp/design

   Description: <one-paragraph summary the agent produced>

   Changes: <bulleted user-visible diffs>

   Test Planning: validate-lead-schema.mjs passed on all 4 files; audit log attached.

   Release Preparation: None -- documentation change, no behavior change.

   Co-Authored-By: TAMURA Yoshiya <a@qmu.jp>
   ```
3. Create branch `standards-sync/<YYYYMMDD-HHmmss>` and push.
4. `gh pr create` with title `Sync standards from qmu.co.jp/design (<short-version-marker>)` and a body containing: (a) plain-language summary of what changed at qmu.co.jp, (b) per-lens section with source URL + before/after diff (markdown code blocks, not raw HTML), (c) the validator verdict, (d) a numbered reviewer checklist (per `plugins/work/rules/general.md` heading conventions), (e) link to the audit-log artifact.
5. If a PR already exists for the same `last_seen_content_hash` (search via `gh pr list --search "in:title <hash-prefix>"`), update it in place rather than opening a duplicate.

### 5. Workflow wiring

1. Add `.github/workflows/standards-sync.yml`:
   ```yaml
   name: Standards Sync
   on:
     schedule:
       - cron: '0 * * * *'    # hourly; see Considerations re: cadence
     workflow_dispatch:
   permissions:
     contents: write
     pull-requests: write
   concurrency:
     group: standards-sync
     cancel-in-progress: false
   jobs:
     sync:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - uses: actions/setup-node@v4
           with: { node-version: '20' }
         - run: npm ci
         - run: bash scripts/standards-sync/fetch-design-page.sh runtime/standards-sync/snapshot
           continue-on-error: true
         - id: changed
           run: bash scripts/standards-sync/check-changed.sh
           continue-on-error: true
         - if: steps.changed.outputs.changed == 'true'
           run: node scripts/standards-sync/run-agent.mjs
           env: { ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }} }
         - if: steps.changed.outputs.changed == 'true'
           run: node scripts/standards-sync/validate-lead-schema.mjs
         - if: steps.changed.outputs.changed == 'true'
           run: bash scripts/standards-sync/open-pr.sh
           env: { GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }} }
         - if: always()
           uses: actions/upload-artifact@v4
           with: { name: standards-sync-audit, path: runtime/standards-sync/ }
   ```
   (Final shape may differ — extract any multi-line shell logic into scripts per the project's shell rule.)
2. Add `.gitignore` entries for `runtime/standards-sync/snapshot*/` (transient fetch output) and `node_modules/`. Do NOT ignore `scripts/standards-sync/state.json` — that one is committed.
3. Add `package-lock.json` (generated by `npm install`) so `npm ci` is reproducible.

### 6. Documentation and operator handoff

1. Add a Standards Sync section to `CLAUDE.md` under Architecture Policy: name the workflow, the four-layer pipeline, the allowlist, and the bot identity. State that the bot opens PRs and never pushes to main.
2. Add a one-paragraph note in [plugins/standards/skills/leading-availability/SKILL.md](plugins/standards/skills/leading-availability/SKILL.md) acknowledging that this workflow itself is an instance of the Vendor Neutrality and Deliberate Dependency Coupling policies it enforces, with the exit strategy summarized. (Manual edit landed by this ticket; *not* by the bot.)
3. Write `scripts/standards-sync/README.md` covering: what the pipeline does, how to dry-run locally (`ANTHROPIC_API_KEY=… node scripts/standards-sync/run-agent.mjs --dry-run --input runtime/standards-sync/snapshot/`), how to disable the cron (toggle the workflow off via the Actions UI; the file stays in the repo as record), and the exit strategy.
4. Operator handoff item (cannot be automated by this ticket): the repo admin must add `ANTHROPIC_API_KEY` as a GitHub Actions secret before the first scheduled run. Document this in the README and call it out in the PR description when this ticket is implemented.

## Considerations

- **Cloudflare bot challenge on qmu.co.jp.** Verified during ticket research: `WebFetch https://qmu.co.jp/design` returns HTTP 403, but `curl -A "Mozilla/5.0 ..."` returns HTTP 200. The Agent SDK's built-in `WebFetch` will be blocked by the same Cloudflare rule. That is why this design fetches via a `curl`-based wrapper script *outside* the agent and hands the HTML to the agent as a Read-able file. Do **not** enable `WebFetch` in `allowedTools`. Alternative if curl spoofing later fails: switch the fetch step to Playwright MCP (per `https://code.claude.com/docs/en/agent-sdk/overview` MCP tab), accepting the heavier dependency.
- **Threat model.** Risks to name in the implementation and the workflow's README, per `leading-security`'s ISMS policy: (1) prompt injection from qmu.co.jp HTML — mitigated by `PreToolUse` hook restricting edit targets, schema validator post-run, and human PR review; (2) SDK supply-chain compromise — mitigated by pinned version, exit strategy, npm audit in CI; (3) secret exfiltration — `ANTHROPIC_API_KEY` is only present as an env var on the `run-agent.mjs` step; `set -x` is disabled; the audit log redacts `Authorization` headers if any are logged; (4) bot writes outside allowlist — defense-in-depth via the hook + the validator + the diff allowlist check in `open-pr.sh`.
- **Hourly cadence is the starting point, not the steady state.** Per `leading-availability`'s "Lean Capacity Planning", observe how often qmu.co.jp actually changes and downshift (probably to `0 */6 * * *` or daily) once the baseline is known. The workflow's `cron` is one line to change.
- **Idempotency.** A run where `check-changed.sh` says "unchanged" exits 0 with a step summary and produces no commit, no PR, no API call to Anthropic. This is the common case and must stay free.
- **Bot identity.** Per the `validate-ticket.sh` history, the bot must commit as `github-actions[bot]` with a `Co-Authored-By: TAMURA Yoshiya <a@qmu.jp>` line — never as `@anthropic.com`. Test this explicitly during dry-run.
- **Do not bump versions.** Per CLAUDE.md, version bumps go through `/release`. The bot must not touch `version` fields in any `plugin.json` or `marketplace.json`.
- **dist/ regeneration is not required.** `scripts/build-plugins/build.mjs` line 33 sets `CORE_SKILLS = plugins/core/skills`; `plugins/standards/` is outside the closure. The bot's PR will pass `dist-freshness.yml` vacuously. Confirm this assumption holds during dry-run; if a future build change pulls standards into the closure, this ticket's PR-open step must also run `node scripts/build-plugins/build.mjs`.
- **Ubiquitous language.** The repo says "leading-*" skills, not "lenses" / "pillars" / "disciplines". Keep that vocabulary in any new prose this ticket adds (workflow file, README, PR body).
- **Tone preservation.** The four `leading-*/SKILL.md` files carry a hand-tuned "humble trade-off-acknowledging tone" (commit `86a048c`). The agent's prompt must include this constraint explicitly; the human reviewer enforces it via PR review.
- **No splitting into sub-tickets.** The four layers (state/fetch, agent, validator, PR-open) and the workflow file are artifact-coupled — the workflow can't run without all four scripts, and each script is hard to test in isolation without the others' fixtures. Implement as one ticket; the Implementation Steps decompose the work in build order. If implementation reveals a layer is genuinely independent (e.g., the schema validator turns out to be useful as a pre-commit hook for human edits too), split it out then.
- **Open questions deferred to /drive.** Two design decisions I made with defaults rather than asking up-front: the change signal is content hash (not an explicit version string on the page — qmu.co.jp doesn't appear to render one), and the update scope is the four `leading-*` files only. If you want a different change signal (e.g., an explicit `<meta name="version">` once you add one to the page) or a wider edit allowlist, update this ticket before `/drive` picks it up.
