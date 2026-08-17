#!/bin/sh -eu
# Step 7 — report documentation drift, starting from README.md.
#
# STUB. This step's behaviour is ticket `20260817113752-implement-the-repository-hygiene-steps.md`; until it lands, the step
# reports `not_implemented` rather than returning "nothing found". The
# distinction is the one `list-inbound-issues.sh` already makes and the one an
# hourly routine lives or dies on: a step that cannot run and a step that ran and
# found nothing are different facts, and rendering the first as the second is how
# an unattended tick starts lying about its own coverage.
#
# The contract this file will keep when it is filled in — inputs, what it may
# write, its abort reasons — is stated in `../../reference/workflow.md`, not here.
#
# Usage: doc-drift.sh --tick <id> --root <repo-root>
# Output: one JSON line {"step","status","reason","summary","needs_agent":[]}

set -eu

printf '{"step": "doc-drift", "status": "skipped", "reason": "not_implemented", "summary": "not implemented yet (ticket 20260817113752-implement-the-repository-hygiene-steps.md)", "needs_agent": []}\n'
