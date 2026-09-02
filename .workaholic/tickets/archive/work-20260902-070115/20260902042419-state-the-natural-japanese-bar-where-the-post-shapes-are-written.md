---
created_at: 2026-09-02T04:24:19+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff: 
feedback: [20260902042405-a-slack-post-s-japanese-must-be-read-on-first-sight-not-decoded.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
claim: work-20260902-070115
---

# State the natural-Japanese bar where the post shapes are written

## Overview

PROPOSED. `rules/interaction.md`, *The language of a post is the language its readers use*
(2026-09-01) settled **which language** a post is written in and said nothing about **what
good Japanese is**. The measured result: posts composed by translating the English record
title word for word — 「組み立てを止める」 for *fail the build* (a reader cannot tell it means
CI), a bare 「形」 for *shape*, 「示せるという判定」 for *demonstrable verdict* — with English
word order preserved around them, so the post reads as a riddle. The operator reports these
arriving one after another.

The language rule's own measurement is the reason this belongs beside the shapes rather
than in a repository's `CLAUDE.md`: a ceiling that shows a language is a ceiling that sets
one, and the same ceiling is what will set the *register*. This ticket adds the quality bar
to every surface that already carries the language rule, in one change.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` — the post is the product surface a person reads

## Key Files

- `plugins/workaholic/rules/interaction.md`, *The language of a post is the language its
  readers use* — the rule's home; the bar is stated here first, beside the
  never-translated list it already carries.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the shape catalog whose
  fenced blocks are the instruction a session actually reads at composition time.
- `plugins/workaholic/skills/notify/SKILL.md` — the ceiling statement the catalog serves.
- `plugins/workaholic/commands/implement.md`, `specificate.md`, `propose.md`,
  `moderate.md` — the four routine-fired ceilings that each restate the language rule;
  they are where a routine session reads it, so the bar must be on all four.
- `plugins/workaholic/rules/workaholic.md` — the `terms/` area's definition; the project's
  own glossary terms are the ones that stay in katakana or English.
- `scripts/test-workflow-scripts.mjs` — where the four restatements are pinned against
  drift, as the post formats already are.

## Implementation Steps

1. Read *The language of a post is the language its readers use* in full, and the four
   command ceilings that restate it, so the new clause is added to one wording rather than
   four divergent ones.
2. Write the bar in `rules/interaction.md` beside the existing never-translated list. State
   it as an outcome a reader can check, not as a style preference: **a channel reader must
   understand what is being asked without opening the English record behind the link.**
   Under it, the three rules the operator named — established technical terms stay in their
   katakana or English forms (ビルド, CI, デプロイ, PR, and the repository's own `terms/`
   entries); the **meaning** of a title is translated, never its words; a title that
   resists translation is **paraphrased** in plain Japanese rather than transliterated.
3. Carry the same wording, byte-identically, into the notify catalog beside each shape's
   free-text slot description, and into the four command ceilings. Byte-identical because
   the existing post formats are already pinned that way and a second wording is the drift
   this repository fixes by pinning.
4. Include the measured examples as worked before/after pairs in the catalog — 「組み立てを
   止める」 → 「ビルドが落ちる」 and so on. A rule with no example is re-decided by every run;
   the examples are what make the bar legible at composition time.
5. Extend the drift pin in `scripts/test-workflow-scripts.mjs` so the four command
   ceilings' language clause is asserted byte-identical to the catalog's, exactly as the
   post formats already are.
6. Update `CLAUDE.md`'s *Write each surface in the language its audience reads* bullet in
   the same change, so the repository's own statement of the rule carries the bar too.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The bar is stated in `rules/interaction.md`, the notify catalog and all four routine-fired
  command ceilings, in one wording.
- The wording is pinned byte-identical across those surfaces by the hermetic suite.
- At least the three measured calques appear as worked before/after pairs.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- The new drift assertion fails when one ceiling's clause is edited alone.
- `outputs/` is regenerated and the `Outputs Freshness` check is clean.

## Considerations

- Nothing mechanical can check the *emitted* Japanese: the composition happens at run time
  and never appears in this tree's markdown. What is checkable is that the bar is stated
  where the session reads, and that is deliberately all this ticket claims — the same limit
  `rules/interaction.md` already records for the language rule itself.
- Keep the never-translated list untouched. Shape labels, status and reason words, slugs,
  branch names, `<@U…>` tokens and URLs stay as they are; the bar governs prose slots only,
  and widening it to machine words would break the dedup that keys on them.

## Final Report — 2026-09-02 (implemented)

**Step 1 — read first, so the clause is added to one wording rather than four.** The four
routine-fired ceilings already carry the language rule as a **single byte-identical sentence**
(`commands/{implement,specificate,propose,moderate}.md`), and the suite already pins its
*presence* per command. So the bar was written once and carried into all four by substitution on
that anchor, not composed four times.

**Step 2 — the bar, in `rules/interaction.md`.** Stated as an outcome a reader can check rather
than a style preference: *a channel reader must understand what is being asked without opening the
English record behind the link.* Under it the three rules the operator named — an established
technical term keeps its ordinary katakana or English form (ビルド, CI, デプロイ, PR, and the
repository's own `terms/` entries); the **meaning** of a title is translated, never its words; a
title that resists translation is **paraphrased** rather than transliterated. The never-translated
list above it is untouched.

**Step 3 — carried byte-identically** into the notify catalog (immediately under the paragraph that
already says its English is the instruction, so it sits with the fenced blocks a session copies)
and into the four command ceilings.

**Step 4 — the worked pairs are in the wording itself**, not in a separate table: 「組み立てを止める」
→ 「ビルドが落ちる」, 「形」 → 「投稿の型」, 「示せるという判定」 → 「実証できたかどうかの判定」. Putting them in
the carried string is what makes them reach the composition site; a rule with no example is
re-decided by every run.

**Step 5 — the drift pin, and the gate is demonstrated rather than asserted.** The existing
language-rule assertion gained a byte-identical comparison of the bar across the four ceilings and
the catalog, plus three assertions on `rules/interaction.md`'s own home (which is deliberately
*not* the identical string — `rules/` carries the measurement and the why, a ceiling carries the
instruction) and one on the stated limit. **Proved by breaking it**: editing one word of
`/moderate`'s clause alone turned the suite red with `FAIL /moderate carries the quality bar
byte-identically` (5975 passed, 1 failed); restored, it is green.

**Step 6 — `CLAUDE.md`'s own bullet** carries the bar, names the one wording and the five surfaces
it ships on, and states that what a run emits is checkable by nothing.

**What this deliberately does not claim.** Nothing mechanical can check the *emitted* Japanese —
the composition happens at run time and never appears in this tree — and `rules/interaction.md`
now says exactly that in its own paragraph, with a pinned assertion on the sentence. What is
checkable is that the bar is stated everywhere a session reads what to emit.

**Verification.** `node scripts/test-workflow-scripts.mjs` → **5976 passed, 0 failed** (13 new
assertions). `node scripts/build-plugins/build.mjs` regenerated `outputs/` with no diff;
`verify.mjs` and `validate-metadata.mjs` pass; `layout-doctor.sh` reports `conforming: true` with
no findings.
