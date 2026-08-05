---
created_at: 2026-08-05T10:13:37+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category: Changed
depends_on:
mission: cross-the-repo-boundary-as-an-issue
merge_policy:
---

# Give fb a cross-repo issue mode

## Overview

Per FB `20260805101319`: `/fb` gains a cross-repository mode. Given a target
repository and an ask, the session composes the ask **in the target's
vocabulary**, applies the masking judgment, shows the one non-skippable verbatim
confirmation (destination, visibility, exact body), runs the release scan as
the second layer, and opens the ask as a **GitHub issue on the target** via
`gh issue create -R <owner/name>` — reporting the issue URL. The target's
[Propose] routine ingests that issue like any inbound report, so the recording
and the proposal judgment happen in the target's own loop. No file is ever
written into the target checkout.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / data-handling policies — content crossing a repository boundary is confirmed by a person, in the exact form it will leave

## Key Files

- `plugins/workaholic/commands/fb.md` — the command grows the target-repository branch of its flow (bare /fb unchanged)
- `plugins/workaholic/skills/feedback/SKILL.md` — new *Crossing a repository boundary* section: target resolution, vocabulary rule, masking judgment (imported from request/SKILL.md §1-3, moved by the sibling ticket), the one-confirmation contract, and the issue as the carrier
- `plugins/workaholic/skills/request/scripts/resolve-target.sh`, `scripts/lib/remote-url.sh` — reused: visibility reporting and canonical URL forms; relocation itself is the sibling ticket's job, so this ticket may call them at their current home
- `scripts/test-workflow-scripts.mjs` — coverage for the new mode's mechanics

## Implementation Steps

1. Extend `commands/fb.md`: when the input names a target repository (an
   `owner/name`, a URL, or "to <repo>"), route to the cross-repo flow; bare
   `/fb` keeps today's in-repo record behavior exactly.
2. Write the *Crossing a repository boundary* section in `feedback/SKILL.md`:
   compose in the target's vocabulary (never this repo's customer context),
   masking as a judgment with the measured leak classes named, the ONE
   AskUserQuestion showing destination + `visibility` + verbatim body
   (non-skippable, never batched, `[<project label>]` prefix), then scan, then
   `gh issue create -R <owner/name> --title --body-file`.
3. Resolve the target through `resolve-target.sh` (visibility included) and
   read this repo's own URL forms through `remote-url.sh` so the identifier
   mask check covers every spelling — the measured 2026-08-04 insteadOf gap.
4. A refused scan (`secret`) hard-stops; `leak`/`size` findings surface for
   fix-or-recorded-override exactly as /ship words it.
5. Tests: target resolution forms; the issue-create call shape (mock `gh`);
   the four real leaked sentences still pass the identifier check unflagged
   (the measured reason the human gate exists — port the existing assertion).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A cross-repo /fb run opens exactly one issue on the target and writes nothing into any checkout of it
- The verbatim confirmation carries destination, visibility, and the exact body in one prompt, and cannot be skipped
- Bare /fb behavior is byte-for-byte unchanged

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (new cases green)

**Gate** — what must pass before approval:

- Hermetic suite green; `build.mjs`/`verify.mjs` clean (feedback skill ships in the bundle); docs updated in the same change

## Considerations

- The issue must read natively in the target — its title carries no [Proposal]
  prefix of ours; what the target's routine does with it is the target's loop's
  business.
- `gh issue create` needs the target to accept issues from this identity; a
  refusal is reported verbatim, never worked around.
- Drive this ticket FIRST — the sibling deletes the request surface and
  re-points the docs at this mode, so this mode must exist when it does.
