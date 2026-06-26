---
created_at: 2026-06-26T12:43:06+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on: [20260626124305-enforce-workaholic-layout-allowlist.md]
---

# `.workaholic/` layout doctor — one-shot audit of an existing tree against the allowlist

## Overview

The hook added by `20260626124305-enforce-workaholic-layout-allowlist.md` prevents *new*
undesignated directories from accreting, but it is file-write-triggered: it cannot retroactively
find the mess that already exists in a repo, and it never fires for directories created with bare
`mkdir`. A consumer repo that adopts the stricter version needs a way to **see what is already
wrong and how to fix it**.

This ticket adds a one-shot "doctor" script that audits an existing `.workaholic/` tree against
the **same canonical allowlist** the hook enforces, and prints a structured report of every
non-conforming path with a suggested remediation. Concretely, run against a tree that has
drifted, it should surface findings such as:

- `.trips/` → undesignated; suggest consolidating into the canonical `trips/`
- `tickets/done/` → invalid ticket state; suggest moving contents to `tickets/archive/<branch>/`
- `proposals/`, `research/` → undesignated top-level dirs; report for owner decision
- (advisory) trip-naming drift (`trip-*` vs `work-*`) and non-standard nested trip internals

It is a conformance audit, not an auto-mutation: it **reports** (and optionally suggests `git mv`
commands), leaving the destructive choice to the repo owner.

## Policies

The standard engineering policies that govern this ticket. The implementing session **MUST** read
each linked policy hard copy before writing code.

- `workaholic:implementation` / `policies/directory-structure.md` — the doctor measures conformance to the canonical layout this policy defines (applies to all layout work).
- `workaholic:implementation` / `policies/coding-standards.md` — fail-fast, declarative shell with no silent fall-through (applies to all code work).
- `workaholic:implementation` / `policies/command-scripts.md` — the doctor is a runnable script discoverable from one place, invoked identically by a developer and by CI; it reads the *same* allowlist the hook reads (no second list).
- `workaholic:implementation` / `policies/policy-conformance-audit.md` — this *is* a conformance audit: surface drift against the stated allowlist as actionable non-conformances rather than letting it become structural.
- `workaholic:operation` / `policies/observability.md` — output must be structured and actionable (path, why non-conforming, suggested fix), not free-form text; limit "findings" to things that genuinely need a human decision.

Repo-own rules (CLAUDE.md): **Shell Script Principle** (audit logic lives in a bundled
`skills/<name>/scripts/<script>.sh`, not inline), **Skill Script Path Rule** (`${CLAUDE_PLUGIN_ROOT}`),
and any new script-bearing skill carries `metadata.internal: true`.

## Key Files

- The canonical allowlist data file/script introduced by the foundation ticket — the doctor MUST read this, not redefine the list. (single source of truth)
- `plugins/workaholic/skills/create-ticket/scripts/sweep-todo.sh` — reference implementation of the bundled-script pattern: a self-contained `.sh` under `skills/<name>/scripts/` that walks `.workaholic/`, stages `git mv`s, and emits JSON. The doctor mirrors its shape (but reports rather than mutates by default).
- `plugins/workaholic/skills/drive/scripts/` — other examples of JSON-emitting workflow scripts to match output conventions.
- `scripts/test-workflow-scripts.mjs` — hermetic harness; add a doctor test that builds a throwaway `.workaholic/` tree with known violations and asserts the report enumerates exactly them.
- `plugins/workaholic/rules/workaholic.md` — the human-readable layout doc; the doctor's report should point back here for the canonical structure.

## Related History

The doctor extends the same enforcement lineage as its foundation ticket and reuses the
sweep-script pattern.

Past tickets that touched similar areas:

- [20260518235327-prohibit-tickets-outside-tickets-dir.md](.workaholic/tickets/archive/work-20260518-235327/20260518235327-prohibit-tickets-outside-tickets-dir.md) — Established the hook-level prohibition the doctor audits the *existing* tree against.
- [20260617210614-establish-deployments-directory-convention.md](.workaholic/tickets/archive/work-20260617-210627/20260617210614-establish-deployments-directory-convention.md) — Defines `.workaholic/` as a closed structure whose allowlist the doctor reports drift from.
- [20260613090209-per-user-todo-subdirectories.md](.workaholic/tickets/archive/work-20260528-122941/20260613090209-per-user-todo-subdirectories.md) — `sweep-todo.sh` precedent for a bundled tree-walking script that stages `git mv`s and emits JSON.

## Implementation Steps

1. **Add a bundled doctor script** under a skill's `scripts/` dir (e.g.
   `plugins/workaholic/skills/<host>/scripts/layout-doctor.sh`), invoked via `${CLAUDE_PLUGIN_ROOT}`.
   Choose the host skill to be the same one that owns the allowlist data file from the foundation
   ticket, so both read one list. If a new skill is created, set `metadata.internal: true`.

2. **Walk the target `.workaholic/` tree** (default: the repo's own `.workaholic/`; accept an optional
   path arg so it can be pointed at another repo). For every top-level entry, classify against the
   canonical allowlist: `ok` (in allowlist), `undesignated` (not in allowlist), or `misplaced-ticket-state`
   (under `tickets/` but not `todo/`/`icebox/`/`archive/`).

3. **Emit a structured report** (JSON for tooling + a human-readable summary). Each finding carries:
   the path, the classification, the reason, and a **suggested remediation** mapping where one is
   obvious — `.trips/` → `trips/`, `tickets/done/` → `tickets/archive/<branch>/`. For truly unknown
   dirs (`proposals/`, `research/`), report them as "owner decision required" without a guessed target.

4. **Add advisory (non-failing) checks** for known drift the top-level allowlist can't express:
   trip directory naming (`trip-*` vs canonical `work-*`) and non-standard nested trip internals
   (`designs/reviews/`, `models/reviews/`). Mark these `advisory` so they inform without being treated
   as hard violations.

5. **Optionally print copy-pasteable `git mv` suggestions** for the obvious remediations, but **never
   mutate** the tree automatically — the doctor reports; the owner decides. (Mirror `sweep-todo.sh`'s
   JSON shape but drop the auto-`git mv`.)

6. **Make it runnable consistently** — document the invocation in `rules/workaholic.md` (or a short
   skill section) so a developer and CI run the identical command (`command-scripts` / `ci-cd` policy).

7. **Add a hermetic smoke test** in `scripts/test-workflow-scripts.mjs`: build a throwaway repo whose
   `.workaholic/` contains `.trips/`, `tickets/done/x.md`, `proposals/p.md`, plus valid `tickets/todo/`,
   `stories/`, `trips/work-.../designs/`; run the doctor; assert the report lists exactly the three
   violations (with correct classifications and the two known remediation mappings) and zero false
   positives on the valid dirs.

8. **Verify locally.** `node scripts/test-workflow-scripts.mjs`; `node scripts/build-plugins/verify.mjs`
   (and `build.mjs` only if a workflow skill's script closure changed).

## Considerations

- **Read the allowlist, never redefine it.** The whole value of the foundation ticket's single source
  of truth is lost if the doctor hard-codes its own copy. Depend on the same data file. (single source of truth)
- **Report, don't auto-fix.** Moving `tickets/done/` into `archive/<branch>/` or collapsing `.trips/`
  into `trips/` are destructive, repo-specific decisions (which branch? merge or keep separate?). The
  doctor surfaces and suggests; it must not `rm`/`mv` without the owner running the suggestion. This
  matches the `policy-conformance-audit` framing (track non-conformances as debt, don't silently rewrite).
- **Empty undesignated dirs.** Because the hook is file-write-triggered, an empty undesignated directory
  can exist; the doctor (a full tree walk) is the only thing that finds it. Decide whether an empty
  undesignated dir is a finding or ignored (git doesn't track empty dirs, so likely advisory-only).
- **Avoid false positives on `concerns/archive/` and `tickets/archive/<branch>/`.** Nested allowed
  paths under an allowed top-level dir are fine; only flag the top-level entry classification and the
  `tickets/` sublocation rule. (`plugins/workaholic/rules/workaholic.md`)
- **Pointing at another repo** via the optional path arg is a convenience for auditing a consumer
  repo from outside; ensure the arg doesn't assume the doctor runs from inside the target repo's git root.
