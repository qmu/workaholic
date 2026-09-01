---
type: Deployment
author: a@qmu.jp
created_at: 2026-08-26T13:45:45+00:00
modified_at: 2026-08-26T13:45:45+00:00
title: Documentation site — Cloudflare Worker
environment: production
confirmation_method: api-probe
command: curl -fsS https://workaholic.qmu.co.jp/
url: https://workaholic.qmu.co.jp/
---

# Documentation site — Cloudflare Worker

The VitePress site under `docs/` is served at <https://workaholic.qmu.co.jp> by the
`workaholic-docs` Cloudflare Worker, an assets-only Worker defined by
`docs/wrangler.jsonc` whose `assets.directory` is the `docs/.vitepress/dist` that
`npm run docs:build` produces.

This is a **deploy-on-merge** target, the same shape as
[`marketplace.md`](marketplace.md): the merge to `main` is the deployment. The
`Docs Deploy` workflow (`.github/workflows/docs-deploy.yml`) builds and deploys on push
to `main` under `docs/**`, so the pre-merge confirmation is a branch-level proof that the
artifact builds, and the post-merge confirmation is a live check that the merged content
is what the hostname serves.

## Inactive until the Cloudflare secrets exist

**This target cannot deploy yet, and that is not a backlog.** The `Docs Deploy` workflow
skips its deploy step — and says so in the run's job summary — whenever
`CLOUDFLARE_API_TOKEN` or `CLOUDFLARE_ACCOUNT_ID` is unset. Two things a person holding
the Cloudflare account must do, once:

1. Add `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` as repository secrets.
2. Bind `workaholic.qmu.co.jp` to the `workaholic-docs` Worker as a custom domain in
   Cloudflare.

Until both are done, the build half runs on every documentation merge and nothing is
published, so `/prepare-release` reporting this target as waiting is reporting *this*,
not an unexplained arrears.

## Procedure

1. Merge to `main` a change that touches `docs/**` — this IS the deployment. The
   `Docs Deploy` workflow builds `docs/` and runs `npx wrangler deploy` from it.
2. For the **first** deploy, or for a change that alters the rendered site without
   touching `docs/**` (the workflow's `paths:` filter does not fire), run the workflow by
   hand: `gh workflow run docs-deploy.yml --ref main`, or the `Run workflow` button on
   the workflow's Actions page.
3. Nothing is deployed from a branch and nothing is deployed by hand from a checkout:
   `wrangler deploy` runs in CI, which is where the credential lives.

## Confirmation

Pre-merge (branch-level proof that the artifact is production-ready) — no Cloudflare
credential is needed for any of it:

1. `cd docs && npm ci && npm run docs:build` succeeds, and
   `docs/.vitepress/dist/index.html` exists.
2. `cd docs && npx wrangler deploy --dry-run` succeeds, reporting the file count it read
   from the assets directory — this is what proves `docs/wrangler.jsonc` still points at
   the directory the build actually writes.

Post-merge (the promotion is live) — run these against the merge commit, not against
"the site exists":

3. The `Docs Deploy` run for the merge commit is green **and its job summary does not
   report a skipped deploy**. A skipped deploy is a green run that published nothing.
4. `curl -fsS https://workaholic.qmu.co.jp/` returns HTTP 200 and the rendered
   `index.html`.
5. `curl -fsS https://workaholic.qmu.co.jp/<page>` returns a string the merge introduced
   — for a merge that edited `docs/routine-loop.md`, for example,
   `curl -fsS https://workaholic.qmu.co.jp/routine-loop.html | grep -q '<the new text>'`.
   Step 4 proves *a* site is up; only this step proves **this merge** is live.
6. `curl -sS -o /dev/null -w '%{http_code}' https://workaholic.qmu.co.jp/no-such-page`
   returns `404`. The Worker is configured with `not_found_handling: "404-page"`, and a
   misconfiguration that answers `200` for every unknown path would make step 5's `grep`
   the only thing standing between a soft 404 and a confirmed deploy.
