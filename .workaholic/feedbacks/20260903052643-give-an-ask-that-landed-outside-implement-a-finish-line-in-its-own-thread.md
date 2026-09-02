---
type: Feedback
title: Give an ask that landed outside /implement a finish line in its own thread
kind: instruction
source: slack
subject: person:YO
created_at: 2026-09-03T05:26:43+09:00
author: a@qmu.jp
supersedes: 
---

# Give an ask that landed outside /implement a finish line in its own thread

Source: https://github.com/qmu/workaholic/issues/917

The operator expects the channel to show, continuously and without being asked, where
development stands. An ask captured by the inbound sweep gets its receipt in its own thread;
when the work it asked for lands through a session working the ask directly rather than
through an /implement unit, no unit ever reaches the route step, so no finish line is ever
posted. The thread ends at the receipt, and from the channel an ask that shipped hours ago
and one nobody has started look identical.

/implement behaved correctly: it had no unit, so it had nothing to announce, and the per-unit
rule is right. What is missing is a reader for the case where a feedback item life ends
somewhere other than a unit route.

The five-minute /infinite-development tick already reads the channel every turn and already
resolves threads through the stateless lookup, so it is the one step positioned to notice
that a feedback item issue is closed while its thread carries a receipt and no finish line.

Asked for: a tick that finds a closed [FB] issue whose thread has a receipt and no finish
line posts one finish line into that thread, naming what landed, exactly once. The usual
bounds apply unchanged: nothing on an idle tick, nothing for an item already announced, and
a tie goes to silence.
