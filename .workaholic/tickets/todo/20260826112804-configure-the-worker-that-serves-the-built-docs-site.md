---
created_at: 2026-08-26T11:28:04+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deploy-the-docs-site-on-merge-to-main
merge_policy:
verification_handoff: 
---

# Configure the Worker that serves the built docs site

## Overview

PROPOSED. The first of three: the Worker that will serve the built site, configured and
provable **without** a Cloudflare credential and without deploying anything. VitePress
already builds to `docs/.vitepress/dist` via `npm run docs:build`; what is missing is the
Worker that serves that directory as static assets.

Separated from the deploy workflow deliberately: this half is authorable and checkable
offline (`wrangler deploy --dry-run` needs no token), while the half that actually
deploys needs the account. Getting the configuration right first means the credentialed
step has nothing left to debug.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `docs/wrangler.jsonc` — NEW. The Worker definition: name, `compatibility_date`, and an
  `assets` binding whose `directory` is `docs/.vitepress/dist`. A modern static-asset
  Worker needs no handler script; if one is required, it is a few lines beside this file.
- `docs/package.json` — READ, and extend only if needed. `docs:build` already produces
  the directory the assets binding points at; do not rename it.
- `docs/.vitepress/config.mjs` — READ. Confirm `base` and `outDir` agree with what the
  assets binding is told; a mismatch here is the failure this ticket exists to catch
  before the credentialed step.
- `.gitignore` — `docs/.vitepress/dist` and `docs/node_modules` must not be committed.
- `docs/package-lock.json` — READ. It is what makes `npm ci` reproducible in the next
  ticket; adding `wrangler` as a devDependency here updates it.

## Implementation Steps

1. Read `docs/.vitepress/config.mjs` and run `npm ci && npm run docs:build` inside
   `docs/`. Record what `docs/.vitepress/dist` actually contains — the assets binding is
   configured against the real output, never an assumed path.
2. Add `wrangler` as a devDependency of `docs/` so the configuration is checkable from a
   clean checkout, and commit the lockfile change with it.
3. Write `docs/wrangler.jsonc`: the Worker name, a `compatibility_date`, and the `assets`
   binding pointing at the build output. Prefer the assets-only form — no handler script
   unless the dry run says one is required.
4. Confirm SPA-versus-static routing matches VitePress's output: it emits real `.html`
   files, so `not_found_handling` should serve `404.html`, not rewrite everything to
   `index.html`. Getting this wrong makes every deep link a soft 404 that still returns
   200, which no smoke test would catch later.
5. Prove it offline: `npx wrangler deploy --dry-run` from `docs/` succeeds with no token
   present. That is this ticket's whole gate.
6. Do **not** add secrets, a workflow, a route or a custom domain here — those are the
   next ticket's, and they are the parts that need the account.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `npx wrangler deploy --dry-run` succeeds from `docs/` with no Cloudflare credential in
  the environment.
- The assets directory the configuration names is exactly what `npm run docs:build`
  produces.
- Nothing built or installed is committed.

**Verification method** — the commands/tests/probes that prove them:

- `npm ci && npm run docs:build` inside `docs/`, then `npx wrangler deploy --dry-run`.
- `git status --porcelain docs/` is clean after a build.

**Gate** — what must pass before approval:

- The dry run passes with no token, and no secret, workflow or route is added.

## Considerations

- The ask names a **Worker**, not Pages. That is followed literally; a Worker with a
  static-assets binding is the current way to serve a built site, so no fork arises.
- `wrangler` pulls a large dependency tree into `docs/`. It stays a devDependency of that
  package only, so nothing in the plugin's own verification chain gains a dependency.
