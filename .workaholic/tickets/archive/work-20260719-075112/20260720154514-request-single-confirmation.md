---
created_at: 2026-07-20T15:45:14+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 1h
commit_hash:
category: Changed
depends_on:
mission:
---

# Streamline /request: one confirmation, and stop using "file" as a verb

## Overview

Two adjustments to `/request`, the only sanctioned way to send a ticket into another repository. They touch the same prose surface, so they are done in one pass to avoid conflicting edits.

**1. Collapse to a single confirmation.** `/request` currently issues **two** `AskUserQuestion` prompts: Step 2 confirms the target (name, remote, visibility), and Step 5 confirms the exact body verbatim. This happens for **every** submission regardless of the visibility combination (public→private, private→public, public→public, private→private) — there is no visibility-driven branching, but two prompts read as being asked too many times. Collapse them into **exactly one** confirmation. The surviving prompt is the **exact-body confirmation** — the command's whole reason to exist, which `request/SKILL.md` §1 says is never removable — now with the destination **folded into it**: the one prompt shows `name` + `remote` + **`visibility`** together with the **verbatim body**, confirmed once, for all four visibility combinations. (Developer decision at ticket time: keep visibility **shown** in that single prompt — a material fact — but never as a second prompt.)

**2. Stop using "file" as a verb.** Throughout `/request`, the word "file" is used as a verb ("File a ticket in…", "file it", "filed path", and the script name `file-request.sh`). Use "file" only as a **noun**; replace the verb with **"submit"** (e.g. "submit a ticket to the target repository", "the submitted path"). This applies in English and Japanese prose alike. Keep "file" where it is genuinely a noun (a body file, the written file).

No behavioural logic changes: `resolve-target.sh` is untouched, `release-scan` stays as the independent second layer after the confirmation, and the cross-repo writer script keeps its exact checks — only its name and the surrounding wording change.

## Policies

- `workaholic:design` / `consent-recording` — the one confirmation is the informed-consent gate for a cross-repository write: it must show the developer **what** goes out (the verbatim body) and **where** (name/remote/visibility) before anything is written. Merging two prompts into one reduces friction without reducing what the developer sees.
- `workaholic:design` / `no-dark-patterns` — the merged prompt keeps a symmetric confirm/cancel; "one confirmation" must not become a default-yes or a pre-checked fast path.
- `workaholic:implementation` / `objective-documentation` — the confirmation shows the body **verbatim** (not a summary, diff, or "I have masked it"); and the terminology change keeps names honest — "file" as a noun for the artifact, a distinct verb ("submit") for the action.
- `workaholic:planning` / `verify-before-building` — the masking judgement (`request/SKILL.md` §1–§2) is the human control the command exists for; relocating *where* the developer confirms must not weaken *that* they confirm the exact text.

## Implementation Steps

1. **`skills/request/SKILL.md` §4 Workflow — merge steps 2 and 5, reordered.** New order: (1) resolve the target (no prompt; `ok:false` → stop), (2) compose the body as a conforming ticket from the target's vocabulary (was step 3), (3) mask it (was step 4), (4) **single combined confirmation** — one `AskUserQuestion` showing the destination `name`/`remote`/`visibility` **and** the exact body verbatim, confirmed together, (5) scan with `release-scan` (was step 6), (6) submit with the writer script (was step 7), (7) report (was step 8). Composing before confirming is safe: `resolve-target.sh` resolves deterministically and fails closed (never guesses), and the single prompt still catches a wrong-but-resolved target because the developer sees the destination on screen.
2. **Preserve the non-skippable guarantee on the combined prompt.** Carry §4.5's intent verbatim onto the merged step: no fast path — not for a clean-looking body, not on a re-run, not because approval was given earlier in the session; the body is shown **verbatim**, as it will be written. State plainly that the destination is folded in so there is **one** confirmation, never two, and never a per-visibility extra prompt.
3. **Terminology sweep — "file" (verb) → "submit"; rename the writer script.** In `skills/request/SKILL.md` and `commands/request.md`, replace every verb use of "file"/"filing"/"filed" with "submit"/"submitting"/"submitted", keeping "file" only as a noun. Rename `skills/request/scripts/file-request.sh` → `skills/request/scripts/submit-request.sh` (`git mv`), and update **every** reference to it — the skill's §4 and §7, `commands/request.md`'s Workflow, and any test in `scripts/test-workflow-scripts.mjs` that names the path. The script's internal logic and its checks (empty body, malformed filename, this repo's own name/path) are unchanged.
4. **`CLAUDE.md` — keep the `/request` description truthful.** Update the command-table row and the "Repository confinement" section so they read as **one** confirmation (destination + exact body) and use "submit" rather than "file" as the verb (including the `file-request.sh` reference → `submit-request.sh`). Verify truthfulness at change time.
5. **Verify.** `node scripts/test-workflow-scripts.mjs` passes (the renamed script exercised at its new path, including the confinement case where the four real leaked sentences pass the writer script unchanged). `/request` is Claude-only and not built into `outputs/`, so no rebuild. Confirm no verb "file" remains in the touched files and no reference to the old script path survives.

## Quality Gate

**Method:** workflow-prose review against the safety invariants, a terminology grep, and the script/test suite. Approve only when all hold:

- `/request`'s workflow issues **exactly one** `AskUserQuestion` (down from two), for **all** visibility combinations — no visibility-driven extra prompt.
- That single prompt shows **both** the destination (`name`, `remote`, **`visibility`**) **and** the **verbatim** body (not a summary/diff/"masked" assertion), with a symmetric confirm/cancel and no default-yes.
- The exact-body confirmation stays explicitly **non-skippable**: the "no fast path (clean body / re-run / prior approval)" language survives, attached to the combined prompt.
- Both repositories are named in the one prompt and the project label is present (satisfies `guard-askuserquestion-label.sh`).
- **No verb use of "file" remains** in `commands/request.md`, `skills/request/SKILL.md`, or the `/request` parts of `CLAUDE.md`; "file" appears only as a noun. The action verb is "submit" (or the developer's chosen alternative).
- `file-request.sh` is renamed to `submit-request.sh` with **all** references updated (skill, command, CLAUDE.md, tests); no reference to the old path survives (`grep -r file-request` is empty). The script's checks are unchanged.
- `resolve-target.sh` logic is unchanged; `release-scan` still runs as the second layer **after** the confirmation, **before** the submit. `node scripts/test-workflow-scripts.mjs` passes.

## Considerations

- **The surviving confirmation must be the body one.** `request/SKILL.md` §1 is emphatic that the exact-body confirmation is the command's purpose and "if a future change makes the confirmation feel redundant, the change is wrong." Merging is allowed **only** because the combined prompt still shows the verbatim body — it removes the *separate target step*, not the *body confirmation*.
- **Do not add visibility branching.** All four visibility combinations get the *same* single confirmation; visibility is displayed, never a decision fork or an extra gate.
- **The script rename is mechanical but on the critical path.** The writer is the only sanctioned cross-repo write; the rename must update every reference and keep the test that proves the four real leaked sentences pass it unchanged. If "submit" is not the developer's preferred verb, substitute their choice consistently (script name included).
- **Reordering compose-before-confirm** wastes a little composition effort if the resolved target was not intended, but the developer still catches it at the single prompt (nothing is written first) — the accepted trade for one confirmation.

## Final Report

Development completed as planned. `/request` §4 now runs resolve → compose → mask →
**one** combined confirmation (destination + verbatim body) → scan → submit → report;
the confirmation stays non-skippable and identical across all four visibility
combinations. Swept the verb "file" → "submit" across `commands/request.md`,
`skills/request/SKILL.md`, and CLAUDE.md (kept "file" as a noun), and renamed
`file-request.sh` → `submit-request.sh` with every reference and test updated.
Verified: exactly one `AskUserQuestion` in the workflow, `grep -r file-request` empty,
`resolve-target.sh` unchanged, and `test-workflow-scripts.mjs` at 1164 passed.

### Discovered Insights

- **Insight**: The two prompts merged cleanly because the target confirmation carried
  no information the body confirmation could not also show — folding `name`/`remote`/
  `visibility` into the verbatim-body prompt loses nothing and removes a gate.
  **Context**: The visibility distinction is preserved as *displayed text*, not as a
  branch — there was never per-visibility logic, so "one confirmation for all four
  combinations" required removing a prompt, not simplifying a conditional.
- **Insight**: The renamed script's contract is asserted by name in
  `test-workflow-scripts.mjs` (`SCRIPTS.submitRequest`, label strings), so the rename
  had to move in lockstep with the tests — the four-real-leaks case still passes,
  which is the guardrail that the human confirmation, not the script, is the masker.
