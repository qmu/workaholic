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

Reflect the qmu.co.jp design-system policy into this repository's `plugins/standards/skills/leading-*/SKILL.md` automatically, while keeping all secrets and all agent execution out of this public repository. A separate, **private** controller repository (`qmu/workaholic-standards-sync`) runs an hourly cron that polls `https://qmu.co.jp/design`, detects content changes against the last-seen hash, invokes the Claude Agent SDK in headless mode, validates the resulting edits against the lead-skill schema, and opens a draft pull request against this public repository via a narrowly-scoped GitHub App. This public repository carries no `ANTHROPIC_API_KEY`, no GitHub Actions secret consumed by the bot, and no scheduled workflow — only the resulting bot PR shows up here, and it is reviewed and merged by a human like any other contribution.

The architecture is shaped by a specific threat: putting an Anthropic API key in a public repository's Actions secrets creates a standing credential-exfiltration target that survives the workflow's own defenses. A workflow-file PR, a compromised maintainer account, or an `@anthropic-ai/claude-agent-sdk` supply-chain compromise would all reach the key. Moving the secret and the executor into a controller repository with no external contributors collapses that attack surface. The residual risks — semantic prompt injection from qmu.co.jp HTML, controller compromise, third-party Action compromise — are bounded by deterministic guardrails (path allowlist, schema validator, draft PRs, CODEOWNERS, SHA-pinned Actions) and by human review of every PR.

## Key Files

### Targets the agent is allowed to edit (in the public repo's working tree on the controller)
- [plugins/standards/skills/leading-accessibility/SKILL.md](plugins/standards/skills/leading-accessibility/SKILL.md) - 52 lines.
- [plugins/standards/skills/leading-availability/SKILL.md](plugins/standards/skills/leading-availability/SKILL.md) - 57 lines; contains the `Deliberate Dependency Coupling` policy this very ticket must satisfy.
- [plugins/standards/skills/leading-security/SKILL.md](plugins/standards/skills/leading-security/SKILL.md) - 37 lines (shortest, most skeletal).
- [plugins/standards/skills/leading-validity/SKILL.md](plugins/standards/skills/leading-validity/SKILL.md) - 84 lines (use as the structural template).

The agent must edit only these four paths. Any change outside the allowlist is a validator failure that aborts the PR-open step.

### Schema contract this repository owns
- [.claude/rules/define-lead.md](.claude/rules/define-lead.md) - Required sections, frontmatter shape, four-tier order. The controller's post-edit validator runs against this checklist, so it must read the file from the cloned repo at run time rather than carrying a stale copy.

### New files in this repository (the only changes to land here directly from this ticket)
- `.github/CODEOWNERS` - Requires reviewer approval for any PR touching `plugins/standards/skills/leading-*/SKILL.md`. Applies to the bot's PRs and to human PRs equally. Branch protection on `main` already requires reviews; this scopes the requirement to the maintainers for these four files specifically.
- `CLAUDE.md` - Add a short Standards Sync section under Architecture Policy: name the controller repo, point at its operator README, and state that this public repo carries no secrets for the sync flow.
- Repo setting (manual, not a file): set the default `GITHUB_TOKEN` permissions to `read-all` in repo Settings → Actions → General → Workflow permissions. Every existing workflow that needs writes (release.yml uses `contents: write`) declares it explicitly at job scope — verified during research, no regression.

### New files in the controller repo (`qmu/workaholic-standards-sync`)
This repository creates a sibling private repo; the implementation steps below scaffold it. Files there:
- `.github/workflows/sync.yml` - The hourly cron. `permissions: read-all` at workflow scope. No `pull_request` or `pull_request_target` triggers. Every third-party Action pinned to a full commit SHA. Concurrency-grouped.
- `package.json` + `package-lock.json` - Pins `@anthropic-ai/claude-agent-sdk`, `@octokit/auth-app`, and `@octokit/rest` to exact versions.
- `src/fetch-design.mjs` - Fetches `https://qmu.co.jp/design` with a real browser User-Agent (Cloudflare blocks the SDK's built-in `WebFetch` — verified during research; `curl -A "Mozilla/5.0 ..."` returns 200, default UA returns 403). Writes raw HTML and SHA-256 to `runtime/snapshot/`.
- `src/check-changed.mjs` - Reads `state/qmu-design-snapshot.json`, compares hash to the freshly-fetched value, emits `changed=true|false` as a `$GITHUB_OUTPUT`. Gates the agent step so the SDK is only paid for when there is actual work.
- `src/run-agent.mjs` - Imports `query` from `@anthropic-ai/claude-agent-sdk`. Configures `allowedTools: ["Read", "Edit", "Glob", "Grep"]` (no `Write`, `Bash`, or `WebFetch`), `permissionMode: "acceptEdits"`, `cwd` rooted at the cloned `workaholic` repo, a `PreToolUse` hook that rejects any edit outside the four `leading-*/SKILL.md` paths, a `PostToolUse` hook that appends each edit to a per-run audit log, and `settingSources: []` so the agent loads no `.claude/` configuration from the target repo.
- `src/validate-lead-schema.mjs` - Pure typed function. Asserts each edited file conforms to `.claude/rules/define-lead.md` (frontmatter keys, section order, required H3s under `## Role`). Exits non-zero on any failure.
- `src/open-pr.mjs` - Authenticates as the GitHub App via `@octokit/auth-app`, mints an installation token (1-hour, repo-scoped, no `workflows:write`), creates a branch on `qmu/workaholic`, commits with the bot's identity, opens a **draft** PR via the REST API. PR body includes: upstream URL, content hash before and after, SDK version, model version, validator verdict, the upstream HTML diff rendered as a markdown code block, and a numbered reviewer checklist.
- `state/qmu-design-snapshot.json` - Committed marker file. Shape: `{ "url", "last_seen_content_hash", "last_checked_at", "last_pr_url", "last_pr_branch" }`. Updated only after the bot PR is successfully opened — same commit in the controller repo, so an unchanged run produces zero git noise.
- `README.md` - Operator doc: GitHub App setup steps, secret list, how to disable the cron, dry-run instructions, the documented exit strategy ("replace SDK with ~80 lines of `@anthropic-ai/sdk` Messages API plus the schema validator").
- `test/fixtures/qmu-design-*.html` + `test/test-*.mjs` - Hermetic tests for fetch (against a local Python `http.server`), validator (against good and intentionally-broken fixture SKILL.md files), and the PR-body renderer.
- `.github/dependabot.yml` - Weekly bumps for the npm deps and the pinned Action SHAs.

### Reference patterns (this repo) the controller borrows from
- [.github/workflows/release.yml](.github/workflows/release.yml) - `GITHUB_TOKEN` + `gh` CLI plumbing pattern.
- [plugins/core/hooks/validate-ticket.sh](plugins/core/hooks/validate-ticket.sh) - Rejects `@anthropic.com` authors. The bot must commit as `github-actions[bot]` with `Co-Authored-By: TAMURA Yoshiya <a@qmu.jp>`, never the SDK default.
- [scripts/build-plugins/build.mjs](scripts/build-plugins/build.mjs) line 33 - `CORE_SKILLS = plugins/core/skills`. Standards is outside the dist closure, so standards-only PRs need no `dist/` regen and pass `dist-freshness.yml` vacuously. Verify during dry-run.

## Related History

The architectural pivot was driven by a security-review pass that surfaced the credential-exfiltration risk of holding `ANTHROPIC_API_KEY` in a public repo. The history below covers the policy foundation, the existing automation patterns the controller borrows from, and the constraints any auto-PR bot in this repo must satisfy.

- [.workaholic/tickets/archive/work-20260417-092936/20260509001216-wire-leads-into-work-flows.md](.workaholic/tickets/archive/work-20260417-092936/20260509001216-wire-leads-into-work-flows.md) - Establishes the four `leading-*` skills as the canonical policy surface.
- [.workaholic/tickets/archive/feat-20260131-125844/20260129123400-auto-release-on-merge.md](.workaholic/tickets/archive/feat-20260131-125844/20260129123400-auto-release-on-merge.md) - Only prior example in this repo of an Action that mutates the repo automatically; sets the `GITHUB_TOKEN` + `gh` precedent.
- [.workaholic/tickets/archive/drive-20260131-223656/20260201100737-reject-anthropic-email-in-ticket-author.md](.workaholic/tickets/archive/drive-20260131-223656/20260201100737-reject-anthropic-email-in-ticket-author.md) - The hard rule that bot commits cannot author as `@anthropic.com`. The controller must override the SDK's default attribution.
- [.workaholic/tickets/archive/work-20260518-235327/20260527142130-relocate-cross-agent-output-into-dist.md](.workaholic/tickets/archive/work-20260518-235327/20260527142130-relocate-cross-agent-output-into-dist.md) - Defines the dist freshness contract; verified during research that standards changes do not touch dist.
- Recent commit `c3796cc` (this branch) - Source-vs-generated split for skill prose. If a future qmu.co.jp policy ever asks for terminology changes, the bot edits source skills and the build rewrites public copies — same pattern still applies.
- External precedent for the controller pattern: `tj-actions/changed-files` (2025) and `reviewdog` (2024) supply-chain compromises — both motivate pinning third-party Actions to full SHAs and minimizing the surface where a malicious Action could read secrets.

## Implementation Steps

This ticket creates two repositories' worth of changes. The public-repo changes are small and land first; the controller repo is the bulk of the work and lands in its own commits over there.

### 1. Public-repo guardrails (lands here)

1. Add [.github/CODEOWNERS](.github/CODEOWNERS): `plugins/standards/skills/leading-* @qmu/maintainers` (or the appropriate human reviewer team / username). Without CODEOWNERS the bot's PRs could in principle be merged by anyone with write access; this scopes the four files to a named reviewer set.
2. Update `CLAUDE.md` with a Standards Sync section under Architecture Policy. State: the cron, the secret, and the agent run in `qmu/workaholic-standards-sync` (private); this repo only receives the resulting draft PRs; the four `leading-*/SKILL.md` files are CODEOWNED; the App has no `workflows:write` so it cannot edit `.github/` from here.
3. Operator step (cannot be coded by this ticket): set repo default `GITHUB_TOKEN` permissions to `read-all` (Settings → Actions → General). Verify existing workflows still pass — `release.yml` already declares `permissions: contents: write` at workflow scope, `validate-plugins.yml` and `dist-freshness.yml` need read-only and continue to work. Document the manual step in `CLAUDE.md`.
4. Operator step (cannot be coded by this ticket): enable branch protection on `main` requiring CODEOWNERS review and disallowing self-approval by the App's bot account.

### 2. GitHub App setup (one-time, manual operator work)

1. Create a GitHub App owned by the `qmu` org. Name: "Workaholic Standards Sync". Homepage: the controller repo URL.
2. Permissions:
   - Repository permissions → Contents: **Read & write**
   - Repository permissions → Pull requests: **Read & write**
   - Repository permissions → Metadata: **Read** (forced)
   - **Do not grant** Workflows, Actions, Administration, Secrets, or any organization permission.
3. Subscribe to no webhook events. The controller polls; it does not react to events.
4. Install the App on exactly two repos: `qmu/workaholic` (target) and `qmu/workaholic-standards-sync` (controller).
5. Generate a private key (`.pem` download). Store it as a secret on the controller repo only.
6. Record the App ID and the installation ID in the controller's README and as repo variables (not secrets) so the runner can resolve the installation at run time.

### 3. Controller repo scaffold

1. Create the private repo `qmu/workaholic-standards-sync`. Initialize with `main`, default-branch protection (required PR review for any human change), and a CODEOWNERS pointing at the same human reviewer set as the public repo.
2. Repo settings: default `GITHUB_TOKEN` permissions read-only, Dependabot enabled.
3. Repo secrets: `ANTHROPIC_API_KEY`, `STANDARDS_SYNC_APP_PRIVATE_KEY`. Repo variables: `STANDARDS_SYNC_APP_ID`, `STANDARDS_SYNC_INSTALLATION_ID`.
4. Initial `package.json` with exact-version pins for `@anthropic-ai/claude-agent-sdk`, `@octokit/auth-app`, `@octokit/rest`. Commit `package-lock.json` so `npm ci` is reproducible.
5. Pin every third-party Action in `.github/workflows/sync.yml` to a full commit SHA, not a tag — per the `tj-actions/changed-files` precedent. Add a comment line above each `uses:` with the human-readable version for review.

### 4. Fetch + change-detection layer

1. `src/fetch-design.mjs`: fetch `https://qmu.co.jp/design` with `User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 ...`. Retries 3x with exponential backoff (2s/8s/32s) on 5xx and network errors. Write `runtime/snapshot/design.html` and a `runtime/snapshot/design.sha256` file containing the hex SHA-256 of the HTML.
2. Exits 0 on transient failure with a stderr note; the workflow step uses `continue-on-error: true` so transient outages do not page anyone. The next-step gate naturally aborts the agent run.
3. `src/check-changed.mjs`: compare the freshly-computed hash against `state/qmu-design-snapshot.json#last_seen_content_hash`. Emit `echo "changed=true|false" >> $GITHUB_OUTPUT`.
4. Hermetic test (`test/test-fetch.mjs`): spin up a Python `http.server` on a random port serving `test/fixtures/qmu-design-baseline.html`. Assert fetch writes the right files and the right hash. Repeat with `qmu-design-changed.html` and assert `check-changed` emits `changed=true`.

### 5. Agent layer

1. `src/run-agent.mjs` skeleton (TypeScript shape; .mjs because the controller has no TS build):
   ```js
   import { query } from "@anthropic-ai/claude-agent-sdk";
   for await (const message of query({
     prompt: buildPrompt({ /* paths, current content, previous snapshot, new snapshot, schema contract */ }),
     options: {
       allowedTools: ["Read", "Edit", "Glob", "Grep"],
       permissionMode: "acceptEdits",
       cwd: process.env.WORKAHOLIC_CLONE_PATH,
       hooks: {
         PreToolUse: [{ matcher: "Edit|Write", hooks: [blockOutsideAllowlist] }],
         PostToolUse: [{ matcher: "Edit", hooks: [auditEdit] }]
       },
       settingSources: []
     }
   })) { /* stream to $GITHUB_STEP_SUMMARY */ }
   ```
2. `blockOutsideAllowlist` rejects any `tool_input.file_path` not matching `^plugins/standards/skills/leading-(accessibility|availability|security|validity)/SKILL\.md$`. The schema validator below is the redundant second layer (defense in depth).
3. `auditEdit` appends `{timestamp, file_path, old_string, new_string}` to `runtime/audit-<run-id>.log`. Uploaded as a workflow artifact.
4. The prompt instructs the agent to: read the four files, read the previous and new snapshots (which are pre-fetched and Read-able files, no `WebFetch` in `allowedTools`), produce minimal diffs preserving the "humble trade-off-acknowledging tone" established in commit `86a048c`, place new content in the correct tier (Policies vs Practices vs Standards per `.claude/rules/define-lead.md`), do not modify frontmatter, do not bump versions.
5. Before invoking, the workflow clones `qmu/workaholic` to a scratch path using the App installation token. `WORKAHOLIC_CLONE_PATH` is the clone root; `cwd` for the agent is that path so it cannot navigate outside.

### 6. Validator layer

1. `src/validate-lead-schema.mjs` exports `validateLeadFile(path) → { ok, errors[] }`. Checks frontmatter keys (`name`, `description`, `user-invocable` only), `name` matches filename, top-level sections appear in the documented order, `## Role` carries the two required H3s.
2. On any failure, the workflow uses the App token to open a GitHub Issue on the controller repo (not the public repo) with the failure summary and the audit log linked. The public repo never sees a broken PR.
3. Hermetic tests (`test/test-validator.mjs`) cover valid, missing-Policies, extra-frontmatter-key, wrong-section-order, and renamed-skill fixtures.

### 7. PR-open layer

1. `src/open-pr.mjs` authenticates as the App via `@octokit/auth-app`, mints an installation token, and uses the Git REST API to:
   - Create branch `standards-sync/<YYYYMMDD-HHmmss>-<hash-prefix>` on `qmu/workaholic`
   - Commit the edited `leading-*/SKILL.md` files with author `github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com>` and `Co-Authored-By: TAMURA Yoshiya <a@qmu.jp>`
   - Open a **draft** PR with title `Sync standards from qmu.co.jp/design (<hash-prefix>)`
2. PR body sections (numbered H2s per `plugins/work/rules/general.md`):
   1. Summary: plain-language description of what changed at qmu.co.jp
   2. Provenance: upstream URL, previous content hash, new content hash, fetched-at timestamp
   3. Agent run: SDK package version, model version, validator verdict, link to the audit-log artifact
   4. Upstream diff: raw HTML diff in a fenced code block (or rendered Markdown if the page is structured enough to extract) — so the reviewer can sanity-check "the edit is justified by what the site says"
   5. Affected files: per-file before/after diffs, markdown-linked to the file path
   6. Reviewer checklist (numbered): "the edits reflect a real qmu.co.jp change, not an agent invention"; "tone is humble and trade-off-acknowledging"; "no frontmatter changes"; "no version bumps"; "no edits outside the four leading-* files"
3. Dedupe: before opening, `gh pr list --search "in:title <hash-prefix>"` against the public repo. If a PR exists for the same hash, push to the existing branch and update the PR body instead of opening a duplicate.
4. Only on successful PR open, update `state/qmu-design-snapshot.json` in the controller repo and commit it (with the App identity) to the controller's `main`. Unchanged runs produce zero commits anywhere.

### 8. Workflow wiring

1. `.github/workflows/sync.yml` shape (final wording extracts multi-step shell to scripts per the project shell rule):
   - Trigger: `schedule: '0 * * * *'` + `workflow_dispatch`
   - `permissions: contents: read` at workflow scope (the App token, not `GITHUB_TOKEN`, is what writes to the public repo)
   - `concurrency: { group: standards-sync, cancel-in-progress: false }`
   - Steps: checkout controller → setup-node@v4 (SHA-pinned) → `npm ci` → mint App token → clone `qmu/workaholic` → fetch design page → check-changed gate → (if changed) run agent → validate → open PR → upload audit artifact
2. Step summary writes to `$GITHUB_STEP_SUMMARY` at every gate: fetched OK / changed=true|false / agent edits N files / validator verdict / PR URL or "no PR opened".
3. Optional: Slack webhook (controller secret) posts on PR open and on three consecutive failures.

### 9. Documentation and operator handoff

1. Write `qmu/workaholic-standards-sync/README.md` covering: pipeline overview, secret list, GitHub App permissions, how to dry-run locally (`ANTHROPIC_API_KEY=… node src/run-agent.mjs --dry-run --input runtime/snapshot/`), how to rotate the App key, how to disable the cron, the exit strategy.
2. Add a one-paragraph note in [plugins/standards/skills/leading-availability/SKILL.md](plugins/standards/skills/leading-availability/SKILL.md) acknowledging this controller-based design as an instance of the Vendor Neutrality and Deliberate Dependency Coupling policies the lens itself enforces. (Manual edit landed by this ticket, not by the bot.)
3. Update [CLAUDE.md](CLAUDE.md) per Step 1.2.

## Considerations

- **Cloudflare bot challenge on qmu.co.jp.** Verified during ticket research: SDK `WebFetch` returns 403, `curl -A "Mozilla/5.0 ..."` returns 200. Fetch happens outside the agent via the wrapper; the agent never receives `WebFetch` in `allowedTools`. If Cloudflare ever tightens UA-based whitelisting, switch the fetch step to Playwright MCP per the SDK docs at `https://code.claude.com/docs/en/agent-sdk/overview` (heavier dep, real-browser semantics).
- **Threat model.** Named in this ticket and in the controller's README per `leading-security`'s ISMS policy:
  - *Credential exfiltration of `ANTHROPIC_API_KEY` from a public-repo workflow change.* Mitigation: secret lives only on the private controller; public repo has no scheduled workflow.
  - *Semantic prompt injection from qmu.co.jp HTML.* Mitigation: PRs are draft; PR body surfaces the upstream diff so the reviewer can verify "site actually said this"; CODEOWNERS + branch protection means the App cannot merge its own PR.
  - *Third-party Action supply-chain compromise.* Mitigation: every `uses:` pinned to a full commit SHA, not a tag; Dependabot raises bumps.
  - *SDK supply-chain compromise.* Mitigation: exact version pinning + `package-lock.json`; documented exit strategy reducing the SDK to ~80 lines of `@anthropic-ai/sdk` Messages API.
  - *Controller-repo compromise.* The controller becomes the new trust boundary. Mitigations: private repo with required PR review, default `GITHUB_TOKEN` read-only, App key stored only as a controller secret, minimal collaborator set, MFA required on collaborator accounts.
- **No `workflows: write`.** The GitHub App must not have permission to modify `.github/workflows/` in either repo. A rogue agent cannot then escalate by editing CI.
- **Public-repo default token read-only.** Defense in depth — even if a future workflow is added here, its `GITHUB_TOKEN` cannot write by default. Workflows that need writes (release.yml) declare them at job scope explicitly.
- **CODEOWNERS scope.** Apply only to the four files the bot may touch. Avoid CODEOWNERS sprawl that would slow human contributions to unrelated paths.
- **Bot identity.** `github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com>` with `Co-Authored-By: TAMURA Yoshiya <a@qmu.jp>`. Never `@anthropic.com` (rejected by `plugins/core/hooks/validate-ticket.sh`).
- **Do not bump versions.** Per CLAUDE.md, version bumps go through `/release`. The bot must not touch any `version` field in `plugin.json` or `marketplace.json`.
- **dist/ regeneration is not required.** `scripts/build-plugins/build.mjs` line 33 confines the build closure to `plugins/core/skills/`. Standards-only PRs pass `dist-freshness.yml` vacuously. Validate during dry-run; if a future build change pulls standards into the closure, this ticket's open-PR step must also run `node scripts/build-plugins/build.mjs` against the clone.
- **Hourly cadence is the starting point.** Per `leading-availability`'s Lean Capacity Planning, observe how often qmu.co.jp actually changes and downshift to `0 */6 * * *` or daily once the baseline is known. One-line change in the controller's `sync.yml`.
- **Idempotency.** A run where `check-changed` says "unchanged" exits 0, writes a step summary, and produces no commit, no PR, no API call to Anthropic.
- **Ubiquitous language.** Use "leading-*" not "lenses" / "pillars" / "disciplines" in any new prose the controller emits (PR body, README, summaries).
- **Tone preservation.** The four `leading-*/SKILL.md` files carry a hand-tuned "humble trade-off-acknowledging tone" (commit `86a048c`). The agent's prompt must include this constraint; the reviewer enforces it.
- **One ticket, two repos.** The public-repo changes are small and can land in a single commit on this branch. The controller repo's scaffolding lands as commits there, owned by the same author. Mark both PRs cross-referenced in the body. This ticket's `commit_hash` field captures only the public-repo change; the controller setup is operator work tracked in the controller's own README.
- **Open question deferred to /drive.** Change signal is content hash because qmu.co.jp does not render an explicit version string today. If you add an explicit version marker (e.g., `<meta name="version">`) to the page first, switching the signal is a one-line change in `check-changed.mjs`. Implementation should leave that swappable.
