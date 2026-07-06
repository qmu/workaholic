---
title: Infrastructure as Code
slug: infrastructure-as-code
category: implementation
source: https://qmu.co.jp/implementation/infrastructure-as-code
---

# Infrastructure as Code

Define configuration as version-controlled code, reproducible from a clean state. Building things in the console is fast for one-off changes and easy to learn, but we prioritize IaC in order to keep infrastructure **reproducible and auditable**. The cost is that ad-hoc, in-the-moment fixes become slower.

## Goal (目標)

The situation this policy aims to achieve is one where the current state of the infrastructure can be fully reconstructed from the code in the repository.

All production infrastructure — VPCs, subnets, load balancers, serverless functions, databases, queues, storage, DNS — is defined in configuration files in the repository; the same infrastructure can be reproduced from the same code in a different account or different region. "When, by whom, and what was changed" can be traced from the git history, and direct changes made in the console (drift) are detected with a path to take them back into the code — the aim is a state in which this cycle continues to turn.

## Responsibility (責務)

The situation this policy aims to prevent is one where the structure of the infrastructure depends on the operator's memory and cannot be explained as files.

Resources that reached production by manual console construction alone — a resource running in production simply because someone created it from the dashboard with no record in code; IaC code and actual infrastructure state remaining drifted and the drift never resolved; "fix it manually for now and reflect it in code later" becoming a habit (manual changes during emergency response are tolerated, but they must always be taken back into the code afterward); IaC code existing but the procedure for creating a new environment living in the operator's memory; secrets hardcoded directly into the IaC code and included in git — these are the states this policy aims not to allow.

## Practices (実践)

### Define all production infrastructure as code

We make IaC the default for new provisioning. Console construction is limited to temporary exploration before it is turned into IaC, or to resources that the IaC tooling does not support.

Tooling options we adopt:

- Cloudflare: `wrangler.toml`-based configuration plus the Terraform Cloudflare provider.

- AWS / GCP / Azure: one of Terraform / Pulumi / CDK.

- Kubernetes: Helm / Kustomize / Argo CD.

The choice of tool is evaluated in line with [Conservative Vendor Dependence](../../design/policies/vendor-neutrality.md).

### Detect drift between the code and the actual state

We periodically inspect whether the IaC code and the actual infrastructure state have diverged (drifted).

- Terraform: run `terraform plan` periodically in CI and notify if a diff appears.

- Pulumi: do the same with `pulumi preview`.

- Cloudflare Wrangler: incorporate a check equivalent to `wrangler deploy --dry-run` into CI.

When drift is detected, we either codify it (bring the code in line with the actual state) or roll it back (bring the actual state in line with the code). We do not leave drift unaddressed.

### Reference secrets from external secret management

We do not hardcode secrets into IaC code.

- Via environment variables: CI's secret feature, or a developer's local environment variables.

- Via a secret management service: AWS Secrets Manager / GCP Secret Manager / HashiCorp Vault / Cloudflare Worker Secret.

- Via encrypted configuration: use sops / age to place encrypted yaml / json in git (with keys managed externally).

`.tfvars` and `.env` files that contain secrets are excluded via `.gitignore`, and are checked by a pre-commit hook to prevent accidental commits.

### Manage sensitive information rotation and location as configuration (センシティブ情報のローテーションと保管場所を設定として管理する)

The location where a secret is stored and the schedule on which it is rotated are themselves configuration — they belong in version-controlled files, not in operator memory.

- Record the storage location of each secret (which Secrets Manager path, which environment variable name, which vault key) in a configuration file or secrets manifest in the repository. Actual values are excluded via gitignore; what is recorded is the metadata: where the value lives, who owns it, and when it rotates.
- Define rotation intervals for secrets that require periodic rotation (database passwords, API keys, certificates, signing keys). Use the rotation automation provided by the secret management service (AWS Secrets Manager automatic rotation, HashiCorp Vault lease TTLs, or Cloudflare Worker Secret replacement via CI).
- When a secret is rotated, update the IaC configuration that references it in the same commit or PR, so the rotation event is traceable in git history alongside the infrastructure change.
- Access to the secret manager itself is also access-controlled; model it in IaC alongside the secrets it protects, so its permission grants are auditable in the same way as any other resource.

### Minimize "differences between environments" through modularization

When reproducing the same infrastructure across production / staging / dev, we structure it so that the common parts are extracted into a shared module and only the environment-specific variables are overridden.

```hcl
module "app" {
  source = "./modules/app"
  environment = "production"
  instance_count = 3
}
```

We avoid "build production by hand only" and "dev is configured differently, so it's a separate implementation." Differences between environments are expressed as differences in variable values.

### Define infrastructure centered on wrangler.toml

For our Cloudflare-based products, `wrangler.toml` is the single source of definition for production infrastructure.

- Write `[vars]`, `[[kv_namespaces]]`, `[[send_email]]`, `[[d1_databases]]`, and so on into `wrangler.toml`.

- Register secrets to production with `wrangler secret put`, and handle them locally via `.dev.vars` (kept under gitignore).

- Reflect them to production through `wrangler deploy` in CI (in tandem with CI/CD automation).

KV namespace IDs, custom domain routes, and the like are stated explicitly in `wrangler.toml`, so that nothing is completed by console creation alone.

### Leave the new-environment setup procedure in a script

We leave the procedure for "reproducing production from a clean state" in a shell script / Makefile / Task file or similar.

```bash
# scripts/bootstrap-env.sh
wrangler kv namespace create CONTACT_RATE_LIMIT
wrangler secret put TURNSTILE_SECRET_KEY
wrangler secret put DATABASE_URL
wrangler deploy
```

This script becomes the new-environment setup procedure itself.

### Treat PR review of IaC changes as "a discussion of infrastructure changes"

PRs for IaC code are handled as carefully as, or more carefully than, feature code.

- Paste the scope of impact (which resources are added, changed, or deleted) into the PR description, using the output of `terraform plan` / `wrangler deploy --dry-run`.

- For changes that involve deletions, confirm rollback feasibility in advance.

- Before reflecting to production, apply it in staging and confirm that the diff is as expected.

### Build a culture of "explore in the console → turn it into code"

Prototyping new features and exploring new configurations may be tried quickly in the console. However, we make it a habit that, before such results reach production, they must always be taken into code.

- Isolate exploratory resources into a "sandbox" account / project.

- Make production reachable only via IaC (restrict console-based production changes through organizational policy).

### Related (関連): CI/CD, portability, observability

IaC should be executed by [Local CI/CD Execution](../../operation/policies/ci-cd.md). Reproducibility supports [Conservative Vendor Dependence](../../design/policies/vendor-neutrality.md). Whether the resources defined by IaC are behaving as expected is confirmed through [Observability and Self-Healing](observability.md).
