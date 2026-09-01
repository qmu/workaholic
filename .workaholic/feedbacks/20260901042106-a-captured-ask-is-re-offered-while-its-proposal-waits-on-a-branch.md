---
type: Feedback
title: A captured ask is re-offered while its proposal waits on a branch
kind: insight
source: development
subject: observer_ai:tamurayoshiya
created_at: 2026-09-01T04:21:06+00:00
author: a@qmu.jp
supersedes: 
---

# A captured ask is re-offered while its proposal waits on a branch

Source: https://github.com/qmu/workaholic/issues/812

Issue #812 — the `20260901-015055` moderation tick's undelivered root, the third consecutive hour with no Slack transport — was offered to this `[Specificate]` tick as an ask in hand for the second time. Its record was already written six hours earlier and sits on `work-20260901-022335` behind pull request #813, whose body carries `Closes #812`. Taking it again would have written a second record for the same hour.

The ask's own content is answered and needs nothing from this repository. It asks for one of two provisioning acts — re-authorize the Slack connector against the workspace holding `#dev-workaholic`, or set `SLACK_BOT_TOKEN` on the cloud environment the routines select — and both are the operator's, not the loop's: on https://github.com/qmu/workaholic/issues/806 the operator ruled directly that the issue stays open because the repair is theirs, and `20260831221757-the-operator-rejects-provisioning-a-slack-bot-identity.md` forbids re-proposing any Slack-side credential until they say otherwise. The mechanism that filed #812 in the first place (issue #807) is working exactly as designed.

What taking it in hand revealed is a different, unproposed defect, and it is in `list-inbound-issues.sh`.

**The header states the intent the implementation misses.** The script's own `ALREADY-CAPTURED EXCLUSION` paragraph reads: "an OPEN issue whose number a feedback record already names is in flight — captured, **its proposal PR open** or its record-only merge pending — and re-taking it would duplicate the record." That is precisely #812's state. But the test is `grep -rqE "/issues/<N>" "$FEEDBACKS_DIR"` over the caller's checkout, which is `main`: a record that exists only on an unmerged proposal branch is invisible to it, so the one case the header names as in-flight is the one case the grep cannot see.

**The sibling reader already solved this.** `list-proposed-refs.sh` walks the artifacts on unmerged remote branches through the same git-native oracle the claim protocol rests on — no auth, no API, a merge-base test per remote branch and a two-dot tree diff per unmerged one — for exactly this reason, recorded in its own header: "its `feedback:` refs on a branch nobody reads, and the seam concluded the ask had not been proposed." The dedup set was taught to read unmerged branches; the discovery set was not. One exclusion reads the base only, one reads the base plus the branches, and the inbound half is the one that decides whether a run happens at all.

**Measured.** #812 has now been offered twice (`20260901-032838`, this tick) while #813 has been open since 02:23. The four earlier hours produced records at hourly cadence, so an issue that stays undelivered is re-taken every hour indefinitely — each re-take a fresh record, a fresh publish-tree branch and a fresh pull request, each conflicting on the generated feedbacks index against every other open proposal (`20260831201820-every-open-proposal-conflicts-on-the-generated-feedbacks-index.md`).

**Why the earlier deferral no longer holds.** `20260901032838-a-fourth-moderation-hour-reached-nobody-and-compounded-with-an-undelivered-proposal.md` named this same loop and proposed no work for it, on the reasoning that "delivering the clean publication closes that loop without any change to the discovery or the dedup set." Delivery is not closing it. #813 is still open six hours on and GitHub now answers `mergeable_state: dirty` for it, and the clean-stranded publications #625 and #635 have been open since 2026-08-26 — six days. The discovery gap outlives every individual delivery failure, and it is one grep away from being closed on its own terms.

What is asked for: make `list-inbound-issues.sh`'s `already_captured` exclusion see a record on an unmerged remote branch, so the header's "its proposal PR open" case is actually excluded. The mechanism to reuse is `list-proposed-refs.sh`'s own branch walk; the cost profile is already measured there and is dominated by the remote branch count rather than the artifact count.
