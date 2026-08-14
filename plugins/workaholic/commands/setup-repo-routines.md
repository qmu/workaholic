---
name: setup-repo-routines
description: Configure the routines the repository needs exactly one copy of, run by one designated account for the whole team. Attempts the configuration itself every time; when this session carries no transport that can reach an account routine, reports that refusal by name and falls back to copy-paste setup sheets as the recovery path.
skills:
  - workaholic:workaholify
---

# Setup Repo Routines

**Run this from one account for the whole repository — a designated person or a project/service account — not from every team member's.** A `repository`-scoped routine is one the repository needs exactly one of; converged by six developers it exists six times and fires six times an hour, each copy doing the same work and racing the others. Nothing in the product can detect or refuse that: a routine is an account-level record, and no account can see another's. **So this is a stated convention, not an enforced one** — there is no ownership signal to check against, and inventing an authorization mechanism the API cannot enforce would only make the guarantee look stronger than it is. What the command does instead is report exactly what it converged, by name, so a second person running it sees their own duplicate in their own report and can delete it.

Run the preloaded `workaholic:workaholify` skill's §5 **Scheduled routines** flow, as its *What the commands do with all this* section states, over the **`repository`-scoped templates only** (`list-routine-templates.sh repository`). Resolve the repository (`resolve-repo-url.sh "$ARGUMENT"` — `$ARGUMENT` is an optional repository name or URL, absent means this checkout), then **attempt the configuration**: find the transport that can reach an account routine (a `RemoteTrigger`-family tool — never the session-only, in-memory `CronCreate`/`CronList`/`CronDelete`), list the account's routines, diff each against its template (name/prompt/model/`cron_expression`/`autofix_on_pr_create`/connectors), apply create/update to converge, and report exactly what changed per routine.

**When no transport is reachable, the attempt fails and says so**: report `no_transport: RemoteTrigger-family tool` (naming what was looked for), then render the copy-paste setup sheets for this scope (`render-setup-sheet.sh --all <repo-url> repository`, prompts verbatim) **as the recovery path for that refusal**, with the preconditions (`check-slack-channel.sh <repo-name>`, `check-bootstrap.sh`) and a plain statement of what cannot be verified from here — including the one this command can never verify: whether somebody else already created the same routine.

**It never touches a `developer`-scoped routine** — those are `/setup-dev-routines`'s, and every developer runs that one for themselves.

It asks no `AskUserQuestion` (`rules/interaction.md`'s *Recommended-label test*); a mutation the tool itself refuses is reported as a refusal, never asked and never silently downgraded to the sheet.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
