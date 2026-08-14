---
name: setup-dev-routines
description: Configure the routines every developer needs their own copy of ([Propose], [Implement]). Attempts the configuration itself every time; when this session carries no transport that can reach an account routine, reports that refusal by name and falls back to copy-paste setup sheets as the recovery path.
skills:
  - workaholic:workaholify
---

# Setup Dev Routines

Run the preloaded `workaholic:workaholify` skill's §5 **Scheduled routines** flow, as its *What the commands do with all this* section states, over the **`developer`-scoped templates only** (`list-routine-templates.sh developer`). Those are the routines every member of the team needs their own copy of, and this is the command a developer joining the repository runs. **This command's job is to configure them** — one job with a failure mode, not two branches to choose between. Resolve the repository (`resolve-repo-url.sh "$ARGUMENT"` — `$ARGUMENT` is an optional repository name or URL, absent means this checkout), then **attempt the configuration**: find the transport that can reach an account routine (a `RemoteTrigger`-family tool — never the session-only, in-memory `CronCreate`/`CronList`/`CronDelete`), list the account's routines, diff each against its template (name/prompt/model/`cron_expression`/`autofix_on_pr_create`/connectors), apply create/update to converge, and report exactly what changed per routine. Configuring is what happened, not what happened to be possible — never report it as luck.

**When no transport is reachable, the attempt fails and says so**: report `no_transport: RemoteTrigger-family tool` (naming what was looked for), then render the copy-paste setup sheets for this scope (`render-setup-sheet.sh --all <repo-url> developer`, prompts verbatim) **as the recovery path for that refusal**, with the two preconditions (`check-slack-channel.sh <repo-name>`, `check-bootstrap.sh`) and a plain statement of what cannot be verified from here. A sheet is a repair the developer performs by hand; it is never the ordinary outcome of this command.

**It never touches a `repository`-scoped routine.** The scope filter is the whole difference between this command and `/setup-repo-routines`, and it is read from each template's own `scope:` field, never from a list written into a command body. A repository routine converged by every team member would exist N times and fire N times an hour.

Either way it asks no `AskUserQuestion` — converging to the developer's own already-declared template needs no decision to ask about (`rules/interaction.md`'s *Recommended-label test*); a mutation the tool itself refuses is reported as a refusal, never asked and never silently downgraded to the sheet.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
