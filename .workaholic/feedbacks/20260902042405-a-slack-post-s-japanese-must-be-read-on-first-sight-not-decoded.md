---
type: Feedback
title: A Slack post's Japanese must be read on first sight, not decoded
kind: instruction
source: slack
subject: person:a@qmu.jp
created_at: 2026-09-02T04:24:05+00:00
author: a@qmu.jp
supersedes: 
---

# A Slack post's Japanese must be read on first sight, not decoded

Source: https://github.com/qmu/workaholic/issues/859

The operator reports that the FB posts arriving in the channel are being produced by
translating the English record titles word for word into Japanese, to the point of
being unintelligible, and that these keep coming one after another.

Measured examples from one post: "fail the build" was rendered as 「組み立てを止める」
(literally "stop the assembling" — the reader cannot tell it means CI), "shape" became
a bare 「形」, and "demonstrable verdict" became 「示せるという判定」; the sentence around
them preserves English word order, so the whole post reads as a riddle.

The operator's instruction: the Japanese the notify rendering emits must be natural
Japanese a reader parses on first sight, not a calque —

- keep established technical terms in their katakana or English forms (ビルド, CI,
  デプロイ, PR, and the project's own glossary terms),
- translate the meaning of the title rather than its words,
- when a title resists translation, paraphrase the ask in plain Japanese instead of
  transliterating it.

The bar to state in the rendering rule: a channel reader must understand what is being
asked without opening the English record behind the link.
