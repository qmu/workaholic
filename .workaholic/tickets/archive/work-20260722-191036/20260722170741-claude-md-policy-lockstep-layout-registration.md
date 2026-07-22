---
created_at: 2026-07-22T17:07:41+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort: 0.5h
commit_hash:
category: Added
depends_on:
mission:
---

# Add a CLAUDE.md policy: a new .workaholic/ artifact directory is a lockstep amendment

## Overview

The concrete drift — `.workaholic/strategies/` live but absent from the layout allowlist and the
`rules/workaholic.md` table — happened because **the policy that would have caught it is not in
CLAUDE.md.** `rules/workaholic.md` carries a lockstep instruction ("Keep the table and that file
in lockstep when amending the structure"), but nothing in CLAUDE.md elevates it to a
change-author policy, and no gate fails a merge when a new artifact ships with the guard's
source-of-truth stale. So the `workaholic:strategy` artifact shipped — its own skill and
`create.sh` writing `.workaholic/strategies/active/` — without either source of truth being
amended.

**Change: add a policy to workaholic's CLAUDE.md** (Project Structure / Architecture Policy
area) stating:

1. **The `.workaholic/` layout is a closed structure.** Introducing a new top-level artifact
   directory (as `strategies/` was) is a deliberate amendment that MUST, in the same change,
   update **both** sources of truth — `hooks/workaholic-layout-allowlist.txt` **and** the table
   in `rules/workaholic.md` — plus any skill/docs that name the artifact. A new artifact type is
   not shipped until its directory is registered.
2. **The guards are load-bearing, not advisory.** The working-directory and layout guards block
   by construction when the plugin is installed (no env-var toggle — see the companion request),
   so the layout source of truth is enforced, not decorative: a stale allowlist becomes a
   correctness bug (it hard-blocks a legitimate write), which is precisely why registration must
   be part of the same change.
3. **Anti-drift check named.** `hooks/layout-doctor.sh` reports undesignated directories against
   the allowlist without mutating the tree; CLAUDE.md points at it as the audit to run when
   amending the structure, and (recommended) it is wired into local verification / a CI gate so
   a drifted allowlist fails before merge rather than surfacing at a guard block later.

## Policies

- This is a documentation/policy change to `CLAUDE.md`, plus (if adopted) a verification-wiring
  change for `layout-doctor.sh`. The concrete `strategies` allowlist fix itself lives in the
  companion request (the guard-enforcement change), which this policy exists to keep from
  recurring.
- Keep the policy a **verifiable rule** per the project's objective-documentation standard (an
  auditor can check "new dir => allowlist + table updated in the same commit"), not a vague
  exhortation.

## Quality Gate

- `CLAUDE.md` states the closed-layout / lockstep-registration policy as a verifiable rule,
  naming both sources of truth (`hooks/workaholic-layout-allowlist.txt` and the
  `rules/workaholic.md` table) and `hooks/layout-doctor.sh` as the audit.
- The policy records that the guards are enforced-by-default (no env-var toggle), so the layout
  source of truth is load-bearing.
- If verification wiring is adopted: `layout-doctor.sh` (or an equivalent check) runs in the
  documented local-verification / CI path and fails on an undesignated directory.
- A reader following the new policy, on adding a hypothetical new artifact directory, is
  instructed to update both sources of truth in the same change.

## Final Report

Development completed as planned. The policy lands as a new `### Closed .workaholic/ layout (lockstep registration)` subsection in CLAUDE.md's Architecture Policy area, stated as a verifiable rule (`git show <commit>` for any commit introducing `.workaholic/<newdir>/…` must also touch both sources of truth). The recommended verification wiring was adopted in full: the `layout-doctor.sh .` audit is now both a `## Local Verification` command and a `Validate Plugins` CI step that fails the merge on `conforming: false`.

### Discovered Insights

- **Insight**: `layout-doctor.sh` exits 0 even when the tree is non-conforming — it reports `{conforming, findings}` on stdout and leaves the verdict to the caller. The CI gate therefore checks `jq -r '.conforming'`, not the exit code; anyone reusing the doctor as a gate must do the same or it will silently never fail.
  **Context**: This is deliberate (the doctor is read-only and advisory by design); the gate/verdict split lives in the caller, which is why the policy names the CI step as the enforcement point rather than the doctor itself.
