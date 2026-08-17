#!/bin/sh -eu
# Step 8 — propose expansion and consolidation work for an active strategy.
#
# STUB. This step's behaviour is ticket `20260817113753-implement-the-strategy-proposal-step.md`; until it lands, the step
# reports `not_implemented` rather than returning "nothing found". The
# distinction is the one `list-inbound-issues.sh` already makes and the one an
# hourly routine lives or dies on: a step that cannot run and a step that ran and
# found nothing are different facts, and rendering the first as the second is how
# an unattended tick starts lying about its own coverage.
#
# The contract this file will keep when it is filled in — inputs, what it may
# write, its abort reasons — is stated in `../reference/workflow.md`, not here.
#
# Usage: strategy-proposals.sh --tick <id> --root <repo-root>
# Output: one JSON line {"step","status","reason","summary","needs_agent":[]}

set -eu

printf '{"step": "strategy-proposals", "status": "skipped", "reason": "not_implemented", "summary": "not implemented yet (ticket 20260817113753-implement-the-strategy-proposal-step.md)", "needs_agent": []}\n'
