# Claude Code native runtime

Reserve a dispatch receipt before starting a subagent. Use the native task identity as `child_id` when the parent reports it. Re-read unfinished receipts after interruption or context compaction, and do not infer completion from the child process ending. Preserve the user's selected model and permission settings.

Use [native-loop.md](native-loop.md) for event fields and state transitions, including recording
a confirmed native cancellation separately from a role's terminal result.

The coordinator's operative instructions are in `commands/infinite-development.md`, including
unattended decisions, evidence before diagnosis, unknown-versus-empty readings, gate-before-write
ordering and the total native worker bound. Apply them even when general plugin rules were not
preloaded. Rediscover actual live children; never infer spare capacity from missing receipts.
