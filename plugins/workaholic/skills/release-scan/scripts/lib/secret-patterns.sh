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
#
# One subtraction is not about the right-hand side at all: the SCOPE-RESOLUTION operator.
# `[:=]` matches a single colon, so the first `:` of Rust/C++/PHP's `::` reads as an
# assignment and `[^[:space:]]{6,}` then swallows the type name — making every `Token::Path`
# in a parser a `token=<secret>` hit. Observed on qfs, where 7 lines tripped the
# non-overridable tier and 5 of them were DOC COMMENTS. A key immediately followed by `::`
# is a namespace qualifier, never an assignment, so it is subtracted before the RHS rules.

# The credential key group, defined ONCE and reused by the match and by every
# subtraction below. They repeat the group on purpose (each must bind to its own matched
# key's right-hand side), so they must stay byte-identical — a group that drifts out of
# step either lets a real secret through or hard-blocks good code on a tier that cannot
# be waived. Interpolate `${_SP_KEY}`; never re-spell it inline.
#
# The `([_-][A-Za-z0-9_-]*)?` tail is what allows a SUFFIX after the keyword. A prefix
# always worked (`client_secret`), but a suffix used to be fatal, so `SECRET_KEY`,
# `secret_key`, `aws_secret_access_key` and `refresh_token_value` all passed straight
# through the non-overridable tier — including Django's SECRET_KEY and the exact key name
# AWS's own config files use. The tail requires the suffix to start with `_` or `-`, which
# is what keeps `tokenizer = "gpt-4"` and friends out: an alphanumeric continuation is not
# a separate word and is not matched.
_SP_KEY='(password|passwd|secret|token|api[_-]?key|access[_-]?key)([_-][A-Za-z0-9_-]*)?'

# A TypeScript TYPE EXPRESSION, for the annotation subtraction below. `apiKey: string` is
# a declaration, not a credential, but it parses as key-colon-literal and so was reported
# on the one tier that cannot be waived — in any TS codebase, on ordinary code.
#
# Note the bug was never "type annotations are unsupported": `let apiKey: string;` was
# always skipped, because the identifier-terminator subtraction accepts the trailing `;`.
# It is narrower — an annotation whose type does NOT end at a terminator. A union
# (`string | undefined`), a generic, or a type ending the line satisfies neither branch and
# falls through to "literal". That is also why it went unnoticed: the simplest shape passes.
#
# Covers `string`, `string | undefined`, `Array<string>`, `Map<string, string>`, `string[]`.
# Deliberately excludes `-`, so `api_key: sk-abc123def` is NOT read as a type and stays
# flagged, and requires a leading letter, so `password: "hunter2xyz"` stays flagged.
_SP_TYPE='[A-Za-z_$][A-Za-z0-9_$]*(<[^>]*>|\[\]|[[:space:]]*[|&][[:space:]]*[A-Za-z_$][A-Za-z0-9_$]*(<[^>]*>|\[\])*)*'

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
                | grep -Ei -e "${_SP_KEY}[[:space:]]*[:=][[:space:]]*[^[:space:]]{6,}" \
                | grep -Eiv \
                    -e "${_SP_KEY}[[:space:]]*::" \
                    -e "${_SP_KEY}[[:space:]]*[:=][[:space:]]*(process\.env|import\.meta\.env|os\.environ|Deno\.env|ENV\[|getenv|System\.getenv)" \
                    -e "${_SP_KEY}[[:space:]]*[:=][[:space:]]*[\$][{]?[A-Za-z_]" \
                    -e "${_SP_KEY}[[:space:]]*[:=][[:space:]]*[{][{]" \
                    -e "${_SP_KEY}[[:space:]]*[:=][[:space:]]*<[A-Za-z_][A-Za-z0-9_ -]*>" \
                    -e "${_SP_KEY}[[:space:]]*[:=][[:space:]]*[\"'][^A-Za-z0-9]" \
                    -e "${_SP_KEY}[[:space:]]*[:=][[:space:]]*[A-Za-z_\$][A-Za-z0-9_\$]*(\.[A-Za-z0-9_\$]+)*[[:space:]]*[,;)}]" \
                    -e "${_SP_KEY}[[:space:]]*:[[:space:]]*${_SP_TYPE}[[:space:]]*([,;)}]|\$)" \
                    -e "${_SP_KEY}[[:space:]]*:[[:space:]]*${_SP_TYPE}[[:space:]]*=[[:space:]]*([A-Za-z_\$][A-Za-z0-9_\$.]*[[:space:]]*([,;)}]|\$)|[0-9])" \
                || true
        } | grep -v '^[[:space:]]*$' | sort -u
    )
    [ -n "$_sp_hits" ] || return 1
    printf '%s\n' "$_sp_hits"
}
