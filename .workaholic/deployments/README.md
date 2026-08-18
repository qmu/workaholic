---
created_at: 2026-06-17T21:32:42+09:00
modified_at: 2026-08-13T00:00:00+09:00
---

# Deployments

**One record per delivery path.** Each file describes one deployment target: the
procedure to deploy/release it (`## Procedure`), and the specific, executable way to
confirm the deployment succeeded in production (`## Confirmation`). `/ship` reads these
entries (via `read-deployments.sh`) and will not complete a deployment unless an
established confirmation method exists for the target — the record **is** the evidence
the gate rests on.

## What it never holds

Credentials of any kind (see *Rules* below), a deploy **log**, or a record of what a run
actually did. A deployment record says what *should* happen and how to prove it did; the
history of what happened is git, the release records, and the stories.

## Who writes it, and when

**A human**, when a delivery path is created or changes. `/ship` is the only live
*reader* and never a writer: a record describes a procedure a person authored, so a
machine that rewrote it from a run would be recording what happened rather than what
should happen — and the next ship would gate on its own last behaviour.

## How staleness becomes visible

This area survived the 2026-08-13 layout reshape (issue #436) on one condition: that
"kept updated" stop being aspirational. `plugins/workaholic/skills/report/scripts/area-freshness.sh`
reports, for every record here and in `terms/`, how many days since its last commit and
whether it still names something this repository has retired. `/report` reads it beside
`doc-drift.sh`. It reports facts, never verdicts, and it never edits a record.

## The target ↔ environment mapping

**What this area answers, in one read.** Which deploy targets exist, which software
environment each one *is*, how each reaches production, and which part of the tree each
one ships:

```bash
bash plugins/workaholic/skills/ship/scripts/read-deployments.sh --mapping
```

Per target it emits `environment`, `deploy_model`, `paths` and `confirmation_method`,
each as `{"value": …, "source": …}` — **`declared` when the record states it,
`defaulted`/`undeclared` when it does not**. The distinction is the point: a defaulted
field is a decision nobody made, and this area's whole premise is that a delivery path is
declared rather than inferred. `report-deploy-status.sh` splices the same object under
`mapping`, so `/release-status` gains the per-target axis without a second command, and
it is deliberately **not** hashed into that report's `digest` — reformatting a record is
not news a human must act on.

**Gaps are named, never rendered as an empty result:**

| Gap | Means |
| --- | ----- |
| `no_targets` | there is no record here at all |
| `environment_undeclared` | a target that cannot be mapped to an environment |
| `path_attribution_undeclared` | no `paths:`, so this target claims the **whole range** — every commit on the base counts as unreleased for it, *including a commit that only writes its own note* |
| `unmatched_component` | a top-level component matching no target's declared `paths:` — it ships nowhere, or nobody claimed it |

`path_attribution_undeclared` is the one to read twice. `paths:` is optional and this
repository declares it on **0 of 1** targets, which is what makes any design that commits
a generated note to `main` count that note against itself.

**Nothing here writes a record.** For an undeclared target the reader offers a *blank*
scaffold and stops:

```bash
bash plugins/workaholic/skills/ship/scripts/read-deployments.sh --scaffold <slug>   # prints to stdout
```

The fields come out empty with the reasoning prompts inline, because the human who
authors this record is deciding where production is and how it is proved. A record
generated from the repository's shape would make the next `/ship` gate on a machine's
guess — the failure the `## Confirmation` gate exists to prevent.

## Deploy models

A target follows one of two models. Pick the one that matches how the target
actually reaches production, and write the `## Confirmation` accordingly.

**Deploy-from-branch** — deploy and confirm from the work branch, *then* merge.
The branch is shipped to production (or a production-equivalent target) before
the PR merges, so an unconfirmable change never reaches `main`. The whole
`## Confirmation` is a single pre-merge check. Use this when you control deploy
timing independently of the merge (e.g. `wrangler deploy` from the branch, then
probe the live URL).

```markdown
---
title: Production web — Cloudflare Workers
environment: production
confirmation_method: api-probe
url: https://example.com/healthz
---
## Procedure
1. `npx wrangler deploy`
## Confirmation
1. `curl -fsS https://example.com/healthz` returns `{"status":"ok"}` with the new build hash.
```

**Deploy-on-merge** — the merge *is* the deployment; the release is published
*from* the merge commit (by CI or `publish-release.sh`). Confirmation splits in
two: a **pre-merge** branch/staging proof that the artifact is production-ready,
and a **post-merge** check that the promotion is live. Use this when production
is defined by the merge itself (a marketplace/release published from `main`).
This repo's own target, [`marketplace.md`](marketplace.md), is the worked
example; its `## Confirmation` is explicitly labelled pre-merge (build/verify/
test/version) and post-merge (`gh release view v<version>`).

`/ship` runs the same flow for both — deploy + confirm before the merge, merge
last — but a deploy-on-merge target's pre-merge step proves readiness while its
post-merge step (Ship Flow step 7) confirms the live promotion. If you write a
deploy-on-merge target, split `## Confirmation` into a "Pre-merge" and a
"Post-merge" part so the two phases are unambiguous.

## File format

```markdown
---
type: Deployment
author: <git user.email>
created_at: <ISO 8601>
modified_at: <ISO 8601>
title: Production web — Cloudflare Workers
environment: production
confirmation_method: browser   # browser | server-batch | db-query | api-probe | other
url: https://example.com/healthz   # optional, non-secret locator
---

## Procedure

1. <copy-paste-executable deploy/release steps, e.g. `npx wrangler deploy`>

## Confirmation

1. <the exact, executable check that proves the deploy worked, e.g.
   "open https://example.com/healthz and confirm it returns {\"status\":\"ok\"}
   with the new build hash">
```

## Rules

- **Never commit secrets.** This directory is version-controlled. Credentials,
  tokens, and session cookies are NEVER written here. Locator fields hold only
  a URL, an endpoint name, or a command *template*. Credentials needed to run a
  confirmation are supplied transiently at ship time.
- Write the `## Procedure` and `## Confirmation` at copy-paste granularity — a
  concrete command/URL, not "deploy it" or "verify the deploy".
- `confirmation_method` must be one of: `browser`, `server-batch`, `db-query`,
  `api-probe`, `other`.

## Confirmation method prerequisites

Each method needs specific tooling at ship time. In a headless or CI ship
context that tooling may be absent, so a target with a declared method can
still be unconfirmable at run time. `/ship` runs an advisory capability check
(`check-confirmation-capability.sh`) before deploy and warns when the current
environment can't run the declared method.

| `confirmation_method` | Needs at ship time | Headless / CI |
| --------------------- | ------------------ | ------------- |
| `api-probe`    | `curl` or `wget` (network access to the endpoint) | runs headless |
| `db-query`     | a DB client (`psql`/`mysql`/`sqlite3`/`mongosh`) + connection | runs headless |
| `server-batch` | `ssh` + transient credentials (supplied at ship time, never persisted) | runs headless |
| `browser`      | an interactive agent with browser tooling | assumes interactive; not for CI |
| `other`        | whatever the `## Confirmation` body documents | depends — make it executable in the ship environment |

**For headless or CI ship contexts, prefer `api-probe` or `db-query`.** Reserve
`browser` for interactive ships. Whatever method a target declares, its
`## Confirmation` must be executable in the environment where `/ship` runs.
