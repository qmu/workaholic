---
type: Feedback
title: Relay Codex loop Slack notifications through the connector-owning main thread
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-04T14:28:33+09:00
author: a@qmu.jp
supersedes:
---

# Relay Codex loop Slack notifications through the connector-owning main thread

# Relay Codex loop Slack notifications through the connector-owning main thread

Source: https://github.com/qmu/workaholic/issues/975

For Codex, do not require each scheduled worker or nested `codex exec` process to establish its own Slack OAuth connection. The main conversation already owns the connected Slack surface, while separately launched workers cannot inherit it; treating the worker as connected produces `no_slack_transport`, silent FB threads, and misleadingly running loops. Return structured Slack read/write intents and tick outcomes to the connector-owning main thread, and have that parent perform the Slack reads, acknowledgements, proposal FB posts, and Implemented replies. Keep authentication attached to the main integration rather than repeating it per worker or session, and define an explicit relay contract plus a visible failure state when no connector-owning parent exists. Consider this with issue #974’s startup proof and progress requirements.
