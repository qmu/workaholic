---
created_at: 2026-08-12T16:35:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy: review
---

# Stop making the harness plugin binding a precondition of a run

## Overview

Every unattended run reached its own scripts through `${CLAUDE_PLUGIN_ROOT}` — the
plugin root the harness bound at session start — and `/drive` §1 terminated `pending`
whenever `check-deps/scripts/check.sh` reported that binding behind the registry
(`loaded_version_behind_registry`). The gate was written to stop a run from executing
*stale* scripts, after a stale `claims.sh` offered five already-driven tickets as fresh
backlog and a tick claimed one (2026-08-04).

Measured 2026-08-12, live: the cloud container binds a **project-scope** install baked
into its image (v1.0.133, commit `77c462d`, 2026-08-06), while the SessionStart
bootstrap runs `claude plugin update`, which reports "√ Plugin updated from 1.0.133 to
1.0.159 **for scope user**" and never touches the project-scope pin. Project scope wins
the binding. Because every tick is a fresh container off that same image, the gate fired
hourly and could not self-heal: **twelve consecutive `[Implement]` ticks terminated
before surveying** while three claimable tickets sat in `todo/` and a checkout at the
registry's own version (1.0.159) sat on disk untouched.

The developer's ruling (2026-08-12, live): the harness binding is not something the loop
may depend on. A current copy of the plugin is present on the VM in every one of these
failures — the run must find it and use it. This is the same reasoning already recorded
for `unbound_in_claude_session` (FB `20260810070110`, `rules/general.md`), which this
ticket generalizes to the stale-binding axis it was deliberately withheld from.

## Policies

- `workaholic:implementation` / `policies/error-handling-and-resilience.md` — a run must degrade rather than stop when a usable input is present
- `workaholic:implementation` / `policies/observability.md` — the degraded state is reported, never silent
- `workaholic:operation` / `policies/deployment-and-release.md` — the container image and registry are the delivery path this failure lives on

## Key Files

- `plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` — new resolver
- `plugins/workaholic/skills/check-deps/SKILL.md` — the field's meaning and the resolver's contract
- `plugins/workaholic/skills/drive/SKILL.md` §1 + `reference/survey.md` — the gate being demoted
- `plugins/workaholic/rules/general.md` — the general rule this generalizes
- `plugins/workaholic/skills/workaholify/routines/implement.md`, `fb.md` — routine prompts
- `plugins/workaholic/skills/notify/SKILL.md` + `reference/notifications.md` — the precondition-stop class
- `plugins/workaholic/skills/workaholify/bootstrap/session-start.sh` — the header whose recorded evidence is wrong

## Implementation Steps

1. Write `check-deps/scripts/plugin-src.sh`: return the **newest** plugin tree on the
   machine — checkout (`<project>/plugins/workaholic`), the newest registry
   `installPath`, a clone at `$WORKAHOLIC_SRC_HOME`, the bound root — ties going to the
   checkout, with `source`, `version`, `degraded` and the full candidate list reported.
2. Demote the gate: `loaded_version_behind_registry` (and `registry_unreadable`, and the
   field's absence) become warnings; `no_plugin_source` becomes the one terminal stop.
   Update `/drive` §1, `reference/survey.md`, the failure-contract table, and
   `check-deps/SKILL.md`.
3. State it generally in `rules/general.md`: the binding is an input, never a
   precondition — unbound *and* stale resolve the same way.
4. Give both routine templates a bootstrap fallback, so a tick whose command never bound
   reads `<src>/commands/<name>.md` and follows it rather than ending.
5. Narrow `workaholic:notify`'s precondition-stop class to `no_plugin_source`, since the
   two former members no longer terminate anything.
6. Correct the `session-start.sh` header: its "exactly ONE entry" evidence is false, and
   that error is what kept the diagnosis at "the image is behind".
7. Record honestly what a degraded run does **not** repair: hooks and the policy lens
   belong to whatever the harness bound.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- With the binding at 1.0.133 and the checkout at 1.0.159, the resolver selects the
  checkout and reports `degraded: true`.
- In a repository that carries no `plugins/` tree, the resolver still selects a current
  tree (the registry `installPath`) without any network access.
- When the binding is already the newest tree, the resolver selects it and reports
  `degraded: false`.
- No documented stop remains for a merely superseded binding; `no_plugin_source` is the
  only terminal outcome of the step.
- The generated bundle and the policy index are in sync, and the hermetic suite passes.

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` under each of the
  three environments above (`CLAUDE_PLUGIN_ROOT` / `CLAUDE_PROJECT_DIR` set explicitly).
- `node scripts/build-plugins/build.mjs`, `verify.mjs`, `validate-metadata.mjs`,
  `node scripts/test-workflow-scripts.mjs`, `bash plugins/workaholic/hooks/layout-doctor.sh .`

**Gate** — what must pass before approval:

- All three resolver scenarios behave as specified, the verification suite is clean, and
  the limits of the degraded mode (hooks, policy lens) are written down rather than
  implied.

## Considerations

- **Merging this does not by itself unblock the fleet.** A tick's `/implement` command
  body comes from the *bound* plugin, so a container still binding an old build reads the
  old rule. The live routine prompts carry the bootstrap fallback and are what actually
  break the loop; `RemoteTrigger` is not exposed to a routine-fired session, so updating
  them is a developer act in the routines UI (or `/setup-routines` from an attended
  session).
- Preferring the newest tree can only move a run forward on the staleness axis, which is
  precisely the property the demoted gate protected — that is what makes the demotion
  safe rather than merely permissive.
- The registry `installPath` candidate needs no network: the bootstrap has already
  downloaded that version, it simply is not what got bound.
- Left open: whether the bootstrap should also update or remove the project-scope
  install. It cannot help the session it runs in (binding precedes hooks) and every tick
  is a fresh container, so it was judged out of scope here.

## Final Report

**Outcome: implemented.** Reconstructed after the fact, at the developer's instruction:
the work was driven and pushed first (during the incident this ticket describes), and the
ticket and story were written afterwards to restore the record. The unit landed on
`claude/nifty-ramanujan-hn0rpm` rather than a `work-*` branch, for the same reason.

- `plugin-src.sh` added (216 lines, POSIX `sh`, `jq`-optional): candidates are compared
  by `sort -V` — the same comparator `check.sh` uses, so the two can never disagree about
  which version is newer — and ties fall to the checkout.
- All three acceptance scenarios verified live: binding 1.0.133 + checkout 1.0.159 →
  `checkout` / `degraded: true`; no `plugins/` tree → `registry` at 1.0.159, no network;
  binding newest → `degraded: false`.
- Gate demoted in `/drive` §1, `reference/survey.md` and the failure-contract table (the
  superseded-binding row now reports rather than terminates); `check-deps/SKILL.md` gained
  a *Resolving the source to run from* section.
- `rules/general.md`'s bullet was rewritten from "an unbound skill surface" to "the
  harness's plugin binding is an input, never a precondition", covering both axes.
- Both routine templates carry the fallback preamble; `notify`'s precondition-stop class
  narrowed to `no_plugin_source` with the two departures recorded.
- `session-start.sh`'s header correction landed in the canonical copy
  (`skills/workaholify/bootstrap/`) and the installed copy was re-synced from it.
- Verified: `verify.mjs` clean, `validate-metadata.mjs` version-aligned, `layout-doctor`
  conforming, `test-workflow-scripts.mjs` **2252 passed / 0 failed**. Regenerating
  `outputs/` also picked up a pre-existing drift (`propose/scripts/list-inbound-issues.sh`
  had never been carried into the bundle).
- The `CLAUDE.md` plugin-boundary rule was amended: `plugin-src.sh` is now the one
  sanctioned crossing to a global install path, and the reason is stated inline.
