---
name: explain
description: Answer a developer's question about the repository from verifiable evidence, render it as a printer-ready HTML report, and print it to PDF with a real browser (Playwright plugin or Chrome DevTools MCP), exporting to a given directory or the Desktop-then-Home default.
allowed-tools: Bash, Read, Glob, Grep, Write
user-invocable: false
skills:
  - workaholic:gather
  - workaholic:discover
  - workaholic:planning
  - workaholic:design
  - workaholic:implementation
  - workaholic:operation
metadata:
  internal: true
---

# Explain

Answer a developer's question about the repository and export the answer as a printer-ready PDF report: the answer is generated as semantic HTML and printed to PDF by a real browser process driven over MCP, landing in an explicit destination directory or, by default, the Desktop (falling back to Home). The answer is technical documentation — verifiable, source-cited, free of speculation.

It is a formal business document, submitted to clients and circulated among colleagues, so every report follows the company house style: monochrome, no decoration (normal weight throughout, headings included; no rules, borders, boxes, or underlines), numbered hierarchical headings, prose as the primary unit, self-explaining (define before use), comfort through consistent spacing rather than ornament. §4 states the rules; the full HTML skeleton is [reference/html-template.md](reference/html-template.md).

## 1. Agent Compatibility

`/explain` depends on a session-provided browser MCP — the Claude Code Playwright plugin (`mcp__plugin_playwright_playwright__*`) or the Chrome DevTools MCP — which this skill checks for at runtime and never bundles. It is therefore Claude-Code-only: `metadata.internal: true`, excluded from the cross-agent `outputs/` build, its command never built. The one `AskUserQuestion` (the Home-directory consent gate) is issued by the command at main-agent level; discovery fan-out uses non-interactive `general-purpose` leaves.

## 2. Run Workflow

The `/explain` command (main agent) runs this workflow directly.

### 2-1. Policy Lens (read first)

The report is subject to `workaholic:implementation` / `objective-documentation`: verifiable, source-cited answers; unknowns reported as unknown; no evaluative adjectives. Outcomes are self-explanatory (`workaholic:design` / `self-explanatory-ui`): success prints the concrete PDF path, a failure an actionable message. The Home write is consent-gated with a plain, symmetric agree/decline and no default-yes (`consent-recording`, `no-dark-patterns`). Isolate the browser call behind one boundary so vendor vocabulary does not leak into discovery or HTML generation (`vendor-neutrality`).

### 2-2. Phase 0: Parse Arguments

`$ARGUMENTS` is `"<question>" [destination-dir]`. The question is mandatory — if absent, print the usage `/explain "<question>" [destination-dir]` and stop; the destination is optional. Gather repo context once for the report header:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/git-context.sh
```

### 2-3. Phase 1: Discover the Answer (adaptive)

Answer from the actual repository, inline first: read and grep the relevant files, the ticket/story/doc trail, and git context. Escalate to a fan-out only when the inline pass is insufficient for a broad question — `general-purpose` leaves (single message) preloading `workaholic:discover`, running its `source` / `history` / `policy` modes and returning JSON; then synthesize. Every claim names the file, path, or commit it rests on.

### 2-4. Phase 2: Render the HTML Report

Write a printer-ready HTML file (skeleton: [reference/html-template.md](reference/html-template.md)) to `.explain/<slug>.html`, **inside this repository** (git-ignored; create the directory if absent). Use semantic HTML with a proper heading hierarchy (`workaholic:planning` / `accessibility-first`); the body carries the question, the sourced answer, and an evidence list of the paths consulted. Write it to the house style (§4), not a bare Q&A dump: open with a paragraph stating the purpose and the conclusion, develop in numbered sections of connected prose, define every term before use; for a Japanese report, natural business Japanese.

Caveat — the staging path is in-repo on purpose; never write the HTML to `chosen_dir`: `hooks/guard-repo-confinement.sh` (blocking `PreToolUse(Write|Edit)`) refuses every `Write` outside this repository, and it cannot exempt a caller — a `PreToolUse` hook sees only `tool_input.file_path`, never which skill is asking, so an `.html` bound for Home is indistinguishable from any other write there. The export is unaffected: only the staging file is in-repo, and the **browser** writes the PDF to `<chosen_dir>/<slug>.pdf` over MCP — not a `Write` tool call, so the gate never sees it and confinement stays absolute on the tool surface it governs.

### 2-5. Phase 3: Resolve Path + Consent

All destination logic lives in the script — never inline:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/explain/scripts/resolve-export-path.sh "<dest-dir-or-empty>"
```

It returns `{ chosen_dir, is_home, needs_permission, exists, writable }`. If `writable` is `false` (or `exists` is `false` and it cannot be created), halt with an actionable blocker naming `chosen_dir`. If `needs_permission` is `true` (the destination is Home), the command issues a `[project label]`-prefixed `AskUserQuestion` with symmetric agree/decline before any write (e.g. "Write to Home" / "Cancel", no default-yes); on decline, stop without writing. Otherwise proceed without a prompt. The final PDF path is `<chosen_dir>/<slug>.pdf`.

### 2-6. Phase 4: Print to PDF (vendor-neutral)

A shell script cannot see MCP tools, so inspect your available tools for a browser backend and drive whichever is present — the same one step either way: open the HTML `file://` URL, print to PDF at the resolved path.

- Playwright plugin: `browser_navigate` to `file://<abs-html-path>`, then `browser_run_code_unsafe` running `await page.pdf({ path: '<pdf-path>', format: 'A4', printBackground: true })` (the Playwright MCP exposes no direct pdf tool; the page-context call is the boundary).
- Chrome DevTools MCP: navigate to the `file://` URL, then its native print-to-PDF.

No browser MCP available → halt with guidance; never emit a broken or empty PDF. The `.html` already sits at `.explain/<slug>.html`, so the work is not lost — name that path and tell the developer to enable the Playwright plugin or the Chrome DevTools MCP and re-run. Do not copy it to `chosen_dir`: that write is refused by the confinement gate (§2-4), and re-running with a browser present produces the PDF there anyway.

### 2-7. Phase 5: Report

Print the concrete outcome — the written PDF path; or, on the no-MCP halt, the in-repo `.explain/<slug>.html` path plus the enable-a-browser-MCP instruction; or the unwritable-destination blocker — and name the primary files the answer drew from so the developer can verify it.

## 3. HTML Report Template (printer-ready, house style)

The full self-contained skeleton is [reference/html-template.md](reference/html-template.md): no external assets, CSS-counter-numbered headings (`1.` / `1-1.` / `1-1-1.`), one spacing unit `--u` with every gap a multiple of it, a comfortable ~40-character measure, the document title separate and unnumbered. Fill the bracketed slots; do not add colour, weight, or dividers — the calm read is the design.

## 4. Writing & House-Style Guidelines

Hold every report to these:

- Monochrome, no decoration: black on white, no colour anywhere; normal font weight throughout, headings included — never bold, boxed, ruled, or underlined. The only non-black tone is a restrained grey for de-emphasised metadata (a shade, not a hue).
- Comfort through spacing, not ornament: one spacing unit, every gap a consistent multiple, generous line-height; keep the rhythm uniform.
- Numbered headings, done by the template's CSS counters.
- Prose first; lists are supportive only, never the primary structure of a section.
- Self-explaining; define before use: introduce each concept in prose where it first appears; a glossary at the end is a last resort, never a substitute for explaining in the body.
- Natural business Japanese (for Japanese reports): each word in its normal form — kanji where the word is normally written in kanji (普段, never ふだん); no casual phrasing or question-form titles; title with a noun phrase (「Workaholic 概要」, not「Workaholicって何？」).
- Objective and source-cited; consent before the Home write; never guess the browser — check available tools, and on absence halt with guidance and the saved `.html`; always end by printing the concrete path or blocker; only ever write to the resolved user-document directory — never config/profile paths, no privilege escalation (system-safety).
