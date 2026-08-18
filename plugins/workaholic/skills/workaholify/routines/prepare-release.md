---
type: Routine Template
id: prepare-release
name: "[Prepare Release] {repo_name}"
renamed_from: "[Release Status] {repo_name}"
scope: repository
trigger: schedule-hourly
trigger_kind: schedule
cron_expression: 45 * * * *
autofix_on_pr_create: false
model: claude-opus-5
allowed_tools: [Bash, Read, Glob, Grep]
mcp: [Slack]
---

# [Prepare Release] — the repository's one tick, and it writes nothing into the tree

**The record moved with the command this time, and it owes the operator a cutover**
(2026-08-18, issue #485). `/fullfill` became `/prepare-release` and this template's `id:`,
`name:` and filename followed, reversing the 2026-08-17 decision that deliberately held
them back. The mechanics that decision named have not gone away — `/setup-repo-routines`
converges an account's routines **by name**, so the next convergence **creates a second
routine** rather than renaming the operator's existing one, and a routine is an
account-level record no other account can list or delete. So the rename ships **with** its
one-time instruction instead of instead of it: an account already running
`[Release Status] <repo>` must **rename that routine in the UI**, not create a second, and
nothing in the plugin can detect or remove a duplicate on another account. The
`renamed_from:` field above is what carries that instruction into
`/setup-repo-routines`' report and its setup sheet; **delete the field once the fleet has
cut over** — it describes a migration, not the routine.

**The post shape moved too** (same change, the ticket's Open Decision 1): the root is
`📦 Prepare release`, not `📦 Release status`. The reason the 2026-08-17 ticket left it
alone — "the prefix is the notify lookup's own exact-string dedup key, so changing it
posts one duplicate line at the cutover" — was simply **not true**: the lookup searches
`` `deploy:<digest>` `` and never the prefix (`workaholic:notify`, *The repository tick's
status line*), so the heading carries no dedup weight and the cutover costs nothing. With
its one measured cost gone, the tie broke toward the ask's own stated goal — a heading
consistent with the command name.

**`scope: repository`** — the repository needs exactly **one** of this routine, configured
by one designated person or a project/service account through `/setup-repo-routines`.
This is the first repository-scoped template and the reason the scope exists: N copies
would each read the same base and post the same line into the same channel every hour,
and nothing in the product can detect or refuse the duplicates
(`workaholic:workaholify` §5, *Two scopes, two commands*).

**It writes nothing into the repository.** No file, no commit, no branch, no pull
request, no merge, no deployment — and no `AskUserQuestion`. The ask this template
answers was "run `/ship` once per hour to update the release notes" (issue #451); the
command is still **not** `/ship`.

**Since 2026-08-17 it does keep the notes current, and the shape is what makes that
safe** (issue #472). `workaholic:ship` §7 recorded three writer designs that were
measured and refused; the first — a merged note's plan is self-referential, because its
own refresh commit changes the count it reports — is answered not by a better writer but
by a home that is not a commit: each target's **GitHub draft release**, invisible to
consumers and free to rewrite. A draft that never enters git cannot count itself. The
other two refusals stand untouched: no open pull request's branch is written, and `/ship`
is never run. So the tick reports hourly and regenerates each target's draft **at most
once per `Asia/Tokyo` day**, plus immediately whenever the release stage advances; an
idle tick writes nothing and posts nothing.

Two frontmatter values differ from the developer-scoped pair, and both follow from the
contract rather than from taste: `autofix_on_pr_create: false` (this routine opens no
pull request, so the flag would declare a behaviour it can never reach — the setup sheet
renders no step for it) and an `allowed_tools` list with no `Write`/`Edit`. That list is
unchanged by the generation step and that is the point: the draft lives outside git, so
the routine still needs no ability to write a file, and the property is stated where the
product can act on it rather than only in prose.

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

Run `/prepare-release`.

If the command or its skills did not load, do not stop: run `bash plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` from the checkout, take its `src`, then read `<src>/commands/prepare-release.md` and follow it with every script path under `<src>`.

If something is waiting and the exact-string search for the digest token finds no earlier post, post this one line as a new top-level message (the workaholic:notify lookup) — no mention token of any kind:

```
📦 Prepare release - <N> commit(s) waiting on <target>
One sentence, max 25 words, what a human must do (cut a release, declare a confirmation method).
Draft note: <draft release URL>
`deploy:<digest>`
<session URL>
```

If nothing is waiting, or that search finds the same digest already posted, post nothing.
