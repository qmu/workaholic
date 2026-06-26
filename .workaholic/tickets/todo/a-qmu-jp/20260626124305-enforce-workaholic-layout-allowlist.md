---
created_at: 2026-06-26T12:43:05+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Infrastructure]
effort:
commit_hash:
category:
depends_on:
---

# Enforce the canonical `.workaholic/` layout via a single-source allowlist + Write/Edit hook

## Overview

The `.workaholic/` tree is documented as a "closed, fixed structure," but nothing
machine-enforces it. The only structural guard today, `plugins/workaholic/hooks/validate-ticket.sh`
(a PostToolUse `Write|Edit` hook), reasons **only about ticket-shaped files**
(`YYYYMMDDHHmmss-*.md`) and ticket sub-locations (`todo/`, `icebox/`, `archive/`).
Any non-ticket file written into an undesignated subdirectory under `.workaholic/`
passes silently.

The cost of this gap shows up in practice: in a long-lived consumer repo, agents accrete
undesignated directories that no rule prevents — for example:

- `.trips/` — a dotted duplicate of the canonical `trips/`, holding three old `trip-*`-named trips
- `tickets/done/` — an invented ticket state (the only terminal state is `archive/<branch>/`)
- top-level `proposals/` and `research/` — neither is a designated subdirectory

This ticket makes the canonical layout **a single source of truth** and has the existing
hook **reject** any file write that lands outside it, so a user can enforce the structure
strictly instead of relying on agent goodwill. It is the foundation for the companion
"doctor" audit ticket (`20260626124306-workaholic-layout-doctor-report.md`), which reads
the same allowlist to report pre-existing violations in a repo.

It generalizes the May 2026 predecessor that first rejected misplaced *tickets*
(`work-20260518-235327/20260518235327-prohibit-tickets-outside-tickets-dir.md`) from
"ticket-shaped-file misplacement" to "any undesignated directory under `.workaholic/`."

## Policies

The standard engineering policies — synced from qmu.co.jp into the `workaholic` policy
skills — that govern this ticket. The implementing session **MUST** read each linked policy
hard copy before writing code and keep every change defensible against that policy's Goal
(目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — this change *is* an instance of "find files from structure, not exploration"; enforcing the canonical layout is enforcing this policy. The enforcement code must itself land in a predictable place (the existing `hooks/` + a bundled skill `scripts/`).
- `workaholic:implementation` / `policies/coding-standards.md` — the new shell logic must be fail-fast and declarative, with no silent fall-through (applies to all code work).
- `workaholic:implementation` / `policies/command-scripts.md` — the allowlist must be a single canonical definition that both the hook and the companion doctor script read; CI invokes the same script a developer runs, never a re-implementation.
- `workaholic:operation` / `policies/observability.md` — hook output must be explainable from the outside: a clear, structured, actionable message (what was rejected, where, why, what to do). The strict/warn toggle is the enforcement lever; default to non-alarmist behavior and escalate to blocking only on explicit opt-in ("no alerts that cry wolf").
- `workaholic:operation` / `policies/ci-cd.md` — the check must be reproducible locally and in CI via the same command, consistent with the existing `verify.mjs` / Outputs Freshness pattern.

Repo-own architecture rules (CLAUDE.md) that constrain *how* this is built:

- **Shell Script Principle** — no complex inline shell in markdown; the allowlist comparison and toggle branching live in a bundled script under `skills/<name>/scripts/`, not inline in the hook prose. (The hook itself is already a script, so a focused regex/lookup block inside it is acceptable; extract to a shared script if the logic is reused by the doctor.)
- **Skill Script Path Rule** — any skill-script reference uses `${CLAUDE_PLUGIN_ROOT}/skills/.../scripts/X.sh`. Hooks reference their own bundled scripts via `${CLAUDE_PLUGIN_ROOT}/hooks/...`.
- **Single source of truth** — exactly one canonical allowlist definition; `rules/workaholic.md` must not drift from what the hook enforces.
- **Cross-Agent Skill Exposure** — if a *new* script-bearing skill is introduced, it MUST carry `metadata.internal: true`. Hooks are Claude-Code-only and excluded from `outputs/`, so a hook-only change needs no `outputs/` rebuild (verify with `verify.mjs`).

## Key Files

- `plugins/workaholic/hooks/validate-ticket.sh` — the existing and only structural guard. The allowlist check slots in **before** the `Skip non-ticket paths` early-return (lines 37-40), which is exactly what lets undesignated non-ticket dirs through today. (lines 23-40 are the current ticket-shape + early-return block; lines 42-59 the ticket-location block.)
- `plugins/workaholic/hooks/hooks.json` — hook registration (PostToolUse `Write|Edit` → `validate-ticket.sh`). No new registration needed if the check stays inside `validate-ticket.sh`; update the `description` string to mention layout enforcement.
- `plugins/workaholic/rules/workaholic.md` — the existing human-readable allowlist table (lines 8-16). **Stale and must be reconciled** (see Considerations): it lists `terms/` but omits `concerns/`, `trips/`, and `release-notes/`, all created/used by live scripts.
- `plugins/workaholic/skills/trip-protocol/scripts/init-trip.sh` — `mkdir -p`s `.workaholic/trips/<trip>/{directions,models,designs,reviews,...}` (line ~32); proves `trips/` is a legitimate top-level dir the allowlist MUST permit. Also note it creates dirs via `mkdir`, not `Write`, so the hook only fires when a *file* is written into a subdir, not on bare directory creation.
- `plugins/workaholic/skills/create-ticket/SKILL.md` — the "Allowed Locations / PROHIBITED" prose (lines 26-37) the hook's error message points at; keep it consistent with the enforced list.
- `scripts/test-workflow-scripts.mjs` — hermetic smoke-test harness. `validate-ticket.sh` currently has **no** coverage; the `testPolicyLens` case (≈ lines 670-726, feeding a `{tool_input:{file_path}}` JSON payload on stdin and asserting exit status) is the exact pattern to mirror.

## Related History

Direct lineage of `.workaholic/` structure enforcement: this generalizes the ticket-misplacement
guard, reuses the lens-vs-safeguard hook architecture, and treats the most recent allowlist
amendment as the source of truth to reconcile against.

Past tickets that touched similar areas:

- [20260518235327-prohibit-tickets-outside-tickets-dir.md](.workaholic/tickets/archive/work-20260518-235327/20260518235327-prohibit-tickets-outside-tickets-dir.md) — Direct predecessor; added the exact `validate-ticket.sh` block (lines 29-35) this ticket reuses/extends, and the two-layer hook+prose pattern.
- [20260617210614-establish-deployments-directory-convention.md](.workaholic/tickets/archive/work-20260617-210627/20260617210614-establish-deployments-directory-convention.md) — Established `.workaholic/` as a "closed, fixed structure" whose allowed-subdir table lives in `rules/workaholic.md`; defines where the single-source allowlist the strict guard reads must live.
- [20260618115347-policy-lens-userpromptsubmit-hook.md](.workaholic/tickets/archive/work-20260618-115347/20260618115347-policy-lens-userpromptsubmit-hook.md) — The hooks.json architecture and the lens-vs-safeguard distinction (non-blocking lens vs blocking `exit 2`) the warn/strict toggle must respect.
- [20260613090209-per-user-todo-subdirectories.md](.workaholic/tickets/archive/work-20260528-122941/20260613090209-per-user-todo-subdirectories.md) — Most recent change to `validate-ticket.sh`'s location regex; precedent for extending the same hook's path validation and following the smoke-test discipline.
- [20260124112456-enforce-specs-subdirectory-structure.md](.workaholic/tickets/archive/feat-20260124-105903/20260124112456-enforce-specs-subdirectory-structure.md) — Earliest allowed-directory-table + prohibition precedent, one level deeper (inside `specs/`).

## Implementation Steps

1. **Reconcile the canonical allowlist (resolve the stale source of truth).** Determine the
   authoritative set of permitted top-level `.workaholic/` subdirectories by cross-referencing
   `rules/workaholic.md` against what live scripts actually create/read. The reconciled set is:
   `concerns/` (with `concerns/archive/`), `deployments/`, `release-notes/`, `specs/`, `stories/`,
   `terms/`, `tickets/`, `trips/`. Plus root files: `README.md` (and any existing root README
   variants). Confirm each against a `grep -r '\.workaholic/' plugins/ scripts/` sweep so the
   list is grounded in code, not folklore. **Correction to note:** `terms/` *is* legitimate
   (it is in `rules/workaholic.md`); the genuine violations to reject are dirs like `proposals/`,
   `research/`, `.trips/`, and `tickets/done/`.

2. **Encode the allowlist as the single machine-readable source.** Add one canonical list the
   hook reads — a plain newline-delimited data file (e.g. `plugins/workaholic/hooks/workaholic-layout-allowlist.txt`,
   or a small bundled script that emits the list) — so the shell hook does not parse the markdown
   table. The companion doctor ticket reads the *same* file. Then update `rules/workaholic.md`'s
   table to match exactly (add `concerns/`, `trips/`, `release-notes/`; keep `terms/`), and note in
   that file that the list is enforced by the hook. Avoid two divergent lists: either generate the
   table from the data file or add a verify check asserting they agree.

3. **Extend `validate-ticket.sh` with a top-level allowlist gate.** Insert a new block after the
   existing ticket-shaped-misplacement check (line ~35) and **before** the `Skip non-ticket paths`
   early-return (line ~37). Logic: if `file_path` is under `.workaholic/`, extract the first path
   segment after `.workaholic/`; if it is a root file, allow only the permitted root files; otherwise
   if the first segment is not in the allowlist, reject. Keep the per-segment extraction and lookup
   in a bundled script if it grows beyond a couple of `case`/regex lines (Shell Script Principle).

4. **Close the `tickets/done/` class of bug.** The first segment `tickets` IS allowed, so the
   allowlist alone won't catch `tickets/done/`. Tighten the existing ticket-location check (lines
   42-59) so that **any** file under `.workaholic/tickets/` that is not in `todo/`, `icebox/`, or
   `archive/<branch>/` is rejected — regardless of whether the filename is ticket-shaped (today the
   check only fires for `YYYYMMDDHHmmss-*.md` names because of the early return at line 37). Be careful
   not to reject legitimate non-ticket files the pipeline writes under `tickets/` (audit for any;
   if none, the stricter rule is safe).

5. **Add a warn/strict toggle (don't break existing consumer repos overnight).** Default the new
   layout gate to **warn** (message to stderr, `exit 0` — non-blocking) and escalate to **block**
   (`exit 2`) only when a per-repo opt-in is set. Pick one explicit mechanism: an env var
   (e.g. `WORKAHOLIC_STRICT_LAYOUT=1`) and/or a committed marker the repo owner adds (e.g. a
   `strict_layout: true` line in a `.workaholic/` config file). Document the toggle in
   `rules/workaholic.md`. Rationale: the existing ticket-shape and ticket-location rejections stay
   hard-blocking (unchanged); only the *new* broad layout gate is toggleable, so a repo that
   has already accreted drift isn't suddenly unable to write until it's cleaned up.

6. **Author a self-explaining rejection message.** On reject, print: the offending path, the
   first-segment that is not allowed, the canonical allowed set, and a one-line remediation hint
   (e.g. "did you mean `trips/`?" for `.trips/`). Reuse `print_skill_reference` to point at the
   create-ticket / rules doc.

7. **Add the first smoke tests for `validate-ticket.sh`.** In `scripts/test-workflow-scripts.mjs`,
   mirror `testPolicyLens`: feed the hook a `{tool_input:{file_path: ...}}` payload on stdin and
   assert exit status. Cover **reject (strict on)**: `.workaholic/proposals/x.md`, `.workaholic/.trips/x.md`,
   `.workaholic/research/x.md`, `.workaholic/tickets/done/y.md`. Cover **allow**: `.workaholic/tickets/todo/<user>/<ts>-t.md`,
   `.workaholic/stories/s.md`, `.workaholic/deployments/d.md`, `.workaholic/concerns/c.md`,
   `.workaholic/trips/<name>/designs/x.md`, `.workaholic/README.md`. Cover **warn (default)**:
   undesignated path exits 0 but writes the warning to stderr.

8. **Run local verification.** `node scripts/build-plugins/verify.mjs` (hook-only change should be
   vacuously fresh; confirms nothing in `outputs/` drifted) and `node scripts/test-workflow-scripts.mjs`.
   Only run `node scripts/build-plugins/build.mjs` if a *workflow skill or its script closure* was
   touched — a hook-only change does not require an `outputs/` rebuild.

## Considerations

- **Stale source-of-truth conflict (must resolve first).** `rules/workaholic.md` lists `specs/`,
  `stories/`, `terms/`, `tickets/`, `deployments/` but omits `concerns/`, `trips/`, and `release-notes/`,
  which live scripts create/read. If the hook encoded only the markdown table verbatim it would reject
  legitimate `trips/` and `concerns/` writes. The reconciliation in Step 1 is the crux; ground the list
  in a `grep` of the codebase, not in the (incomplete) doc. (`plugins/workaholic/rules/workaholic.md` lines 8-16)
- **The guard is file-write-triggered, not `mkdir`-triggered.** `init-trip.sh` and others create
  directories with `mkdir -p`, which never fires a `Write`/`Edit` hook. So an *empty* undesignated
  directory cannot be caught by this hook — only the first file written into it. That is acceptable
  (an empty dir is harmless and git ignores it), but the doctor report (companion ticket) is what
  catches already-existing undesignated dirs regardless of how they were made. (`plugins/workaholic/skills/trip-protocol/scripts/init-trip.sh`)
- **Trip naming + internal layout drift is out of scope here.** Consumer repos also show `trip-*`
  vs `work-*` trip naming and non-standard nested `designs/reviews/`, `models/reviews/`. This ticket
  enforces only the *top-level* `.workaholic/` allowlist (plus the `tickets/` sublocation rule). Deep
  per-trip internal validation is a separate concern; the doctor report can flag it advisorily.
- **Default-warn vs default-block is a deliberate policy call.** Per `operation/observability`,
  default to warn and require explicit opt-in to block, so adopting the new version does not brick a
  repo mid-flight. The *existing* hard rejections (ticket shape, ticket location) are unchanged and
  stay blocking. (`plugins/workaholic/hooks/validate-ticket.sh`)
- **Keep the two prose docs in sync with the enforced list.** `create-ticket/SKILL.md` lines 26-37
  enumerate prohibited dirs as examples; if that list and `rules/workaholic.md` and the hook's data
  file disagree, the contract is ambiguous. Prefer one data file + generated/verified prose.
- **No `outputs/` rebuild for a hook-only change**, but if Step 2 introduces a new script-bearing
  skill, it must carry `metadata.internal: true` and you must re-run `build.mjs`/`verify.mjs`.
