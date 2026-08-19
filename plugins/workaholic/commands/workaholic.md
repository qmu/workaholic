---
name: workaholic
description: Configure the routines an account needs exactly one copy of across every repository ([Workaholic]). Attempts the configuration itself every time; when this session carries no transport that can reach an account routine, reports that refusal by name and falls back to copy-paste setup sheets as the recovery path.
skills:
  - workaholic:workaholify
---

# Workaholic

**Run this once for your account, not once per repository.** A `user`-scoped routine is one the *account* needs exactly one of, whatever number of repositories that account has set up: it converges the account's own workaholic routines across all of them. A second copy would do the same work twice on the same records and race itself. That count is the whole reason the scope exists, and it is why this is a third command rather than a widened `/setup-dev-routines`: `developer` multiplies by developers **and** by repositories, `user` multiplies by neither, and one command answering both questions could no longer report how many of a routine should exist.

Run the preloaded `workaholic:workaholify` skill's §5 **Scheduled routines** flow, as its *What the commands do with all this* section states, over the **`user`-scoped templates only** (`list-routine-templates.sh user`). Resolve the repository (`resolve-repo-url.sh "$ARGUMENT"` — `$ARGUMENT` is an optional repository name or URL, absent means this checkout); for this scope the repository is the one holding the **routine definitions**, not whichever repository prompted the run. Then **attempt the configuration**: find the transport that can reach an account routine (a `RemoteTrigger`-family tool — never the session-only, in-memory `CronCreate`/`CronList`/`CronDelete`), list the account's routines, diff each against its template (name/prompt/model/`cron_expression`/`autofix_on_pr_create`/connectors), apply create/update to converge, and report exactly what changed per routine.

**This is also the command `[Workaholic]` itself runs**, which makes two rules load-bearing rather than stylistic:

- **The enumeration is the account's own routine list, and its limit is reported.** Each routine names the repository it runs against, so the account's routines *are* the domain to converge — nothing in the loop holds a list of "this user's repositories", and neither a GitHub repository listing (which enumerates repositories with no routine and cannot say which should have one) nor an operator-maintained list (a second source of truth that drifts silently) answers the question asked. State the consequence rather than implying coverage: **a repository the account has never created a routine on is invisible to this run**, and the report says so.
- **Never converge the `user`-scoped routine from an unattended tick.** A routine that rewrites routines can take an account's whole fleet down in one pass, and the failure worth designing against is a bad definition propagating everywhere at once. A tick therefore converges every routine **except its own record**; that record is converged only by a person invoking this command, exactly as `[Propose]` is converged by a person running `/setup-repo-routines` and never by a tick. Converge one routine at a time and report each as its own line — never batch, never infer a mutation from a report.

**Drift is the rendered diff, never a version number.** A plugin version bump is a cheap pre-filter and nothing more: a template edit that did not bump a version is exactly the change this routine exists to propagate, and a version-gated run would sit still through it. The rendered `name`/prompt/`model`/`cron_expression`/`autofix_on_pr_create`/connectors comparison is what convergence already computes; nothing new is needed to decide what counts as an update.

**When no transport is reachable, the attempt fails and says so**: report `no_transport: RemoteTrigger-family tool` (naming what was looked for), state that the account's routines could therefore not be read at all and that **nothing was converged** — never a silent success, and never a claim of convergence this run did not perform — then render the copy-paste setup sheets for this scope (`render-setup-sheet.sh --all <repo-url> user`, prompts verbatim) as that refusal's recovery path, with the preconditions (`check-slack-channel.sh <repo-name>`, `check-bootstrap.sh`) and a plain statement of what cannot be verified from here.

**It never touches a `developer`- or `repository`-scoped routine.** The scope filter is the whole difference between the three setup commands, and it is read from each template's own `scope:` field, never from a list written into a command body.

It asks no `AskUserQuestion` (`rules/interaction.md`'s *Recommended-label test*); a mutation the tool itself refuses is reported as a refusal, never asked and never silently downgraded to the sheet.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
