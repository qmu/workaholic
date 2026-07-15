---
type: enhancement
layer: [Domain, Config]
created_at: 2026-07-15T14:39:54+09:00
author: a@qmu.jp
depends_on: []
mission:
---

# Let an artifact relate to more than one mission

## Motivation

A `/report` run covered work that advanced two missions and had to ask the developer
which single one the story belonged to. Whichever they picked, the other relation was
discarded — and with it, that mission's rolled-up progress.

**The scalar shape was never argued.** The ticket that introduced `mission:`
(`20260706203045-mission-frontmatter-linkage`) does not discuss cardinality anywhere; its
Considerations cover optionality, slug integrity, and backfill scope, and nothing else.
The `planning/terminology` policy it cites governs *naming* — one concept, one word — not
how many values a field holds, so it cannot be read as the rationale.

**And the model already contradicts it.** That same ticket made every *other* relation
plural in the same breath: `tickets: [...]` on stories and concerns, and reserved
`tickets: []` / `stories: []` / `concerns: []` on `mission.md` itself. The foundation
ticket calls a mission "a durable narrative and a machine-readable **web** of relations".
`mission:` is the only singular relation in the whole model — an unexamined asymmetry, not
a decision. Pluralising it makes the schema self-consistent; it does not reverse anything.

**The loss is specified, not accidental.** `report/SKILL.md:588` is the one place
cardinality is confronted, and it resolves it by asking a human to throw a true relation
away:

> if they disagree (more than one distinct slug), ask the developer which mission the
> story belongs to (or none) via `AskUserQuestion`.

So the multi-mission case was anticipated and coped with rather than modeled. That also
sits badly with the model's own commitment that progress is *computed, never a hand-set
number*: forcing a human to discard a real relation makes the mission→work graph
subjective and silently under-counts the discarded mission. After this change the
disagreement branch **disappears** — the union of the covered tickets' slugs *is* the
story's mission list — rather than being re-tuned into a nicer prompt.

## Scope

**In:** the artifact→mission relation becomes many-valued on tickets, stories, and
concerns.

**Out:** mission-to-mission hierarchy. `20260709023256` explicitly instructs "never
conflate mission / trip / epic"; parent/child has no prior art here and stays out.

**Out:** backfilling history. Per the standing concern
`existing-artifacts-are-not-backfilled-into`, emission is forward-only — the ~15 existing
artifacts carrying an empty scalar `mission:` must keep parsing, unchanged.

## Decisions taken (do not re-litigate)

- **Data is plural; placement is singular.** An artifact records *every* mission it
  advances. Execution stays single-homed: a ticket is driven in one worktree. The
  `.worktrees/<slug>` and port-base 1:1 keying is untouched — this change widens
  "which missions does this work advance", never "where does this work happen".
- **All owning missions' gates must pass.** If a ticket names two missions, `/drive` reads
  both quality gates and the change must satisfy both. The reasoning: if the work cannot
  meet a mission's bar, it should not claim to advance that mission. This makes naming a
  mission a commitment rather than a label.
- **Wire shape: YAML inline list**, `mission: [slug-a, slug-b]` — the house shape already
  used by `layer: [UX, Domain]` and `tickets: [a.md, b.md]` in the very same frontmatter
  blocks. A block list would break every line-oriented parser harder.
- **A scalar keeps parsing as a one-element list.** `mission: foo` reads as `[foo]`, and
  an empty scalar and an empty list both mean "no mission". This is the living-migration
  convention the mission scripts already use for legacy flat dirs.

## Key Files

**The five scalar parse sites — every one is first-match-wins, so a list would be silently
truncated to nothing rather than erroring:**

- `skills/drive/scripts/archive.sh:63-72` — awk `print; exit`, then one mutator call each.
- `skills/ship/scripts/extract-deferred-concerns.sh:77-78` — python, explicit first-wins
  guard `if mm and not story_mission`. Feeds the concern stamp at `:191`.
- `skills/ship/scripts/extract-deferred-concerns.sh:243-256` — a **second, independent**
  awk parse of the same field in the same file, driving the "concern deferred (stuck)"
  append.
- `skills/report/scripts/apply-deferred-concern-verdicts.sh:69-92` — awk, then one append.
- `skills/catch/scripts/scan-window.sh:126` — `sed … | head -n1`.

**The one non-regex breakage:**

- `skills/catch/scripts/scan-window.sh:228` — jq `.mission == $s` scalar equality in the
  `in_flight` join. Becomes a membership test.

**Writers:**

- `commands/ticket.md:65` + `skills/create-ticket/SKILL.md:100,107,198,295` — Step 4c's
  single-select `AskUserQuestion` becomes multi-select; `list.sh`'s active-only filter is
  unchanged.
- `skills/report/SKILL.md:578,588` — story frontmatter and the inheritance rule. `:588`'s
  disagreement branch is deleted, not rewritten.
- `skills/ship/scripts/extract-deferred-concerns.sh:191` — concern stamping.
- `skills/report/scripts/merge-concerns.sh:137` — writes a hardcoded empty `mission: ` on
  a compound concern. A compound concern superseding members from different missions is
  this same problem in miniature; make it the **union** of its members' missions.
- `commands/mission.md:60` — kickoff stamping. Single-mission by nature, lowest risk.

**Docs:** `skills/mission/SKILL.md:38-80,171-186` (schema + seam table),
`skills/drive/SKILL.md:371` (the gate rule), `skills/catch/SKILL.md:52,55,80`,
`skills/okf/SKILL.md:46`, `CLAUDE.md`, `.workaholic/README.md`.

**Confirmed NOT affected — do not touch, and do not "fix" them:**
`hooks/validate-ticket.sh` (zero `mission` references; it never validates the field),
`hooks/mission-lens.sh`, `skills/okf/scripts/refresh-index.sh` (reads each `mission.md`'s
own `title`, never the relation), `skills/ship/scripts/commit-release-note.sh` and the
release-note frontmatter (no `mission:` field exists), and all nine
`skills/mission/scripts/*.sh` (they take a bare slug as `$1` and never parse the relation).

## Implementation Steps

1. **Extract the parser once.** The frontmatter-field awk is duplicated four times across
   the seams. Per CLAUDE.md's Shell Script Principle, put the scalar→list read in one
   shared script (e.g. `mission/scripts/read-relation.sh`, emitting one slug per line) so
   the migration happens in a single place and the sites cannot drift — the same
   one-rule-source shape as `lib/secret-patterns.sh` and `hooks/lib/check-subject.sh`.
   Reuse the canonical inline-list parse already at `hooks/validate-ticket.sh:239`.
2. Convert the five parse sites to that reader and make each dispatch a **loop over slugs**.
   This is safe by construction: all five funnel into the same two mutators, and both are
   already idempotent (`append-changelog.sh:36` keys on `grep -Fq`; `tick-acceptance.sh`
   keys on the artifact basename). No dedup logic is needed. Keep each call best-effort
   (`|| true`) — a mission update must never block an archive, extract, or commit.
3. `scan-window.sh`: emit `mission` as an array, and change the jq join to a membership
   test.
4. `report/SKILL.md`: inheritance becomes the **union** of the covered tickets' slugs.
   Delete the disagreement `AskUserQuestion`.
5. `create-ticket` Step 4c + `commands/ticket.md`: multi-select over active missions.
6. `merge-concerns.sh`: union the members' missions instead of writing empty.
7. `drive/SKILL.md:371`: a ticket with N missions has N gates and must satisfy all of them.
8. Docs in the same change; `node scripts/build-plugins/build.mjs` (all six of
   `create-ticket`/`drive`/`report`/`ship`/`catch`/`mission` are `DEFAULT_TARGETS`, so
   `outputs/` regenerates or CI's Outputs Freshness fails), then `verify.mjs` and
   `validate-metadata.mjs`.

## Considerations

- **The failure mode is silence, not breakage.** Every seam is best-effort and gates on
  `[ -n "$X" ]`, so a half-migrated field does not error — it quietly stops rolling
  missions, and nobody notices until a mission's progress is wrong weeks later. This is
  why the Quality Gate below asks for a deliberate reverse check rather than a green suite.
- **Fixture churn is the real cost.** Ten fixtures hardcode `mission: ${slug}` and two
  assertions encode the scalar shape as regexes (`/^mission:\s*real-time-notifications\s*$/m`
  at `test-workflow-scripts.mjs:2287`, `/^mission:\s*$/m` at `:2303`). Every one of the five
  breaking sites already has a named test, so the net is genuine — the risk is tedium, not
  blind spots.
- **`tick-acceptance.sh` is keyed on the artifact basename**, so a ticket naming two
  missions ticks an item on each mission only where that mission's Acceptance actually
  lists it, and no-ops elsewhere. That is already the right behaviour; do not add a
  cardinality rule to the mutators.
- `validate-ticket.sh` validates the ticket's other fields but has never looked at
  `mission:`. That is why both `mission: <slug>` and a bare `mission:` pass today. Widening
  the field needs no hook change — but note there is no enforcement here either, so a
  typo'd slug is caught by nothing. Out of scope; worth a concern.

## Policies

- `implementation/directory-structure` / `implementation/coding-standards` — universal.
  POSIX `#!/bin/sh -eu`.
- `implementation/command-scripts` — step 1: the relation read becomes one named script
  every seam calls, rather than four copies of an awk block.
- `implementation/objective-documentation` — the load-bearing one. The mission graph is
  meant to be derived from relations, not from a human's choice under a forced prompt.
  `report/SKILL.md:588` currently makes a true relation depend on which option someone
  clicked.
- `implementation/test` — test against the real thing: a real two-mission ticket through a
  real archive, not a mocked parse.
- `planning/terminology` — one concept, one shape: `mission: [a, b]` matches the
  `layer: [...]` / `tickets: [...]` inline-list form already used beside it.
- `design/data-sovereignty` — the relation is the data; discarding one to fit a scalar
  loses information the model claims to hold.

## Quality Gate

Test-green is not the gate. The seams swallow their own errors, so a broken migration
looks exactly like a working one.

1. **A two-mission ticket rolls both, exactly once each.** Hermetic: create two real
   missions, archive one ticket carrying both slugs, assert **each** mission gains exactly
   one `## Changelog` line and each has its acceptance item ticked. The existing
   "exactly one changelog line" idempotency assertion becomes per-mission.
2. **Reverse-check the silence.** Leave one of the five parse sites on the old scalar
   reader and confirm the suite goes red. If it stays green, the tests are not watching
   that seam and the migration could half-land unnoticed. Restore, and confirm green.
   (This session has had four tests that passed while measuring nothing; a seam that fails
   silently deserves the check.)
3. **The scalar still works.** A ticket with `mission: foo` and a ticket with a bare
   `mission:` both behave exactly as they do today. Forward-only means the existing ~15
   artifacts must not need touching.
4. **The prompt is gone.** A `/report` over tickets naming two different missions produces
   a story with both slugs and asks nothing.
5. **All gates enforced.** A ticket naming two missions surfaces both quality gates in
   `/drive`.
6. `node scripts/test-workflow-scripts.mjs`, `verify.mjs`, `validate-metadata.mjs` green;
   `outputs/` regenerated so CI's freshness diff is clean.
