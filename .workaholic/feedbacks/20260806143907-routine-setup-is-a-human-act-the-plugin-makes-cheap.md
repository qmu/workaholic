---
type: Feedback
title: Routine setup is a human act the plugin makes cheap
kind: instruction
source: discussion
created_at: 2026-08-06T14:39:07+09:00
author: a@qmu.jp
supersedes: 
---

# Routine setup is a human act the plugin makes cheap

The developer's ruling, 2026-08-06, closing the day's routine-management findings: /setup-routines does not hold as an API management surface, and /workaholify must not lean on it. The grounds are measured, not argued. A routine's GitHub trigger wiring is configured in the web UI only (code.claude.com/docs/en/routines, Add a GitHub trigger), is invisible to GET /v1/code/triggers — a routine that demonstrably fired on an assigned issue returns a record with no trigger field and no last_fired_at — and cannot be created, read, or verified from a session. The list endpoint paginates at 20 with has_more, which a whole day of account surveys never read, so the fleet inventory itself was wrong: the wired, firing [Propose] workaholic sat beyond page one while six visible http_api duplicates were surveyed, updated, and finally deleted by hand. A tool that manages the readable half of a routine while blind to the half that determines whether it runs at all misleads more than it helps. What remains for the plugin is exactly one job: make the human's UI setup as cheap as possible — render, from each template, a copy-paste setup sheet (name, model, prompt verbatim, the trigger's exact UI steps from a structured declaration, connectors, channel) — and stop pretending to know or manage the account. Prompt updates through the API remain technically possible; they are retired with the rest, because half-managing is how six duplicates got carefully updated while the real routine ran a stale prompt.
