---
created_at: 2026-08-02T09:30:00+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
priority: P1
effort: 1h
commit_hash:
category: Changed
depends_on:
claim: work-20260804-112404
---

# `submit-request.sh`'s last backstop substring-matches the source repo name, so a repo whose name is a common word can never file any request

## Overview

`skills/request/scripts/submit-request.sh:50-53` refuses a body that still names
the calling repository:

```sh
source_name="$(basename -- "$SOURCE_ROOT")"
if grep -qiF -- "$source_name" "$body_file"; then
    emit_err "body still names this repository ('${source_name}') — mask it and re-confirm"
fi
```

The match is a **case-insensitive plain substring** over the whole body. When the
calling repository's basename is an ordinary English word, that word also occurs
inside directory names on both sides of the request — including directories that
belong to the *target* repository and have nothing to do with the caller.

Worked example, with the real name replaced by `atlas`. A repo named `atlas`
files a ticket asking a sibling site repo to wire up a set of generated pages.
The body is a list of roughly seventy path pairs:

```
docs/atlas-reports/foo.md -> docs/site-atlas/foo.md
```

- the left side is the caller's own output directory,
- the right side is **the target repository's own directory name**.

Neither names the caller *as a repository*, but both contain the substring, so
the backstop refuses. The list of paths is the ticket's only content, so there is
nothing to remove: the refusal is unconditional and the request can never be
filed by any legitimate means.

Observed 2026-08-02 on a real run. The developer had already passed the
`/request` confirmation gate — destination and verbatim body reviewed and
approved — and the mechanical backstop underneath it then refused the submission
with an instruction ("mask it") that cannot be followed.

## Current behavior

Any body containing the caller's basename as a substring is refused, including as
part of an unrelated path segment (`<name>-reports/`, `site-<name>/`) and inside
ordinary prose using the word in its dictionary sense.

The refusal is silent about *why* it matched, so the developer sees an accusation
of leaking a repository name against a body that leaks nothing.

## Expected behavior

The backstop refuses a body that references the calling repository **as a
repository**, and passes a body where the same characters appear as part of an
unrelated identifier.

## Steps

1. Replace the substring test at `:50-53` with a boundary-aware or
   remote-form-aware match. In preference order:
   - match the `owner/name` form and the clone URL taken from the caller's
     `origin` remote — unambiguous, and the shape an actual reference takes;
   - failing that, match the bare basename only where it is **not** adjacent to
     `-`, `_` or `/` on either side, so `<name>-reports` and `site-<name>` do not
     match while a standalone mention does.
2. Leave the absolute-path test at `:54-56` exactly as it is. It is an exact
   match with no false-positive mode, and it is the check that actually carries
   weight.
3. Make the error message name what matched and where (line number and the
   matched text), so a future false positive is diagnosable instead of
   mysterious.
4. Add fixtures covering both directions — see the Quality Gate below.

## Considerations

- **Do not weaken the true positive to fix the false one.** A bare mention of the
  caller by name, its absolute path, and its `owner/name` remote form must all
  still be refused. The narrowing is about adjacency, not about dropping checks.
- **Do not solve this by renaming the offending repository.** The next repo whose
  name is a common word hits the same wall, and the check would still be wrong.
- The `/request` confirmation gate is working correctly and must not be touched.
  The skill is explicit that the backstop is "not a substitute for the
  confirmation" — this change keeps that relationship and only repairs the
  mechanism underneath it.
- Worth noting in the skill text: the backstop is the one place where a
  legitimate request can be refused *after* the developer has approved it, so its
  false-positive rate is a usability property, not just a safety one.

## Policies

- **fail-fast, machine-checkable gaps** — a backstop that cannot distinguish an
  identifier from a substring fails closed on legitimate work. Its matching rule
  must be explicit and covered by fixtures rather than left incidental.
- **objective-documentation** — the current error instructs the developer to do
  something impossible. An error message must describe an action that exists.
- **security design** — the confinement rule is correct and survives this change.
  Narrowing a false positive must not widen the true positive.
- **ci-cd** — a delivery step that can never succeed is worse than an absent one:
  it reports a masking failure whose real cause is invisible from the message.

## Quality Gate

**Acceptance criteria**

1. A body containing only path segments that embed the caller's basename
   (`docs/<name>-reports/x.md`, `docs/site-<name>/x.md`) submits successfully.
2. A body containing a standalone mention of the caller by name is still refused.
3. A body containing the caller's absolute path is still refused.
4. A body containing the caller's `owner/name` remote form is still refused.
5. The refusal message names the matched text and its line, for all three
   refusing cases.

**Verification method**

Fixture-driven test over `submit-request.sh` with one body per criterion,
asserting the script's raw exit status and the JSON `ok` field with no pipes
masking the status. Mutation-check the new matcher: revert it to the substring
form and confirm criterion 1 fails.

**Gate that must pass**

The new fixture test, plus this repository's existing lint and test targets, with
bare unmasked exit codes.

## Final Report

Development completed as planned. The preference order in the ticket's step 1 was taken
literally: the `owner/name` and clone-URL forms are matched exactly and are *new* checks,
and the bare-name test is narrowed to adjacency rather than replaced by them.

### Discovered Insights

- **Insight**: The `owner/name` and clone-URL forms were never checked before — the old
  backstop caught them only *incidentally*, as a side effect of the bare-name substring
  match. Narrowing the substring rule without adding them would have been a net loss of
  true positives, not a neutral change.
  **Context**: This is why the ticket's "do not weaken the true positive to fix the false
  one" is not satisfied by adjacency alone. The two exact checks are what let the loose one
  become strict.

- **Insight**: POSIX ERE has no `\b`, so the adjacency rule is spelled as explicit
  neighbour classes: `(^|[^A-Za-z0-9_/-])<name>([^A-Za-z0-9_/-]|$)`. Alphanumerics are
  excluded alongside `-`, `_` and `/`, which is slightly stricter than the ticket asked —
  `<name>Reports` no longer matches — and is right for the same reason: it is a different
  identifier, not a mention of this repository.
  **Context**: `$` inside a double-quoted shell string needs escaping (`\$`) or the shell
  eats it before grep ever sees the pattern.

- **Insight**: The repository basename can itself contain regex metacharacters (a `.` in
  the directory name is enough), so the bare name is escaped before it becomes part of an
  ERE. The three exact checks stay `grep -F` and need no escaping at all — which is a
  reason to prefer them wherever a form is available.
  **Context**: A backstop that mis-parses its own repository name would fail open, which is
  the direction this check must never fail in.

- **Insight**: This backstop is structurally different from every other check in the
  script: it is the only one that can refuse work the developer has *already approved*.
  That makes its false-positive rate a usability property, and it is why the refusal now
  cites the matched text and its line — a mysterious refusal after a verbatim confirmation
  is the shape that made the original defect unrecoverable.
  **Context**: Recorded in `request/SKILL.md` §6 and in CLAUDE.md's repository-confinement
  section, so a future narrowing has the reasoning rather than just the rule.
