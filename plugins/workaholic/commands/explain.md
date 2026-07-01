---
name: explain
description: Answer a question about the repository and export a printer-ready PDF report rendered from HTML by a real browser.
skills:
  - workaholic:explain
---

# Explain

<!-- workaholic:policy-lens — opts this command into the always-on engineering-policy lens injected by hooks/policy-lens.sh (UserPromptSubmit). Keep this marker. -->

**Notice:** When user input contains `/explain` - whether "run /explain", "explain X and export a PDF", "write a report answering …", or similar - they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

This command (main agent) runs the preloaded `workaholic:explain` skill. Follow its **Run Workflow** section end-to-end (Phase 0 Parse Arguments, Phase 1 Discover the Answer, Phase 2 Render the HTML Report, Phase 3 Resolve Path + Consent, Phase 4 Print to PDF, Phase 5 Report).

**Arguments** (`$ARGUMENTS`):
- **First argument — the question (MANDATORY).** If it is missing, tell the developer the usage `/explain "<question>" [destination-dir]` and stop.
- **Second argument — destination directory (optional).** When omitted, the skill resolves the export path by priority **Desktop → Home** via `resolve-export-path.sh`.

**All user interaction happens here (one-level fan-out).** When the resolved (or explicit) destination is the **Home directory**, this command issues the consent `AskUserQuestion` itself **before** any write — a plain, symmetric agree/decline (no default-yes), prefixed with the `[project label]` from `${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh` (`workaholic:design` / `consent-recording`, `no-dark-patterns`). Any discovery fan-out spawns `general-purpose` leaves that return JSON and never prompt.

**Policy Lens**: The `hooks/policy-lens.sh` UserPromptSubmit hook injects the engineering-policy lens on every `/explain` run (via the marker above). The report is technical documentation — keep it objective and source-cited (`workaholic:implementation` / `objective-documentation`); every outcome (resolved path, success, failure, missing browser) must be understandable without a manual (`workaholic:design` / `self-explanatory-ui`).
