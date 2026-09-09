---
type: Feedback
title: Name the destination in the binding report instead of a boolean
kind: defect
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-09T09:04:59+09:00
author: a@qmu.jp
supersedes: 
---

# Name the destination in the binding report instead of a boolean

`infinite-development`'s report contract asks for "the declared binding this tick resolved". It
does not say the destination must be named, and nothing checks that it was. A session can satisfy
the line with `ok:true / declared:true / conflicts:[]` — which reports that *a* binding resolved,
not *which* — and the report reads as complete while carrying no destination at all.

Measured on `osbrjp/coop-planner`, 2026-09-09. A loop session ran roughly fifty consecutive ticks
calling the reader as

```
read-declared-binding.sh --root . | jq -c '{ok,declared,conflicts,reason}'
```

The projection drops `binding`, so the channel name never entered that session's context from the
authoritative source. Every tick reported the boolean triple. When the operator later asked where
the reports were being delivered, the session answered with a channel name it had never read —
`#dev-csnet`, plausible because the repository is saturated with `csnet` (the `csnet` MCP server,
the sibling `coop-csnet-poc`, the hostname `app-csnet.coop-planner.com`) and a peer session in the
same listing was titled `dev-csnetチャンネルへのアクセス確認`. The declared channel is
`coop-planner` / `C0BKV34JK39`. The operator caught it; nothing in the loop could have.

The reader is not at fault — `binding` was present and correct in every one of those fifty
responses. What the contract permits is the whole of the defect: the one field a person would use
to catch a wrong destination is optional in the report, so the wrongness had no surface to appear
on. Fifty ticks of "the binding resolved" and one sentence of prose were the only two things the
operator could see, and only the second could be wrong.

This is the skill's own top rule turned inside out. *Readability precedes counting — an incomplete
read is unknown, never zero.* A projected-away field is an incomplete read that does not look like
one: a null read is visible and a discarded field is not, so the gap gets filled instead of
reported. Every other identifier in those reports (`884fcc2a`, `work-20260909-082717`,
`qfs_preview_refused`, issue numbers) came from a tool result and was checkable. The channel name
was the only string the session authored, and it was the only one that was wrong.

**Asked for:** make the report line carry `channel` and `mount` verbatim from the reader, so a
destination that was never read cannot be reported as one. A rendering helper beside
`read-declared-binding.sh` — one line, `coop-planner (C0BKV34JK39) via /slack-yodex` — would make
quoting it cheaper than paraphrasing it, which is what actually decides whether a session does it.

**And one thing the reader itself could say.** In this repository the declaration lives in
`AGENTS.md`, which is **untracked**. `read-declared-binding.sh` answers `sources: ["AGENTS.md"]`,
`ok: true`, `conflicts: []` with no signal that its own source is uncommitted — a destination that
`git clean` would remove is reported as settled. The reader already opens the file; whether it is
tracked is one `git ls-files --error-unmatch` away, and a session that saw `source_tracked: false`
would say so rather than discover it by accident.
