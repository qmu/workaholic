# Claude Code native runtime

Reserve a dispatch receipt before starting a subagent. Use the native task identity as `child_id` when the parent reports it. Re-read unfinished receipts after interruption or context compaction, and do not infer completion from the child process ending. Preserve the user's selected model and permission settings.
