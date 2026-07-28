---
created_at: 2026-07-26T01:17:11+09:00
author: a@qmu.jp
type: bugfix
layer: [Domain]
effort: 2h
commit_hash:
category: Changed
depends_on:
mission:
---

# Mission-worktree creation must carry the env files the project actually reads, not only the repo-root `.env` — the current behaviour silently disables every credential-dependent run and disguises itself as a finding

## Overview

A series of unattended overnight runs across several missions all reached the same
conclusion and all deferred their credential-gated work unspent: *"no API credentials are
present in this environment."* Each agent wrote a careful, well-reasoned deferral note
saying so. **The credentials had been on the machine the entire time.** Days of unattended
capacity produced nothing, and the false finding was written into tickets, mission
changelogs, and planning notes, where it was re-read and re-derived on subsequent nights
as established fact.

The cause is a provisioning gap in `create-mission-worktree.sh`, and it is made severe by
three facts composing:

1. **The creator copies only `<repo-root>/.env`** into the new worktree, then appends its
   own `WORKAHOLIC_PORT_BASE` / `WORKAHOLIC_DEV_PORT` / `WORKAHOLIC_DOCS_PORT` lines to
   the worktree's root `.env`.
2. **Many projects do not keep their env file at the repo root.** Where the runnable
   package is a subdirectory, its own tooling loads an env file *relative to that
   package* — so the file the project actually reads is `<package>/.env`, which the
   creator never looks at and never carries.
3. **Env loaders fail silently on a missing file.** Node's `--env-file-if-exists` is the
   common case: absent file, no warning, no non-zero exit — every variable simply unset.

Composed, they produce the worst possible shape: a worktree that **looks correctly
provisioned** — it has a `.env`, because the creator wrote one — while holding none of the
project's credentials. Observed directly: a worktree's root `.env` contained exactly three
lines, all three of them the port variables the creator itself appended.

### Why this is worse than an ordinary bug

It does not fail loudly; **it fails as a plausible finding.** From inside the worktree the
agent's observation is completely correct — the env file is not there and the variables
are unset — so it reasons its way to a confident, wrong, *durable* conclusion and records
it. Nothing in the worktree contradicts it. The failure then survives the run that
produced it: later sessions read the deferral notes as evidence and plan around a
constraint that does not exist.

The tell was visible only from outside: sibling worktrees provisioned by hand *did* carry
the project-level env file, and those runs produced real results. Same repository, same
credentials, same night — the only difference was which worktrees the script had made.

## The rule the implementation must satisfy

- **Carry every env file the project reads, not the root one by assumption.** Root-only is
  a guess about layout, and it is wrong for any project whose runnable unit is a
  subdirectory.
- **Let the project declare its env-file locations** rather than having the creator infer
  them; default to the repo root when nothing is declared, so existing projects are
  unaffected. Discovering the candidates (for example, from the paths the repo ignores) is
  acceptable as a fallback, but a declaration is preferable to a heuristic.
- **Never write an env file the project does not read.** Appending the port variables to a
  root `.env` that nothing loads manufactures the exact artifact that makes the gap
  invisible — a file whose only function is to make provisioning look like it succeeded.
  Put the port variables where the project will actually read them, or keep them in a
  clearly separate file that is not mistakable for the project's env.
- **Report what was carried.** The creator already emits JSON; it must name the env files
  it copied, and say plainly when it found none. A caller — and a reviewing human — should
  be able to see the gap at creation time, not infer it hours later from a failed run.
- **Make "missing credentials" a checked claim, not an observation.** Guidance that lets an
  unattended run record a credential-shortfall finding must first require confirming that
  the env files exist where the project reads them. An agent reporting absent credentials
  should be reporting the *provisioning* state, not just the state of its own process
  environment.

## Policies

The standard engineering policies that govern this ticket. The implementing session
**MUST** read each linked policy hard copy before writing and keep every change defensible
against that policy's Goal, Responsibility, and Practices.

- `workaholic:development` / `policies/overnight-ai.md` — the stated purpose of the
  overnight model is to eliminate the causes of stopping *before* the run starts. A
  provisioning gap that silently disables every credentialed run is precisely such a
  cause, and this one was invisible from the only vantage point the night agent had.
- `workaholic:implementation` / `policies/objective-documentation.md` — a creator that
  reports success while having carried nothing is not reporting objectively. What was
  copied, and what was not found, must be in the output.
- `workaholic:operation` — provisioning the environment a worktree runs in is part of
  keeping the work runnable; a half-provisioned tree is an operational defect, not a
  caller's problem to discover.

## Key Files

- `plugins/workaholic/skills/branching/scripts/create-mission-worktree.sh` — the copier.
  Replace the single root-`.env` copy with a declared/discovered set, and extend the
  emitted JSON with what was carried.
- Any sibling worktree creator in `plugins/workaholic/skills/branching/` — the same
  root-only assumption is likely duplicated; fix them together so the two paths cannot
  drift.
- `plugins/workaholic/skills/monitor/` and `plugins/workaholic/skills/drive/` — wherever an
  unattended run is told it may defer on missing credentials, require the provisioning
  check first, so a deferral note records a verified state rather than a plausible one.
- Wherever worktree layout is documented for project authors — the declaration mechanism
  needs to be discoverable by the projects expected to use it.

## Quality Gate

Verification is script-level: `create-mission-worktree.sh` is a POSIX script with a
testable contract, so the gate is the hermetic suite plus a real invocation, not
documentation review.

**Acceptance criteria** — the checkable conditions that must hold:

- [ ] Creating a worktree in a project whose env file lives in a subdirectory results in
      that subdirectory env file being present in the new worktree with its contents intact.
- [ ] Creating a worktree in a project whose env file is at the repo root behaves exactly
      as it does today (no regression for the existing layout).
- [ ] Creating a worktree in a project with no env file at all does not fabricate one that
      the project would read, and says so in its output.
- [ ] The creator's JSON output names every env file carried, and reports an empty result
      explicitly rather than by omission.
- [ ] The port variables the creator injects are readable by the project's own tooling, or
      are written somewhere that cannot be mistaken for the project's env file.
- [ ] Tests cover all three layouts (root, subdirectory, none) and assert on the reported
      output as well as the resulting files.
- [ ] The unattended-run guidance requires verifying env-file presence before recording a
      missing-credentials deferral, and names the check to run.

## Final Report

Development completed as planned. A single shared carrier (`lib/carry-worktree-env.sh`) now backs **both** worktree creators (`create-mission-worktree.sh`, `ensure-worktree.sh`), so the root-only assumption cannot drift between them: it carries every env file the project reads — declared in a repo-root `.worktree-env`, else the root `.env` plus discovered git-ignored subdir `.env` files — to the same relative path, and reports `env_files_carried`. The port vars go into the carried root `.env` when the project has one (byte-identical to before) and into a separate `.env.worktree` otherwise — never a fabricated bare root `.env`, the artifact that disguised the gap. Guidance in `drive` §3a and `monitor` §2 makes "missing credentials" a checked claim (confirm `env_files_carried` before a shortfall deferral). Verified: `node scripts/test-workflow-scripts.mjs` 1332 passed / 0 failed (16 new assertions over all three layouts + declaration + reported output, plus three pre-existing consumer tests reconciled to the new contract); build+verify clean (`drive`/`mission` outputs regenerated); metadata valid; posix-lint conforming; layout conforming.

### Discovered Insights

- **Insight**: Moving the port vars off the root `.env` for no-root-env projects rippled into three other consumers that all assumed ports live in `.env` — `gate.sh` (reads dev/docs ports), `allocate-worktree-port.sh` (scans used bases), and `ensure-git-excludes.sh` (must ignore the new file).
  **Context**: The port vars are a small convention with a surprisingly wide read surface. Any change to *where* they are written has to update every reader in the same commit or a subdir-env project silently loses port resolution or collides on ports. The tell was three test failures that were themselves asserting the old fabricated-`.env` behavior — i.e. the tests encoded the bug.
- **Insight**: `.env` as a git-exclude pattern (no slash) already matches a subdir `app/.env` at any depth, so carried subdir env files never dirty the worktree — but `.env.worktree` needed its own exclude line because it is a distinct name.
  **Context**: This is why cleanup (which refuses a dirty worktree) keeps working for subdir-env projects without extra handling: the project's own `.gitignore` plus the shared `.env` exclude cover the carried credential files; only workaholic's invented `.env.worktree` was new and had to be added to the exclude list.
- **Insight**: The bug's severity came from *silent* env-loader failure, so the durable fix is as much the reporting (`env_files_carried`, an empty array stated explicitly) as the carrying.
  **Context**: A creator that carried the right files but still reported nothing would leave the next false-finding undetectable. Making the empty carry visible at creation time — and telling the unattended run to check it before deferring — is what converts "no credentials" from a plausible conclusion into a checkable claim.
