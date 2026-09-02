---
name: implement
description: Unattended executor - survey the claimable missions and unclaimed backlog, claim each PR-unit, implement it, and route it by merge policy, with no prompt at any step.
skills:
  - workaholic:drive
  - workaholic:story
  - workaholic:ship
---

# Implement

<!-- workaholic:policy-lens — keep: hooks/policy-lens.sh matches this marker. -->

Run the preloaded `workaholic:drive` skill's **Unified Run** section end to end. This is the **unattended** entry point — the one the `[Implement]` routine and every caller-side loop invoke: **no `AskUserQuestion` anywhere, at any step**; a decision the run cannot make is deferred and recorded in the final report, never asked. It **never overrides a gate** (a `secret` hard-stops; a `size`/`leak` block or a missing confirmation method demotes to the PR path, reported with the gate that caused it) and never calls `land-unit.sh`. `$ARGUMENTS`, when present, names one unit (a mission slug or a ticket path) — a scope, not a mode. End with the reconciliation line and the terminal token derived from the skill's §7 table — the `/goal /implement ok` caller contract, never self-graded.

## What this run posts

The notification surface is **this command's**, not the routine's — a routine prompt names the command and nothing else, so a shape that changes here reaches every account's routine on the next run with no routine edit (`workaholic:notify`, *The command is the ceiling*). Post shapes are byte-identical to `workaholic:notify`'s catalog; a diff between the two is a drift to fix, never a second wording.

**Every skill section, reference file or command body this run consults is read with the **Read tool**, never with `sed`, `grep`, `cat` or `head`** (2026-09-02, issue #865): a shell read under the plugin cache is a permission prompt an unattended run cannot answer, and the Read tool is the same bytes with no prompt. A reference such as *see `workaholic:notify`, One thread per feedback item* names a section to open with Read, not a line to grep for.

**Every free-text slot below is written in Japanese, and so is this run's own reasoning and report** — the shape's label, step ids, status and reason words, slugs, branch names, `<@U…>` tokens and URLs are never translated, and a GitHub artifact stays English (`rules/interaction.md`, *The language of a post is the language its readers use*).

**And that Japanese must be read on first sight, not decoded** — the bar is an outcome, not a style preference: *a channel reader must understand what is being asked without opening the English record behind the link.* An established technical term keeps its ordinary katakana or English form (ビルド, CI, デプロイ, PR, and the repository's own `terms/` entries); the **meaning** of a title is translated, never its words; a title that resists translation is **paraphrased** in plain Japanese rather than transliterated. Measured: 「組み立てを止める」 for *fail the build* belongs as 「ビルドが落ちる」, a bare 「形」 for *shape* as 「投稿の型」, 「示せるという判定」 for *demonstrable verdict* as 「実証できたかどうかの判定」.

Post one finish line per claimed PR-unit into its reply thread (the `workaholic:notify` lookup) — one line per unit, never one per feedback stem:

```
🟢 Implemented [#123 Title](<repo-url>/pull/123)
One sentence, max 30 words, what the unit changed.
by [web routine](<session URL>)
```

When a unit ends in **handoff** its finish line is this one instead — never `🟢 Implemented`, and never a second post beside it — naming the person who must run what this environment could not:

```
🟡 Handoff <@U…> [#123 Issue Title](<repo-url>/pull/123)
The next run resumes it automatically; `git fetch && git checkout <branch>` to take it sooner. One sentence, max 25 words, what remains only.
<session URL>
```

The `<@U…>` names the **unit's own assignee, never you**: resolve it from the unit's `assignees` and, when it does not resolve, post the line with **no token at all** rather than a guessed one, and report it as unaddressed. Post that line through the **tokened transport** — `bash ${CLAUDE_PLUGIN_ROOT}/skills/specificate/scripts/notify-slack.sh --thread-ts <the thread's ts> "<the line>"` — whenever `SLACK_BOT_TOKEN` is set, so a bot speaks it and the mention notifies that person even when they are the account this session posts as. That script is `workaholic:notify`'s **fallback** transport, and it is selected here for its **identity** rather than for its availability: this one line is a directed post, which is the only case where which account speaks matters. The connector resolved the thread, so hand its `ts` straight through and never search for one. With no token, post it through the connector exactly as you post `🟢 Implemented`. Report per unit which surface carried it and whom it named. **`🟢 Implemented`, the `📝 FB` root and the precondition-stop shape always ride the connector**, unchanged.

If that lookup finds no thread, post this description root first and the finish line above as a reply into it — no mention token of any kind on the root:

```
📝 FB - [<feedback title>](<repo-url>/blob/main/.workaholic/feedbacks/<stem>.md)
One sentence, max 30 words, what the feedback asks for.
<session URL>
```

If the run stops before claiming anything, post `workaholic:notify`'s precondition-stop shape instead. An attended `/drive` run posts none of this.


Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or guess retired namespaces.
