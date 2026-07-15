---
type: refactoring
layer: [Domain, Config]
created_at: 2026-07-15T12:10:49+09:00
author: a@qmu.jp
depends_on: []
---

# Remove the leak rule from release-scan: it detects nothing and misfires on our own conventions

## Motivation

The `leak` rule does not work. This is measured, not argued.

**It detects zero of the five real leaks.** All five sentences that actually
contaminated public repositories were run through the rule's structured pattern:
zero findings. The pattern matches `.internal`, `.local`, and `.corp` hostnames.
What leaked was a `.dev` hostname, a component name, a document filename, a mail
label, and cloud resource names. Not one is within reach of the pattern.

**It misfires on our own mandatory convention.** The same pattern matches
`metadata.internal` — the frontmatter field CLAUDE.md *requires* every
script-bearing skill to carry. `CLAUDE.md` writes it three times to document that
requirement. Adding a line that explains our own rule raises a `leak` finding
against us. It also matches `env.local` and `settings.local`, i.e. ordinary
config filenames.

**Its other half cannot exist where it is needed.** The denylist is
`.workaholic/leak-denylist`, git-ignored by design so the client-name list never
ships. The consequence is that it exists on exactly one machine, in one repository.
Every other repository has no denylist, so the whole rule is skipped there —
silently, since the loop is wrapped in `if [ -f "$denylist" ]` with no else. Four of
the five contaminated repositories are repositories where it could never have run.
This is the same distribution failure as the convention it was built to enforce:
a control present at one site in five.

**And a denylist is structurally unable to do this job.** It matches terms known in
advance. `realestate-mcp`, `seiho-target-matrix.pdf`, `HSS様`, `csnet-poc.qmu.dev` —
none existed as a term to list before the moment they leaked. A list cannot contain
tomorrow's filenames.

The rule was added 2026-07-14 11:04. Every leak predates it (2026-06-16 through
06-24), so it never failed in service — it was built after the fact and does not
address the thing it was built for. Keeping it costs false positives against our own
docs and, worse, buys a false sense of coverage: `CLAUDE.md:268` and
`release-scan/SKILL.md:41` both currently tell the reader that the scan
"machine-enforces the standing 'keep motivation generic, never name other
repos/clients' convention." It does not, and cannot.

Delete it. Prevention belongs to the confinement rule and `/request`'s masking
judgment, which is where a human decides. A pattern matcher was never going to
recognise a client's name.

## Scope

**Remove:** the `leak` rule in both halves — the internal-hostname pattern and the
denylist loop.

**Keep:** `secret` and `size`. Credential shapes genuinely *are* enumerable in
advance — that is what makes a regex the right tool for them, and the reason the same
regex set is shared with `ship/record-evidence.sh`. Size is arithmetic. Neither
depends on knowing a client's vocabulary. This ticket is not an argument against
deterministic scanning; it is an argument against using it on something it cannot see.

## Key Files

- `plugins/workaholic/skills/release-scan/scripts/scan-branch-safety.sh:107-128` —
  the two `leak` blocks to delete (internal-hostname at ~107, denylist at ~117).
- `plugins/workaholic/skills/release-scan/SKILL.md:41` — documents the denylist and
  calls the fail-open a "conservative default".
- `CLAUDE.md:268` — the release-safety scan paragraph.
- `.gitignore:8` — `.workaholic/leak-denylist`.
- `plugins/workaholic/commands/ship.md`, `commands/report.md` — the leak tier in the
  consumer-facing severity description.
- `scripts/test-workflow-scripts.mjs` — 12 occurrences of `leak`.
- `plugins/workaholic/skills/release-scan/scripts/gate-decision.sh` — verify it is
  tier-generic and needs no change.

## Implementation Steps

1. Delete both `leak` blocks from `scan-branch-safety.sh`. The `.workaholic/leak-denylist`
   exclusion in the `added_lines` awk filter goes too — nothing reads that file now.
2. Remove `.workaholic/leak-denylist` from `.gitignore`.
3. Delete the local `.workaholic/leak-denylist` (untracked, 29 entries, created
   2026-07-15 01:15). It is a client-name list with no remaining reader.
4. Rewrite `release-scan/SKILL.md` to describe only `secret` and `size`. Remove the
   denylist section and the "conservative default" framing.
5. Rewrite `CLAUDE.md:268`. Delete the claim that the scan machine-enforces the
   convention, and the `leak` tier from the rule list. State what the scan does: it
   catches credential shapes and oversized diffs in `<base>..HEAD`. Say plainly that it
   does not detect client-context leakage and must not be relied on for it — the reader
   who believes otherwise is the failure mode being removed.
6. Update `ship.md` / `report.md` severity descriptions to two tiers.
7. Remove the leak assertions from `scripts/test-workflow-scripts.mjs`.
8. `node scripts/build-plugins/build.mjs` — `release-scan` is in `report`/`ship`'s script
   closure, so `outputs/workflows/skills/{report,ship}/` regenerate. Then `verify.mjs`
   and `validate-metadata.mjs`. CI's Outputs Freshness fails on any `outputs/` diff.
9. Update `README.md` / `.workaholic/README.md` if either describes the leak tier.

## Considerations

- **This removes a control and adds none.** Between this landing and `/request`
  shipping, there is nothing at all watching for client-context leakage. That is an
  honest statement of the current position rather than a change in it: the rule
  detected zero of five, so its removal subtracts zero detection. What it subtracts is
  the false belief in coverage, which is the actual hazard — the four leaks that were
  never in this repository happened with no scan present and nobody noticed for weeks.
- Do not replace it with a better pattern. That is the trap. The next pattern will
  also not know tomorrow's filenames. The reason this failed is not that the regex was
  poor; it is that the target is semantic.
- `sweep-todo.sh` and several `policies/*.md` matched a grep for "leak" — check each
  is the English word, not this rule, before touching.
- The 29 denylist entries are the only surviving record of which terms were judged
  sensitive. If that judgement has value, it belongs in the upstream qmu.co.jp safety
  article as prose, not as a git-ignored file on one machine.

## Policies

- `implementation/directory-structure` / `implementation/coding-standards` — universal.
- `implementation/objective-documentation` — the load-bearing one. Documentation must
  describe the actual behavior, not the intended behavior at the time of writing.
  `CLAUDE.md:268` and `SKILL.md:41` describe a capability that was never real.
- `design/defense-in-depth` — a layer that rejects nothing is nominal. The policy's own
  test, applied honestly, condemns this layer rather than asking us to patch it.
- `operation/ci-cd` — prevents "treating a green indicator — absent any evidence of
  what the inspection actually verified — as proof the code is healthy." A `pass`
  verdict from a rule with zero detection capability is exactly that green indicator.
- `safety/risk-management` — removing a control is a re-evaluation hook. Record the
  residual: no automated client-context detection exists, by decision.

## Quality Gate

1. **Prove the removal costs nothing.** Re-run the five real leaked sentences against
   the scan before and after. Before: zero `leak` findings. After: zero. Identical
   output is the evidence that no detection was lost. If the before-run produces a
   finding, this ticket's premise is wrong and it must stop.
2. **Prove the false positive is gone.** A diff that adds a `metadata.internal` line to
   `CLAUDE.md` must produce no finding after the change, and must be confirmed to
   produce one before it.
3. **`secret` and `size` are untouched.** Feed a known credential shape and an oversized
   diff; both still fire, `secret` still non-overridable via `gate-decision.sh`.
4. `node scripts/test-workflow-scripts.mjs`, `verify.mjs`, `validate-metadata.mjs` all
   green, and `outputs/` regenerated so CI's freshness diff is clean.
5. **No stale claim survives.** Grep the repo for any remaining sentence asserting the
   scan enforces the client-name convention. Zero hits.
