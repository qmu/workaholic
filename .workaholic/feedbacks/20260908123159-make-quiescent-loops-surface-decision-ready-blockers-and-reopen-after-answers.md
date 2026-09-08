---
type: Feedback
title: Make quiescent loops surface decision-ready blockers and reopen after answers
kind: instruction
source: discussion
subject: person:Yoshiya Tamura
created_at: 2026-09-08T12:31:59+09:00
author: a@qmu.jp
supersedes: 
---

# Make quiescent loops surface decision-ready blockers and reopen after answers

# Make quiescent loops surface decision-ready blockers and reopen after answers

kind: instruction / source: discussion / subject: person:Yoshiya Tamura

When a strategy becomes `quiescent` because progress depends on a human decision, the development loop must not treat that fact as a terminal explanation visible only in a worker report. The coordinator should turn the blocker into a decision-ready Slack question, address it to the responsible person, record the answer through the existing answer path, and re-evaluate the strategy after the answer so development can continue.

Before asking, the loop must judge the maturity of the question. Many accumulated questions concern implementations considered too early, before their business, design, data, or operational premises were established. A question that is premature, cannot yet be answered, does not need an answer now, or is meaningless until its premises are examined must not become a gate merely because it exists. The loop should first revisit or retire its assumptions, defer the question with an explicit reason, or formulate the prerequisite planning work. Only a question whose answer is both currently necessary and supported by adequate premises should block progress and be sent to Slack.

Apply this to the `propose`/`specificate` and moderation behavior: `no_evolutionary_move` and `quiescent` are observations, not permission to end silently. Every human-decision dependency must have an observable route to resolution, while immature questions must not freeze the project.

Source: https://github.com/qmu/workaholic/issues/1085
