---
type: Feedback
title: QFS hides a rejected write's own error and a renamed mount cannot call its procedures
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-09T16:28:31+09:00
author: a@qmu.jp
supersedes: 
---

# QFS hides a rejected write's own error and a renamed mount cannot call its procedures

# QFS hides a rejected write's own error, and a non-/slack mount cannot call its own procedures

Source: https://github.com/qmu/workaholic/issues/1136

Two QFS-side observations, both measured on 2026-09-09 while wiring this repository's declared
Slack binding (`workspace: qmu`, `channel: dev-workaholic`) to newly authorized accounts
`cc01-qmu` and `cdx01-qmu`. Neither is a workaholic defect; both were found because a workaholic
transport path stopped on them, and both are stated as observations rather than diagnoses.

**1. A rejected write hides the service's own error.** `chat.postMessage` is answered by Slack
with HTTP 200 and `{"ok": false, "error": "..."}` — Slack's convention for an application-level
refusal. The qfs HTTP driver collapses this to
`{"error":{"code":"commit_failed","kind":"commit_failed","message":"Terminal { reason: \"service response failed: service_rejected\" }"}}`
and the response body is never surfaced. At `RUST_LOG=debug` the applier logs only
`rest request method=POST url=https://slack.com/api/chat.postMessage status=200`, and
`RUST_LOG=trace` adds nothing carrying the body. So the caller cannot distinguish `missing_scope`
from `not_in_channel`, `restricted_action`, `is_archived` or a payload error — all of which need
different fixes by different people. Measured on both `/slack-cdx01-qmu` and `/slack-cc01-qmu`
inserting into `<mount>/qmu/C0BLL9J7FMY/messages`: the PREVIEW is correct and complete in both
cases (`total_affected: {"exact": 1}`, one INSERT row, `irreversible: false`); only `--commit`
fails. Reads through the same mounts and the same credential succeed, so the token is valid and
the mount is right. What would settle it: carry the service's own `error` field into the terminal
reason, or log the response body at debug when a 2xx is classified as `service_rejected`. A
refusal that names itself is the difference between a one-minute fix and an afternoon of
elimination.

**2. A mount not named `/slack` makes its own advertised procedures uncallable.** A multi-account
setup needs distinct mount paths, so the accounts here are mounted as `/slack-cc01-qmu`,
`/slack-cdx01-qmu`, `/slack-clauyo`, `/slack-yodex`. `qfs describe /slack-cdx01-qmu/qmu --json`
advertises five procedures on that node — `react(channel, ts, emoji)`, `pin`, `unpin`, `update`,
`delete` — and neither documented call form reaches them: the piped form answers
`{"code":"unknown_driver","kind":"capability","message":"no driver is mounted for namespace `slack`"}`
and `CALL /slack-cdx01-qmu/qmu.react(...)` answers
`{"code":"parse_error","kind":"parse","message":"a reserved keyword cannot be used here","detail":"RESERVED_AS_IDENTIFIER"}`.
The procedure namespace appears to be derived from the mount name — the PREVIEW plan for an INSERT
on the same path reports `"target":{"driver":"slack-cdx01-qmu", …}` — and `slack-cdx01-qmu` is a
hyphenated identifier the parser will not accept in a `CALL`. The result is that INSERT works on
these mounts while every procedure DESCRIBE advertises does not, which makes DESCRIBE's
`procedures` list unreliable exactly where it is most needed: on a host with more than one account
for the same service. What would settle it: let a `CALL` name the driver namespace of the mount it
is piped from (or accept a quoted/hyphenated namespace), or have DESCRIBE omit procedures that
cannot be called on that mount. Either is fine; the two disagreeing is the problem.

**What is not being claimed.** Item 1 is an observation about error reporting, not a claim that any
particular Slack error is the cause — establishing that is precisely what the missing body would
allow. Item 2 was measured on the `CALL` forms in `qfs skill`; if another form reaches these
procedures, that form is not discoverable from DESCRIBE's output.
