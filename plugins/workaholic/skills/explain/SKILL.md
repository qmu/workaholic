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

Answer a developer's question about the repository and export the answer as a **printer-ready PDF report**. The report is generated as semantic HTML and printed to PDF by a **real browser process** driven over MCP, then written to an explicit destination directory or, by default, to the Desktop (falling back to Home). The answer is technical documentation: verifiable, source-cited, and free of speculation.

## 1. Agent Compatibility

`/explain` depends on a **session-provided browser MCP** — the Claude Code **Playwright plugin** (`mcp__plugin_playwright_playwright__*`) or the **Chrome DevTools MCP**. The workaholic plugin bundles no browser tooling and declares no MCP server, so the browser is an external dependency this skill *checks for* at runtime and never bundles. Because of that dependency it is **Claude-Code-only** (like `/trip`): the script-bearing skill carries `metadata.internal: true`, is excluded from the cross-agent `outputs/` build, and its command is never built. The one `AskUserQuestion` (the Home-directory consent gate) is issued by the command at the main-agent level; any discovery fan-out uses non-interactive `general-purpose` leaves.

## 2. Run Workflow

The `/explain` command (main agent) runs this workflow directly: it reads/greps the repo, optionally fans out discovery leaves, writes the HTML, runs the bundled resolver script, issues the consent prompt itself, and drives the browser MCP.

### 2-1. Policy Lens (read first)

The report is technical documentation subject to `workaholic:implementation` / `objective-documentation`: state verifiable, source-cited answers (name the files and quote the evidence the answer rests on); report unknowns as unknown; avoid evaluative adjectives. Every outcome must be understandable without a manual (`workaholic:design` / `self-explanatory-ui`): success prints the concrete PDF path, failures return an actionable message. The Home write is consent-gated with a plain, symmetric agree/decline and no default-yes (`workaholic:design` / `consent-recording`, `no-dark-patterns`). Isolate the browser call behind one boundary so vendor vocabulary does not leak into discovery or HTML generation (`workaholic:implementation` / `vendor-neutrality`).

### 2-2. Phase 0: Parse Arguments

`$ARGUMENTS` is `"<question>" [destination-dir]`. The **question is mandatory** — if absent, print the usage `/explain "<question>" [destination-dir]` and stop. The **destination directory is optional**. Gather repo context once for the report header:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/git-context.sh
```

### 2-3. Phase 1: Discover the Answer (adaptive)

Answer the question from the actual repository, **inline first**: read and grep the relevant files, ticket/story/doc trail, and git context. Escalate to a fan-out **only when the inline pass is insufficient** for a broad question — spawn `general-purpose` leaves (single message) that preload `workaholic:discover` and run its `source` / `history` / `policy` modes, returning JSON; then synthesize. Keep the answer factual and traceable: every claim names the file, path, or commit it rests on; unknowns are stated as unknown, not guessed.

### 2-4. Phase 2: Render the HTML Report

Write a **printer-ready HTML file** (see the **HTML Report Template**, section 3) to a working path (e.g. a scratch file, or `<chosen_dir>/<slug>.html`). Use semantic HTML with a proper heading hierarchy so the PDF is structurally sound and machine-readable (`workaholic:planning` / `accessibility-first`). The body carries the question, the sourced answer, and an evidence list of the files/paths consulted.

### 2-5. Phase 3: Resolve Path + Consent

Resolve the export directory (all destination logic lives in the script — never inline):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/explain/scripts/resolve-export-path.sh "<dest-dir-or-empty>"
```

It returns `{ chosen_dir, is_home, needs_permission, exists, writable }`. Then:

- If `writable` is `false` (or `exists` is `false` and it cannot be created), **halt** with an actionable blocker naming `chosen_dir` — do not write.
- If `needs_permission` is `true` (the destination is the Home directory), the **command** issues a `[project label]`-prefixed `AskUserQuestion` with a symmetric agree/decline **before** any write: e.g. options **"Write to Home"** and **"Cancel"** (no default-yes, decline as easy as accept). On decline, stop without writing.
- Otherwise (Desktop, or an explicit non-Home destination) proceed without a prompt.

The final PDF path is `<chosen_dir>/<slug>.pdf`.

### 2-6. Phase 4: Print to PDF (vendor-neutral)

**Capability check (model-level).** A shell script cannot see MCP tools, so inspect your **available tools** for a browser backend:

- **Playwright plugin** — `mcp__plugin_playwright_playwright__browser_navigate` etc. are present.
- **Chrome DevTools MCP** — its navigate + print-to-PDF tools are present.

Drive whichever is present, expressing the same one step (open the HTML `file://` URL, print to PDF at the resolved path):

- **Playwright plugin**: `browser_navigate` to `file://<abs-html-path>`, then print via `browser_run_code_unsafe` running `await page.pdf({ path: '<pdf-path>', format: 'A4', printBackground: true })` (the Playwright MCP exposes no direct pdf tool, so the page-context call is the boundary).
- **Chrome DevTools MCP**: navigate to the `file://` URL, then invoke its native print-to-PDF to the resolved path.

**No browser MCP available → halt with guidance.** Do not emit a broken/empty PDF. Save the generated **`.html`** to `chosen_dir` so the work is not lost, then stop and tell the developer to enable the Playwright plugin or the Chrome DevTools MCP and re-run (mirrors the degrade-gracefully pattern in `.workaholic/concerns/archive/48-*`).

### 2-7. Phase 5: Report

Print the concrete outcome: the written **PDF path** (or, on the no-MCP halt, the saved `.html` path plus the enable-a-browser-MCP instruction; or the unwritable-destination blocker). Name the primary files the answer drew from so the developer can verify it.

## 3. HTML Report Template (printer-ready)

A minimal, self-contained, print-optimized skeleton (no external assets, so the browser renders it offline). Fill the bracketed slots; keep one coherent print rule set.

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>[Question] — [repo name]</title>
<style>
  @page { size: A4; margin: 18mm; }
  * { box-sizing: border-box; }
  body { font: 12pt/1.5 -apple-system, "Segoe UI", Roboto, sans-serif; color: #1a1a1a; }
  header { border-bottom: 2px solid #1a1a1a; padding-bottom: 8px; margin-bottom: 18px; }
  h1 { font-size: 18pt; margin: 0 0 4px; }
  .meta { font-size: 9pt; color: #666; }
  h2 { font-size: 13pt; margin: 18px 0 6px; border-bottom: 1px solid #ddd; padding-bottom: 2px; }
  code, pre { font-family: "SF Mono", Menlo, Consolas, monospace; font-size: 10pt; }
  pre { background: #f5f5f5; padding: 8px; border-radius: 4px; overflow-wrap: anywhere; white-space: pre-wrap; }
  ul.evidence { font-size: 10pt; }
  footer { margin-top: 24px; border-top: 1px solid #ddd; padding-top: 6px; font-size: 9pt; color: #666; }
</style>
</head>
<body>
  <header>
    <h1>[Question]</h1>
    <div class="meta">[repo name] · [branch] · generated [ISO date]</div>
  </header>
  <main>
    <h2>Answer</h2>
    <!-- The sourced answer. Use <h2>/<h3>, <p>, <pre><code> for snippets. -->
    <h2>Evidence</h2>
    <ul class="evidence">
      <!-- One <li> per file/path/commit the answer rests on. -->
    </ul>
  </main>
  <footer>Generated by /explain · workaholic</footer>
</body>
</html>
```

## 4. Writing Guidelines

- **Objective and source-cited.** Every claim names the file, path, or commit it rests on; unknowns are stated as unknown. No evaluative adjectives (`workaholic:implementation` / `objective-documentation`).
- **Consent before the Home write.** The Home prompt is asked before rendering-to-disk-at-Home, at command level, symmetric agree/decline, no default-yes; declining writes nothing.
- **Never guess the browser.** Do not assume a browser MCP exists — check available tools, and on absence halt with guidance and the saved `.html`.
- **Self-explanatory outcomes.** Always end by printing the concrete path written (PDF, or the fallback `.html`), or the specific blocker — never a silent finish.
- **Confine the write.** Only ever write to the resolved user-document directory; never touch config/profile paths or escalate privilege (system-safety).
