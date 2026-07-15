---
type: enhancement
layer: [UX, Domain]
created_at: 2026-07-15T12:10:48+09:00
author: a@qmu.jp
depends_on: [20260715121047-confine-writes-to-current-repo.md]
---

# Add /request: the only sanctioned path for filing a ticket in another repository

## Motivation

Its sibling ticket confines every workflow's writes to the current repository. That
confinement is only honest if the legitimate need it blocks has an outlet — a
developer working in one repository genuinely does need to raise work against
another. Without `/request`, the confinement becomes an obstacle developers route
around, and a rule that gets routed around is worse than no rule, because it also
teaches that the rules are negotiable.

`/request` is that outlet, and it is deliberately narrow: it is the *only* way to
write into another repository, and it cannot file anything without first confirming
that our customer context has been masked out.

## The judgment is the control, not the pattern

The masking confirmation is a **judgment step, not a matcher**, and this is the
central design decision — do not implement it as a regex pass and call it done.

The evidence is direct. The terms that actually leaked across five repositories were
a private component name, a document filename with its byte size, a mail label
carrying an honorific, and an internal hostname. **None of them were enumerable in
advance.** A denylist cannot list a filename before the file exists. Every
deterministic control in this repo — the denylist, the secret regexes, the scan —
is structurally incapable of recognising them.

What did work, observably: during this investigation an egress check applied a
*judgment* about whether content was appropriate to send across a boundary, and
caught a leak that this repo's own scan was structurally blind to. `/request` puts
that same judgment at the crossing point.

## Key Files

- `plugins/workaholic/commands/commit.md` — the cleanest thin-command exemplar (46
  lines) to copy structurally.
- `plugins/workaholic/skills/create-ticket/SKILL.md` — the ticket shape, frontmatter
  template, and Output Contract a filed request must satisfy in the *target* repo.
- `plugins/workaholic/skills/gather/scripts/project-label.sh` — every
  `AskUserQuestion` body must open with `[<project label>]`;
  `hooks/guard-askuserquestion-label.sh` blocks otherwise.
- `plugins/workaholic/skills/release-scan/scripts/scan-branch-safety.sh` — the
  deterministic layer to run *in addition to* the judgment, never instead of it.
- `scripts/build-plugins/build.mjs:50` (`DEFAULT_TARGETS`) — registration point if the
  skill should reach non-Claude agents.
- `.claude-plugin/marketplace.json` — version lockstep.

## Implementation Steps

1. `commands/request.md` — thin orchestration; all `AskUserQuestion` at command level.
2. `skills/request/SKILL.md` (+ `scripts/`) — the knowledge layer. Script-bearing, so
   `metadata.internal: true` is mandatory.
3. Resolve the target repository explicitly and confirm it with the developer. Never
   infer it silently.
4. Compose the request body, then **mask**: strip our customer context — repo names,
   filesystem paths, component names, document filenames, hostnames, infrastructure
   resource names, account identifiers, and any concrete grounding detail carried from
   the source context.
5. **Present the masked body to the developer for confirmation before writing
   anything.** This step is non-skippable. There is no "obviously clean" fast path —
   an optional confirmation is a convention, and conventions are what failed here.
   The confirmation must show the body verbatim as it will be filed.
6. Run `scan-branch-safety.sh` over the composed body as a second, deterministic layer
   underneath the judgment. It will catch the enumerable subset. It must not be
   treated as sufficient.
7. Write the ticket into the target repo's `.workaholic/tickets/todo/<user>/`,
   conforming to `create-ticket`'s Output Contract so the target's `/drive` can consume
   it unmodified.
8. Update `CLAUDE.md`'s command table, `README.md`, `.workaholic/README.md`.
9. `node scripts/build-plugins/build.mjs`, then `verify.mjs` and `validate-metadata.mjs`.

## Considerations

- **Compose-then-mask is the weaker of two shapes; we are choosing it knowingly.**
  The alternative is a synthetic request builder that never carries source context at
  all — build the request from the *target* repo's vocabulary plus synthetic
  placeholders, so there is nothing to mask and "forgot to mask" cannot occur by
  construction. That is structurally safer and materially heavier. Recording the
  trade here: if masking is observed to miss anything in practice, that is the
  trigger to move to the synthetic shape, and the miss should be treated as a
  design signal rather than an isolated mistake.
- `/request` is a new egress path from private context toward potentially-public
  repositories. That is precisely the hazard this incident was made of. It is
  justified only by being narrow, explicit, and confirmed — if any of those three
  erode, it becomes a sanctioned leak channel.
- The target repo may be public while the source is private. The confirmation prompt
  should say which, because it changes what the developer is agreeing to.
- One-level fan-out: subagents cannot call `AskUserQuestion`, so the confirmation
  lives at the command level.

## Policies

- `implementation/directory-structure` / `implementation/coding-standards` — universal.
- `planning/legal-compliance-check` — a command that moves content toward a public repo
  has NDA and personal-information obligations as a design premise, not an afterthought.
- `planning/terminology` — one word per concept for the masking vocabulary and the
  placeholder form.
- `design/data-sovereignty` — data minimization: carry only fields with a specific use.
  What is never sent cannot leak; this is the argument for the synthetic shape.
- `design/defense-in-depth` — the judgment and the deterministic scan are two
  independent layers. Neither may be collapsed into the other.
- `design/self-explanatory-ui` — the confirmation must make what will be filed, and
  what was masked, legible before the developer agrees. No silent success.
- `implementation/objective-documentation` — the scan layer cites `file:line` + rule.
- `safety/standard` — §6/§7. The rule this command exists to serve.
- `safety/privacy-policy` — a new egress path for personal information.
- `safety/risk-management` — a new externally-exposed path is a mandatory
  re-evaluation hook; record the accepted residual (unknown-term leakage the mask
  cannot anticipate).
- `safety/incident-report` — what to do when masking is found to have failed after
  the fact.

## Quality Gate

Test-green is not the gate. 538 tests were green while five repositories leaked.

1. **The confirmation cannot be skipped.** Drive a request end-to-end and confirm by
   observation that no path — not a clean body, not a re-run, not an approval given
   earlier in the session — files anything without the developer seeing the final body.
   If a fast path exists, the ticket has failed.
2. **Replay the real incidents.** For each of the four contaminated sibling
   repositories, take the actual leaked sentence and attempt to file it through
   `/request`. The masking step must remove the customer context in each. These are
   real, verified leaks with known-correct answers, which makes them a better gate
   than any synthetic fixture — and they are the specific cases the current controls
   provably miss.
3. **The filed ticket is consumable.** The ticket written into the target repo passes
   that repo's `validate-ticket.sh` and is picked up by its `/drive` without hand-editing.
4. **The confinement still holds.** With `/request` shipped, a direct cross-repo write
   outside `/request` is still refused (the sibling ticket's gate is not weakened by
   adding the outlet).
