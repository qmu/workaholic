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

**It is a formal business document.** These reports are submitted to clients and circulated among colleagues to explain a situation or a design, so every one follows the company house style: **monochrome** (black on white, no colour), **no decoration** (normal font weight throughout — headings included — and no rules, borders, boxes, or underlines), **numbered hierarchical headings**, **prose as the primary unit** (lists only in support), and **self-explaining** (every term introduced in the sentences before it is used; a glossary only as a last resort). Comfort is achieved through **consistent spacing**, not ornament. The full rules are §3 (template) and §4 (guidelines); hold every report to them.

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

Write a **printer-ready HTML file** (see the **HTML Report Template**, section 3) to **`.explain/<slug>.html`, inside this repository** (git-ignored; create the directory if absent). Use semantic HTML with a proper heading hierarchy so the PDF is structurally sound and machine-readable (`workaholic:planning` / `accessibility-first`). The body carries the question, the sourced answer, and an evidence list of the files/paths consulted.

**Write it to the house style (§3–§4), not as a bare Q&A dump.** The answer is a business report: open with a paragraph that states the purpose and the conclusion, then develop it in **numbered sections** of **connected prose**; introduce every term in the sentence where it first appears (define before use); keep the page **monochrome, normal-weight, and free of rules/boxes**; and let the template's spacing scale carry the hierarchy. For a Japanese report, write natural business Japanese — kanji where a word is normally kanji, no casual or question-form phrasing.

> **The HTML staging path is in-repo on purpose — do not write it to `chosen_dir`.** `hooks/guard-repo-confinement.sh` is a blocking `PreToolUse(Write|Edit)` gate: **every** `Write` outside this repository is refused, and `chosen_dir` (Desktop, Home, or an explicit destination) is outside it by definition. An earlier version of this step offered `<chosen_dir>/<slug>.html` as an option; that path is now dead on arrival and would halt the run. The gate cannot carve out an exception for this skill — a `PreToolUse` hook sees only `tool_input.file_path`, never which skill is asking, so an `.html` bound for Home is indistinguishable from any other write there.
>
> **The export is unaffected.** Only the *staging* file moves in-repo. The PDF still lands at `<chosen_dir>/<slug>.pdf`, because the **browser** writes it (Phase 4) — that is an MCP call, not a `Write` tool call, so the gate never sees it and confinement stays absolute on the tool surface it governs.

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

**No browser MCP available → halt with guidance.** Do not emit a broken/empty PDF. The generated **`.html`** already sits at `.explain/<slug>.html` from Phase 2, so the work is never lost — **name that path** and stop, telling the developer to enable the Playwright plugin or the Chrome DevTools MCP and re-run (mirrors the degrade-gracefully pattern in `.workaholic/concerns/archive/48-*`). Do **not** copy it to `chosen_dir`: that write is refused by the confinement gate (see Phase 2), and re-running with a browser present produces the PDF there anyway.

### 2-7. Phase 5: Report

Print the concrete outcome: the written **PDF path** (or, on the no-MCP halt, the in-repo `.explain/<slug>.html` path plus the enable-a-browser-MCP instruction; or the unwritable-destination blocker). Name the primary files the answer drew from so the developer can verify it.

## 3. HTML Report Template (printer-ready, house style)

A self-contained, print-optimized skeleton (no external assets, so the browser renders it offline). The visual identity is **monochrome and quiet**: black text on white, **no colour**; **normal weight everywhere**, headings included (never bold); **no rules, borders, boxes, or underlines**. Hierarchy and comfort come from **type size and one consistent spacing scale** — a single unit `--u`, and every gap a multiple of it (never special-case a gap). Headings are **numbered hierarchically** (`1.` / `1-1.` / `1-1-1.`) by CSS counters, so the numbering cannot drift; the document title is separate and unnumbered. Paragraphs are the body; lists are supportive only.

Fill the bracketed slots. Do **not** add colour, weight, or dividers — the calm read is the design.

```html
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="utf-8">
<title>[報告書タイトル]</title>
<style>
  @page { size: A4; margin: 24mm 22mm; }
  * { box-sizing: border-box; }
  :root {
    --ink: #000;   /* 本文・見出しは黒のみ */
    --sub: #555;   /* 補助情報だけに使う無彩色グレー（色ではなく濃淡） */
    --u: 1.7rem;   /* 基準スペーシング単位。すべての余白はこの倍数 */
  }
  html { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  body {
    font-family: "Noto Sans CJK JP","Hiragino Kaku Gothic ProN",-apple-system,sans-serif;
    color: var(--ink); background: #fff;
    font-weight: 400; font-size: 10.5pt; line-height: 1.9; margin: 0;
  }
  .doc { max-width: 40em; margin: 0 auto; }   /* 快適な行長（およそ40字） */

  /* 装飾なし・全て標準ウェイト。階層は文字サイズと余白だけで表す */
  h1, h2, h3, p, ul, ol, dl { margin: 0; font-weight: 400; }
  h1 { font-size: 15pt; line-height: 1.6; }
  h2 { font-size: 12.5pt; line-height: 1.6; }
  h3 { font-size: 11pt; line-height: 1.6; }

  /* 見出し番号は CSS カウンタで自動採番（1. / 1-1. / 1-1-1.） */
  .doc { counter-reset: h1; }
  h1 { counter-reset: h2; counter-increment: h1; }
  h2 { counter-reset: h3; counter-increment: h2; }
  h3 { counter-increment: h3; }
  h1::before { content: counter(h1) ". "; }
  h2::before { content: counter(h1) "-" counter(h2) ". "; }
  h3::before { content: counter(h1) "-" counter(h2) "-" counter(h3) ". "; }

  /* 一貫した縦のリズム。間隔はすべて --u の倍数 */
  * + h1 { margin-top: calc(var(--u) * 2); }
  * + h2 { margin-top: calc(var(--u) * 1.4); }
  * + h3 { margin-top: calc(var(--u) * 1); }
  :is(h1,h2,h3) + * { margin-top: calc(var(--u) * 0.6); }
  p + p { margin-top: calc(var(--u) * 0.75); }
  p + :is(ul,ol,dl) { margin-top: calc(var(--u) * 0.5); }
  li { margin-top: 0.5rem; }
  ul, ol { padding-left: 1.4em; }

  .title-block { margin-bottom: calc(var(--u) * 2.2); }
  .title-block .t { font-size: 17pt; line-height: 1.6; }
  .title-block .meta { color: var(--sub); font-size: 9pt; margin-top: calc(var(--u) * 0.5); }

  /* 用語集は最終手段（本文で説明できない語だけ） */
  dl.glossary dt { margin-top: calc(var(--u) * 0.5); }
  dl.glossary dd { margin: 0.3rem 0 0 1.4em; }

  footer { color: var(--sub); font-size: 8.5pt; margin-top: calc(var(--u) * 2.2); }
  code { font-family: "Noto Sans Mono CJK JP","SF Mono",monospace; font-size: 0.92em; }
</style>
</head>
<body>
<div class="doc">
  <div class="title-block">
    <div class="t">[報告書タイトル：体言で簡潔に。くだけた表現・疑問形は避ける]</div>
    <div class="meta">[提出先／作成者] ・ [対象] ・ [YYYY-MM-DD]</div>
  </div>

  <!-- 導入：目的と結論を先に、段落で述べる -->
  <p>[本資料が何を説明するか、結論を先に述べる導入段落。]</p>

  <h1>[節見出し]</h1>
  <p>[段落で説明する。未定義の語は、使う前にその文中で説明する。]</p>

  <h2>[小見出し]</h2>
  <p>[段落が主体。箇条書きは補助にとどめる。]</p>

  <!-- 必要な場合のみ、末尾に用語集（最終手段）
  <h1>用語</h1>
  <dl class="glossary">
    <dt>[用語]</dt><dd>[定義]</dd>
  </dl>
  -->

  <footer>[出典：参照した具体的なファイル・パス] ・ Generated by /explain</footer>
</div>
</body>
</html>
```

## 4. Writing & House-Style Guidelines

The report is submitted to clients and read by colleagues, so it carries a business register and the company's visual identity. Hold every report to these:

**House style (visual):**

- **Monochrome, no decoration.** Black text on white, **no colour anywhere**. **Normal font weight throughout — headings included**; never bold, never emphasis-by-weight, never coloured, boxed, ruled, or underlined. The only permitted non-black tone is a restrained grey for de-emphasised metadata (the title's meta line, the footer) — a shade of black, not a hue.
- **Comfort through spacing, not ornament.** One spacing unit; every gap a consistent multiple of it; generous line-height and a comfortable measure (~40 Japanese characters per line). Aim past mere accessibility for a calm, comfortable read achieved through spacing alone. Keep the rhythm uniform — do not special-case gaps.
- **Numbered headings.** Sections are numbered hierarchically — `1.`, `1-1.`, `1-1-1.` — prepended to the heading (the template's CSS counters do this). The document title is separate and unnumbered.

**House style (writing):**

- **Prose first; lists are supportive only.** The default unit is the paragraph — sentences that connect ideas into an argument. Reach for a list only when the material genuinely is an enumeration, and never as the primary structure of a section.
- **Self-explaining; define before use.** Never use a term the reader has not been given. Introduce each concept **in prose, in the sentence or paragraph where it first appears**, before relying on it. A glossary at the end is a **last resort** — only for a term that cannot be explained inline, never a substitute for explaining in the body. Do not assume shared vocabulary that was not established in the document.
- **Natural business Japanese** (for Japanese reports). Write each word in its normal form — **kanji where the word is normally written in kanji** (e.g. 普段・通常, never spelled ふだん); do not render kanji words in hiragana. Avoid casual or childish phrasing and question-form titles (not「Workaholicって何？」); title with a noun phrase (e.g.「Workaholic 概要」). Formal, plain, and natural — neither jargon-dense nor colloquial.

**Operational:**

- **Objective and source-cited.** Every claim names the file, path, or commit it rests on; unknowns are stated as unknown. No evaluative adjectives (`workaholic:implementation` / `objective-documentation`).
- **Consent before the Home write.** The Home prompt is asked before rendering-to-disk-at-Home, at command level, symmetric agree/decline, no default-yes; declining writes nothing.
- **Never guess the browser.** Do not assume a browser MCP exists — check available tools, and on absence halt with guidance and the saved `.html`.
- **Self-explanatory outcomes.** Always end by printing the concrete path written (PDF, or the fallback `.html`), or the specific blocker — never a silent finish.
- **Confine the write.** Only ever write to the resolved user-document directory; never touch config/profile paths or escalate privilege (system-safety).
