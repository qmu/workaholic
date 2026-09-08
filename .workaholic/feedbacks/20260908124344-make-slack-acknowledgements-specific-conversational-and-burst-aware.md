---
type: Feedback
title: Make Slack acknowledgements specific, conversational, and burst-aware
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-08T12:43:44+09:00
author: a@qmu.jp
supersedes: 
---

# Make Slack acknowledgements specific, conversational, and burst-aware

## Context

In a project Slack feedback burst, `/work` replied once per item with the identical sentence:

> 受理しました。実装可能な単位へ具体化して進めます：[#708](...)

The issue number changed, but the message did not identify the substance of the request. A sequence of these receipts is difficult to scan, provides less information than the linked issue title, and reads like an automated bot rather than a capable collaborator participating in a shared human/AI workspace.

The operator asked that, at minimum, the issue title be shown. More importantly, Workaholic's instructions should be designed for a general-purpose AI agent collaborating with people in Slack, not for a notification bot repeating fixed copy.

## Requested behavior

Revise the Slack receipt and notification guidance across `/work`, `notify`, and inbound feedback handling around a human-centered conversation contract:

1. Every receipt must make the acknowledged subject recognizable without opening the link. Include the issue title or a concise, faithful description of what was heard.
2. Do not repeat identical boilerplate for a rapid series of messages. When several related asks arrive together, prefer one compact grouped acknowledgement that maps each subject to its issue, while still reacting to each source message for durable per-message state.
3. Let the general-purpose agent phrase acknowledgements naturally from the conversation context. Templates should constrain required facts and state transitions, not force a fixed sentence whose only variable is an issue number.
4. Match the person's language and conversational register. Acknowledgements should sound like a competent teammate: concise, specific, and appropriately varied, without pretending to be human or adding ornamental chatter.
5. Explain only commitments the workflow has actually made. Avoid mechanically promising “implementation-ready concretization” when an ask may still need discovery, grouping, or conservative judgment.
6. Preserve machine-checkable delivery separately from prose: reactions, issue references, thread identity, and durable receipt records can remain structured while the visible sentence stays useful to people.
7. Treat burst ergonomics as a first-class case. Apply deduplication/grouping thresholds and ensure a long run of receipts does not dominate the channel or increase notification fatigue.

For example, a single receipt could say:

> 「第1・第2列を個別に折り畳めるようにする」を #708 として記録しました。隣接する列幅・固定表示の要望と合わせて、レイアウト単位で整理します。

A burst could instead be summarized once with a short subject-to-issue list.

## Human-centered rationale

Slack is a mixed human/AI collaboration space, not merely an event sink. Repetitive generic messages create cognitive friction, make different requests indistinguishable, and evoke avoidable bot aversion. Specific, context-aware acknowledgements improve scanability and trust, reduce notification fatigue, and invite people to continue contributing feedback. This should be treated as a human-centered design requirement, not cosmetic tone polish.

## Acceptance criteria

- A receipt identifies the request's substance in the visible text, preferably through the issue title or an equally specific paraphrase.
- Five related messages received in a short burst do not produce five indistinguishable template replies; the workflow groups them or makes each independently informative.
- Required workflow facts remain testable without snapshotting one mandatory prose sentence.
- Tests cover a single ask, a related burst, unrelated concurrent asks, and a request that is recorded but not yet implementation-ready.
- The instructions explicitly frame Slack output as communication among human and AI collaborators and include notification fatigue and cognitive aversion in the design rationale.

Source: https://github.com/qmu/workaholic/issues/1090
