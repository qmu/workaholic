---
description: Watch Slack with no model in the loop and implement new requests in the background — the lightweight development loop.
---

# Work

Run the **`workaholic:watch` skill** in this session. `$ARGUMENTS` may carry an interval
(`/work 1m`, `/work 5m`); pass it to the watcher as seconds, default 120.

One session, one watcher: if a Monitor running `watch-slack.sh` is already live in this session,
say so and start nothing. To stop, stop that Monitor.
