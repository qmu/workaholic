---
created_at: 2026-07-01T12:21:39+09:00
author: a@qmu.jp
type: enhancement
layer: [UX, Infrastructure]
effort: 4h
commit_hash: 2e5ef4f
category: Added
depends_on:
---

# Add /explain: answer a repo question and export a PDF report

## Overview

Add a Claude Code command `/explain` (thin command + comprehensive `workaholic:explain` skill) that answers a developer's question about the repository and exports the answer as a printer-ready **PDF report**. Invocation: `/explain "<question>" [destination-dir]`.

- **Arg 1 — question (mandatory):** the developer's question about the repo.
- **Arg 2 — destination directory (optional):** where to write the report. If omitted, the export path is resolved by priority **Desktop → Home**: use `$HOME/Desktop` when it exists, otherwise fall back to `$HOME`.
- **Home requires consent:** if the resolved (or explicit) target is the **Home directory**, `/explain` must ask the developer for permission **before** writing (a symmetric agree/decline prompt). Desktop (and an explicitly-passed destination) are written without a prompt.
- **PDF is browser-printed:** the report is generated as semantic HTML and printed to PDF by a **real browser process** driven over MCP — the Claude Code **Playwright plugin** (`mcp__plugin_playwright_playwright__*`) or the **Chrome DevTools MCP**, whichever the session exposes.

Backend flow: discover the repo facts that answer the question → render a printer-ready HTML report → resolve the export path → (Home) get consent → drive a browser to print the HTML to PDF at that path → report the written path.

**Two capabilities that are new to workaholic** (greenfield — no precedent in the repo): (a) rendering HTML and printing a PDF via a real browser, and (b) writing an artifact **outside** the repo (Desktop/Home). Every existing workaholic artifact lives under `.workaholic/`; the PDF is the first out-of-repo output. Discovery confirmed the plugin bundles **no** browser tooling and declares **no** MCP server (there is no `.mcp.json`), so the browser MCP is **session-provided** and must be treated as an external dependency `/explain` checks for — never bundled. This makes `/explain` **Claude-Code-only** (like `/trip`): its command is never built to `outputs/`, and its script-bearing skill is excluded from the cross-agent build.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional plugin layout: `commands/explain.md` + `skills/explain/SKILL.md` + `skills/explain/scripts/*.sh` (applies to all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — house style; bundled scripts are machine-checked by posix-lint (applies to all code work)
- `workaholic:implementation` / `policies/command-scripts.md` — all path resolution (explicit dest vs Desktop→Home, existence/writability, Home detection) and the MCP-capability check are consolidated into runnable bundled POSIX scripts invoked via `${CLAUDE_PLUGIN_ROOT}`; no inline conditional shell in markdown (Shell Script Principle)
- `workaholic:implementation` / `policies/objective-documentation.md` — the report states verifiable, source-cited answers derived from the actual repo (file paths, quoted evidence); unknowns are reported as unknown, no speculation or evaluative adjectives
- `workaholic:implementation` / `policies/vendor-neutrality.md` — isolate the Playwright / Chrome-DevTools-MCP call behind one boundary so vendor vocabulary does not leak into discovery or HTML generation
- `workaholic:implementation` / `policies/emergent-design-system.md` — the printer-ready HTML/print-CSS (page size, margins, heading scale) is a new rendering component; derive one coherent rule set deliberately and record the why
- `workaholic:design` / `policies/self-explanatory-ui.md` — the argument contract, the Home-permission prompt, and every outcome (resolved path, success, failure) are understandable without a manual; success prints the concrete PDF path, failures return actionable messages
- `workaholic:design` / `policies/interaction-design-standard.md` — define the loading/empty/error/success states of the long-running browser/PDF step consistently with other workaholic commands; report progress, don't leave the developer in silence
- `workaholic:design` / `policies/modeless-design.md` — one-shot invocation (question in, PDF out), not a stateful wizard; the Home prompt is the one justified focus point and offers a clear decline path
- `workaholic:design` / `policies/consent-recording.md` — the out-of-repo Home write requires explicit consent obtained BEFORE the write, asked at the command/main-agent level (never in a leaf subagent)
- `workaholic:design` / `policies/no-dark-patterns.md` — the Home prompt is a plain, symmetric agree/decline with no default-yes, no pre-selected consent, no nudging; declining is as easy as accepting
- `workaholic:design` / `policies/access-control.md` — resolve "which destination needs consent" in ONE authoritative place (the bundled resolver), not scattered across command prose
- `workaholic:planning` / `policies/accessibility-first.md` — generate the report from semantic HTML with proper heading hierarchy so the PDF is machine-readable and structurally sound

## Key Files

- `plugins/workaholic/commands/catch.md` - Closest command template: read-only repo Q&A, thin orchestration-only body, `skills:` frontmatter, `<!-- workaholic:policy-lens -->` sentinel, Notice + Plugin-boundary blocks. Copy this shape for `commands/explain.md`.
- `plugins/workaholic/commands/ticket.md` - Template for command-level `AskUserQuestion` with the `[<project label>]` prefix (from `project-label.sh`) and one-level fan-out (spawns `general-purpose` leaves in one message). Model for the Home-permission gate and the optional discovery fan-out.
- `plugins/workaholic/skills/catch/SKILL.md` - Comprehensive read-only-Q&A skill template: `allowed-tools: Bash` (+Read/Glob/Grep), `user-invocable: false`, `metadata.internal: true` (**required** — `/explain`'s skill bundles scripts), `skills:` preload (gather + 4 pillars), an Agent Compatibility section, a Run Workflow with gather → optional fan-out → synthesize. Mirror it for `skills/explain/SKILL.md`.
- `plugins/workaholic/skills/catch/scripts/scan-window.sh` - POSIX `#!/bin/sh -eu` JSON-emitting script pattern for `/explain`'s bundled scripts (the dest resolver + capability check).
- `plugins/workaholic/skills/discover/SKILL.md` - The source/history/policy discovery modes a fan-out can reuse to gather repo facts (escalation path — see Implementation Step 2).
- `plugins/workaholic/skills/gather/scripts/git-context.sh` and `project-label.sh` - Reuse for repo_url/branch and the `[project label]` prompt chip on the Home-permission `AskUserQuestion`.
- `plugins/workaholic/skills/ship/scripts/check-confirmation-capability.sh` - The plugin's only existing "browser capability" code — deliberately abstract (checks `CI` env, names no MCP). Precedent for `/explain`'s MCP-capability check script (does the session expose a browser MCP?), which is genuinely new.
- `plugins/workaholic/skills/system-safety/SKILL.md` - Governs out-of-repo writes. **Verdict from policy discovery:** writing a PDF to `~/Desktop` or `~/` is NOT a prohibited system operation (that list targets config/profiles/`/etc`/global installs/sudo). The export is permitted; the Home prompt is a consent gate, not a system-safety block.
- `plugins/workaholic/hooks/validate-ticket.sh` and `workaholic-layout-allowlist.txt` - The layout gate matches only `*.workaholic/*` paths, so a `~/Desktop/*.pdf` or `~/*.pdf` write is neither validated nor blocked by it — out-of-repo export is new territory but not hook-blocked. No allowlist change needed (the PDF is not under `.workaholic/`).
- `scripts/build-plugins/build.mjs` - `DEFAULT_TARGETS = ["create-ticket","drive","report","ship","catch"]`. **Do NOT add `explain`** — it depends on session-provided browser MCP and is Claude-only (like `/trip`). Commands are never built; the skill stays `metadata.internal: true`. No `outputs/` footprint.
- `scripts/test-workflow-scripts.mjs` - Where the resolver + capability-check smoke tests go (hermetic throwaway-repo, JSON/filesystem assertions, no network).
- `plugins/workaholic/rules/shell.md` - POSIX-sh mandate for the bundled scripts (`#!/bin/sh -eu`, no bashisms; posix-lint enforced).
- `.claude/settings.json` - Evidence the repo declares no MCP server (no `.mcp.json` anywhere); the browser MCP is session-provided.

## Related History

Greenfield — no PDF/HTML/browser/out-of-repo-export precedent anywhere in tickets, stories, or git history. `/catch` is the nearest neighbor (read-only repo Q&A) and the reuse template; `/report` writes an in-repo story + PR (different output, in-repo only).

Past tickets that touched similar areas:

- [20260630011811-add-catch-command.md](.workaholic/tickets/archive/work-20260630-011820/20260630011811-add-catch-command.md) - Introduced `/catch`, a read-only repo-reading command with thin command + skill + `general-purpose` fan-out — the architecture template
- [20260626124306-workaholic-layout-doctor-report.md](.workaholic/tickets/archive/work-20260626-124322/20260626124306-workaholic-layout-doctor-report.md) - Prior repo-inspection "report" command (text findings in-context; no HTML/PDF/browser) — pattern reference

Related recorded concern:

- `.workaholic/concerns/archive/48-confirmation-execution-depends-on-tooling-that.md` - Confirmation tooling may be absent in a session, forcing a graceful halt — the exact degrade-gracefully reasoning `/explain` applies to a missing browser MCP.

## Implementation Steps

1. **Thin command** `plugins/workaholic/commands/explain.md`: frontmatter `skills:` preloading `workaholic:explain` (+ `workaholic:gather`, the 4 policy pillars); the `<!-- workaholic:policy-lens -->` sentinel; Notice + Plugin-boundary blocks; orchestration-only body that parses arg 1 (question, required — error if missing) and optional arg 2 (dest dir), delegates to the skill's Run Workflow, and issues the Home-permission `AskUserQuestion` itself (one-level fan-out).
2. **Comprehensive skill** `plugins/workaholic/skills/explain/SKILL.md` (`allowed-tools: Bash, Read, Glob, Grep`; `user-invocable: false`; `metadata.internal: true`): document the Run Workflow — (a) gather git context; (b) **adaptive discovery**: the main agent answers the question **inline first** (grep/read/gather); **only when that is insufficient** for a broad question, escalate by fanning out `general-purpose` leaves that preload `workaholic:discover` (source/history/policy) and return JSON; (c) synthesize a sourced answer; (d) render the printer-ready HTML; (e) resolve path + consent; (f) browser-print to PDF; (g) report the path.
3. **Path-resolution script** `skills/explain/scripts/resolve-export-path.sh` (POSIX `#!/bin/sh -eu`): input = optional explicit dest; output JSON `{chosen_dir, is_home, needs_permission, exists, writable}`. Logic: explicit dest → honor it (no prompt); else `$HOME/Desktop` if it exists → else `$HOME` (`is_home:true`, `needs_permission:true`). Fail safe (clear blocker) if the chosen dir is not writable. All conditionals live here, never in markdown.
4. **MCP-capability check** `skills/explain/scripts/check-browser-capability.sh` (or a documented in-skill check): determine whether the session exposes a browser MCP; emit which backend is available (Playwright plugin vs Chrome DevTools MCP) or none.
5. **Vendor-neutral browser boundary**: document the single HTML→PDF step so either backend satisfies it — Playwright plugin: `browser_navigate` to the `file://` HTML then print via `page.pdf()` (through `browser_run_code_unsafe`, since the Playwright MCP has no direct pdf tool); Chrome DevTools MCP: navigate + native print-to-PDF. Pick whichever the capability check found.
6. **No-MCP halt**: when no browser MCP is available, **save the generated `.html`** to the resolved destination so the work isn't lost, then halt with an actionable message naming the two MCPs to enable and to re-run. Do not emit a broken/empty PDF.
7. **Home consent gate**: when `needs_permission` is true (or an explicit dest is Home), the command issues a `[project label]`-prefixed `AskUserQuestion` with a symmetric agree/decline before any write (no default-yes). Decline → stop without writing.
8. **Printer-ready HTML template**: semantic HTML with a print stylesheet (page size, margins, heading hierarchy) recorded as one coherent rule set; content is objective and source-cited.
9. **Claude-only wiring**: add `/explain` to the Commands table in `CLAUDE.md`; confirm it is NOT in `DEFAULT_TARGETS` and has no `outputs/` footprint.
10. **Smoke tests** in `scripts/test-workflow-scripts.mjs` for `resolve-export-path.sh` (explicit dest honored, Desktop chosen when present, Home fallback + `needs_permission` when Desktop absent, unwritable → blocker) and the capability check.

## Quality Gate

Developer-selected gate: **script tests + manual E2E**.

**Acceptance criteria:**

- `resolve-export-path.sh` is covered by hermetic smoke tests asserting: explicit dest is honored with `needs_permission:false`; `$HOME/Desktop` chosen when it exists (`is_home:false`, no prompt); fallback to `$HOME` when Desktop absent sets `is_home:true`/`needs_permission:true`; an unwritable target returns a fail-safe blocker.
- The MCP-capability check is exercised (reports the available backend, or none).
- `posix-lint.sh` reports **0 findings** for the new scripts; they are `#!/bin/sh -eu` POSIX (no bashisms).
- **Manual E2E**: running `/explain "<question>"` with no dest produces a real, printer-ready **PDF on the Desktop**; running it so the target resolves to Home shows the symmetric permission prompt and only writes on accept; a session with no browser MCP halts with the guidance message and saves the `.html`.
- The report content is **objective and source-cited** (names files/paths it drew from; unknowns marked unknown) — a spot-read confirms no speculation.
- `/explain` adds **no `outputs/` footprint** (build unchanged); the skill carries `metadata.internal: true`.

**Verification method:**

- `node scripts/test-workflow-scripts.mjs` green including the new resolver/capability assertions; `sh plugins/workaholic/hooks/posix-lint.sh` 0 findings; `node scripts/build-plugins/build.mjs` leaves `outputs/` unchanged and `verify.mjs` stays green.
- Manual runs: (1) default → PDF on Desktop; (2) Home-resolving → prompt shown + gated; (3) no-MCP → HTML saved + halt message; each observed directly.

**Gate:** the resolver/capability smoke tests + posix-lint are green, `outputs/` is untouched by the addition, AND the three manual runs (Desktop PDF, Home prompt, no-MCP halt) behave as specified with a spot-read confirming the report is sourced/objective.

## Considerations

- **Browser MCP is session-provided, not bundled.** `/explain` cannot guarantee Playwright or Chrome DevTools MCP is present; the capability check + graceful halt (Step 6) are load-bearing, not optional (`.claude/settings.json` shows no `.mcp.json`; concern #48 is the precedent).
- **Playwright MCP has no direct PDF tool.** Printing via Playwright requires `page.pdf()` through `browser_run_code_unsafe`; Chrome DevTools MCP prints natively. The vendor-neutral boundary must accommodate both call shapes (`skills/explain/scripts/` + skill prose).
- **First out-of-repo artifact.** The PDF lands outside `.workaholic/`, outside every existing allowlist/hook. Keep the write confined to the resolved user-document dir; the resolver must never touch config/profile paths or escalate privilege (system-safety).
- **Consent must precede the write.** The Home prompt is asked before rendering-to-disk-at-Home, at command level (leaf subagents can't prompt); symmetric agree/decline, no default-yes (`consent-recording`, `no-dark-patterns`).
- **Desktop may not exist** (e.g. a headless Linux box has no `~/Desktop`) — the resolver's fallback to Home (which then prompts) handles this; the smoke test must cover it.
- **Report objectivity.** The answer is technical documentation subject to "verifiable against the code": cite file paths, quote evidence, mark unknowns as unknown (`objective-documentation`).

## Final Report

Development completed as planned, with one scope refinement. Built `commands/explain.md` (thin, mandatory-question + optional-dest, Home-consent gate at command level), `skills/explain/SKILL.md` (`metadata.internal: true`, numbered headings, adaptive discovery → printer-ready HTML template with `@page` print CSS → path resolution → consent → vendor-neutral browser print → no-MCP halt), and `skills/explain/scripts/resolve-export-path.sh` (POSIX; `{chosen_dir, is_home, needs_permission, exists, writable}`). Added `/explain` to the CLAUDE.md Commands table + structure listings and a 12-assertion resolver smoke test. Verified Claude-only: no `explain` in `outputs/` (not in `DEFAULT_TARGETS`), skill internal, command unbuilt. Suite 260 passed / 0 failed; posix-lint 0; build/verify/metadata in lockstep.

**Scope refinement — the browser-MCP capability check is model-level, not a shell script.** Implementation Step 4 offered "check-browser-capability.sh (or a documented in-skill check)"; the shell-script form is not viable because a shell cannot see the session's MCP tool surface (MCP tools are exposed to the model, not the shell), so the check is documented in the skill as the agent inspecting its own available tools. This is the ticket's sanctioned alternative. The consequence is that the gate item "capability-check tested" is covered by the manual no-MCP E2E rather than a unit test; the one bundled script (`resolve-export-path.sh`) received the full smoke suite instead.

The remaining criteria are the agreed manual E2E: (1) `/explain "<q>"` with no dest → a real printer-ready PDF on the Desktop; (2) a Home-resolving target → the symmetric permission prompt, writing only on accept; (3) a session with no browser MCP → halt with guidance and the saved `.html`.

### Discovered Insights

- **Insight**: A bundled shell script cannot detect which browser MCP (Playwright plugin vs Chrome DevTools) — or whether any — is available, because MCP tools are part of the model's tool surface, not the shell environment. Capability detection for MCP-backed features is inherently model-level; a shell "capability check" can only probe OS-level signals (a browser binary on PATH), which is not the same gate.
  **Context**: Future workaholic features that depend on session-provided MCP tools (like `/explain`'s browser, or a future data-source MCP) must document a model-level tool-availability check and a graceful halt, and cannot rely on a shell probe or a bundled `.mcp.json` — the plugin declares none.
- **Insight**: `/explain` is the first workaholic feature to write an artifact outside `.workaholic/`. The `validate-ticket.sh` layout hook matches only `*.workaholic/*` paths, so a `~/Desktop/*.pdf` write is neither validated nor blocked — the out-of-repo export sits entirely outside the plugin's artifact-confinement machinery by construction, which is why the consent gate + resolver's fail-safe writability check are the only guardrails and had to be built deliberately.
  **Context**: The consent is UX/design (Home prompt), not a system-safety block — writing to user-document dirs is permitted; only config/profile/privilege paths are prohibited. The resolver centralizes "which destination needs consent" so that rule lives in one place (`access-control`).
