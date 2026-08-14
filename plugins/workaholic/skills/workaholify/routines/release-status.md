---
type: Routine Template
id: release-status
name: "[Release Status] {repo_name}"
scope: repository
trigger: schedule-hourly
trigger_kind: schedule
cron_expression: 45 * * * *
autofix_on_pr_create: false
model: claude-opus-5
allowed_tools: [Bash, Read, Glob, Grep]
mcp: [Slack]
---

# [Release Status] — the repository's one tick, and it writes nothing

**`scope: repository`** — the repository needs exactly **one** of this routine, configured
by one designated person or a project/service account through `/setup-repo-routines`.
This is the first repository-scoped template and the reason the scope exists: N copies
would each read the same base and post the same line into the same channel every hour,
and nothing in the product can detect or refuse the duplicates
(`workaholic:workaholify` §5, *Two scopes, two commands*).

**It is a reader.** No file, no commit, no branch, no pull request, no merge, no
deployment — and no `AskUserQuestion`. The ask this template answers was "run `/ship`
once per hour to update the release notes" (issue #451); the command is **not** `/ship`,
and the tick does not update the notes. `workaholic:ship` §7 records the three writer
designs that were measured and refused — a merged note's plan is self-referential (its
own refresh commit changes the count it reports), an open pull request's branch belongs
to whoever holds its claim, and `/ship` merges. What is left is the strongest honest
thing: check the plan and say what a human has to act on. The precedent is this
repository's own `area-freshness.sh` — *it reports, it never writes*.

Two frontmatter values differ from the developer-scoped pair, and both follow from the
reader contract rather than from taste: `autofix_on_pr_create: false` (this routine opens
no pull request, so the flag would declare a behaviour it can never reach — the setup
sheet renders no step for it) and an `allowed_tools` list with no `Write`/`Edit`, which
is the contract stated where the product can act on it.

**Two gates make an idle tick silent**, and they are the reason a recurring post is
allowed at all under `workaholic:notify`'s bright line: nothing waiting (`actionable:
false`) posts nothing, and an answer already posted (the `deploy:<digest>` search finds
it) posts nothing. The digest hashes the substantive per-target state and deliberately
not the base sha, so a base that merely advanced is not news.

**The prompt is the developer's own** (P3, Q2) and states no rule a skill already owns:
`workaholic:ship` owns the read and its refusals, `workaholic:notify` owns every
notification rule, and the always-loaded `rules/` own the standing prohibitions. The one
literal format below stays embedded because a routine cannot defer its own output
contract, and `workaholic:notify`'s `reference/notifications.md` mirrors it verbatim as
the sole sanctioned shape for this event (P10) — a future edit to either copy is a drift
to fix, never a second wording. No repository is named in the prompt (P7); `{repo}`
does not appear at all, because this line links no pull request.

## Prompt

Run `/release-status`.

If the command or its skills did not load, do not stop: run `bash plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` from the checkout, take its `src`, then read `<src>/commands/release-status.md` and follow it with every script path under `<src>`.

If something is waiting and the exact-string search for the digest token finds no earlier post, post this one line as a new top-level message (the workaholic:notify lookup) — no mention token of any kind:

```
📦 Release status - 14 commit(s) waiting on marketplace
One sentence, max 25 words, what a human must do.
`deploy:<digest>`
<session URL>
```

If nothing is waiting, or that search finds the same digest already posted, post nothing.
