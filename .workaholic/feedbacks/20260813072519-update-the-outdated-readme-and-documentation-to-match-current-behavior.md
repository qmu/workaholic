---
type: Feedback
title: Update the outdated README and documentation to match current behavior
kind: instruction
source: discussion
created_at: 2026-08-13T07:25:19+00:00
author: a@qmu.jp
supersedes: 
---

# Update the outdated README and documentation to match current behavior

Source: https://github.com/qmu/workaholic/issues/432 (opened by claude[bot], assigned to tamurayoshiya)

The ask, in the reporter's words: update all outdated `README.md` files and documentation across the project so they reflect the current state of the code.

The ask names no specific passage, so proposal-time discovery measured the drift rather than inheriting the framing. Against `origin/main` at `cdcbfe1`, three surfaces carry statements the shipped behavior contradicts:

- **Root `README.md`** (460 lines, 79 commits since its last touch). Line 59 and line 288 both state that `/propose` runs "on the reported ask rather than on a clock" — the `[Propose]` routine has fired on a fixed hourly schedule (`15 * * * *`) since 2026-08-12 and discovers its own asks through `list-inbound-issues.sh` (`workaholic:propose`, *Clock-fired discovery*). Lines 59, 94 and 262 make the human merge of the proposal pull request the approval seam — proposal pull requests auto-merge on opening (`WORKAHOLIC_AUTO_MERGE=1`), with quality gated at the `release/*` QA window instead. Line 68 describes `/setup-routines` as rendering copy-paste sheets and managing "nothing" — its current contract attempts configuration every time through a `RemoteTrigger`-family tool, with the sheets demoted to the no-transport refusal's recovery path.
- **`docs/`**. `proposal-loop-runbook.md` is current on the clock-fired trigger (lines 59-65) but still carries the retired `/setup-routines` "renders sheets, manages nothing" description at lines 68-84.
- **`.workaholic/README.md`**. The `feedbacks/` entry names `/fb`, `/ship` and `/report` as the stream's writers and omits `/propose`, which writes a record on every run. The "Use with other coding agents" workflow list in the root README names six portable workflow skills; `outputs/workflows/skills/` ships eight.

`CLAUDE.md` is the current-behavior statement the repository's own policy keeps in the same commit as each change, so it is the reference the other documents are measured against, not itself a subject of this work.
