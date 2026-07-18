---
type: bugfix
layer: [Infrastructure]
effort: 0.1h
created_at: 2026-07-15T17:23:02+09:00
author: a@qmu.jp
depends_on: []
mission:
---

# The secret rule reads a function call as a literal, and hard-blocks `/ship` on it

> **Iceboxed 2026-07-15 — superseded, work delivered.** This ticket's argument was accepted
> and carried out. The developer chose its second direction (**Invert pass 2**), and the
> inversion shipped in `e3366bfd` via
> `.workaholic/tickets/archive/work-20260715-112717/20260715181934-invert-secret-pass2-to-match-values.md`,
> which carried the executable plan and the measured 40-row gate. Both shapes this ticket
> reported now subtract: `apiKey: keyOption(),` and
> `const htmlToken: Parser<Inline, null> = map<`.
>
> It is kept rather than deleted because the *argument* outlived the fix: a denylist of
> innocence can never be finished, and four subtractions retrofitted after four incidents is
> what that looks like from inside. That reasoning is the reason the current rule matches on
> the value, and it is the thing to re-read before anyone proposes a fifth subtraction.
>
> Two claims here were later measured FALSE and should not be trusted on re-read:
> `record-evidence.sh` does **not** share this file (it keeps an inline copy, and the two
> have drifted), and the inversion does **not** eliminate enumeration — `apiKey: string` and
> `password: mysecret123` are the same shape, so a bounded primitive list survives by
> necessity. See the successor's Findings and Final Report.

## Policies

Added at close (this ticket predates the mandatory section; it entered `todo/` only for its verification close):

- `workaholic:implementation` / `policies/objective-documentation.md` — every verdict here is measured against the real regexes, never reasoned about
- `workaholic:operation` / `policies/ci-cd.md` — the rule under test is a non-overridable `/ship` merge gate; its credibility budget is the ticket's whole argument

## Quality Gate

**Acceptance criteria**: the 12-shape regression bar in *How to Fix* holds against the current `lib/secret-patterns.sh` — all five guilty shapes flag, all seven innocent shapes subtract — and `record-evidence.sh` reaches the rules through the shared source, not an inline copy.

**Verification method**: pipe the shapes through `secret_grep` directly; confirm the suite's release-scan and record-evidence assertions are green.

**Gate**: the measured run and the green suite, recorded in the Final Report.

## Motivation

`secret_grep`'s pass 2 subtracts reference-shaped right-hand sides, because reading a key
from somewhere else is the *correct* way to handle secrets and flagging it "punished good
code and hard-blocked /ship on pure false positives" — the file's own words. The
subtraction covers a **bare identifier** and a **dotted path**. It does not cover a
**call**: `keyOption()` fails the terminator test — after the identifier comes `(`, not
one of `,;)}` — so the most ordinary way to fetch a credential in TypeScript is reported
on the one tier that cannot be waived.

Measured against the current `lib/secret-patterns.sh`:

| line | verdict |
|---|---|
| `apiKey: keyOption(),` | **flagged** — false positive |
| `apiKey: theKey,` | subtracted (correct) |
| `apiKey: "sk-abc123def456",` | flagged (correct — real literals still caught) |

So the rule's *intent* is right and its reach is one shape short. A `/ship` on a
TypeScript project that reads its key through an accessor is hard-blocked with
`{"decision": "block", "overridable": false, "hard": 5}`, and there is no bypass by
design (`gate-decision.sh`).

**This is the same failure the file keeps re-fixing.** Its comments record the previous
rounds in order: the environment-reference exclusions were added because good code was
punished; the `::` subtraction was added after "qfs, where 7 lines tripped the
non-overridable tier and 5 of them were DOC COMMENTS"; the `_SP_TYPE` annotation
subtraction was added because "`apiKey: string` … was reported on the one tier that
cannot be waived — in any TS codebase, on ordinary code"; the `([_-][A-Za-z0-9_-]*)?`
tail was added after `SECRET_KEY` and `aws_secret_access_key` passed straight *through*.
Each fix was correct, and each was reached only after a real branch was blocked.

**The pattern beneath them is the argument.** Every entry in that list is the same
mistake in a new costume: a key NAME is treated as evidence, when the right-hand side is
what decides. Pass 2's structure inverts the burden — it matches on the name, then
subtracts the innocent shapes one at a time, so the default for an unseen shape is
"hard-block, non-overridable". A denylist of innocence can never be finished; the next
unlisted-but-innocent shape is always a `/ship` outage. Four subtractions, each retrofitted
after an incident, is what an unbounded list looks like from inside.

**And the cost is not the blocked branch.** A non-overridable tier that keeps crying wolf
trains its readers to conclude "false positive again" without looking — the exact reflex
the tier exists to prevent. This ticket's own source is an instance: five findings,
verified by hand, all five noise, and the *correct* next thought was one keystroke away
from being "just override it".

## Findings

Two distinct shapes, both verified against the real regexes rather than reasoned about:

1. **Call on the right-hand side** — `apiKey: keyOption(),`, `const token = s.trim()…`.
   The identifier/dotted-path subtraction requires a terminator immediately after the
   path; a call puts `(` there. This accounts for 4 of 5 observed findings.
2. **A type annotation followed by a generic call** —
   `const htmlToken: Parser<Inline, null> = map<`. `_SP_TYPE` matches
   `Parser<Inline, null>`, but the branch then requires `= <identifier><terminator>` or
   `= <digit>`; `map<` satisfies neither, so it falls through to "literal". Note the
   identifier here is `htmlToken` — the keyword matched a **substring of a camelCase
   name**, not a key at all.

Shape 2 raises a question worth answering rather than patching: should the keyword match
require a word boundary? `htmlToken` and `firstToken` are not credential keys, and
`_SP_KEY` already carries a documented tail rule (`[_-]`-prefixed suffixes) that exists to
stop exactly this class of over-match on the *right* side. There is no matching rule on
the left, so any identifier ending in `…Token` is a candidate.

## How to Fix

Two directions; the second is the one the history argues for.

- **Narrow**: extend the subtraction to accept a call — `…[A-Za-z0-9_$]*\(…\)` before the
  terminator — and require a word boundary (or an `[_-]`/start-of-word prefix) on the key
  match so `htmlToken` no longer reads as `token`. Cheap, and it unblocks. It is also the
  fifth retrofit.
- **Invert pass 2** so it matches on the *value*, not the name: flag `key = <literal>`
  where a literal is a quoted string or a bare non-identifier run ending the line — the
  two shapes the file already says it means to catch (`.env`-style `TOKEN=value123`,
  `api_key = "sk-…"`). Everything else — identifier, path, call, template, annotation,
  environment read — is a reference and needs no enumeration. This turns an unbounded
  denylist of innocence into a bounded allowlist of guilt, which is the only version that
  stops accruing incidents.

Whichever is chosen, the regression bar should be the shapes already recorded in the
file's comments — they read as a test list that was never written down: `.env`-style bare
values, quoted `sk-…` literals, `api_key: sk-abc123`, `SECRET_KEY`,
`aws_secret_access_key`, `Token::Path`, `apiKey: string`, `apiKey: string | undefined`,
plus the two above. `secret_grep` is a pure stdin→stdout filter, so each case is one line.

## Considerations

- **Do not weaken pass 1.** The unmistakable key shapes (`AKIA…`, `gh*_`, `xox*`, PEM) are
  matched unconditionally and must stay that way; this ticket is only about pass 2's
  generic-assignment family.
- **The non-overridable tier is right, and that is why this matters.** The fix must not be
  "make secrets overridable". A tier that cannot be waived has to be near-zero
  false-positive to stay credible — which raises the bar on pass 2 rather than lowering it.
- **`record-evidence.sh` shares this file** (per its header, `scan_secrets()` was factored
  out into it), so a change lands in both the branch scanner and the evidence guard.
  Whatever regression list is written should run against both callers.
- Observed on a TypeScript monorepo whose `/ship` was blocked. The shapes above are
  ordinary TypeScript and carry nothing project-specific.

## Final Report

Closed as **verified delivered** (2026-07-18, no code change). Every demand was measured
against the current tree rather than trusted from the icebox note:

- Both reported shapes subtract: `apiKey: keyOption(),` and
  `const htmlToken: Parser<Inline, null> = map<` pass `secret_grep` silently.
- The full regression bar (12 shapes from How to Fix) holds: all five guilty shapes flag
  (`TOKEN=value123…`, quoted and bare `sk-…`, `SECRET_KEY=…`, `aws_secret_access_key = …`),
  all seven innocent shapes subtract (`Token::Path`, both annotations, call, generic call,
  identifier, `process.env` read).
- The drift this ticket's icebox note reported is also gone: `record-evidence.sh` now
  sources the shared `lib/secret-patterns.sh` and reuses `secret_pass1_grep`; its
  deliberate non-use of pass 2 is documented in its header.
- The regression list exists as suite assertions (literal-vs-reference, suffixed keywords,
  value inversion, record-evidence shared rules) — 964 tests green.

### Discovered Insights

- **Insight**: The bounded-allowlist-of-guilt argument held in practice — no fifth
  subtraction was ever needed after the inversion; the two shapes this ticket reported were
  covered by the value rule without any new enumeration.
  **Context**: Re-read this ticket's Motivation before proposing any keyword-side
  subtraction to `secret-patterns.sh`; the argument is the reason the rule matches values.
