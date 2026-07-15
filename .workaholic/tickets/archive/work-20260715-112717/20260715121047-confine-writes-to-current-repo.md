---
type: enhancement
layer: [Domain, Config]
created_at: 2026-07-15T12:10:47+09:00
author: a@qmu.jp
depends_on: []
---

# Confine every workflow's writes to the current repository

## Motivation

An agent working inside one repository carried that repository's context into a
different repository's committed artifacts. The write validated as perfectly
conformant, because nothing in the chain ever asks *which repository* the target
belongs to.

The root cause is not a missing gate. It is that the rule was never distributed.
The convention "keep motivation generic, never name other repos/clients" is cited
in `CLAUDE.md:268` and `skills/release-scan/SKILL.md:41` as a *standing* rule that
the scan "machine-enforces" — but both citations were written on 2026-07-14, and
the rule they cite has no body anywhere in the plugin. Its only real existence was
a per-project agent memory file, which loads only when working in this repository.
Five sibling repositories were contaminated by the same mechanism over four weeks;
four of them are repositories where that memory never loaded. The rule reached one
site in five, and four of the five incidents happened at the four sites it did not
reach.

So this ticket does two things: it gives the confinement rule a body inside the
plugin (where the plugin's distribution carries it to every repository), and it
closes the path-resolution hole that let the write look legitimate.

## Upstream dependency (not this repo's work)

The **policy** statement — "customer context must not be carried into another
repository's artifacts" — belongs in the company security standard at
qmu.co.jp `/safety`, not in this plugin. `plugins/workaholic/skills/safety/policies/`
is a synced mirror; anything hand-written there is overwritten by the next
`workaholic-standards-sync` run. The controller polls hourly and opens a PR here
automatically, so once the article is authored upstream the mirror arrives on its own.

This ticket therefore covers only the plugin-side mechanism. It must not edit
`skills/safety/policies/*`.

**Circular-dependency note:** authoring that upstream article is itself a
cross-repository change, which after this ticket lands is only permitted through
`/request` — which does not exist until the sibling ticket ships. Author the
upstream article by hand before, or accept that the first `/request` is used for it.

## Key Files

- `plugins/workaholic/hooks/validate-ticket.sh:116` — `tickets_path="${file_path#*.workaholic/tickets/}"`
  discards everything *before* `.workaholic/tickets/`, so an absolute path into a
  foreign repo reduces to a valid-looking suffix and passes. This is the incident's
  exact write path. Note it is PostToolUse — it fires after the file exists.
- `plugins/workaholic/hooks/guard-ticket-structure.sh:46` — extractor regex begins at
  `.workaholic/tickets/`, so the repo prefix is outside the match by construction.
- `plugins/workaholic/skills/create-ticket/SKILL.md:36-47` — `## Allowed Locations`
  constrains only the path suffix, never which repository.
- `plugins/workaholic/skills/create-ticket/scripts/sweep-todo.sh:24` — `TODO_ROOT=".workaholic/tickets/todo"`,
  a bare relative path resolved against the ambient cwd.
- `plugins/workaholic/skills/gather/scripts/git-context.sh:9` — `ROOT="$(git rev-parse --show-toplevel ...)"`,
  the existing sanctioned repo-root idiom to reuse.
- `plugins/workaholic/rules/` — where the plugin-side rule text lands.

## Implementation Steps

1. Write the confinement rule into the plugin's own rules so it ships to every
   repository that installs the plugin: every workflow writes only inside the
   current repository or one of its worktrees; crossing to another repository is
   permitted **only** through `/request`. State it as a rule with a body, not as a
   citation of a rule held elsewhere.
2. Reference that rule from `skills/create-ticket/SKILL.md`'s `## Allowed Locations`,
   so the rule is in front of the agent at the moment it composes a ticket path.
3. Add a repo-root resolution step to the ticket write path: resolve the intended
   target against `git rev-parse --show-toplevel`, and accept it only when it is
   inside that root **or** inside one of `git worktree list`'s entries. The
   worktree case is not optional — missions run in `.worktrees/<slug>/`, and a naive
   "must be under $PWD" check breaks the mission model.
4. Correct `CLAUDE.md:268` and `skills/release-scan/SKILL.md:41`. Both currently claim
   the scan machine-enforces a standing convention. The scan reads
   `git diff <base>..HEAD` only, so it never sees content already merged, and its
   denylist rule is skipped silently when the git-ignored file is absent. Neither
   sentence is true as written; say what the scan actually does.
5. Update `README.md` and `.workaholic/README.md` for the confinement rule.

## Considerations

- **Do not solve this with a hook.** A `PreToolUse` hook sees a path and a content
  string. It can reject an absolute path to a foreign repo — worth doing, and step 3
  covers the deterministic part — but the substance of what leaked (a component name,
  a document filename, a mail label, an internal hostname) is semantic and was not
  enumerable in advance. A pattern matcher cannot recognise it. The control that
  actually worked, empirically, during this investigation was a judgment applied at
  the moment content crossed a boundary, not a matcher.
- The existing guards are documented as fail-open by deliberate convention
  (`guard-ticket-structure.sh:30-35`, `validate-ticket.sh:53-54`). Step 3 should state
  where it sits on that spectrum rather than inherit it silently.
- There are currently **no tests at all** for `validate-ticket.sh` or
  `guard-ticket-structure.sh`.
- Hooks and rules are Claude-Code-only and have no `outputs/` footprint, so no
  rebuild. `create-ticket` **is** built into `outputs/workflows` — editing its
  SKILL.md requires `node scripts/build-plugins/build.mjs`.

## Policies

- `implementation/directory-structure` — the rule and guard land in the conventional
  `rules/` and `hooks/` locations.
- `implementation/coding-standards` — POSIX `#!/bin/sh -eu`; no bash.
- `implementation/command-scripts` — the containment decision belongs in a named,
  runnable script so agent, developer, and CI reach the same verdict.
- `design/defense-in-depth` — a boundary starts closed; a layer that rejects nothing
  is nominal. This is the policy the current fail-open posture contradicts.
- `design/access-control` — the containment check is defined once and called from
  every entry point; no path may bypass it.
- `safety/standard` — §6/§7: no mention of other clients' engagements, no unconsented
  disclosure. This is the rule the plugin-side mechanism serves.
- `safety/risk-management` — name and accept the residual: a deliberate bypass remains
  possible, and that must be recorded rather than treated as impossible.

## Quality Gate

**Acceptance is measured at the sites that failed, not in this repository.**

Test-green is explicitly *not* the gate: 538 tests passed green throughout the
four weeks in which five repositories were contaminated.

1. **The rule is visible where it was missing.** Open a session in a sibling
   repository that has the plugin installed (`research` is the honest test — it is
   one of the four sites the old convention never reached) and confirm by observation
   that the confinement rule actually loads into context there. This is the direct
   test of the root cause. If the rule does not appear, the ticket has failed
   regardless of anything else.
2. **The foreign write is refused.** Attempt a ticket write to another repository's
   `.workaholic/tickets/todo/<user>/` by absolute path, and by `../` relative path.
   Both must be refused, and the refusal must name `/request` as the sanctioned route.
3. **The mission model still works.** A ticket write inside a `.worktrees/<slug>/`
   worktree must still succeed. A confinement that breaks worktrees is a regression,
   not a fix.
4. Hermetic cases for 2 and 3 in `scripts/test-workflow-scripts.mjs` (throwaway repos,
   real worktrees), since neither hook has any test today.
