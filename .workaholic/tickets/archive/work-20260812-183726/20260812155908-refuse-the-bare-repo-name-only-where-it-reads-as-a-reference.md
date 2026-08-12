---
created_at: 2026-08-12T15:59:08+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260812155852-check-outbound-body-sh-refuses-ordinary-prose-not-only-references.md]
merge_policy:
claim: work-20260812-183726
---

# Refuse the bare repo name only where it reads as a reference

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it from a
     proposal into queued work. -->

`check-outbound-body.sh`'s last rule refuses this repository's basename wherever it stands
alone as a word. For a repository whose basename is an ordinary English word, a standalone
occurrence is usually not a reference to the repository — it is just the language. The
2026-08-02 narrowing fixed adjacency to *identifier* characters; it did not address prose.

Measured 2026-08-12 (qmu/workaholic#384) on a body that was a generated publish plan —
about seventy path pairs plus their headings and page titles. It was refused on two lines
naming no repository: the plan's own heading, and a line carrying a published article's
title that has to be reproduced verbatim because it doubles as the destination's sidebar
label. The refusal instructs "mask it and re-confirm", and for the title that names an
action that does not exist — masking it would mean changing a published page's title to
satisfy a lint. This fires *after* the developer's verbatim confirmation, the one place a
legitimate ask can still be refused past the human gate, so its false-positive rate is a
usability property as much as a safety one.

The proposal is to recognise a *reference* by adjacency, the same way 08-02 recognised an
identifier. The exact checks — every clone URL form, the `owner/name` slug, the absolute
path — do not change and keep carrying the weight.

## Policies

- `workaholic:safety` — the backstop is a security control; any narrowing states what it
  gives up and why the remaining controls still hold.
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh`, no bashisms
  (`plugins/workaholic/rules/shell.md`); the script runs under `set -eu` with `grep`
  exiting 1 on no match, a shape the existing helpers already handle.
- `workaholic:design` / the crossing's human confirmation remains the actual control; a
  mechanical check must not become optional.

## Key Files

- `plugins/workaholic/skills/feedback/scripts/check-outbound-body.sh` — the bare-name rule
  is the final check (`name_re` / `first_ere`, end of file); the four exact rules above it
  are untouched. Its header documents the 08-02 narrowing and must record this one too.
- `scripts/test-workflow-scripts.mjs` — pins the current behaviour in **two** places:
  "check-outbound-body refuses a body naming the source repo" / "a standalone mention is
  still refused" (~L7303, ~L7326) and "check-outbound-body refuses a standalone mention of
  this repo" (~L7577). Both assertions encode the rule being changed.
- `plugins/workaholic/skills/feedback/SKILL.md` — describes the backstop as refusing "its
  name as a standalone identifier"; that sentence becomes wrong.
- `plugins/workaholic/skills/feedback/reference/crossing.md` — the same claim in the
  crossing's own reference (~L91).
- `plugins/workaholic/rules/general.md`, `CLAUDE.md` — state what the confinement/crossing
  guarantees; check whether either restates the bare-name rule.

## Implementation Steps

1. **Reproduce first.** Build a body in a throwaway checkout whose basename is an ordinary
   word (the suite's existing `body()` / `json()` helpers do this) containing: a heading
   using the basename as a plain capitalised English word, and a line quoting a title that
   contains it. Run `check-outbound-body.sh` and record the actual refusal text and line
   citation. Do not proceed on the report's description alone.
2. **Localize.** Confirm the refusal comes from the final bare-name rule and not from the
   slug, clone-URL, or absolute-path rules — the 2026-08-02 incident recorded in the
   script's header is precisely a case where the wrong rule fired and named the wrong thing
   to mask, so identify the rule by its emitted message, not by inspection alone.
3. **Implement the adjacency test.** Refuse the basename when it reads as a reference:
   - inside backticks — code formatting marks it as a token rather than prose;
   - adjacent to a repository-indicating noun: `<name> repo`, `<name> repository`,
     `<name> checkout`, `<name> worktree`, `<name> project`, and the reversed
     `repository <name>` form.
   Otherwise let it pass. Keep the case-insensitivity and the existing identifier-adjacency
   exclusion; keep every refusal citing the matched text and its line.
4. **Do not add a skip flag.** The reporter rules this out and the reasoning holds: an
   escape hatch reachable by the agent the backstop exists to constrain turns a mechanical
   check into an optional one.
5. **Rewrite the pinned assertions rather than deleting them.** At both sites, replace
   "a standalone mention is still refused" with the pair this change actually means: a
   *qualified* mention (backticked, or beside a repo-indicating noun, both orders) still
   refuses and still names the matched text and its line; a plain-prose mention passes.
   Every other true positive — clone URL in each form, `owner/name`, absolute path, glued
   identifiers, embedded path segments — must still assert exactly as today.
6. **Update the prose in the same change**: the script header (record this narrowing beside
   the 08-02 one, including what it gives up), `feedback/SKILL.md`, and
   `feedback/reference/crossing.md`.
7. Regenerate `outputs/` (`node scripts/build-plugins/build.mjs`) — a feedback-skill script
   changed, so the bundle is stale until rebuilt and `Outputs Freshness` CI fails on the
   diff.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A body using the basename as ordinary prose (heading, quoted title) passes.
- A body naming it in backticks, or beside `repo`/`repository`/`checkout`/`worktree`/
  `project` in either order, still refuses, citing the matched text and its line.
- Every exact rule is unchanged and still refuses: each clone-URL form, `owner/name`, the
  absolute path.
- No new flag, env var, or argument can bypass the check.
- The script header and both prose documents describe the rule that now runs.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the rewritten assertions at both sites, green.
- The step-1 reproduction re-run against the fixed script, before/after output in the
  Final Report.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` clean.

**Gate** — what must pass before approval:

- The reproduction is recorded before the fix, per the diagnosis-first rule.
- The Final Report names the true positive being given up (an unqualified bare mention in
  prose now passes) and why the remaining controls still hold.

## Considerations

- The reporter's adjacency rule is recorded as their proposed mechanism; step 1 reproduces
  and localizes before adopting it. If localization shows a different rule fired, that is
  the finding, and this design is revisited rather than applied on top.
- The noun list is a judgment call with no exhaustive answer. Keep it short and literal
  rather than growing it speculatively — a missed qualifier now passes as prose, which is
  the same trade this change already accepts, and the verbatim human confirmation remains
  the control.
- Case and possessives (`<Name>'s repo`) are worth one thought each while writing the
  expression; a possessive form is still a reference.
- This is one narrowing later on the same rule. Whatever the pattern becomes, the script's
  header is where the next reader learns why — keep it the record, not the commit message.

## Final Report

Development completed as planned.

### Reproduction, before the fix (step 1)

A body of the reported shape — a heading using the basename as a plain capitalised English
word, plus a line quoting a published article's title that contains it — run against the
unmodified script from this repository (basename `workaholic`, an ordinary English word):

```
{"ok": false, "error": "body still names this repository ('workaholic') at line 1:# Workaholic publish plan — mask it and re-confirm"}
```

The quoted-title line alone refuses identically:

```
{"ok": false, "error": "body still names this repository ('workaholic') at line 1:The article Being a workaholic is not a strategy keeps its title verbatim. — mask it and re-confirm"}
```

### Localization (step 2)

Identified by the **emitted message**, not by inspection: the refusal text is the bare-name
rule's own (`body still names this repository ('<name>')`). The three exact rules above it
were each exercised on their own input and each fired with its own distinct message —
`clone URL at line …`, `names this repository as 'qmu/workaholic' at line …`,
`contains this repository's path at line …` — so the wrong-rule failure mode recorded in the
script's 2026-08-02 header is not what happened here.

### The same reproduction, after the fix

```
# Workaholic publish plan / quoted-title line   -> {"ok": true}
```

### What changed

- `check-outbound-body.sh`'s final rule now requires a **qualifier** as well as the existing
  identifier-adjacency exclusion: a backtick on either side, or one of `repo`, `repository`,
  `checkout`, `worktree`, `project` directly before or after the name, possessive (`'s`,
  `’s`) allowed, case-insensitive, both orders. The regex is assembled from named parts
  (`lb`/`rb`/`noun`/`poss`) so the next reader can see the rule rather than parse it.
- No flag, env var or argument can bypass it — step 4 of the plan, deliberately.
- The four exact rules (each clone-URL form, `owner/name`, absolute path) are byte-unchanged.
- Both pinned test sites rewritten rather than deleted: eight qualified forms still refuse
  and still cite matched text + line, and the prose cases now assert a pass.
- Prose updated in the same change: the script header (this narrowing recorded beside the
  08-02 one, including what it gives up), `feedback/SKILL.md`, `feedback/reference/crossing.md`
  (the two narrowings now read as one adjacency story). `rules/general.md` and `CLAUDE.md`
  restate neither rule, so neither needed a change.
- `outputs/` regenerated — the feedback skill's script closure ships in the `catch` and
  `mission` bundles.

### The true positive being given up

An **unqualified** bare mention in prose now passes ("A ticket that still says `<name>` in
the text"), and so does a qualifier outside the five-noun list, including its plurals. The
remaining controls still hold: the `owner/name` slug, every clone-URL form and the absolute
path are matched exactly and carry the real weight, and the developer's verbatim
confirmation of destination and body is — as the script's header has always said — the
actual control. This was never assurance, and a pass still means only "our own name is
absent in the forms we can mechanically know".

### Discovered Insights

- **Insight**: `check-outbound-body.sh` resolves the source repository from the **caller's
  cwd** (`git rev-parse --show-toplevel`), not from the body or any argument.
  **Context**: a reproduction that builds a throwaway repo and invokes the script by
  absolute path silently checks the *calling* repository instead. The controls in this
  ticket's step 2 read as false passes until the invocation was run against the repo whose
  remote forms were actually being matched. Anyone extending the crossing tests should note
  the suite's `json(cwd, script, args)` helper exists precisely to pin that cwd.
- **Insight**: the noun list is a judgment surface with no exhaustive answer, and it was
  deliberately left at the five singular forms the ticket named — plurals (`repos`,
  `worktrees`, `repositories`) are **not** matched.
  **Context**: a missed qualifier passes as prose, which is the same trade the change
  already accepts, and the alternative is an ever-growing morphology list inside a backstop
  whose header insists it is not assurance. If a real refusal is ever missed on a plural,
  that is the evidence to grow the list — not speculation.
