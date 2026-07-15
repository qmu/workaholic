---
name: request
description: File a ticket in another repository, with this project's customer context masked and confirmed first.
skills:
  - workaholic:request
  - workaholic:create-ticket
  - workaholic:release-scan
  - workaholic:gather
---

# Request

<!-- workaholic:policy-lens — opts this command into the always-on engineering-policy lens injected by hooks/policy-lens.sh (UserPromptSubmit). Keep this marker. -->

**Notice:** When user input contains `/request` — whether "run /request", "raise a ticket in <other repo>", "ask <other repo> to…", or similar — they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

This command is a **thin orchestration** layer over the preloaded `workaholic:request` skill. It is the **only** sanctioned way to write into another repository — every other route is refused by `hooks/guard-repo-confinement.sh` (see `rules/general.md`, "Never modify another repository"). For work in *this* repo, use `/ticket`.

Run the skill's **Workflow** end to end. The skill owns the knowledge; this command owns the orchestration and every `AskUserQuestion` (one-level fan-out — subagents cannot prompt).

## The one rule this command exists to enforce

**Step 5 — showing the developer the exact body and having them confirm it — cannot be skipped.** Not for a body that looks clean, not on a re-run, not because approval was given earlier in the session. Show the text verbatim, as it will be filed.

Masking is a **judgement**, not a pattern match. The terms that have actually leaked from this organisation were a component name, a document filename, a mail label, a hostname, and cloud resource names — none of them enumerable in advance, so no scan could have seen them. `release-scan` runs in step 6 as a second layer beneath the judgement and catches only what someone already listed; a `pass` from it is not permission to skip step 5. If you ever find yourself reasoning that the confirmation is unnecessary this time, that is the failure mode, not an optimisation.

## Workflow

Follow `workaholic:request`'s Workflow §4:

1. Resolve the target — `bash ${CLAUDE_PLUGIN_ROOT}/skills/request/scripts/resolve-target.sh <path-or-name>`. On `ok: false`, show the error and stop. Never guess a target.
2. Confirm the target via `AskUserQuestion`, quoting `name`, `remote`, and **`visibility`** — filing into a public repo is a different decision from a private one, and the developer must see which they are making.
3. Compose the body as a conforming ticket, built from the **target's** vocabulary (skill §3).
4. Mask it (skill §2).
5. **Confirm the exact body** via `AskUserQuestion`. Non-skippable.
6. Scan it — `bash ${CLAUDE_PLUGIN_ROOT}/skills/release-scan/scripts/scan-branch-safety.sh`.
7. File it — `bash ${CLAUDE_PLUGIN_ROOT}/skills/request/scripts/file-request.sh <target-root> <filename> <body-file>`.
8. Report the filed path. **Do not commit in the target repo** — that is its owner's decision.

**Project label in every prompt:** prefix each `AskUserQuestion` body with `[<project label>]` — run `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh` once and reuse its `project` value. `hooks/guard-askuserquestion-label.sh` blocks otherwise. For the two prompts here, name **both** repositories: the developer is deciding about a boundary, so both sides must be on screen.
