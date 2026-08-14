---
type: Feedback
title: Close achieved missions automatically at the end of /implement
kind: instruction
source: discussion
subject: person:a@qmu.jp
created_at: 2026-08-14T03:09:19+00:00
author: a@qmu.jp
supersedes: 
---

# Close achieved missions automatically at the end of /implement

# Close achieved missions automatically at the end of /implement

Ending a mission that has fully landed is still a manual `/mission-close`. On 2026-08-14 three missions — `draft-deployment-plans-in-the-release-note-before-deploying`, `refresh-the-outdated-documentation-to-match-current-behavior` and `revive-strategy-and-reshape-the-workaholic-artifact-set` — were sitting `active` at 3/3 `## Acceptance` with every ticket archived and a story reported, and had to be swept closed by hand (PR #446) hours after their implementing PRs merged; the roadmap lens kept showing them as in-flight the whole time. `/implement` should do this itself: at the end of its unattended run, close any mission whose acceptance is total and whose work has merged as `achieved`, so done-but-open missions stop accreting between human sweeps. `abandoned` and `carried` stay a human ruling — only the unambiguous fully-achieved case is what the unattended path may close on its own.
