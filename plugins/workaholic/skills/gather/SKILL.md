---
name: gather
description: Gather git context and ticket metadata in single calls.
allowed-tools: Bash
user-invocable: false
metadata:
  internal: true
---

# Gather

Bundled probes that emit JSON for the work flow. Each script is independent; preload this skill once and call whichever you need.

## Git Context

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/git-context.sh
```

Returns `{branch, base_branch, repo_url, archived_tickets, git_log}` — the current branch, the remote's default branch, the HTTPS repo URL (SSH forms converted), the current branch's archived ticket paths, and the oneline log from base to HEAD.

## Ticket Metadata

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/ticket-metadata.sh
```

Returns `{created_at, author, filename_timestamp}` — ISO 8601 with timezone for frontmatter, the git user email, and the `YYYYMMDDHHmmss` stamp for the ticket filename.

## Ownership — who an artifact belongs to

One reader for every artifact kind (missions since 2026-07-28; tickets since P2, 2026-08-06, when a ticket's owner stopped being its `todo/<user-slug>/` directory). The oracle lives in this neutral skill so no consumer parses the field itself.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/owners.sh <artifact-file>   # zero or more owners, one per line
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/owns.sh <artifact-file> [identity]
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/read-assignees.sh <file>    # the field-shape parser
```

`owners.sh` resolves the artifact's plural `assignees` (through `read-assignees.sh`, the single parser of the field shape), falling back to a legacy singular `assignee` so nothing predating the plural field is orphaned. Empty output means unowned — team-owned, claimable by anyone, never an error. A ticket's `author:` is deliberately not a tier: author is who wrote the spec, immutable history; owner is who is to do it, meant to change.

`owns.sh` answers the ownership question in one word:

| verdict | meaning |
| ------- | ------- |
| `mine` | the identity is among the owners |
| `unowned` | nobody owns it — claimable |
| `other` | owned, and not by this identity |
| `unresolved` | owned, and this runner has no identity to compare against |

`unresolved` is its own answer, never folded into `other`: both imply "do not offer it", but "somebody else's" and "I cannot tell whose" are different facts and must never render identically in a survey. Comparison is by slug (`user-slug.sh`), not string equality, so `A@Qmu.jp` matches `a@qmu.jp` and a migration-stamped `a-qmu-jp` still matches its owner's email.

Every consumer reads through these — `/drive`'s survey, `/ticket`'s summary, `ship`'s todo check and concern lane, `list.sh`'s `relation`, `summary.sh`, the mission lens — which is what keeps the queue a runner drains and the roadmap a developer sees from disagreeing about whose work it is.

### The living migration

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/migrate-todo-owners.sh [tickets-root]
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/migrate-ticket-states.sh [tickets-root]
```

Moves `todo/<user-slug>/X.md` → `todo/X.md`, stamping `assignees` from the directory it came from (the author's email when its slug matches that directory, else the bare slug — both compare correctly because `owns.sh` compares by slug). A ticket that already names owners keeps them and is only moved: the field outranks the directory, always. It runs from the write seams (`/ticket`'s publish step, `promote-icebox.sh`, `archive.sh`) and deliberately not from the side-effect-free `plan-units.sh`; every reader tolerates both layouts (`-maxdepth 2`), so the migration converges the tree rather than gating it. It replaces the retired `create-ticket/scripts/sweep-todo.sh`, which routed strays the other way.

`migrate-ticket-states.sh` is its sibling and runs at the same seams: it folds the retired `tickets/abandoned/` and `tickets/icebox/` directories into `tickets/archive/unbranched/`, carrying the state in frontmatter (`status: abandoned` / `status: icebox`) instead of in a path (2026-08-13, issue #436 — P2's *state is a field, not a directory* applied to ticket state). `archive/unbranched/` because the archive is keyed by the branch that **drove** a ticket and neither of these was ever driven. It stamps before it moves (so a failed stamp leaves the ticket where it was), never touches the body, never touches a ticket that already carries a `status:` — which is what makes a second run report `migrated: 0` — and refuses a filename collision rather than guessing, exactly as its sibling does. Emits `{"migrated": N, "moves": [{from, to, status}]}`.

`status:` on a ticket is the one state axis, and **absent means queued**: `done` (stamped by `archive.sh` when a ticket passes its gate), `abandoned`, `icebox`. `promote-icebox.sh` **clears** the field when it returns a ticket to `todo/`, because a queued ticket carrying an end state is one every survey correctly refuses to offer.

## Project Label

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh
```

Returns `{project}` — the repo-root basename, truncated to 12 characters — the `[label]` prefix for interactive-prompt question bodies, so a developer with several sessions open can tell which repository is asking. Deliberately network-free (no `git remote` call), because it runs at prompt time on every question.

## Commit KPI

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/commit-kpi.sh [window]
```

Orchestration-throughput KPI derived from git history over a `git log --since` window (default "1 week"): `{window, total_commits, agent_commits, agent_share, median_changed_lines, p90_changed_lines, oversize_commits}`. It measures how well the agent fleet is orchestrated, never human output; its policy guards are documented with the catch skill.

## Story Sections

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/story-sections.sh [--table] <story-file>...
```

Measures where a branch story's lines actually are, section by section, over any set of story files: `{files, total_lines, mean_lines, sections: [{name, files, total, mean, blocks}]}` (`--table` renders the same numbers aligned). `mean` is per story measured, not per story carrying the section, so a section present in half the set contributes half as much. `blocks` counts `###` subsections, separating "long because many blocks" from "its blocks are verbose". Ordinals are stripped from heading names, frontmatter is excluded, and a `##` line inside a fence is body text.

## Caveats

- Control for workload before reading a story-length delta: story length tracks ticket count, so compare sets restricted to single-ticket stories — dividing a set's lines by its ticket count makes a heavier multi-ticket set look shorter per ticket (the template was edited four times on that assumption while the mean grew).
