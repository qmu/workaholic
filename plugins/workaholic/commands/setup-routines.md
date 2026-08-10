---
name: setup-routines
description: Wire this repository's Claude Code Web routines directly when a RemoteTrigger-family tool is exposed to this session; otherwise render copy-paste setup sheets so a developer can create them by hand in the web UI.
skills:
  - workaholic:workaholify
---

# Setup Routines

Run the preloaded `workaholic:workaholify` skill's §5 **Scheduled routines** flow, as its *What the command does with all this* section states: resolve the repository (`resolve-repo-url.sh "$ARGUMENT"` — `$ARGUMENT` is an optional repository name or URL, absent means this checkout), then detect `RemoteTrigger` availability (*Direct-apply when `RemoteTrigger` is exposed*) before anything else. **When exposed** — an interactive session only; never the routine-fired class — list the account's routines, diff each against its template (name/prompt/model/schedule/connectors), and apply create/update calls to converge, reporting exactly what changed per routine. **When absent**, behavior is unchanged: render the copy-paste setup sheets (`render-setup-sheet.sh --all <repo-url>`, prompts verbatim), report the two preconditions (`check-slack-channel.sh <repo-name>`, `check-bootstrap.sh`), and say plainly what cannot be verified from here. Either way it asks no `AskUserQuestion` — converging to the developer's own already-declared template needs no decision to ask about (the skill's *Recommended-label test* reasoning); a mismatch the tool itself refuses is reported, not asked.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
