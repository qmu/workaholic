---
name: setup-routines
description: Render copy-paste setup sheets for this repository's Claude Code Web routines, so a developer can create them by hand in the web UI.
skills:
  - workaholic:workaholify
---

# Setup Routines

**Notice:** When user input contains `/setup-routines` — whether "run /setup-routines", "set up the routines", "how do I wire the drive routine", "what should run against this repo", or similar — they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

`/setup-routines [repository name]` renders, for each shipped template, a **copy-paste setup sheet**: the routine's name, model, repository, the prompt verbatim in one block, the exact web-UI steps for its trigger, the connectors to keep and the Slack channel to have ready. The developer opens <https://claude.ai/code/routines> beside it and creates the routine by hand.

**It manages nothing, and that is the design** (the developer's ruling, 2026-08-06; `.workaholic/feedbacks/20260806143907-routine-setup-is-a-human-act-the-plugin-makes-cheap.md`). A routine's GitHub trigger is configurable **in the web UI only** — the product documentation says so, and the API record carries no event field — so the wiring can be neither read, written, nor drift-checked from a session. The command therefore makes **no `RemoteTrigger` call at all**: it does not survey the account, does not report drift, and does not create, refresh or remove anything. What it can do honestly is state what each routine *should* be, cheaply enough to paste.

Run this workflow:

1. **Resolve the repository.** `$ARGUMENT` is an optional repository name or URL; absent, it means this checkout.

   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/resolve-repo-url.sh "$ARGUMENT"
   ```

   When `source` is `same_org_as_checkout`, say which repository you resolved to — a bare name is a guess inside this checkout's organisation, and answering confidently about the wrong repository is the failure this command must not commit.

2. **Render the sheets.** All templates, or one when the developer named it:

   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/render-setup-sheet.sh --all <repo-url>
   ```

   Print the output as it comes. It is markdown written for a person with a browser open, and the prompt blocks must reach them **verbatim** — never summarise, re-wrap, or "clean up" a prompt: what they paste is what runs.

3. **Report the two preconditions**, because a routine created without them runs and then fails at its last step:

   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/check-slack-channel.sh <repo-name>
   bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/check-bootstrap.sh
   ```

   `checked: false` means *could not look*, never *does not exist* — report it that way. The bootstrap hook is the one without which every routine stops at its own "the workaholic plugin must be loaded" precondition, firing on time and doing nothing.

4. **Say what cannot be verified from here.** Whether the developer completed the wiring — and whether a routine has ever fired — is not answerable from the account: `last_fired_at` is populated for a cron fire and absent for a GitHub-triggered one. A routine that ran is recognised by what it produced (an issue, a pull request, a channel post), and the sheet says so.

**No `AskUserQuestion` anywhere in this command.** There is no mutation to confirm: the developer is the one acting, in their own browser, and the sheet is what they act from.
