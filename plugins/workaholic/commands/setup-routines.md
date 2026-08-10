---
name: setup-routines
description: Render copy-paste setup sheets for this repository's Claude Code Web routines, so a developer can create them by hand in the web UI.
skills:
  - workaholic:workaholify
---

# Setup Routines

Run the preloaded `workaholic:workaholify` skill's §5 **Scheduled routines** flow, as its *What the command does with all this* section states: resolve the repository (`resolve-repo-url.sh "$ARGUMENT"` — `$ARGUMENT` is an optional repository name or URL, absent means this checkout), render the copy-paste setup sheets (`render-setup-sheet.sh --all <repo-url>`, prompts verbatim), report the two preconditions (`check-slack-channel.sh <repo-name>`, `check-bootstrap.sh`), and say plainly what cannot be verified from here. It manages nothing: no `RemoteTrigger` call, no `AskUserQuestion` — the developer creates the routines by hand at <https://claude.ai/code/routines> from the sheet. Whether a `RemoteTrigger`-class tool is available at all is session-class-dependent (`workaholic:workaholify`'s *What a routine can be triggered by* and its `reference/routines.md`); this command does not call one either way.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
