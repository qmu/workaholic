#!/bin/sh
# Shared secret-shape denylist. Source this file and call `secret_grep` to filter a
# stream of lines (on stdin) down to those matching a known credential shape.
#
# Factored from ship/scripts/record-evidence.sh's scan_secrets() so the branch
# scanner and the evidence guard use ONE regex set. Deliberately excludes bare
# hex/base64 so commit hashes, versions, and blob ids never false-positive.
#
# Two passes, because the two rule families need opposite treatment:
#
#   1. Known key SHAPES (AKIA…, gh*_, github_pat_, xox*, bearer/basic, PEM) — the value
#      itself is unmistakably a credential, so these match unconditionally. A line may
#      legitimately hold both a reference and a real key (`k = process.env.X; // ghp_…`),
#      so pass 2's exclusions must NOT apply here.
#
#   2. Generic `password=`/`token=`/`api_key=` ASSIGNMENTS — the key name alone proves
#      nothing; only the right-hand side says whether this is a literal secret or ordinary
#      code REFERENCING one. Reading a key from the environment or passing it in a variable
#      is the *correct* way to handle secrets, so flagging those punished good code and
#      hard-blocked /ship on pure false positives (`secret` is non-overridable by design —
#      see gate-decision.sh). Pass 2 therefore subtracts the reference forms below.
#
# The exclusions repeat the key group on purpose: each must bind to the matched key's own
# right-hand side, or an unrelated `= foo;` elsewhere on the line would suppress a real
# `api_key = "sk-…"` sitting next to it.
#
# Still flagged (do not regress): `.env`-style `TOKEN=supersecretvalue123` (a bare value
# ending the line), quoted literals (`api_key = "sk-…"`), and unquoted non-identifier
# literals (`api_key: sk-abc123`). The "bare identifier + terminator" exclusion is what
# keeps those safe — a real `.env` value ends the line, whereas a variable reference is
# followed by `,` `;` `)` or `}`.

# Reads stdin, prints matching lines, returns 1 when nothing matched.
secret_grep() {
    _sp_input=$(cat)
    _sp_hits=$(
        {
            # ---- pass 1: unmistakable key shapes (never subtracted) ----
            printf '%s\n' "$_sp_input" | grep -Ei \
                -e 'AKIA[0-9A-Z]{16}' \
                -e 'gh[pousr]_[A-Za-z0-9]{20,}' \
                -e 'github_pat_[A-Za-z0-9_]{20,}' \
                -e 'xox[baprs]-[A-Za-z0-9-]{10,}' \
                -e '(bearer|basic)[[:space:]]+[A-Za-z0-9._~+/=-]{16,}' \
                -e '-----BEGIN[ A-Z]*PRIVATE KEY-----' \
                || true

            # ---- pass 2: generic assignments, minus reference-shaped right-hand sides ----
            printf '%s\n' "$_sp_input" \
                | grep -Ei -e '(password|passwd|secret|token|api[_-]?key)[[:space:]]*[:=][[:space:]]*[^[:space:]]{6,}' \
                | grep -Eiv \
                    -e '(password|passwd|secret|token|api[_-]?key)[[:space:]]*[:=][[:space:]]*(process\.env|import\.meta\.env|os\.environ|Deno\.env|ENV\[|getenv|System\.getenv)' \
                    -e '(password|passwd|secret|token|api[_-]?key)[[:space:]]*[:=][[:space:]]*[$][{]?[A-Za-z_]' \
                    -e '(password|passwd|secret|token|api[_-]?key)[[:space:]]*[:=][[:space:]]*[{][{]' \
                    -e '(password|passwd|secret|token|api[_-]?key)[[:space:]]*[:=][[:space:]]*<[A-Za-z_][A-Za-z0-9_ -]*>' \
                    -e '(password|passwd|secret|token|api[_-]?key)[[:space:]]*[:=][[:space:]]*["'"'"'][^A-Za-z0-9]' \
                    -e '(password|passwd|secret|token|api[_-]?key)[[:space:]]*[:=][[:space:]]*[A-Za-z_$][A-Za-z0-9_$]*(\.[A-Za-z0-9_$]+)*[[:space:]]*[,;)}]' \
                || true
        } | grep -v '^[[:space:]]*$' | sort -u
    )
    [ -n "$_sp_hits" ] || return 1
    printf '%s\n' "$_sp_hits"
}
