---
type: Feedback
title: A fourth moderation hour reached nobody and compounded with an undelivered proposal
kind: insight
source: development
subject: observer_ai:moderate
created_at: 2026-09-01T03:28:38+00:00
author: a@qmu.jp
supersedes: 
---

# A fourth moderation hour reached nobody and compounded with an undelivered proposal

Source: https://github.com/qmu/workaholic/issues/815

The `/moderate` tick at `20260901-025208` rendered its hourly root (5 change lines, 3 impairment lines, 5 questions) and no transport could reach the loop's channel, so the tick filed the rendered root as one `[FB]` issue, verbatim, rather than losing the hour with its container. This is the **fourth consecutive hour** of the same condition (`20260831-235117`; `20260901-005151` → #810, recorded at `20260901011816-a-second-moderation-hour-reached-nobody-and-was-preserved-as-an-issue.md`; `20260901-015055` → #812, recorded on the branch behind pull request #813; and this one). Both transports were named as out: the Slack connector is authenticated against `osbrworkspace.slack.com`, which holds none of the loop's channels — `slack_search_channels` for `dev-workaholic` and for `workaholic` both return no result, and a direct read of the recorded coordinate `C0BLL9J7FMY` answers `channel_not_found` — and `notify-slack.sh` answers `no_token`, with `WORKAHOLIC_INBOUND_SLACK_CHANNEL=dev-workaholic` set, so the channel resolves and only the credential is missing.

The cost this hour, with the ledger untouched so every question stays held and is offered again the moment a transport returns: the morning per-strategy digest (139 commits, 1 strategy, 1 day overdue) reached nobody; five arrears questions were cleared to ask and reached nobody, all five `undrivable-unit:` on artifacts naming `tamura.yoshiya@gmail.com`, an address no entry in `.claude/git-identities` names, whose repair is one mapping line; eighteen further questions stay held from earlier ticks; and eight outstanding questions have answers this tick could not read (all eight coordinates in `C0BLL9J7FMY`, `thread_unreadable:channel_not_found`), so a person who has already replied has still not been heard. `thread-reconcile` held five candidates and `unanswered-asks` could not read `#dev-workaholic` at all — `channel_unreadable:channel_not_visible_to_connector`, never an honest quiet hour.

The ask states its own scope: the repair is **provisioning rather than code**, https://github.com/qmu/workaholic/issues/806 already carries that request, and this issue exists to preserve the hour's content rather than to duplicate it. It asks this repository for no work of its own, and the mechanism it exercises — a tick whose rendered post says *post* and whose every transport is out files the root as one `[FB]` issue — is working as designed. Two standing rulings bound what could be proposed against it in any case: the operator rejected provisioning a Slack bot identity, "Do not re-propose a bot identity, an app token, or any Slack-side credential until the operator says otherwise" (`20260831221757-the-operator-rejects-provisioning-a-slack-bot-identity.md`), and on #806 the operator ruled directly that the issue stays open because the repair is theirs, not the loop's.

One thing this hour adds that the three before it did not. The condition is now visible in a second place: issue #812 was re-offered to this `[Specificate]` tick although pull request #813 already carries its record and `Closes #812`, because the discovery excludes only issues a record on the base names, and a record-only proposal cites no artifact so the dedup set cannot see it either. #813 is itself one of the five `clean` stranded publications recorded at `20260901032409-a-clean-stranded-publication-is-delivered-by-nothing.md` — it is unmerged because nothing delivers a publication that needs nothing but a merge. So the two conditions compound: the undelivered root files an issue, the issue's proposal strands clean, and the unmerged proposal leaves the issue open to be re-offered next hour. Delivering the clean publication closes that loop without any change to the discovery or the dedup set, which is why no work is proposed for it here.
