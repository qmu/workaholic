---
name: setup-routines
description: List the scheduled Claude Code Web routines that run against a repository — what they do, on what schedule, and whether they still match the shipped template.
skills:
  - workaholic:workaholify
---

# Setup Routines

**Notice:** When user input contains `/setup-routines` — whether "run /setup-routines", "what runs against this repo", "which routines are configured", "is the drive routine still scheduled", or similar — they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

`/setup-routines [repository name]` answers a question a repository could not previously answer about itself: **what runs against it, on what schedule, and from which template.** The configuration lives in the plugin (the templates) and in the Claude Code Web account (the live routines) — the repository declares nothing, so the only way to answer is to ask the account and report what it says (`workaholic:workaholify` §5). This command is **read-only**: it creates, changes and deletes nothing.

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
   - On `checked: true`, give one short block per routine: what it does (the `template` id — `fb` turns a reported issue into a feedback record and a PR, `merged-pr` announces a merge to `dev-<repo>`, `drive` runs the queue hourly), its `trigger` and `schedule`, its `target_repo`, whether it is `enabled`, and its `status`. Render `template_set_version` as *the version of the template set compared against* — the account records no version on a routine, so nothing here can say which version created one.
   - A `drifted` routine is reported **per field**, from its `drift` list. "This routine differs" is not a report.
   - `status: unknown` means a routine matching no template: somebody's deliberate one-off, listed so nothing is invisible. Never a problem, and never a deletion proposal — the API has no delete at all; deletion is a human act at <https://claude.ai/code/routines>.
   - `missing` names templates with no live routine. Report it as available, not as a fault.
   - `elsewhere` summarises drift in the other repositories carrying workaholic routines. Mention it: the templates are one set applied to many repositories, so the same defect replicated seven times is still one defect.

5. **Report the preconditions every template depends on.** Every routine posts to `dev-<repo_name>`, so name `slack_connector` from the listing and probe the channel:

   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/check-slack-channel.sh <repo-name>
   ```

   **`checked: false` is "could not check", never "the channel is missing"** — a locked credential store returns the same error as a nonexistent channel, and conflating them sends a developer to create a channel that already exists.

Close by saying plainly that this command changed nothing, and that creating or refreshing a routine is a separate, confirmed act.
