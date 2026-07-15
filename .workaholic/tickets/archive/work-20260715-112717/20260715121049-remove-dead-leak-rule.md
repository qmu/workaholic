---
type: refactoring
layer: [Domain, Config]
created_at: 2026-07-15T12:10:49+09:00
author: a@qmu.jp
depends_on: []
---

# Remove the internal-hostname pattern from release-scan: it detects nothing and misfires on our own conventions

## Motivation

The `leak` rule has two independent halves. One works within its limits. The other
does not work at all. This ticket removes only the second, and the split is drawn
from measurement rather than argument.

**The internal-hostname pattern detects zero of the five real leaks.** All five
sentences that actually contaminated public repositories were replayed through the
scan in a throwaway repo. The pattern
(`[a-z0-9_-]+\.(internal|local|corp)`) produced **no findings**. What leaked was a
`.dev` hostname, a component name, a document filename, a mail label, and cloud
resource names. Not one is within its reach.

**It misfires on our own mandatory convention.** The same pattern matches
`metadata.internal` — the frontmatter field CLAUDE.md *requires* every script-bearing
skill to carry, and which CLAUDE.md itself writes three times to document that
requirement. Adding a line explaining our own rule raises a `leak` finding against us.
It also matches `env.local` and `settings.local`, i.e. ordinary config filenames.

Zero true positives, a standing false positive against our own docs. There is nothing
to preserve.

## What is NOT in scope, and why

**The denylist half stays.** An earlier draft of this ticket claimed the whole `leak`
rule detects nothing. That claim was wrong, and the replay proves it: with the
denylist present the scan returns `block` with **6 findings across 4 of the 5 leaked
lines** (`data-platform` ×2, `seiho`, `sonpo`, `hss-mcp`, `qmu.dev`). It works.

Its limits are real and should be stated rather than removed:
- It exists only where `.workaholic/leak-denylist` exists. The file is git-ignored by
  design, so it is present on one machine in one repository. Four of the five
  contaminated repositories could never have run it, and the rule is skipped there
  silently (`if [ -f "$denylist" ]`, no else).
- It is retrodictive. The 29 entries were authored at 2026-07-15 01:15, from these very
  leaks. It catches them because it was written knowing them, which says nothing about
  tomorrow's filenames.
- Even with the list present, `HSS様` is **not** caught — the one term that reached
  shipped product source. The term nobody could enumerate travelled furthest.

So the denylist is a narrow, real control. Keep it, and stop describing it as more.

**`secret` and `size` stay.** Credential shapes genuinely are enumerable in advance,
which is what makes a regex the right tool and why the same set is shared with
`ship/record-evidence.sh`. Size is arithmetic.

## Key Files

- `plugins/workaholic/skills/release-scan/scripts/scan-branch-safety.sh:107-113` — the
  internal-hostname block to delete. Leave the denylist block (~117-128) intact.
- `plugins/workaholic/skills/release-scan/SKILL.md:41` — states "Absent file → only the
  structured internal-hostname pattern runs (conservative default)". After this change
  there is no such fallback: absent file → nothing runs.
- `CLAUDE.md:268` — says the scan catches leakage via "a git-ignored,
  developer-maintained `.workaholic/leak-denylist` plus internal-hostname patterns",
  and that this "machine-enforces the standing convention".
- `plugins/workaholic/commands/ship.md`, `commands/report.md` — leak-tier description.
- `scripts/test-workflow-scripts.mjs` — check for internal-hostname assertions.

## Implementation Steps

1. Delete the internal-hostname block from `scan-branch-safety.sh`. Leave the denylist
   block and its `added_lines` self-exclusion untouched.
2. `release-scan/SKILL.md`: drop the internal-hostname pattern. Rewrite the absent-file
   sentence — "conservative default" is now plainly false, since absent file means the
   `leak` rule does nothing whatsoever. Say that.
3. `CLAUDE.md:268`: drop `internal-hostname patterns`. Correct the claim that the scan
   "machine-enforces the standing convention" — it enforces it **only where a denylist
   exists, and only for terms already known**, which today means this repository alone.
   A reader who believes the sentence as written is the failure mode being removed.
4. `ship.md` / `report.md`: update the leak-tier description to denylist-only.
5. Remove any internal-hostname assertions from `scripts/test-workflow-scripts.mjs`.
6. `node scripts/build-plugins/build.mjs` — `release-scan` is in `report`/`ship`'s script
   closure, so `outputs/workflows/skills/{report,ship}/` regenerate. Then `verify.mjs`
   and `validate-metadata.mjs`. CI's Outputs Freshness fails on any `outputs/` diff.
7. Update `README.md` / `.workaholic/README.md` if either describes the pattern.

## Considerations

- **Do not replace it with a better pattern.** That is the trap. The next pattern also
  will not know tomorrow's filenames. This failed not because the regex was poor but
  because the target is semantic. Prevention belongs to the confinement rule and
  `/request`'s masking judgment, where a human decides.
- The denylist's fail-open is left in place by decision, not oversight. It is not the
  defect it appears to be: a fail-closed denylist cannot work when the file is
  git-ignored, and committing the list would publish the client names — the leak itself.
  Record the residual rather than patching it.
- After step 3, no sentence in the repo should overstate what the scan covers. That
  overstatement, not the dead regex, is what made this worth doing.
- `sweep-todo.sh` and several `policies/*.md` match a grep for "leak" — confirm each is
  the English word, not this rule, before touching.

## Policies

- `implementation/directory-structure` / `implementation/coding-standards` — universal.
- `implementation/objective-documentation` — the load-bearing one. "Documentation
  describes the actual behavior of the code, not the intended behavior at the time of
  writing." `CLAUDE.md:268` and `SKILL.md:41` describe coverage that is not real.
- `design/defense-in-depth` — a layer that rejects nothing is nominal. Applied honestly,
  the policy condemns the internal-hostname layer rather than asking us to patch it —
  and vindicates keeping the denylist, which does reject something.
- `operation/ci-cd` — prevents "treating a green indicator — absent any evidence of what
  the inspection actually verified — as proof the code is healthy."
- `safety/risk-management` — record the residual: outside this repository there is no
  automated client-context detection, by decision.

## Quality Gate

The replay fixture is the gate. It is five real leaked sentences with known-correct
answers, which beats any synthetic fixture.

1. **Removal costs nothing.** Replay the five sentences **without** a denylist, before
   and after the change. Before: `pass`, zero findings (measured). After: identical.
   Same output is the evidence that no detection was lost. Any finding in the
   before-run falsifies this ticket and it must stop.
2. **The denylist is not damaged.** Replay the five **with** the denylist present.
   Before: `block`, 6 findings on lines 1/2/3/5 (measured). After: identical. Fewer
   findings means the change broke a working control.
3. **The false positive is gone.** A diff adding a `metadata.internal` line to
   `CLAUDE.md` produces a finding before the change and none after. Confirm both halves.
4. **`secret` and `size` untouched.** A known credential shape and an oversized diff
   both still fire; `secret` still non-overridable via `gate-decision.sh`.
5. `node scripts/test-workflow-scripts.mjs`, `verify.mjs`, `validate-metadata.mjs` green,
   `outputs/` regenerated so CI's freshness diff is clean.
6. **No stale claim survives.** Grep for any remaining sentence asserting the scan
   enforces the client-name convention generally. Zero hits.
