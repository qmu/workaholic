---
type: Feedback
title: Make the unattended cloud runner a shape the plugin assumes
kind: instruction
source: discussion
created_at: 2026-08-01T03:11:10+09:00
author: a@qmu.jp
supersedes: 
---

# Make the unattended cloud runner a shape the plugin assumes

「パイロットルーティンで埋めるのではなく、この構想含めてfeedbackしつつ、ちゃんとworkaholicのプラグインの構成自体がこれを想定したものとなるようにしたい」 — the shape is an hourly cloud routine that drives, from the latest `main`, the missions and tickets assigned to the developer, through `/report`, and ends either in review-and-merge or in a report that hands the remainder to a human and their Claude Code. Building it as a pilot on 2026-08-01 (`[Drive] workaholic (pilot)`, an Anthropic cloud routine) measured four places where the plugin does not assume that runner, and where the routine prompt is currently compensating: a fresh cloud checkout starts on a generated branch with the wrong git identity, and `plan-units.sh` swallows the resulting `list-todo.sh` failure into a silently empty backlog; the survey never filters missions by `assignees`, so any runner is offered every approved mission; a claim is pushed within seconds but nothing announces it, so a person sees no PR and no message until the whole unit is driven; and an unfinished unit cannot be resumed by anybody. A prompt can paper over all four — that is the wrong home, because the next runner has to re-derive them.
