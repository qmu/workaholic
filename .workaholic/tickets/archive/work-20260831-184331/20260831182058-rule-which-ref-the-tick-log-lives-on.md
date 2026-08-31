---
created_at: 2026-08-31T18:20:58+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: take-the-moderation-tick-s-log-off-main
merge_policy:
verification_handoff: 
---

# Rule which ref the tick log lives on

## Overview

PROPOSED. The operator ruled the direction — the tick log moves to a dedicated ref
in this same repository — and left the ref itself to be answered. This ticket
answers it once, in writing, so the six tickets after it implement one decision
rather than each inventing their own: **which ref**, **how it is created on a
repository that has never had one**, **how a fresh container fetches it**, and
what the two mechanisms that already read refs must say about it.

The namespace question is already measured and must not be re-opened by guess:
`drive/reference/claims.md` records that `refs/claims/*` answers `RPC failed; HTTP
403` on create **and** on delete over both transports, and that `refs/heads/*` is
the only writable namespace in a routine's container. A design that needs a
custom namespace is therefore not implementable where it has to run.

Two mechanisms already read `refs/heads/*` and both need an explicit rule about
the new ref, or it will be misread the hour it appears:

- `drive/scripts/list-claims.sh` — **unmerged remote branches are the only claim
  oracle**, so a log ref under `refs/heads/` is a claim candidate unless it is
  excluded by name.
- `hooks/guard-git-branch.sh` — exactly two literal branch patterns are
  permitted (`work-YYYYMMDD-HHMMSS`, `release/YYYYMMDD-HHMMSS`); everything else
  is blocked at the agent's Bash surface.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — an operational log is read, not reviewed

## Key Files

- `plugins/workaholic/skills/moderate/SKILL.md` — the tick log's model; the new
  ref's name, creation and fetch are stated here, once, as the mechanism's home.
- `plugins/workaholic/skills/drive/reference/claims.md` — the measured 403
  evidence for `refs/claims/*` and the `refs/heads/*` writability finding.
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — the claim oracle
  that must not read the log ref as a claim.
- `plugins/workaholic/hooks/guard-git-branch.sh` — the branch-name gate.
- `plugins/workaholic/rules/workaholic.md`, `CLAUDE.md` — the current statement
  that the tick "commits its own log to the base through the publish tree".

## Implementation Steps

1. **Reproduce the constraint before designing against it.** In this container,
   attempt one push into a non-`refs/heads/` namespace and record the exact
   response beside `claims.md`'s. A design built on a namespace that answers 403
   here is unimplementable, and finding that out in ticket 2 costs the mission.
2. Establish how a routine's container sees refs today: what the clone's
   refspec fetches, whether it is shallow, and what a single named ref costs to
   fetch. Record the commands and their measured output.
3. Decide the ref, and write the decision down with its reason: the name, the
   namespace it sits in, and why a reader that already walks `refs/heads/*`
   (`list-claims.sh`) will not confuse it with a claim.
4. Decide how it is created on a repository that has never carried one — the
   first tick creates it, or `/workaholify` does — and state which, with the
   failure mode of the other named.
5. Decide how a fresh container reaches it, as an exact command with its bound
   and its named failure (a fetch that cannot reach the ref is a degradation the
   tick reports, never a silent empty log).
6. Write the ruling into `workaholic:moderate` as the mechanism's one home, and
   update `CLAUDE.md` and `rules/workaholic.md` in the same change.
7. State, in the same place, what `list-claims.sh` and `guard-git-branch.sh` must
   each say about the ref. Implementing them is ticket 2's; **naming** them is
   this ticket's, so ticket 2 has one specification to satisfy.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `workaholic:moderate` names the ref, its creation path, and the exact fetch a
  fresh container runs, each with its named failure mode.
- The namespace choice cites the measured response from step 1, not `claims.md`
  alone.
- `CLAUDE.md` and `rules/workaholic.md` no longer say the tick commits its log to
  the base, and say what it does instead.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `bash plugins/workaholic/hooks/layout-doctor.sh .`
- Read back the three documents and confirm no surface still describes the
  publish-tree-to-base path for the log.

**Gate** — what must pass before approval:

- The push probe in step 1 was actually run and its output is quoted in the
  ruling. A ruling that only cites an earlier document has not measured anything.

## Considerations

- The ref is not a branch anybody drives, so nothing about the claim protocol,
  the heartbeat or the worktree model changes. Say so explicitly, or a later
  reader will assume it does.
- Ticket 5 rules on the history already on `main`; this ticket rules only on
  where new log writes go. Keep them apart.

## Final Report

Development completed as planned. The ruling is written into `workaholic:moderate`
(*Where the log lives, and why it is not `main`*) as the mechanism's one home, with
`rules/workaholic.md` and `CLAUDE.md` updated in the same change so no surface still
describes the publish-tree-to-base path for the log.

The ruling, in four parts:

- **The ref is `refs/heads/workaholic/moderation-log`**, an orphan history whose tree
  carries only `.workaholic/moderations/<UTC-day>.md`. The namespace is forced by a
  measurement taken in this container, not inherited from `claims.md`: pushing the base
  tip into `refs/moderations/*`, `refs/claims/*` and `refs/notes/*` each answered
  `error: RPC failed; HTTP 403`, and the response is quoted in the ruling.
- **The first tick that needs the ref creates it**, seeding it from the checkout. The
  `/workaholify` alternative is named with its failure mode: an attended command run
  rarely means a repository whose operator has not run it loses every tick's log
  silently, which is the degradation the mission exists to remove.
- **A fresh container reaches it through one bounded fetch**, quoted as an exact command,
  with `log_ref_unreachable` and `log_ref_absent` as its two named failures. A fetch that
  could not reach the ref is reported, never rendered as an empty log.
- **The two ref-walking mechanisms each get a rule**: `list-claims.sh` excludes the ref by
  name; `guard-git-branch.sh` is left alone, deliberately, because the creation path is a
  push and not a local branch-creation surface.

### Discovered Insights

- **Insight**: `guard-git-branch.sh` cannot see the log ref's creation at all. Its
  tokenizer tracks only `checkout`/`switch`/`branch`/`worktree`; a `git push
  <sha>:refs/heads/<name>` sets `gitseen=1`, fails to match a tracked subcommand, resets
  and allows.
  **Context**: The ticket anticipated widening the guard. Widening it would have added a
  permitted name to a gate that never sees this path — cost with no benefit. The correct
  answer was to bind the *publisher* to the push form instead, which is why the ruling
  says the suite pins that the publisher creates no local branch.

- **Insight**: `lib/claims.sh`'s claim scan already rejects a log ref, but incidentally —
  its fast filter is `a Claim a PR-unit commit in the unmerged range`, and a log ref has
  none.
  **Context**: That is a backstop whose validity depends on nothing on the ref ever
  carrying a claim subject, which nobody is watching. Recording it as a backstop and
  making the by-name exclusion the rule keeps the property from silently becoming
  incidental again.

- **Insight**: An orphan history is not just tidiness. `git rev-list --count main..<ref>`
  over unrelated histories returns the log ref's whole commit count, so a claim scan that
  reached the ahead-count test would pay for it on every scan.
  **Context**: The by-name exclusion is placed before the ahead-count test for this
  reason, not only for correctness.
