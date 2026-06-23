---
created_at: 2026-06-17T21:32:42+09:00
modified_at: 2026-06-17T21:32:42+09:00
---

# Deployments

Each file in this directory describes **one deployment target** — the
procedure to deploy/release it, and the specific, executable way to confirm
the deployment succeeded in production. `/ship` reads these entries (via
`read-deployments.sh`) and will not complete a deployment unless an
established confirmation method exists for the target.

## File format

```markdown
---
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
