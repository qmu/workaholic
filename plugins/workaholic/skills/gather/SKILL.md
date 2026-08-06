---
name: gather
description: Gather git context and ticket metadata in single calls.
allowed-tools: Bash
user-invocable: false
metadata:
  internal: true
---

# Gather

Bundled probes that emit JSON for the work flow. Each script is independent; preload this skill once and call whichever script you need.

## Git Context

Gathers all context needed for documentation subagents in a single shell script call.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/git-context.sh
```

Output:

```json
{
  "branch": "feature-branch-name",
  "base_branch": "main",
  "repo_url": "https://github.com/owner/repo",
  "archived_tickets": [".workaholic/tickets/archive/branch/ticket1.md", "..."],
  "git_log": "abc1234 First commit\ndef5678 Second commit"
}
```

Fields: `branch` (current branch), `base_branch` (default branch of the remote), `repo_url` (HTTPS form; SSH URLs are converted), `archived_tickets` (array of ticket paths for current branch), `git_log` (oneline log from base to HEAD).

## Ticket Metadata

Gathers all dynamic metadata values needed for ticket frontmatter in a single shell script call.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/ticket-metadata.sh
```

Output:

```json
{
  "created_at": "2026-01-31T19:25:46+09:00",
  "author": "developer@company.com",
  "filename_timestamp": "20260131192546"
}
```

Fields: `created_at` (ISO 8601 with timezone for frontmatter), `author` (git user email), `filename_timestamp` (YYYYMMDDHHmmss for the ticket filename).

## Ownership — who an artifact belongs to

**One reader, every artifact kind.** A mission has carried its owners in a plural `assignees` field since 2026-07-28; a **ticket** joined it on 2026-08-06 (P2), when its owner stopped being its directory (`.workaholic/tickets/todo/<user-slug>/`). Ownership-as-path cost three things: an unreadable queue and an empty one were the same observation, reassignment was a file move, and two ownership models coexisted with the queue using the worse one. So the oracle lives here, in the neutral skill, rather than beside either artifact.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/owners.sh <artifact-file>   # zero or more owners, one per line
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/owns.sh <artifact-file> [identity]
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/read-assignees.sh <file>    # the field-shape parser
```

`owners.sh` resolves the artifact's own plural `assignees` (through `read-assignees.sh`, the single parser of the field shape — inline-list and bare forms), falling back to a legacy singular `assignee` so nothing predating the plural field is orphaned. **Empty output means unowned**, which is a real state: team-owned work, claimable by anyone, never an error. A ticket's `author:` is deliberately *not* a tier — author is who wrote the spec and is immutable history, owner is who is to do it and is meant to change.

`owns.sh` answers the three-way question every consumer actually asks, in one word:

| verdict | meaning |
| ------- | ------- |
| `mine` | the identity is among the owners |
| `unowned` | nobody owns it — claimable |
| `other` | owned, and not by this identity |
| `unresolved` | owned, and this runner has no identity to compare against |

`unresolved` is its own answer rather than being folded into `other`. Both imply the same conservative action — do not offer it — but they are different **facts**, and collapsing them is the defect the whole change removes: "somebody else's" and "I cannot tell whose" must never render identically to an operator reading a survey. Comparison is by **slug** (`user-slug.sh`), not string equality, so `A@Qmu.jp` matches `a@qmu.jp` *and* a migration-stamped `a-qmu-jp` still matches its owner's email.

Every consumer reads through these — `/drive`'s survey, `/ticket`'s summary, `ship`'s todo check and concern lane, `list.sh`'s `relation`, `summary.sh`, and the mission lens — which is what keeps the queue a runner drains and the roadmap a developer is shown from disagreeing about whose work it is.

### The living migration

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/migrate-todo-owners.sh [tickets-root]
```

Moves `todo/<user-slug>/X.md` → `todo/X.md`, stamping `assignees: [<owner>]` derived from the directory it came from — the author's email when its slug matches that directory, the bare slug otherwise (the slug rule is lossy, so the email cannot be recovered from the path alone; both forms compare correctly because `owns.sh` compares by slug). A ticket that already names owners keeps them and is only moved: the field outranks the directory, always.

It runs from the **write** seams (`/ticket`'s publish step, `promote-icebox.sh`, `archive.sh`) and deliberately **not** from `plan-units.sh`, which documents itself as side-effect-free and runs inside claim worktrees. That is affordable because **every reader tolerates both layouts** (`-maxdepth 2`): the migration converges the tree, it never gates it. A reader that saw only the flat form would make an unmigrated checkout report an empty queue — the exact failure being removed.

It replaces `create-ticket/scripts/sweep-todo.sh`, which existed only to route strays *into* the per-user directories.

## Project Label

Emits a short label — the git repository's directory name, truncated to 12 characters — used as a `[label]` prefix at the start of interactive-prompt question text, so a developer running several Claude Code sessions across tmux panes can tell which repository a waiting dialog belongs to.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh
```

Output:

```json
{
  "project": "workaholic"
}
```

Field: `project` (repo-root basename, ≤12 chars for the header chip). Deliberately network-free — unlike `git-context.sh` it makes no `git remote` call, because it is invoked at prompt time on every question.

## Story Sections

Measures where a branch story's lines actually are, section by section, over any set of story files. It exists because the story template has been edited on assumption: four structural edits landed to make stories shorter and the mean grew instead, and nobody could say which section had absorbed the difference.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/story-sections.sh [--table] <story-file>...
```

Output (JSON by default; `--table` renders the same numbers aligned for a report):

```json
{
  "files": 9,
  "total_lines": 1140,
  "mean_lines": 126.7,
  "sections": [
    { "name": "Changes", "files": 9, "total": 281, "mean": 31.2, "blocks": 9 }
  ]
}
```

`mean` is per **story measured**, not per story carrying the section, so a section present in half the set contributes half as much — the question is what a story costs on average. `blocks` counts the `###` subsections beneath a section, which is what separates "long because it has many blocks" from "its blocks are verbose": Concerns held its block count across the two sets above while its lines per block rose 61%. Ordinals are stripped from heading names (`## 5. Concerns` and `## 6. Concerns` aggregate), frontmatter is excluded, and a `##` line inside a fence is body text rather than a heading.

**Control for workload before reading a delta.** Story length tracks how many tickets the branch drove, so compare sets holding that constant — the cleanest control is to restrict both sets to single-ticket stories. Dividing a whole set's lines by its ticket count is the wrong normalization: multi-ticket stories amortize the per-story overhead, so a heavier set looks *shorter* per ticket while every individual story got longer.
