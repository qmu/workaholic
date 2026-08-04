---
created_at: 2026-08-05T04:25:00+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission:
merge_policy:
claim: work-20260804-195257
---

# Normalize SSH and HTTPS remote URLs in routine matching

## Overview

Measured during the 2026-08-05 /setup-routines run: `resolve-repo-url.sh`
returns this checkout's remote as `git@github.com:qmu/workaholic` (the SSH
form), while every live routine's `git_repository.url` is
`https://github.com/qmu/workaholic`. `list-routines.sh` /
`compare_routines.py` normalize only a trailing slash and `.git`, so the two
forms never match — the survey reported **zero routines and all templates
missing for a repository with three live, working routines**, which is exactly
the confident-wrong answer the command exists to prevent. The workaround was
passing the https form by hand.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / reachability policies — an identity comparison must be canonical before it is trusted to say "nothing exists"

## Key Files

- `plugins/workaholic/skills/workaholify/scripts/lib/compare_routines.py` — the URL normalizer (repo-membership match)
- `plugins/workaholic/skills/workaholify/scripts/resolve-repo-url.sh` — emits the raw remote form; either it canonicalizes, or the comparer does (prefer one canonicalizer both sides call)
- `plugins/workaholic/skills/workaholify/scripts/list-routines.sh`, `compare-routines.sh` — consumers
- `scripts/test-workflow-scripts.mjs` — matching cases

## Implementation Steps

1. Add one canonical form: `git@github.com:owner/name`, `ssh://git@github.com/owner/name`,
   `https://github.com/owner/name` (each ± `.git`, ± trailing slash) all reduce
   to `github.com/owner/name` lowercased host.
2. Apply it on both sides of the membership match; keep the reported `repo`
   field as the caller passed it.
3. Hermetic tests: SSH-form caller matches an https-form routine and vice
   versa; a different repo still never matches.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `list-routines.sh git@github.com:qmu/workaholic` reports the same three routines as the https form
- A wrong-repo URL still yields zero matches

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (new normalization cases green)

**Gate** — what must pass before approval:

- Hermetic suite green; `verify.mjs` clean if the workaholify skill ships in the bundle

## Considerations

- The template↔routine pairing by display name is a separate axis (renames make
  a routine `unknown`); this ticket fixes only the repo-membership match.
