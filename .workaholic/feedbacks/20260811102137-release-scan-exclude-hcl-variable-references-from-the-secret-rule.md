---
type: Feedback
title: release-scan: exclude HCL variable references from the secret rule
kind: instruction
source: discussion
created_at: 2026-08-11T10:21:37+00:00
author: a@qmu.jp
supersedes: 
---

# release-scan: exclude HCL variable references from the secret rule

# release-scan flags HCL variable-reference assignments as credentials

qmu/workaholic#378: scan-branch-safety.sh's secret_grep matches an HCL assignment whose value is a variable reference (e.g. `api_token = var.cloudflare_api_token`) as a hard-blocking secret, with no override available since secret is the one non-overridable tier. This permanently blocks any branch touching a Terraform stack that wires a provider credential through a variable — the documented, correct pattern. Pass 2 of the secret pattern already matches on the value rather than the key name and already treats process.env.X and similar host-language reference forms as references rather than literals; HCL's reference forms (var., local., data.) appear not to be covered by that exclusion. Fix: extend the value-is-a-reference exclusion to cover HCL's var./local./data. reference forms, while keeping a literal value (api_token = "...") detected as hard exactly as before.
