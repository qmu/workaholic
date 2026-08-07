---
type: Feedback
title: Adopt the six-color notify state emoji set, keeping the rocket for auto merge
kind: instruction
source: discussion
created_at: 2026-08-07T19:09:39+09:00
author: a@qmu.jp
supersedes: 
---

# Adopt the six-color notify state emoji set, keeping the rocket for auto merge

Developer's ruling on the emoji reconciliation that PR #301's ticket (from issue qmu/workaholic#300) left to the implementer: adopt the six-color state set 🔵 Proposed / 🟠 Implementing / 🟡 Handoff / 🟢 Implemented / 🟣 Merged / 🔴 Blocked for the notify post shapes, with one deliberate exception — an auto merge (merge_policy: auto, shipped by /ship without human approval) keeps 🚀, so 🟣 continues to mean "a person approved this merge" and the auto-vs-human distinction stays emoji-level, never text-only, as recorded in notify's reference/notifications.md. This supersedes the emoji proposed in issue #300 (📐/✅/🛠) and renames the "Merge Requested" shape to "Implemented"; each color maps to exactly one state, ending 🟢's double duty as both Proposed and Merge Requested.
