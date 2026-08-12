---
name: setup-routines
description: Configure this repository's Claude Code Web routines. Attempts the configuration itself every time; when this session carries no transport that can reach an account routine, reports that refusal by name and falls back to copy-paste setup sheets as the recovery path.
skills:
  - workaholic:workaholify
---

# Setup Routines

Run the preloaded `workaholic:workaholify` skill's §5 **Scheduled routines** flow, as its *What the command does with all this* section states. **This command's job is to configure the routines** — one job with a failure mode, not two branches to choose between. Resolve the repository (`resolve-repo-url.sh "$ARGUMENT"` — `$ARGUMENT` is an optional repository name or URL, absent means this checkout), then **attempt the configuration**: find the transport that can reach an account routine (a `RemoteTrigger`-family tool — never the session-only, in-memory `CronCreate`/`CronList`/`CronDelete`), list the account's routines, diff each against its template (name/prompt/model/`cron_expression`/`autofix_on_pr_create`/connectors), apply create/update to converge, and report exactly what changed per routine. Configuring is what happened, not what happened to be possible — never report it as luck.

**When no transport is reachable, the attempt fails and says so**: report `no_transport: RemoteTrigger-family tool` (naming what was looked for), then render the copy-paste setup sheets (`render-setup-sheet.sh --all <repo-url>`, prompts verbatim) **as the recovery path for that refusal**, with the two preconditions (`check-slack-channel.sh <repo-name>`, `check-bootstrap.sh`) and a plain statement of what cannot be verified from here. A sheet is a repair the developer performs by hand; it is never the ordinary outcome of this command.

Either way it asks no `AskUserQuestion` — converging to the developer's own already-declared template needs no decision to ask about (`rules/interaction.md`'s *Recommended-label test*); a mutation the tool itself refuses is reported as a refusal, never asked and never silently downgraded to the sheet.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
