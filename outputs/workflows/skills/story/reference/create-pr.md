# Create PR — script contracts

## Derive the PR title

Take the first item from the story's Summary/Overview highlights list; if multiple items exist, append "etc" (e.g. "Add dark mode toggle etc").

## create-or-update.sh

```bash
bash ../story/scripts/create-or-update.sh <branch-name> "<title>"
```

What it does:

1. Strips YAML frontmatter from `.workaholic/stories/<branch-name>.md` via `strip-frontmatter.sh`
2. Writes the clean content to a private per-run temp file (`mktemp`, removed on exit) — never a constant path two concurrent runs could share
3. Drops the `low`-severity concern blocks from the body via `filter-low-concerns.sh`, leaving a line naming how many were dropped and pointing at the story file. The story file is untouched, and the ship-time extractor reads the file — every severity is still recorded
4. Bounds the body under GitHub's 65,536-character limit via `shrink-pr-body.sh` (the `## Handoff` block is non-droppable)
5. Checks whether a PR exists for the branch; creates or updates accordingly
6. Prints exactly one line: `PR created: <URL>` or `PR updated: <URL>` — the format the story command requires

Steps 3 and 4 are the only two places the PR body and the story file diverge, both in the same direction for the same reason: the file is the record, the body is the reading experience.

**Degrade when `gh` is absent**: the script reports `{"pr": null, "reason": "gh_unavailable", ...}` and exits 0 rather than dying at exit 127 after the branch is already pushed. The branch and its story are safe and pushed; open or update the pull request by hand (or via an agent's MCP GitHub access — a shell script cannot reach it, which is why the script degrades and hands the problem up). Under `/drive`, record `pr_error: gh_unavailable` in the run report; the unit is never `blocked` for this, but a unit that was going to ship is demoted to the PR path.

## strip-frontmatter.sh

```bash
bash ../story/scripts/strip-frontmatter.sh <file>
```

Outputs the clean markdown body to stdout. Handles files with frontmatter, without (pass-through), and empty files. Only strips frontmatter starting on line 1 — `---` separators elsewhere are preserved.
