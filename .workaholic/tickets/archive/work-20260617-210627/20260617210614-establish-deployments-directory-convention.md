---
created_at: 2026-06-17T21:06:14+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Infrastructure]
effort: 1h
commit_hash: ea70c13
category: Changed
depends_on:
---

# Establish the `.workaholic/deployments/` convention

## Overview

Introduce a new `.workaholic/deployments/` directory that holds the project's
deployment contract: per-target markdown files that each describe **(a)** the
deployment / release procedure and **(b)** the specific, executable way we
confirm the deployment succeeded in production. This ticket establishes the
convention only — the directory, its place in the fixed `.workaholic/`
structure, the per-file frontmatter schema, and a reader script that the
`/ship` workflow will consume. Wiring `/ship` to *require* a documented
confirmation method is the dependent follow-up
(`20260617210615-require-verified-deployment-confirmation-in-ship.md`).

The motivation: today `/ship` learns how to deploy and verify from optional
`## Deploy` / `## Verify` sections in `CLAUDE.md`, and a missing section causes
ship to **silently skip** verification. That is the opposite of the policy we
want — a deployment with no established way to confirm it succeeded should not
be shippable. To gate on that, the confirmation method first needs a durable,
version-controlled home, which is what `.workaholic/deployments/` provides.

`.workaholic/` is a **closed, fixed structure** (`rules/workaholic.md` lists
exactly `specs/`, `stories/`, `terms/`, `tickets/` and instructs agents to
refuse any directory outside the list). Adding `deployments/` is therefore a
deliberate amendment to that rule and its frontmatter schema table — not an
ad-hoc `mkdir`.

## Key Files

- `plugins/workaholic/rules/workaholic.md` - The allowed-subdirectory table (lines 8-16) and the "Additional fields per subdirectory" table (lines 44-51). Both must gain a `deployments/` row, plus a request-mapping hint ("deploy steps" / "release procedure" → `deployments/`).
- `plugins/workaholic/skills/ship/scripts/` - Home for the new reader script (`read-deployments.sh`). Lives under the ship skill so it joins ship's build closure when the dependent ticket references it.
- `plugins/workaholic/skills/report/scripts/list-active-carryovers.sh` - Canonical pattern for a `.workaholic/` frontmatter-corpus scanner: resolves the dir, `read_field`/`read_body` via `awk`, JSON-escapes via `python3`/`node`/`perl`, skips `README.md`, emits a JSON array. The new reader should mirror it almost line-for-line.
- `plugins/workaholic/skills/ship/scripts/check-todo.sh` - Pattern for a guard script that returns a `{clean, count, ...}` JSON shape consumed by an AskUserQuestion gate; the deployments reader should return a comparably shaped object so the dependent ticket can branch on it.

## Related History

The `/ship` deploy-and-verify convention has a well-documented lineage but has never enforced verification as a hard precondition; it has always *skipped* when the deploy/verify spec is absent. This ticket adds the missing data-source layer that a future hard gate consumes.

Past tickets that touched similar areas:

- [20260528091259-ship-deploy-doc-from-claude-md.md](.workaholic/tickets/archive/work-20260528-091259/20260528091259-ship-deploy-doc-from-claude-md.md) - Moved ship's deploy/verify source-of-truth to `CLAUDE.md` `## Deploy`/`## Verify`; this ticket adds a structured alternative/companion source under `.workaholic/deployments/`.
- [20260311105613-add-ship-drive-command.md](.workaholic/tickets/archive/drive-20260310-220224/20260311105613-add-ship-drive-command.md) - Origin of the externalized "instruction file tells ship how to deploy/verify" idea; the deployment markdown files are its structured successor.
- [20260617001707-publish-github-release-on-ship.md](.workaholic/tickets/archive/work-20260617-000311/20260617001707-publish-github-release-on-ship.md) - Most recent ship-skill change; establishes the bundled-script convention and the outputs/-regen + smoke-test discipline any new ship script follows.

## Implementation Steps

1. **Amend `rules/workaholic.md`**:
   - Add a `deployments/` row to the allowed-subdirectory table: purpose "Deployment/release procedures and their success-confirmation methods".
   - Add a `deployments/` row to the "Additional fields per subdirectory" table defining the schema (see step 2).
   - Add a request-mapping hint to the Guidelines list so "deploy steps", "release procedure", "how to verify a deploy" route to `deployments/` rather than being refused.
2. **Define the per-file frontmatter schema** (each file = one deployment target). On top of the mandatory `author` / `created_at` / `modified_at`:
   - `title` - human label (e.g. "Production web — Cloudflare Workers").
   - `environment` - the target environment (e.g. `production`, `staging`).
   - `confirmation_method` - an enum the reader can branch on: `browser` | `server-batch` | `db-query` | `api-probe` | `other`. This is the field that answers "is there an established way to confirm success?".
   - Optional locators kept **non-secret**: `url` / `endpoint` / `command` (the confirmation surface), never credentials.
3. **Define the file body shape** (documented in `rules/workaholic.md` and/or a `README.md` template under `deployments/`): a `## Procedure` section (the deploy/release steps, copy-paste executable) and a `## Confirmation` section (the exact, executable check — a URL to open and what to look for, a batch command to run on the server, a DB query and expected row, etc.). Granularity must be executable, not abstract (per the Capacity & Recovery policy).
4. **Add `plugins/workaholic/skills/ship/scripts/read-deployments.sh`**, modeled on `list-active-carryovers.sh`:
   - Resolve the repo's `.workaholic/deployments/` (handle absent dir → return an empty, "no confirmation method" result, do not error).
   - For each `*.md` (skipping `README.md`), read `title`, `environment`, `confirmation_method`, optional `url`/`endpoint`/`command`, and the `## Procedure` / `## Confirmation` body sections.
   - Emit a single JSON object the ship gate can branch on, e.g.
     `{"has_confirmation": <bool>, "count": N, "deployments": [ {title, environment, confirmation_method, url, procedure, confirmation} ]}`.
     `has_confirmation` is true only when at least one entry carries a non-empty `confirmation_method` and `## Confirmation` body.
   - Reuse the `read_field` / `read_body` / `escape_json` helpers verbatim from `list-active-carryovers.sh`; keep it POSIX-compatible per `rules/shell.md`.
5. **Do NOT regenerate `outputs/` in this ticket.** `read-deployments.sh` is not yet referenced by `skills/ship/SKILL.md`, so it is outside ship's build closure (`computeClosure` only bundles scripts referenced from the SKILL.md). The regen happens in the dependent ticket once `SKILL.md` references the script. (If a build is run anyway, ensure no `outputs/` diff is committed from this ticket alone.)
6. **Verify** with `node scripts/build-plugins/verify.mjs` and `node scripts/test-workflow-scripts.mjs` (and add a hermetic smoke test for `read-deployments.sh` if step 4 lands here rather than in the dependent ticket).

## Considerations

- `.workaholic/` is a closed structure; this amendment is the *only* sanctioned way to add `deployments/`. The validation surfaces that scan `.workaholic/` (the ticket-validation hook, drive/report scanners) must not treat the new directory as a stray (`plugins/workaholic/rules/workaholic.md`, `plugins/workaholic/hooks/`).
- **Secrets safety**: `.workaholic/deployments/*.md` is version-controlled. Credentials, tokens, and session cookies must NEVER be written into these files. Frontmatter locators stay non-secret (a URL, an endpoint name, a command *template*). Actual credentials are supplied transiently at ship time (handled in the dependent ticket) and per `workaholic:system-safety` are never persisted to shell profiles or global config (`plugins/workaholic/skills/system-safety/SKILL.md`).
- **operation:CI/CD policy** — the confirmation method recorded in-repo is the codebase "answering for itself" whether a deploy is good, rather than relying on knowledge in one person's head; deployment facts should stay traceable (`plugins/workaholic/skills/operation/policies/ci-cd.md`).
- **implementation:Observability policy** — the `## Confirmation` section should map to *business-health* verification (does it actually work in business terms), the strongest of the three health-check kinds (`plugins/workaholic/skills/implementation/policies/observability.md`).
- **implementation:Capacity & Recovery policy** — write the procedure and confirmation at copy-paste granularity (a concrete command/URL, not "verify the deploy"); a confirmation method is not trusted until it has actually been executed (`plugins/workaholic/skills/implementation/policies/operational-planning.md`).
- **Shell rule** — all logic (dir resolution, field parsing, the `has_confirmation` decision) lives in the bundled `read-deployments.sh`; no inline conditionals/pipes in markdown. Reference it as `${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/read-deployments.sh` (`CLAUDE.md` Shell Script Principle / Skill Script Path Rule).
- The existing allowed-list already omits `release-notes/` and `concerns/` (used by ship) — pre-existing drift. Consider noting it, but fixing that drift is out of scope for this ticket.

## Final Report

Development completed as planned, with one corrected assumption (see insight).

Implemented: amended `plugins/workaholic/rules/workaholic.md` (added `deployments/` to the allowed-subdirectory table, the per-subdirectory frontmatter schema table — `title`/`environment`/`confirmation_method` enum + optional non-secret `url`/`endpoint`/`command` locators, the required `## Procedure`/`## Confirmation` body sections, and a "never commit secrets" warning — plus a request-mapping hint); added the POSIX `read-deployments.sh` reader under `plugins/workaholic/skills/ship/scripts/`; and created `.workaholic/deployments/README.md` as the convention's concrete template. Verified the reader against both an empty/README-only directory (`has_confirmation:false`) and a synthetic entry (`has_confirmation:true`, fields and `## Procedure`/`## Confirmation` parsed, valid JSON). build/verify/validate-metadata/smoke all pass.

### Discovered Insights

- **Insight**: The build does NOT bundle ship scripts by per-script SKILL.md reference — it copies the *entire* `plugins/workaholic/skills/ship/scripts/` directory into `outputs/workflows/skills/ship/ship/scripts/`. So adding `read-deployments.sh` produced an `outputs/` entry immediately, even though no SKILL.md references it yet.
  **Context**: The ticket's step 5 assumed `computeClosure` includes a script only once SKILL.md references it, and therefore that this ticket should leave `outputs/` untouched. That is false for a skill's *own* scripts dir. The regenerated `outputs/workflows/skills/ship/ship/scripts/read-deployments.sh` was committed with this ticket; omitting it would have failed the Outputs Freshness CI. Future tickets adding a script to an existing built skill should expect — and commit — the corresponding `outputs/` copy.
- **Insight**: The `outputs/workflows/skills/<skill>/<skill>/scripts/` doubled path (e.g. `ship/ship/scripts/`) is the normal generated layout for a skill's own scripts, not a bug.
  **Context**: Sibling skills' scripts are nested one level under the target skill dir (`ship/branching/scripts/`, `ship/gather/scripts/`), and the skill's own scripts mirror that as `ship/ship/scripts/`.
