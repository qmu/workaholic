---
type: Routine
name: drive-loop
schedule: "*/5 * * * *"
command: claude -p "/drive" --dangerously-skip-permissions
env_file: .workaholic-drive.env
log_file: /tmp/workaholic-drive.log
---

# Drive loop — drain the queue every 5 minutes

Runs the sole executor against this repository's queue. Each tick surveys what is
claimable, claims a PR-unit, drives it, and routes it by its effective merge policy;
an empty queue is a normal, silent outcome.

The tick ends with the reconciliation line and an honest terminal token (`ok` only when
nothing claimable remains **and** the survey was current with the base), which is what
makes the cron log readable without a debugger.

`env_file` holds this machine's `SLACK_BOT_TOKEN` / `WORKAHOLIC_SLACK_CHANNEL` and lives
in `$HOME`, never in the repository — the crontab line sources it rather than carrying
the values, because `crontab -l` is not privileged.

Procedure and troubleshooting: `docs/drive-loop-runbook.md`.
