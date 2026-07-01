---
name: commit
description: Commit the working changes with a policy-conformant message via commit.sh.
skills:
  - workaholic:commit
  - workaholic:gather
---

# Commit

**Notice:** When user input contains `/commit` — whether "run /commit", "commit this", "commit my changes", or similar — they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

This command is a **thin orchestration** layer over the preloaded `workaholic:commit` skill. It is the sanctioned path for a small, legitimate, **non-ticketed** change (docs, a config tweak, a one-line fix, or an explicit user request) that should still carry the structured, policy-conformant commit message. **Prefer `/drive` for anything ticketed** — `/drive` implements, approves, and archives the ticket and commits it for you. `/commit` is the escape hatch that keeps the message format intact instead of free-handing a raw `git commit`.

Do **not** re-implement staging or message assembly here — `commit.sh` owns multi-contributor-safe staging and trailer rendering. This command only derives the inputs and calls it.

## Workflow

1. **Inspect the working tree.** Run `git status` and review the staged diff (`git diff --cached`) and the unstaged diff (`git diff`) to understand exactly what would be committed.

2. **Stage safely.**
   - `commit.sh` stages all **tracked** changes by default (`git add -u`); it **never** uses `git add -A`.
   - If there are **untracked** files that belong in this commit, list them and **ask the user** (`AskUserQuestion`, selectable options) before staging them, then pass those files explicitly to `commit.sh` as trailing `[files...]` arguments. Never stage untracked files without confirmation — they may belong to another contributor. Set that prompt's `header` to the **project label** — run `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh` and use its `project` value — so a developer with several sessions open across tmux panes can see which repository is asking.
   - If nothing is staged and there are no tracked changes, tell the user there is nothing to commit and stop.

3. **Derive a conformant message** (see `workaholic:commit` → Message Format):
   - **title**: present-tense verb, **50 characters or fewer**, with **no** prefix (`feat:` / `fix:` / `[tag]`).
   - **why / changes / concerns / insights / verify**: short paragraphs drawn from the actual diff and the user's intent. Use `None` (or empty) for `why`/`concerns`/`insights` when there is nothing to record — those sections are then omitted.

4. **Commit via the script** (the only authorized commit path):

   ```bash
   sh ${CLAUDE_PLUGIN_ROOT}/skills/commit/scripts/commit.sh [--category <Added|Changed|Removed>] "<title>" "<why>" "<changes>" "<concerns>" "<insights>" "<verify>" [files...]
   ```

   **Argument order is strict**: any flags (`--category`, `--skip-staging`) come **first**, then the six positional args in exactly this order — `title why changes concerns insights verify` — then optional `[files...]`. Putting `--category` after the positionals silently drops it (it is parsed as a filename, not a flag), so the `Category:` trailer goes missing. Pass `--category` when the change maps cleanly to Added / Changed / Removed so `/report` can group it. The trailer block (including any `Co-Authored-By`) is whatever `commit.sh` emits — this command stays trailer-agnostic and adds no attribution line itself.

5. **Report the result**: surface the commit hash from `commit.sh`'s output.

## Notes

- This command does **not** create a branch, open a PR, or push. It commits the current changes on the current branch only. Use `/report` to open a PR and `/ship` to merge and deploy.
- The off-policy commit gate (`hooks/guard-git-commit.sh`) blocks a raw `git commit` with a prefixed/over-long subject. Because this command commits through `commit.sh` (not a top-level `git commit`), it is the sanctioned route that the gate points violators toward.
