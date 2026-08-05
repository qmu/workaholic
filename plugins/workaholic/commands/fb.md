---
name: fb
description: Register a piece of feedback — a design conclusion, an instruction, a concern, or customer material — as an immutable record in the repository's feedback stream.
skills:
  - workaholic:feedback
  - workaholic:gather
  - workaholic:commit
---

# Feedback

**Notice:** When user input contains `/fb` — whether "run /fb", "record this as feedback", "register the conclusion", "この議論をフィードバックに残して", or similar — they likely want this command.

**Why `/fb` and not `/feedback`:** Claude Code ships a **built-in `/feedback`** ("Send feedback to Anthropic or report a bug"), so the bare name is taken and typing it would send the developer's project context to Anthropic instead of registering a record — a silent wrong action, not a missing one. The command is therefore triggered as `/fb`; **only the trigger is abbreviated.** The artifact is still a *feedback*, the skill is still `workaholic:feedback`, the records still live in `.workaholic/feedbacks/` with `type: Feedback`, and every document still calls the corpus the **feedback stream**. Do not propagate `fb` into the vocabulary.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

This command is a **thin orchestration** layer over the preloaded `workaholic:feedback` skill. A feedback is one **immutable record** of inbound project context — the raw material later planning reads (see the skill for the concept, schema, and immutability rule). This command captures one record; it never proposes work, edits an existing record, or restates the skill's rules.

## Route first: is this repository the destination?

**Cross-repo mode fires only when `$ARGUMENT` names another repository** — an `owner/name`, a GitHub URL, or an explicit "to \<repo\>" / "against \<repo\>" / "ask \<repo\> to…". Anything else, including a bare `/fb`, is the in-repo record below, **unchanged**. When the input merely *mentions* another repository without addressing it, that is an in-repo record about that repository; ask nothing and record it here.

When it does name a destination, run the `workaholic:feedback` skill's **Crossing a repository boundary** section end to end (§4, steps 1-8) instead of the workflow below. The crossing carrier is a **GitHub issue on the target**; nothing is written into any checkout of it, and no feedback record is written here — the ask belongs to the target's stream, and its `[Propose]` routine ingests the issue like any other inbound report.

**The one rule the cross-repo mode exists to enforce:** the single `AskUserQuestion` — showing the developer the destination (with **visibility**) and the exact title and body they are about to send — **cannot be skipped.** Not for a body that looks clean, not on a re-run, not because approval was given earlier in the session. Show the text verbatim. Masking is a **judgement**, not a pattern match: the terms that have actually leaked were a component name, a document filename, a mail label, a hostname and cloud resource names, none of them enumerable in advance. The scan in step 5 and the identifier backstop in step 6 sit **beneath** that judgement and catch only what someone already wrote down; a pass from either is not permission to skip step 4. If you find yourself reasoning that the confirmation is unnecessary this time, that is the failure mode, not an optimisation.

## Workflow — the in-repo record (bare `/fb`, and every input that names no other repository)

1. **Gather the content.** `$ARGUMENT`, when present, is the feedback (or names what to capture from the conversation); when absent, the feedback is the conclusion/instruction the current conversation just reached. Write the body **faithfully in the contributor's own words** — an excerpt, an instruction, a conclusion. Summarize for length, never editorialize.

2. **Classify — decide, do not ask** (`rules/interaction.md`, the Recommended-label test): derive `kind` (`insight` / `instruction` / `concern` / `material` / `answer`) and `source` (`meeting` / `slack` / `discussion`) from the context — both are almost always recommendable from what just happened. **Apply the skill's deciding rule for `kind`** (`workaholic:feedback`, *Choosing the kind*): if the reporter asks for something to be done, it is an `instruction`; a `concern` is a worry with no ask attached. This is where that call is made — downstream readers see only the file, and `/propose` will not act on a misfiled ask. If the record moots or resolves an earlier feedback, find its filename via:

   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/feedback/scripts/list.sh
   ```

3. **Register it** (the only sanctioned writer — never Write/Edit a feedback file directly):

   ```bash
   printf '%s\n' "<body>" | bash ${CLAUDE_PLUGIN_ROOT}/skills/feedback/scripts/create.sh "<title>" <kind> <source> [supersedes-filename]
   ```

   The script stamps metadata, derives the filename, refreshes the OKF indexes, and git-stages. On `reason: "exists"`, re-run with a more specific title (the timestamp+slug collided).

4. **Commit** via the commit skill (policy-conformant subject, e.g. `Record feedback on <topic>`):

   ```bash
   sh ${CLAUDE_PLUGIN_ROOT}/skills/commit/scripts/commit.sh "<title>" "<why>" "<changes>" "None" "None" "<verify>"
   ```

5. **Report** the written path and its `kind`/`source` in one line.
