---
type: Feedback
title: Workaholify is the preparation command, so it must apply rather than report
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-08-14T10:37:18+00:00
author: a@qmu.jp
supersedes: 
---

# Workaholify is the preparation command, so it must apply rather than report

**The framing itself is wrong: `/workaholify` is not an audit command.** The developer's intent, stated again on 2026-08-14: `/workaholify` is **the preparation command** — what a repository runs to be able to use workaholic consistently — and that covers state, not just wiring. The current `commands/workaholify.md` and the gateway skill run it as a report: audit `CLAUDE.md` (offer a reference), check the bootstrap, render the routine setup sheets, confirm the guard, then "report what conforms and what needs fixing". Feedback `20260813205116` already records half of this for routines (direct-apply instead of sheets); this ask is the other, larger half: **the repository's own `.workaholic` tree**.

**What was measured (2026-08-13 → 08-14).** Structural changes such as P2 (ticket ownership: directory → `assignees:` field) ship with a living migration (`gather/scripts/migrate-todo-owners.sh`) that converges only at write seams — and in the current tree only `promote-icebox.sh` actually calls it (issue #444). A repository that predates the change therefore stays on the legacy `todo/<user-slug>/` layout indefinitely, while `/workaholify` reports it fully conformant — and that misread let an `[Implement]` routine claim, implement, and merge colleagues' path-owned tickets overnight (#444). The developer ran `/workaholify` expecting exactly this to be repaired ("running it should update the repository's directory structure too — recent ticket-directory changes should have been folded into it") and got a clean audit instead.

**Ask.**

1. Make `/workaholify` **apply, not report**: converge the `CLAUDE.md` wiring, the bootstrap, the routines (per `20260813205116`), **and the `.workaholic` tree's layout** — run every living migration (`migrate-todo-owners.sh`, the missions layout migration, `migrate-concerns.sh`, and whatever ships next) as part of the command's own end-to-end flow. A confirmation dialog before applying is acceptable; stopping at a rendered report is not. Report-only remains the recovery path for a named refusal, never the ordinary outcome.
2. State that contract in the gateway skill so every future structural change registers its migration at this seam — a single registry of living migrations the command walks — so the next P2-shaped change cannot leave repositories on a layout the current plugin misreads while `/workaholify` calls them conformant.

Source: https://github.com/qmu/workaholic/issues/445
