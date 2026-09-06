---
created_at: 2026-09-07T07:05:14+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260907070309-a-scratchpad-redirect-must-not-assume-truncates.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
merge_policy:
verification_handoff: 
claim: work-20260907-074532
---

# Say that a scratchpad redirect must not assume > truncates

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it from a
     proposal into queued work. -->

Add one rule to `plugins/workaholic/rules/shell.md`: a shell redirect into the scratchpad
must not assume `>` truncates. Under `noclobber` — which this machine's login shell sets —
a `>` onto an **existing** path writes nothing, and a run that carries on reads whatever
was already in the file. The consequence is a **stale read**, not an empty one, which is
why the failure is dangerous: a run that redirects, then parses, then acts has data that
looks fresh and belongs to a different run.

Measured twice in one session before it was filed: a `/moderate` tick began parsing a
17-hour-old JSON from a different tick, and a `/specificate` run carried the stale body of
a **different issue (#1012)** into a feedback record. The second was caught by the run's
own vigilance before it published — nothing mechanical caught either.

The rule's home is settled by precedent rather than by judgement: `rules/shell.md` already
carries two rules about what an **agent composes at run time** rather than about `*.sh`
files (*Reading a plugin script: a read tool, never a Bash text pipeline* and *Composing
the call: the path in full, the reader first, no assignment prefix*), and both state in
their own words that enforcement is a human reading them because the composition never
appears in this tree. This is the third rule of exactly that shape.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `plugins/workaholic/rules/shell.md` — the file this rule joins; match the voice of its two
  existing run-time-composition sections (state the measurement, state what it does not fix)

## Key Files

- `plugins/workaholic/rules/shell.md` — the one file this ticket edits. The new section
  goes beside the two existing run-time-composition rules, not among the POSIX `*.sh`
  conventions at the top.
- `plugins/workaholic/rules/interaction.md` — read only, to confirm the wider rule this is
  an instance of (*An unattended run never waits for a person*); cite it, do not restate it.

## Implementation Steps

1. **Confirm the behaviour on this machine before writing a rule that asserts it.** A rule
   that overclaims is falsifiable by the first reader who tries it. The reproduction is one
   command and it has already been run once (see Considerations for what it returned);
   re-run it so the ticket's own claim is measured rather than inherited:

   ```sh
   printf 'STALE\n' >| /tmp/probe.txt
   sh -c "set -C; printf 'FRESH\n' > /tmp/probe.txt; echo exit=\$?"
   cat /tmp/probe.txt
   ```

2. **Write one section into `plugins/workaholic/rules/shell.md`**, placed after *Composing
   the call: the path in full, the reader first, no assignment prefix*. It must say **both**
   halves, because either alone is insufficient:
   - `>` onto an **existing** path may fail and write nothing (under `noclobber`, which is
     the operator's own profile setting and is inherited by every command this session
     composes); and
   - the consequence is a **stale read**, not an empty one — the next reader gets a
     different run's data and has no signal anything went wrong.

   State the repair in the ask's own terms: **`>|`, or a filename unique to the run.**

3. **Carry the measurement into the section**, as the file's two sibling rules do — the two
   occurrences (the `/moderate` tick's 17-hour-old JSON, the `/specificate` run's #1012
   body) and the reproduction from step 1.

4. **State what the rule does not do**, again as its siblings do: nothing mechanical checks
   it, because the redirect is composed at run time and appears in no file this repository
   could scan. Name the three refused repairs from the ask so a later session does not
   re-derive them — the operator's shell configuration is not this repository's to change, a
   `PreToolUse` deny would convert a silent failure into a mid-run refusal (a different
   failure, not obviously better), and the scratchpad's residue is not the defect so no
   scheduled clean is added.

5. **Update the documentation in the same change** (`CLAUDE.md`, *Enforcement gates*, where
   the sibling composed-shell rules are already summarised) so the new rule is discoverable
   from the same place as the two it joins. Keep it to one clause; the story stays in
   `rules/shell.md`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `plugins/workaholic/rules/shell.md` carries one new section stating both halves — that `>`
  onto an existing path may write nothing, and that the consequence is a **stale read**.
- The section names `>|` **and** a run-unique filename as the repair, and names the three
  non-goals (shell config, `PreToolUse` guard, scheduled clean) as refused with their reasons.
- The section sits among the run-time-composition rules, not among the POSIX `*.sh`
  conventions, and it says in its own words that nothing mechanical enforces it.
- `CLAUDE.md` names the rule in the same commit.
- No hook, no check, no script and no shell configuration is added or changed.

**Verification method** — the commands/tests/probes that prove them:

- The reproduction in step 1 returns a non-zero redirect status and a stale `cat`.
- `node scripts/test-workflow-scripts.mjs` — the suite pins the four routine-fired ceilings
  byte-identically against their sources; run it to prove this edit disturbed none of them.
- `sh plugins/workaholic/hooks/posix-lint.sh` — no `*.sh` file changed, so it must stay clean.

**Gate** — what must pass before approval:

- The suite above is green and the rule reads as a rule rather than as a description of an
  incident.

## Considerations

- **The word "silently" is the one thing to get right, and the measurement narrows it.**
  Measured on this machine (login `zsh` reports `noclobber` set): `sh -c "set -C; printf
  'FRESH\n' > <existing>"` prints `cannot create <path>: File exists` on **stderr** and exits
  **2**; the file keeps its old bytes and a following `cat` prints them. So the redirect is
  not literally silent — it is **unnoticed**: the message is one line among a tool result, the
  non-zero status is not checked when the redirect sits in a `;`-chain or a heredoc, and the
  next read succeeds with the wrong content. Prefer wording like *may fail and write nothing*
  over *fails silently*; the second is falsifiable in one command and would weaken the rule.
  `>|` on the same path exits 0 and writes.
- **`rules/shell.md` declares `paths: '**/*.sh'` in its frontmatter**, while this rule governs
  a command an agent composes and not a script in the tree. That mismatch already exists for
  the two sibling sections and is not this ticket's to fix; do not move the rule to another
  file over it, and do not change the frontmatter as a side effect.
- **A mechanical row was considered and is refused here for the reason its sibling records.**
  The precedent that fails on `gh issue|pr|repo` keys on a command whose every use is wrong;
  `>` is correct in the overwhelming majority of its uses in this tree, and a row keying on
  "a redirect whose target is under the scratchpad" cannot tell an agent's composed command
  from a script's own output because the composition never appears in a file.
- **Scope discipline**: this is one section plus one `CLAUDE.md` clause. Resist auditing the
  tree for existing `>` redirects — the rule governs what a run composes next, and a sweep
  of committed scripts is a different change answering a question nobody asked.

## Final Report

Development completed as planned. `plugins/workaholic/rules/shell.md` carries one new section,
*A scratchpad redirect must not assume `>` truncates*, placed after *Composing the call: the path
in full, the reader first, no assignment prefix* and before *Reaching GitHub: REST only, never
GraphQL* — among the run-time-composition rules, not among the POSIX `*.sh` conventions. `CLAUDE.md`
names it in one clause under *Enforcement gates*, beside the two sibling rules it joins. No hook,
check, script or shell configuration was added or changed, and the file's `paths: '**/*.sh'`
frontmatter was left alone.

The behaviour was re-measured before the rule was written rather than inherited from the ticket:
`sh -c "set -C; printf 'FRESH\n' > <existing>"` printed `cannot create <path>: File exists` on
stderr, exited **2**, left the old bytes in place, and the following `cat` printed `STALE`; the
same command with `>|` exited 0 and wrote. That is what the section claims and no more.

### Discovered Insights

- **Insight**: The ticket's Key Files entry asks the section to cite `rules/interaction.md`,
  *An unattended run never waits for a person*, as "the wider rule this is an instance of". Read in
  full, that section's axis is *a run with no human present composes only commands an allowlist can
  name*, and its two named cases are both about a composed command reaching a permission dialog.
  A `noclobber` redirect raises no dialog — the failure is the opposite of waiting, since the run
  carries on with another run's data. The section therefore cites it as a **shape** sibling (a rule
  about what a run composes at run time, holdable by nothing in this tree) and says plainly that it
  does not share the subject.
  **Context**: The ticket's own Considerations warn that "a rule that overclaims is falsifiable by
  the first reader who tries it". Writing the citation as an instance-of would have been exactly
  that failure inside the rule warning against it. A later reader adding a fourth rule of this shape
  should check the same thing: the three siblings share a *home* and an *enforcement story*, not a
  cause.

- **Insight**: `plugins/workaholic/rules/` is outside the generated-bundle closure — an
  argument-less `node scripts/build-plugins/build.mjs` after this edit produced no diff under
  `outputs/`, so a rules-only change never needs a regeneration commit.
  **Context**: The `Outputs Freshness` CI workflow fails on any `outputs/` diff, which makes the
  build worth running as a check even for a change that cannot plausibly touch it; running it costs
  seconds and proves the negative.
