#!/bin/sh
# Shared secret-shape denylist. Source this file and call `secret_grep` to filter a
# stream of lines (on stdin) down to those matching a known credential shape.
#
# Factored from ship/scripts/record-evidence.sh's scan_secrets() so the branch
# scanner and the evidence guard use ONE regex set. Deliberately excludes bare
# hex/base64 so commit hashes, versions, and blob ids never false-positive.

# Reads stdin, prints matching lines, returns grep's status (1 = no match).
secret_grep() {
    grep -Ei \
        -e 'AKIA[0-9A-Z]{16}' \
        -e 'gh[pousr]_[A-Za-z0-9]{20,}' \
        -e 'github_pat_[A-Za-z0-9_]{20,}' \
        -e 'xox[baprs]-[A-Za-z0-9-]{10,}' \
        -e '(bearer|basic)[[:space:]]+[A-Za-z0-9._~+/=-]{16,}' \
        -e '-----BEGIN[ A-Z]*PRIVATE KEY-----' \
        -e '(password|passwd|secret|token|api[_-]?key)[[:space:]]*[:=][[:space:]]*[^[:space:]]{6,}'
}
