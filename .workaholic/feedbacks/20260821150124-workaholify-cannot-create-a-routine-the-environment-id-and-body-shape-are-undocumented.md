---
type: Feedback
title: /workaholify cannot create a routine: the environment id and body shape are undocumented
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-08-21T15:01:24+09:00
author: a@qmu.jp
supersedes: 
---

# /workaholify cannot create a routine: the environment id and body shape are undocumented

# /workaholify §5 cannot create a routine: the environment id and the create body shape are documented nowhere

Source: https://github.com/qmu/workaholic/issues/542

Measured 2026-08-20 in an interactive session carrying `RemoteTrigger`, against an account whose routine list was empty. `/workaholify` §5 reached the account, found five templates to create, and could create none of them — not `no_transport`, the transport was there and was used. The run stopped on `job_config.ccr.environment_id`, a required create field that nothing in the flow supplies and no document in the plugin names a source for:

    create {"job_config": {"ccr": {}}}
    → 400 translate job_config v1→v2: job_config must set ccr.environment_id or ccr.self_hosted_runner_pool_id

`render-routine.sh` omits `job_config` deliberately — the environment id is an account-level fact, and the body shape "belongs to the tool's own contract" — but the tool's contract documents actions, not `job_config`, and §5 never says where an environment id comes from. The operator was handed back work the session could have done, which is the defect §*`/workaholify` converges too* was written to close, one layer deeper. It bites hardest on an account with **no routines yet** — the only state where §5 has real work to do, and the only state where no live record exists to copy a body from.

Seven gaps are named: no stated source for `environment_id` (the harness's own `schedule` skill renders them); "there are two" is one account's fact stated as general, with nothing telling the session to enumerate first; the create/update body shape is documented nowhere and was recovered by walking 400s (`job_config.ccr.{environment_id, session_context, events}`, `events[].data.{uuid, session_id, type, parent_tool_use_id, message}`); template fields including `notifications: push` have no stated record mapping and are rendered as display strings rather than JSON; `mcp: []` is unachievable in one call (a create silently auto-attaches connectors; clearing them needs a second `update` with `clear_mcp_connections: true`); `sources` is not renderable at all, and `[Workaholic]`'s checkout of qmu/workaholic is stated only in template prose; and `no_transport` is the only named refusal, which is the wrong one for a session that reaches the account but cannot resolve an environment.

Six fixes are asked for: record the verified body in `reference/routines.md`; state the environment rule in §5 (enumerate, one → use it, more → ask, none → refuse by name); build the body in one place rather than in each caller; give templates a `sources:` field; add a second named refusal beside `no_transport`; and drop the account-specific count from `render-routine.sh`'s comment.

The 2026-08-19 run on this repository created four routines successfully and is not counter-evidence: that account already had two live routines, so `environment_id`, the `events[].data` envelope and the `session_context` shape were all copied off an existing record rather than derived from any document.
