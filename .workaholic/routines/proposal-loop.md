---
type: Routine
name: proposal-loop
schedule: "*/15 * * * *"
command: claude -p "/propose" --dangerously-skip-permissions
env_file: .workaholic-drive.env
log_file: /tmp/workaholic-propose.log
---

# Proposal loop — read new feedback every 15 minutes

Reads the feedback records merged since the runner-local cursor, plus the repository's
own state, and either stays silent or proposes a mission with its ticket set behind a
pull request.

**Silence is the expected outcome most ticks.** The judgment bar is deliberately
conservative: a false negative costs one cycle, a false positive spams the channel.

Only one runner may point at a repository — the cursor is runner-local state, and two
crons on one repo would each advance a cursor the other cannot see.

Procedure and troubleshooting: `docs/proposal-loop-runbook.md`.
