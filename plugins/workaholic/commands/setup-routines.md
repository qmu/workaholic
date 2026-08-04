---
name: setup-routines
description: List the scheduled Claude Code Web routines that run against a repository, and add, refresh or remove one — each confirmed verbatim, one at a time.
skills:
  - workaholic:workaholify
---

# Setup Routines

**Notice:** When user input contains `/setup-routines` — whether "run /setup-routines", "what runs against this repo", "which routines are configured", "is the drive routine still scheduled", or similar — they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

`/setup-routines [repository name]` answers a question a repository could not previously answer about itself: **what runs against it, on what schedule, and from which template.** The configuration lives in the plugin (the templates) and in the Claude Code Web account (the live routines) — the repository declares nothing, so the only way to answer is to ask the account and report what it says (`workaholic:workaholify` §5).

**Reading is free; changing is not.** Steps 1-5 read and report, and are safe to run anywhere. A routine is a standing, outward-facing process that acts on a repository unattended, so **every create, refresh and removal is confirmed verbatim, one routine at a time** (step 6) — never batched into a single yes, never inferred from a drift report, and never in an unattended run.

Run this workflow:

1. **Resolve the repository.** `$ARGUMENT` is an optional repository name or URL; absent, it means this checkout.

   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/resolve-repo-url.sh "$ARGUMENT"
   ```

   When `source` is `same_org_as_checkout`, say which repository you resolved to — a bare name is a guess inside this checkout's organisation, and answering confidently about the wrong repository is the failure this command exists to prevent.

2. **Ask the account.** Load the tool with `ToolSearch select:RemoteTrigger`, then call `RemoteTrigger` with `{action: "list"}` and write its **raw** JSON response to `.routines/live.json` (git-ignored, and in-repo because `guard-repo-confinement.sh` refuses every write outside the repository).

   **If the call fails, write nothing** and go straight to step 3 without the file. That is the whole point: the reader then reports that it could not check, instead of inventing an empty account.

3. **Read it back.**

   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/list-routines.sh <repo-url> --live .routines/live.json
   ```

4. **Report it to someone who has never seen this repository before.**

   - **`checked: false` is "I could not look", never "nothing runs here."** Say so in those words, name the `reason`, and stop — do not list, guess, or reassure. A developer told a live repository has no routines will believe it.
   - On `checked: true`, give one short block per routine: what it does (the `template` id — `fb` turns a reported issue into a feedback record and a PR, `merged-pr` announces a merge to `dev-<repo>`, `drive` runs the queue hourly, `propose` runs the proposal batch every 15 minutes), its `trigger` and `schedule`, its `target_repo`, whether it is `enabled`, and its `status`. Render `template_set_version` as *the version of the template set compared against* — the account records no version on a routine, so nothing here can say which version created one.
   - A `drifted` routine is reported **per field**, from its `drift` list. "This routine differs" is not a report.
   - `status: unknown` means a routine matching no template: somebody's deliberate one-off, listed so nothing is invisible. Never a problem, and never a deletion proposal — the API has no delete at all; deletion is a human act at <https://claude.ai/code/routines>.
   - `missing` names templates with no live routine. Report it as available, not as a fault.
   - `elsewhere` summarises drift in the other repositories carrying workaholic routines. Mention it: the templates are one set applied to many repositories, so the same defect replicated seven times is still one defect.

5. **Report the preconditions every template depends on.** Every routine posts to `dev-<repo_name>`, so name `slack_connector` from the listing and probe the channel:

   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/check-slack-channel.sh <repo-name>
   ```

   **`checked: false` is "could not check", never "the channel is missing"** — a locked credential store returns the same error as a nonexistent channel, and conflating them sends a developer to create a channel that already exists.

6. **Add, refresh or remove — one routine, one confirmation.** Do this only for what the developer asked for, or, when the listing found drift or an unused template, after asking once whether to change anything at all. Then, **per routine**:

   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/plan-routine-change.sh <create|refresh|remove> <template-id> <repo-url> --live .routines/live.json
   ```

   Write the plan to `.routines/plan-<template-id>.json`, and then:

   - **`noop: true` is an answer, not a failure.** Report its `reason` and move on without asking: `no_drift` means the routine already matches the template and refreshing it would change nothing; `already_exists`, `not_present`, `already_disabled` and `disabled_routine` each say what to do instead. Never re-plan a noop as a different action to force something through.
   - Otherwise **show the developer the plan's `name`, `trigger`, `cron_expression`, `model`, `enabled` and the **whole** `prompt`, verbatim**, and confirm it with `AskUserQuestion` (one question, one routine, body prefixed with the `[<project label>]` from `gather/scripts/project-label.sh`). A batch confirmation is not this rule. Ask which `environment_id` to use — the account has more than one and nothing here guesses.
   - On confirmation, pass the plan's own `confirm_digest` back through the gate:

     ```bash
     bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/authorize-routine-change.sh --plan .routines/plan-<template-id>.json --digest <confirm_digest>
     ```

     Call `RemoteTrigger` **only** on `authorized: true`, and send exactly the returned `apply` block (plus the `environment_id` and the `slack_connector` from step 4): `{action: "create", body}` for a create, `{action: "update", trigger_id, body}` for a refresh or a removal. On `authorized: false`, report the `reason` and stop for that routine — `digest_mismatch` and `plan_tampered` both mean the body about to be sent is not the body that was confirmed.
   - **"Remove" means disable.** The routines API has no delete, so a removal is an update setting `enabled: false`. Say that plainly, and say that deleting the entry itself is a human act at <https://claude.ai/code/routines>. Never report a routine as gone when it is disabled.

7. **Report what changed.** Name each routine that was created, refreshed or disabled with its resulting URL, and each one that was left alone with the reason. Close by re-stating what still requires a human: deleting a routine outright.
