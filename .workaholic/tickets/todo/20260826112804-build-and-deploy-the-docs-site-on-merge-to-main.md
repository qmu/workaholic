---
created_at: 2026-08-26T11:28:04+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deploy-the-docs-site-on-merge-to-main
merge_policy:
verification_handoff: The Cloudflare account: an API token and account id must be added as repository secrets, and workaholic.qmu.co.jp must be bound to the Worker as a custom domain. An unattended run holds neither the account nor the DNS.
---

# Build and deploy the docs site on merge to main

## Overview

PROPOSED. The deploy path itself: a GitHub Actions workflow that builds `docs/` and
publishes it to the Worker on merge to `main`, so the site behind
<https://workaholic.qmu.co.jp> follows the base with no human step.

This ticket declares `verification_handoff` because the last mile is a **third-party
account this repository's unattended runs do not hold**: the Cloudflare API token and
account id must be added as repository secrets, and the hostname must be bound to the
Worker as a custom domain. The code is fully authorable and reviewable here; only the
proof that the live site serves the base is a person's act. The pull request therefore
opens and stays open with its `## Handoff` quoting exactly that.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `.github/workflows/docs-deploy.yml` — NEW. Build and deploy on push to `main`.
- `.github/workflows/release-note-draft.yml` — READ FIRST, as the in-repo precedent for a
  workflow that holds a credential, defines its own checkout rather than inheriting one,
  and **skips cleanly when the secret is unset** rather than failing. Follow it.
- `.github/workflows/outputs-freshness.yml` — READ, for this repository's Actions house
  style (triggers, permissions, node setup).
- `docs/wrangler.jsonc`, `docs/package.json`, `docs/package-lock.json` — the previous
  ticket's output; the workflow consumes them and changes none of them.

## Implementation Steps

1. Read `.github/workflows/release-note-draft.yml` end to end. It is the repository's
   existing answer to "a workflow that needs a credential it may not have", and its
   skip-when-unset shape is the one to copy rather than reinvent.
2. Add `.github/workflows/docs-deploy.yml`, triggered on `push` to `main` and filtered by
   `paths:` to `docs/**` plus the workflow's own file — a merge that touches no
   documentation should not redeploy.
3. Give the job the narrowest `permissions:` it needs (`contents: read`), pin the node
   version, and install with `npm ci` inside `docs/` so the lockfile decides.
4. Build with `npm run docs:build`, then deploy with `wrangler deploy` using
   `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` from repository secrets.
5. **Skip, do not fail, when the secrets are absent** — a fork without them must not see
   a permanently red workflow — and name the skip in the job summary so an absent
   credential is never mistaken for a successful deploy.
6. Add a `workflow_dispatch` trigger so the operator can run the first deploy by hand
   once the secrets exist, without waiting for a documentation merge.
7. Write the handoff into the pull request: which two secrets to add, and that
   `workaholic.qmu.co.jp` must be bound to the Worker as a custom domain in Cloudflare.
   Name them precisely; that list is the whole of what a person must do.
8. Do not add the deployment record here — that is the third ticket.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The workflow is valid, triggers on `push` to `main` filtered to `docs/**`, and does not
  trigger on other branches or on pull requests.
- With the secrets unset the job **skips** and says so; it does not fail and does not
  report a deploy it did not make.
- The deploy step is the only step that touches Cloudflare, and the build step passes
  without any credential.

**Verification method** — the commands/tests/probes that prove them:

- The workflow file parses (`actionlint`, or the Actions run itself on merge).
- The build steps run locally with no credential: `npm ci && npm run docs:build` in
  `docs/`.

**Gate** — what must pass before approval:

- The build half is proved with no credential.
- The `## Handoff` names both secrets and the custom-domain binding.
- The live site is **not** asserted by this run — that is the handoff.

## Considerations

- **Why the handoff rather than a Quality Gate item.** "The site serves the base at
  https://workaholic.qmu.co.jp" cannot be cleared by an unattended run: it needs an
  account nobody here holds. As a gate item it would be re-claimed and re-failed every
  tick forever; as a declared handoff the pull request opens once, stays open, and costs
  nothing per tick.
- The `paths:` filter is a deliberate choice with a stated cost: a change that alters the
  rendered site without touching `docs/**` will not redeploy. `workflow_dispatch` is the
  escape hatch, and it is cheaper than redeploying on every merge to `main`.
