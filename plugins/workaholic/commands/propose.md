---
name: propose
description: Read your own active strategies, plan one bounded ticket or mission whose evolutionary move brings the nearest one closer to its aim, and open that plan as a GitHub issue the next /specificate tick ingests. Reads this repository and writes nothing into it.
skills:
  - workaholic:propose
  - workaholic:strategy
---

# Propose

Run the preloaded `workaholic:propose` skill end to end — its `reference/loop.md` carries the
steps. Survey the strategies (`survey-strategies.sh`), read the selected direction and what has
landed against it, choose **one** move (`depth`, `breadth` or `contraction`), and open it with
`open-proposal.sh`.

**The proposal is one bounded hypothesis.** The issue names the experience it demands and its
ordered ticket set. A single ticket is valid when it is the whole hypothesis. Two or more tickets
that share a mid-term outcome may form a mission, sized by what the container must be able to hold
(`plugins/workaholic/rules/workaholic.md`, *What a Mission Must Be Able to Hold*). The body carries
`## Experience` and one-or-more `## Tickets` beside the three commitment sections. `/propose`
plans the natural scale; `/specificate` validates and writes it.

**It writes nothing into this repository** — no file, no commit, no branch, no pull request, no
merge, no deployment — and it never issues `AskUserQuestion`. Its only write is the GitHub
issue, assigned to the running identity so `/specificate`'s discovery ingests it.

**It posts nothing to Slack.** Reading the channel, answering on it and capturing an ask are the
tick's, not this command's (`commands/infinite-development.md`); a proposal is announced by
nobody, because the issue is assigned to exactly one person and GitHub already delivers it.

**Every skill section or reference file this run consults is read with the Read tool**,
never with `sed`, `grep`, `cat` or `head` (2026-09-02, issue #865): a shell read under the
plugin cache is a permission prompt an unattended run cannot answer.

**And both reaches take the checkout's own path** (`plugins/workaholic/…`), never `<src>` (2026-09-06, ticket `20260906185501`): a **Read** of `<src>` lands under the plugin cache whenever the registry tree wins the equal-version tie, and a `bash` call at that same path froze a runner even though `Bash(bash:*)` is allowlisted by prefix with no path term — the allowlist covers that call, and a path inside a `.claude/` directory is classified as Claude's own configuration by a judgement applied above it. So compose every call at `call_src`, which `plugin-src.sh` answers beside `src`: identical bytes, inside the workspace, and equal to `src` wherever no checkout holds that version. The reach is removed, not permitted.

**Every free-text slot below is written in Japanese, and so is this run's own reasoning and report** — the shape's label, step ids, status and reason words, slugs, branch names, `<@U…>` tokens and URLs are never translated, and a GitHub artifact stays English (`rules/interaction.md`, *The language of a post is the language its readers use*).

**And that Japanese must be read on first sight, not decoded** — the bar is an outcome, not a style preference: *a channel reader must understand what is being asked without opening the English record behind the link.* An established technical term keeps its ordinary katakana or English form (ビルド, CI, デプロイ, PR, and the repository's own `terms/` entries); the **meaning** of a title is translated, never its words; a title that resists translation is **paraphrased** in plain Japanese rather than transliterated. Measured: 「組み立てを止める」 for *fail the build* belongs as 「ビルドが落ちる」, a bare 「形」 for *shape* as 「投稿の型」, 「示せるという判定」 for *demonstrable verdict* as 「実証できたかどうかの判定」.

**It is not housekeeping, and it is not a document about the aim.** A drifted document, a
missing test, an inconsistent name are `/moderate`'s work. A proposal must commit to the
strategy: it names what it is chosen against, or it is not emitted. A tick that cannot name one
of the three moves reports `no_evolutionary_move` and opens nothing — a real answer, not a
failure. **A move that would produce documentation *about* an Aim whose subject is to build
something is refused as `describing_move`**; a move whose deliverable is a new cross-cutting
obligation nobody asked for is refused as `invented_obligation`; a `depth` move whose chain
roots in the loop's own earlier output is refused as `self_refining`.

**Every refusal is reported by name and every gate is mechanical**: a strategy that is closed,
not yours, past its date, cites no feedback record, already carries queued work, or already
carries an open proposal is skipped with that reason stated. Stage and `arrived`/`quiescent`
guide the hypothesis and ride the report; `観察中` permits observation work. A tick that cannot
read its own open proposals proposes nothing at all.

**The readings ride the report and gate nothing**: `pace`, `overdue`, `expiring`, `arrived` with
its residue, each un-acted operator-facing pull request, and how long each standing blocker has
been standing. A degraded read is named as degraded, never as an empty one — and a strategy the
survey refused `attribution_unreadable` is named with that word and no other, because a report
implying the tick judged what it could not read is the collapse the reading exists to end.

Invoke skills by their loaded `workaholic:` namespace; never read global plugin installs or
guess retired namespaces.
