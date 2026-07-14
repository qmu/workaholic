---
created_at: 2026-07-14T10:33:49+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort: 2h
commit_hash: 0fb0888
category: Changed
depends_on: [20260714103349-release-scan-engine.md]
mission:
---

# Wire the Branch-Safety Scan into /report (Warn) and /ship (Block)

## Overview

Consume the scan engine (from the depended-on ticket) at both release seams, with the developer-agreed tiering:

- **`/report` — loud warn.** `/report` cannot merge, so it runs `scan-branch-safety.sh` early and surfaces any findings prominently in the release-readiness assessment (Step 8), forcing `releasable: false` when there is a block-class finding. This gives the developer the finding at PR time so they can fix it before shipping.
- **`/ship` — hard gate, pre-merge.** `/ship` runs the same scan as a gate **before the merge step** (merge is last), and **halts** on a block, mirroring ship's existing deploy hard-gate idiom (the branch staying open is the rollback). Enforce the severity tiers:
  - `secret` (`hard`) → **non-overridable block**: stop the ship; the developer must remove the secret and re-run. No confirm-through (parallel to ship's rule that a failed confirmation is never bypassable).
  - `size` (`override`) → block, but the `/ship` command may offer an **explicit recorded override** via `AskUserQuestion` (large can be legitimate); proceeding is recorded in the ship evidence.
  - `leak` (`confirm`) → block, overridable with **confirmation** (and the option to add the term to the git-ignored `.workaholic/leak-denylist` suppression or fix the diff); the choice is recorded.

`/ship` has no subagent fan-out, so the gate is the engine **script** run by the ship flow (the command issues any override `AskUserQuestion` at the command level). `/report` runs the same script; if a fuzzy second opinion is ever wanted it belongs only at report (never gating ship) — out of scope here.

## Policies

- `workaholic:operation` / `policies/ci-cd.md` — a reproducible release-gating check that brackets the release: the report warn is the pre-check, the ship block is the gate at the publish seam.
- `workaholic:design` / `policies/defense-in-depth.md` — the ship block is the closed-default boundary; the report warn is the earlier, softer layer.
- `workaholic:safety` / `policies/standard.md` — enforces the no-credential-exposure / no-foreign-client-terminology commitments at the point content would go public.
- `workaholic:implementation` / `policies/coding-standards.md` + `directory-structure.md` — thin-command orchestration reusing the engine via `${CLAUDE_PLUGIN_ROOT}`; no scan logic re-implemented in markdown.

## Key Files

- `plugins/workaholic/skills/ship/SKILL.md` - Add the pre-merge scan gate to the Ship Flow (§5), before the merge step: run `${CLAUDE_PLUGIN_ROOT}/skills/release-scan/scripts/scan-branch-safety.sh`, halt on a block per the tiers. ship is built → `build.mjs` rebuild (and referencing `release-scan` pulls it into ship's closure/outputs).
- `plugins/workaholic/commands/ship.md` - The thin command issues the override `AskUserQuestion` (with the `[<project label>]` prefix) for `size`/`leak` findings and enforces the non-overridable `secret` block.
- `plugins/workaholic/skills/report/SKILL.md` - Wire the scan into Step 8 "Assess Release Readiness": run the engine, list findings, force `releasable: false` on a block-class finding; supersede the existing prose secrets-review with the engine's objective output. report is built → rebuild.
- `plugins/workaholic/commands/report.md` - Note the scan step (the command already orchestrates the readiness assessment).
- `plugins/workaholic/skills/ship/scripts/record-evidence.sh` - Record any size/leak override in the ship evidence, so an accepted risk is auditable.
- `CLAUDE.md`, `README.md`, `.workaholic/README.md` - Document that `/report` warns and `/ship` blocks on the scan, with the tiering (same commit).

## Related History

`/report`'s readiness review already inspects `git diff main..HEAD` for secrets as unenforced prose; `/ship`'s deploy hard gate is the established "halt, do not skip, the open branch is the rollback" idiom this reuses. This ticket makes the scan a real, tiered gate at both seams.

Past tickets that touched similar areas:

- [20260714103349-release-scan-engine.md](.workaholic/tickets/todo/a-qmu-jp/20260714103349-release-scan-engine.md) - Supplies the scan engine + verdict/severity schema this ticket consumes.

## Implementation Steps

1. In `report/SKILL.md` Step 8, run `scan-branch-safety.sh`, render its findings in the readiness output, and force `releasable: false` when any finding's verdict is block. Replace the prose secrets-review bullet with the engine's objective findings.
2. In `ship/SKILL.md` Ship Flow, insert the scan gate before the merge step; on a block, halt per tier — `secret` non-overridable; `size`/`leak` may be overridden via the `/ship` command's `AskUserQuestion`, recorded in the ship evidence.
3. In `commands/ship.md`, add the override prompt (label-prefixed) for `size`/`leak` and the hard stop for `secret`.
4. Update docs; rebuild (`build.mjs`, both report & ship are built), then `verify.mjs`, `validate-metadata.mjs`, `posix-lint`, `test-workflow-scripts.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A branch with a secret in its diff: `/report` marks it not releasable (block surfaced); `/ship` **halts before merge** and the secret block is **not** overridable (no confirm-through path leaves the PR merged).
- A branch with an oversized/too-many-files diff: `/ship` blocks but allows an explicit recorded override; proceeding merges and the override is recorded in evidence.
- A branch with a denylisted term: `/ship` blocks, overridable with confirmation; the confirmation/suppression is recorded.
- A clean branch: `/report` reports releasable and `/ship` passes the gate with no prompt.
- Both `report` and `ship` rebuilt (`outputs/` diff committed); `verify.mjs`/`posix-lint` clean.

**Verification method** — the commands/tests/probes that prove them:

- A `node scripts/test-workflow-scripts.mjs` case seeds the four branch scenarios and asserts the **gate decision** the ship flow would take from the engine verdict — secret ⇒ hard-block (no override branch reachable), size/leak ⇒ block-with-override, clean ⇒ pass — plus that an override is recorded via `record-evidence.sh`. (The scan engine's own correctness is covered by the engine ticket; this asserts the consumer's tier enforcement.)
- `node scripts/build-plugins/build.mjs` (report + ship rebuild) + `verify.mjs` + `validate-metadata.mjs` + `posix-lint` pass.

**Gate** — what must pass before approval:

- Full local suite green (`test-workflow-scripts.mjs`, `build.mjs` outputs committed, `verify.mjs`/`validate-metadata.mjs`/`posix-lint`).
- Live in-session demo: a crafted branch shows `/report` warning and `/ship` blocking, with the secret block non-overridable and a size/leak override recorded.
- Docs updated (report warns, ship blocks, the tiering).

## Considerations

- The secret block must be genuinely non-overridable — do not add a confirm-through that could leave a secret in a merged PR (`plugins/workaholic/commands/ship.md`).
- Keep the merge LAST: the scan gate runs before merge, and a block leaves the PR open (the rollback), consistent with ship's deploy gate (`plugins/workaholic/skills/ship/SKILL.md`).
- `/report`'s warn must not become a silent pass — a block-class finding forces `releasable: false` so the readiness assessment cannot say "ready" over a real finding (`plugins/workaholic/skills/report/SKILL.md`).
- Record overrides so an accepted size/leak risk is auditable later (`plugins/workaholic/skills/ship/scripts/record-evidence.sh`).
- Any `AskUserQuestion` the ship override uses must carry the `[<project label>]` prefix (guard-askuserquestion-label.sh) (`plugins/workaholic/commands/ship.md`).

## Final Report

Development completed as planned. Added `release-scan/scripts/gate-decision.sh` (maps the scan verdict to a ship decision: any finding → block; any `hard`/secret → non-overridable) so the tier policy is a testable script, not just prose. `/report` Step 8 runs the scan as a loud warn (forces `releasable: false` on a block, supersedes the prose secret-review); `/ship` Ship Flow §5 gains step 2b, a pre-merge gate that halts on a block — secret non-overridable, size/leak overridable with a recorded accepted-risk evidence entry, the override prompt issued by the `/ship` command. Hermetic test covers all tier mappings + a real `scan | gate-decision` on a secret; 522 passed / 0 failed, build/verify/metadata/posix-lint clean, report+ship rebuilt with release-scan bundled.

### Discovered Insights

- **Insight**: Making the ship tier policy a small `gate-decision.sh` (verdict JSON → `{decision, overridable}`) keeps the secret-is-never-bypassable rule **objective and unit-testable**, rather than relying on the agent to interpret severities from prose. The ship flow prose then just acts on `overridable`.
  **Context**: Referencing `release-scan` from the built `report` and `ship` skills pulls it into both closures, so its scripts are bundled into `outputs/workflows/skills/{report,ship}/release-scan/` — a rebuild is required and the outputs diff is expected.
