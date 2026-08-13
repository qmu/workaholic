---
created_at: 2026-08-13T08:15:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: refresh-the-outdated-documentation-to-match-current-behavior
merge_policy:
---

# Reconcile the okf skill's ticket type claim

## Overview

Minted mid-run while driving
`20260813072628-update-the-artifact-hub-and-rules-docs-to-current-behavior.md`. The
problem is real and observed, but it sits in a **skill**, outside that mission's
stated scope (`README.md`, `docs/*.md`, `.workaholic/README.md`,
`plugins/workaholic/rules/*.md`), so it is queued rather than fixed opportunistically.

`plugins/workaholic/skills/okf/SKILL.md:15` enumerates per-file OKF conformance and
includes tickets among the documents carrying a `type:`:

> tickets (`type: enhancement|bugfix|refactoring|housekeeping`), stories
> (`type: Story`), missions (`type: Mission`), feedbacks (`type: Feedback`), release
> notes (`type: Release Note`) …

Three independent sources say the opposite, and the code agrees with them:

- `CLAUDE.md`, *`.workaholic/` runtime conventions*: "**Tickets are the exception**: no
  `type:` frontmatter, and `tickets/` internals are never index-managed."
- `.workaholic/README.md:10` — the same exception, in the artifact hub every consuming
  repository inherits.
- The shipped tickets themselves: none of the three tickets in this mission's set
  carries a `type:` field, and `hooks/validate-ticket.sh` does not require one.

So the skill is the stale one. It matters more than a stray sentence would, because
`okf/scripts/refresh-index.sh` is the writer of the bundle indexes and this skill is
what a session reads before touching them: a session that believes tickets are
index-managed knowledge documents may try to give them a `type` or fold `tickets/`
into the OKF index, which the layout rules elsewhere forbid.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` / `policies/distribute-policies-as-plugins.md` — the skills ship as agent context

## Key Files

- `plugins/workaholic/skills/okf/SKILL.md` — the stale enumeration (line 15).
- `plugins/workaholic/skills/okf/scripts/refresh-index.sh` — check whether the code
  shares the belief or only the prose does.
- `plugins/workaholic/hooks/validate-ticket.sh` — the ticket floor; it requires no `type:`.
- `CLAUDE.md`, `.workaholic/README.md` — the two current-behavior statements of the exception.
- `outputs/okf/` — the generated bundle; confirm nothing there depends on the claim.

## Implementation Steps

1. **Confirm the direction of the error before editing.** Read
   `refresh-index.sh` and `okf.mjs` to establish whether the ticket `type:` vocabulary
   is merely described or actually consumed. If any code reads it, this ticket is a
   different (larger) change and should say so rather than editing prose around live
   behavior.
2. Correct `okf/SKILL.md:15` to state the exception the rest of the project states:
   tickets carry no `type:` and `tickets/` is not index-managed.
3. Grep the plugin for the retired vocabulary
   (`enhancement|bugfix|refactoring|housekeeping` as a ticket `type`) and correct or
   remove whatever else still carries it; the `type`/`layer` ticket fields were retired
   2026-08-07, so this may be a survivor of that change.
4. Regenerate the outputs bundle (`node scripts/build-plugins/build.mjs`) — `okf` is a
   script-bearing skill and the `Outputs Freshness` CI fails on any diff.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `okf/SKILL.md` no longer claims tickets carry a `type:`, and states the exception instead.
- No file under `plugins/workaholic/` still describes a ticket `type:` vocabulary, or the
  Final Report names each survivor and why it is legitimate.
- No behavior change: the index regeneration writes the same files it wrote before.

**Verification method** — the commands/tests/probes that prove them:

- `grep -rn "type: enhancement" plugins/ outputs/` returns nothing.
- `bash plugins/workaholic/skills/okf/scripts/refresh-index.sh` leaves `.workaholic/index.md`
  and the per-area indexes byte-identical (`git status --short` clean afterwards).

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` green.
- `node scripts/build-plugins/build.mjs` then `verify.mjs` green, with `outputs/` committed
  if the skill's text changed.

## Considerations

- The reverse reading is possible and must be ruled out first (step 1): if tickets were
  *meant* to be OKF-typed and the exception is the regression, the fix belongs in the
  ticket writer and the layout rules, not in this skill. The evidence points the other
  way — no shipped ticket carries the field and no hook asks for it — but the check is
  cheap and the cost of guessing wrong is a schema change made by accident.
- Scope this to the contradiction. `okf/SKILL.md` is otherwise current, and a rewrite
  would bury a one-line correction in an unreviewable diff.

## Final Report

Development completed as planned.

**Step 1 — the direction of the error was confirmed before editing, and the skill is the
stale one.** No code consumes a ticket `type:`:

- `okf/scripts/refresh-index.sh` never reads ticket frontmatter. Its only mention of the
  queue is line 315, which links `tickets/` as a bare directory in the root index; the
  `-type f` / `-type d` hits in it are `find` flags, not frontmatter. The skill's own
  prose already said it "deliberately does not touch anything inside `tickets/`", so the
  enumeration contradicted the same file's next paragraph.
- `scripts/build-plugins/okf.mjs` handles exactly one `type` value, the producer-defined
  `type: Engineering Policy` for the policy bundle — nothing about tickets.
- `hooks/validate-ticket.sh:244` states the opposite of the skill in a comment:
  `type`/`layer`/`effort`/`commit_hash`/`category` are RETIRED (2026-08-07), "tolerated,
  never validated", with no rule at all.

So the reverse reading (tickets *should* be OKF-typed) is ruled out: nothing writes the
field, nothing reads it, and the hook deliberately declines to ask for it.

**Changes** — `plugins/workaholic/skills/okf/SKILL.md`, prose only, two lines:

1. The opening OKF-bundle sentence now says *knowledge* document and carries the
   exception explicitly ("the queue is a work surface, not a knowledge area: a ticket
   carries no `type` and `tickets/` internals are never index-managed"), matching
   `CLAUDE.md` and `.workaholic/README.md:10` word for word in substance.
2. The per-file conformance list drops tickets and gains a sentence forbidding their
   re-addition, citing the 2026-08-07 retirement and `validate-ticket.sh`.

**Two in-line corrections to the same enumeration**, made because the sentence was being
rewritten anyway and leaving them would have kept it half-stale — neither is a scope
expansion beyond the one list: `releases (type: Release)` was missing from a list
`CLAUDE.md` gives as `Story | Mission | Feedback | Release Note | Release`, and the trip
artifacts are now named *legacy* (`.workaholic/trips/` is read-only history).

**Surviving mentions of the retired vocabulary, and why each is legitimate.** The gate's
grep (`grep -rn "type: enhancement" plugins/ outputs/`) returns exactly one logical line,
in two copies:

- `plugins/workaholic/skills/create-ticket/reference/ticket-format.md:38` — the *Common
  mistakes* table row `| Retired fields written anew | type: enhancement, layer: [UX] |
  Omit them |`. It names the vocabulary in order to **prohibit** it, and the same file's
  *Retired (2026-08-07)* section above it is the canonical statement of the retirement.
  Removing it would delete the warning, not the staleness.
- `outputs/workflows/skills/create-ticket/reference/ticket-format.md:38` — the generated
  copy of that same line; `outputs/` is never hand-edited.

`scripts/test-workflow-scripts.mjs` also carries the vocabulary in ~30 fixtures, which is
correct and outside the gate's scope: they exercise the *grandfathered* corpus the hook
comment describes, so a fixture without a retired field would stop testing tolerance for
one.

**Verification run** — all from the claim worktree:

- `grep -rn "type: enhancement" plugins/ outputs/` → only the two prohibition rows above.
- `bash plugins/workaholic/skills/okf/scripts/refresh-index.sh` → `{"refreshed": true,
  "indexes": 8}` and `git status --short` afterwards shows only the intended `SKILL.md`
  modification: the index regeneration wrote byte-identical files, so no behavior changed.
- `node scripts/build-plugins/build.mjs` → clean; **`outputs/` came back byte-identical**,
  because `okf` contributes only its script closure to the bundle and its `SKILL.md` prose
  is not published (the assembled skills are create-ticket, drive, report, ship, catch,
  mission, review-sections, write-release-note).
- `node scripts/build-plugins/verify.mjs` → self-contained, policy index in sync, OKF
  bundle 48 files fresh with 210 links resolving.
- `node scripts/build-plugins/validate-metadata.mjs` → Codex manifests valid at 1.0.176.
- `node scripts/test-workflow-scripts.mjs` → **2447 passed, 0 failed**.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` → `conforming: true` (three
  pre-existing trip-naming advisories, non-blocking and untouched).

### Discovered Insights

- **Insight**: A script-bearing skill can be in the build's *closure* without its prose
  being published. `build.mjs` reported `closure=[…, okf, …]` for both `catch` and
  `mission`, yet `outputs/workflows/skills/` contains no `okf` directory and this edit
  produced no `outputs/` diff at all.
  **Context**: The closure carries the scripts a published skill calls, not the calling
  skill's `SKILL.md`. So "is this skill in some closure?" is the wrong question when
  deciding whether a prose edit needs `outputs/` committed — the answer is whether the
  skill is in the *assembled* list the build prints on its `assembled workflows plugin`
  line. Rebuilding remains mandatory (the ticket's step 4 is right to demand it); what
  changes is the expectation that a diff must follow.

- **Insight**: This contradiction survived the 2026-08-07 `type`/`layer` retirement
  because the retirement was executed against the ticket *writer* and its validator, and
  `okf/SKILL.md` describes ticket frontmatter without owning any of it.
  **Context**: The retirement correctly updated `create-ticket/reference/ticket-format.md`
  (both the schema section and the mistakes table) and `hooks/validate-ticket.sh`. A
  second-order describer — a skill that enumerates another workflow's schema as context
  for its own job — is invisible to a grep for the *writer's* code paths. When a schema
  field is retired, the sweep needs to cover prose that merely *mentions* the field, not
  just prose that *specifies* it.

- **Insight**: The stale claim was locally self-contradicting: line 15 listed tickets as
  `type`-bearing while line 34 of the same file said the script "deliberately does not
  touch anything inside `tickets/`".
  **Context**: Where a skill states both a conformance rule and its own exclusions, the
  exclusion list is the more reliable of the two — it is what the script's behavior is
  read off, whereas the conformance list is a description of other workflows' output and
  drifts with them.
