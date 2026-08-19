#!/bin/sh -eu
# Mint the id that names one `/propose` tick.
#
# WHY IT EXISTS (2026-08-17, issue #471). A tick spans many separate shell
# invocations — nine step scripts, then whatever the agent files afterwards — and
# every one of them writes into the same log section. An id minted per invocation
# would scatter one tick across nine sections; an env var does not survive between
# a session's separate shell invocations. So the id is minted ONCE, by `run.sh`,
# and passed explicitly to everything downstream.
#
# UTC, not local time. The log's day file is derived from the id's first eight
# characters, so a runner in Asia/Tokyo and a container in UTC must agree on which
# file a tick belongs to. (The one place local time matters is the check-in step's
# late-night boundary, which reads the workspace timezone deliberately and
# separately — a clock for humans, not for file names.)
#
# Usage: tick-id.sh
# Output: one JSON line {"tick": "YYYYMMDD-HHMMSS"}

set -eu

printf '{"tick": "%s"}\n' "$(date -u +%Y%m%d-%H%M%S)"
