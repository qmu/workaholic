---
type: Feedback
title: Revive the Strategy artifact and reshape the .workaholic artifact set
kind: instruction
source: discussion
created_at: 2026-08-13T11:24:58+00:00
author: a@qmu.jp
supersedes: 
---

# Revive the Strategy artifact and reshape the .workaholic artifact set

Source: https://github.com/qmu/workaholic/issues/436 (opened by claude[bot], assigned to tamurayoshiya)

The ask, in the reporter's words — six directions for the `.workaholic/` artifact set:

- **Revive the deprecated `Strategy` artifact**, "consisted by Aim, Schedule, and Assignee".
- **Feedback of one's opinion towards the software experience** records "a subject that formed the opinion (Person, People (Meeting), Observer AI, etc.)" together with the detail of the feedback.
- **Erase `policies`, `guides`, and `specs`** — "after the plugin update, erase immediately".
- **Redesign `deployments` and `terms`** — they "need to be defined and kept updated".
- **Migrate `tickets/[todo|archive]`**: fold `abandoned` and `icebox` into `archive`, with the status tracked in YAML frontmatter.
- **Apply these migrations through `/workaholify`.**

Proposal-time discovery measured the base rather than inheriting the framing. The `Strategy` artifact is not merely dormant: it was deliberately retired on 2026-07-28 (`tickets/archive/work-20260728-183130/20260728183203-retire-strategy-layer.md`, decision B3 of `docs/loop-engineering-workflow.md`) on the grounds that long-lived direction accretes in the feedback stream and two direction homes would drift; `mission/scripts/migrate-strategies.sh` still runs as the living migration that converts any surviving strategy into a feedback record. The shape asked for here — Aim, Schedule, Assignee — is not the retired shape (`## Direction`, no completion conditions), so this is a re-introduction with a different definition rather than a revert, and the retirement's reasoning is what the new artifact has to answer.

The other five land on live mechanisms. `.workaholic/policies/` (7 files), `guides/` (3) and `specs/` (10) exist here and are registered in the closed layout's two lockstep sources (`hooks/workaholic-layout-allowlist.txt` and the table in `plugins/workaholic/rules/workaholic.md`), so erasing them is a layout amendment, not a `rm`. `deployments/` (marketplace.md) and `terms/` (6 files) are registered the same way and have no writer or upkeep seam today. `tickets/` currently holds `abandoned/` (6 tickets), `icebox/` (1) and `archive/` (752); the queue's `todo/` is empty and therefore absent. `guard-ticket-structure.sh`, `validate-ticket.sh` and `layout-doctor.sh` all encode the four-state ticket layout, and the feedback schema (`type`, `title`, `kind`, `source`, `created_at`, `author`, `supersedes`) carries no field for the subject that formed an opinion, with `validate-feedback.sh` as its write-time floor and immutability forbidding a retrofit edit of existing records.
