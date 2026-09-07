# Codex native runtime

Reserve a dispatch receipt before starting a subagent. Keep the parent turn open while work is active so user input can interrupt it. After compaction or interruption, read the receipt and current snapshot again before starting another worker. Preserve the user's selected model and permission settings.
