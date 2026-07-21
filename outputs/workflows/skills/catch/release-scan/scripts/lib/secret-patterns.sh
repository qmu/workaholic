#!/bin/sh
# Shared secret-shape rules. Source this file and call `secret_grep` to filter a stream of
# lines (on stdin) down to those matching a known credential shape.
#
# Deliberately excludes bare hex/base64 so commit hashes, versions, and blob ids never
# false-positive.
#
# SHARED with ship/scripts/record-evidence.sh — partially, and the boundary is deliberate.
# That script sources this file for the credential KEY GROUP (`_SP_KEY`) and the pass-1
# unmistakable shapes (`secret_pass1_grep`), so those can never drift again (they had:
# measured 2026-07-15, the evidence guard's inline copy missed all five suffixed-keyword
# shapes — `SECRET_KEY`, `aws_secret_access_key`, … — that this file had caught since
# 84d238d9).
#
# What is NOT shared is pass 2's value judgment (`secret_grep` stays scanner-only). The
# two guards read different material and want different bars. This file scans CODE, where
# a reference is ordinary and a false positive hard-blocks /ship with no bypass.
# record-evidence.sh scans a few lines of free-text deploy evidence on their way into a
# PUBLIC story, where a false positive costs a rephrase and a false negative publishes a
# credential — so it stays paranoid and flags a generic assignment on the key name alone.
# Pass 2's reference reasoning is code-shaped and would weaken it: `token: abc123def,` is
# a reference in TypeScript, and a pasted JSON fragment in prose.
#
# Two passes, because the two rule families need opposite treatment:
#
#   1. Known key SHAPES (AKIA…, gh*_, github_pat_, xox*, bearer/basic, PEM) — the value
#      itself is unmistakably a credential, so these match unconditionally. A line may
#      legitimately hold both a reference and a real key (`k = process.env.X; // ghp_…`),
#      so pass 2's rules must NOT apply here.
#
#   2. Generic `password=`/`token=`/`api_key=` ASSIGNMENTS — the key name alone proves
#      nothing; only the right-hand side says whether the line HOLDS a secret or merely
#      REFERENCES one. Reading a key from the environment or passing it in a variable is
#      the *correct* way to handle secrets, so flagging those punishes good code and
#      hard-blocks /ship on pure false positives (`secret` is non-overridable by design —
#      see gate-decision.sh).
#
# ---------------------------------------------------------------------------------------
# PASS 2 MATCHES ON THE VALUE, NOT THE KEY NAME. That direction is the whole design, and it
# was arrived at the hard way.
#
# The rule used to work the other way round: match the key NAME, then subtract innocent
# right-hand sides one at a time — a bare identifier, a dotted path, an environment read, a
# template, `::`, a type annotation. Each subtraction was correct, and each was retrofitted
# only AFTER a real branch had been hard-blocked. The list never converged, because the
# default for an unseen shape was "hard-block, non-overridable", and innocence is unbounded:
# the next unlisted-but-innocent shape was always the next outage. A call — `apiKey:
# keyOption()`, the most ordinary way to fetch a credential in TypeScript — was the fifth.
#
# So pass 2 asks the opposite question: does the right-hand side LOOK LIKE A SECRET VALUE?
# Only two shapes do, and unlike innocence, guilt is bounded:
#
#   (a) a QUOTED string whose content starts alphanumeric — `api_key = "sk-…"`
#   (b) a BARE run of value characters that ENDS THE LINE — `.env`-style `TOKEN=value123`
#
# Everything else — identifier, dotted path, call, template, generic, annotation, scope
# resolution — simply is not one of those two shapes and needs no rule of its own. The old
# subtractions for `::`, `${…}`, `{{…}}`, `<placeholder>`, quoted-non-alphanumeric, and
# identifier-plus-terminator are all GONE. They were not wrong; an allowlist of guilt just
# makes them unnecessary. `Token::Path` is not skipped because `::` is enumerated — it is
# skipped because `:Path` is not a literal.
#
# Why (b) must END THE LINE: a real `.env` value ends the line, whereas a variable
# reference is followed by `,` `;` `)` or `}`. That single observation separates
# `TOKEN=supersecretvalue123` (a credential) from `apiKey: theKey,` (a reference) without
# enumerating either. It is why `apiKey: keyOption(),` costs nothing to skip: a call ends
# in `(`…`),`, so it never reaches the anchor.
#
# TWO RULES SURVIVE THE INVERSION. Both are CLOSED lists — API names and language keywords,
# not "shapes that happen to look innocent" — which is why they do not reopen the denylist:
#
#   * ENVIRONMENT READS. `SECRET_KEY = process.env.DJANGO_SECRET` genuinely is shape (b):
#     dots are value characters and it ends the line, so the allowlist of guilt catches it.
#     The well-known env-reader names are short and closed, so subtracting them costs
#     nothing and buys back the single most common correct way to handle a secret.
#
#   * `key: <primitive>` AT END OF LINE. This is the one real ambiguity, and matching on the
#     value does not dissolve it: `apiKey: string` (a TypeScript annotation) and `password:
#     mysecret123` (a plaintext credential in a YAML file) are the SAME shape — `key: word`
#     — and the line carries nothing that separates them. Both values are bare words, so
#     asking about the value cannot help. `grep -Ei` runs the pass case-insensitively, so
#     "an uppercase initial means a type" is not available either.
#
#     It errs toward FLAGGING: only a KNOWN PRIMITIVE type name is subtracted, and an
#     unknown bare word reads as a literal. That direction was paid for. An earlier version
#     resolved it the other way — any identifier counted as a type — and silently stopped
#     flagging three real credential shapes on the one tier nothing else backstops. A false
#     positive here is noise; a false negative ships a key. The cost is that a custom type
#     (`apiKey: MyKeyType`) is flagged, which is exactly what the rule did before the
#     annotation subtraction ever existed, so it is not a new false positive.
#
# RESIDUAL, named rather than solved: a NON-env dotted path that ends the line without a
# terminator (`apiKey = config.key`) reads as shape (b) and flags. It flagged before this
# inversion too — the old identifier/dotted-path subtraction also required a trailing
# `,;)}` — so it is not a regression, and it errs in the safe direction. A quoted JWT still
# flags via (a); a bare unquoted one (`TOKEN=eyJhbGc.eyJzdWI.SflKxw`) flags via (b),
# because dots are value characters.
#
# The gate for any future change here is the 40-line table in the ticket that produced this
# inversion, mirrored in test-workflow-scripts.mjs: 15 lines that must flag (a miss ships a
# key) and 25 that must not (a hit hard-blocks /ship with no bypass).
# ---------------------------------------------------------------------------------------

# The credential key group, defined ONCE and reused by the match and by both surviving
# subtractions. They repeat the group on purpose (each must bind to its own matched key's
# right-hand side), so they must stay byte-identical — a group that drifts out of step
# either lets a real secret through or hard-blocks good code on a tier that cannot be
# waived. Interpolate `${_SP_KEY}`; never re-spell it inline.
#
# The `([_-][A-Za-z0-9_-]*)?` tail is what allows a SUFFIX after the keyword. A prefix
# always worked (`client_secret`), but a suffix used to be fatal, so `SECRET_KEY`,
# `secret_key`, `aws_secret_access_key` and `refresh_token_value` all passed straight
# through the non-overridable tier — including Django's SECRET_KEY and the exact key name
# AWS's own config files use. The tail requires the suffix to start with `_` or `-`, which
# is what keeps `tokenizer = "gpt-4-tokenizer"` out: an alphanumeric continuation is not a
# separate word, so the keyword is never followed by `:` or `=` and the line never matches.
_SP_KEY='(password|passwd|secret|token|api[_-]?key|access[_-]?key)([_-][A-Za-z0-9_-]*)?'

# A VALUE character: what a credential is actually made of. Excludes every character that
# marks a reference — `(` `)` (call), `{` `}` (template/object), `$` (interpolation), `<`
# `>` (generic/placeholder), `,` `;` (terminator), `:` (scope resolution), quotes, space.
_SP_VCHAR='[A-Za-z0-9_.+/=~-]'

# A LITERAL right-hand side: the two shapes a secret value actually takes.
#   (a) quote + alphanumeric + 4 more non-space  — a 6-character floor, so `token: "ab"`
#       stays quiet; a quote followed by punctuation is a placeholder, not a value.
#   (b) 6+ value characters running to the end of the line (trailing blanks tolerated).
_SP_LIT="([\"'][A-Za-z0-9][^[:space:]]{4,}|${_SP_VCHAR}{6,}[[:space:]]*\$)"

# A TYPE ANNOTATION sitting between `key:` and `=`, for the `secret: string = "…"` form.
# Deliberately NARROW — no `;` `{` `}` `(` `)` `=` or quotes — so it cannot run across an
# unrelated `= "…"` later on the line and manufacture a hit on a key that has no value of
# its own. Covers `string`, `string | undefined`, `Array<string>`, `Map<string, string>`,
# `string[]`.
_SP_ANNOT='[]A-Za-z0-9_$<>|&,.[[:space:]-]*'

# The known primitive type names — the whole of the surviving `key: bareword` enumeration.
# See the header: an unknown bare word is a literal, not a type.
_SP_PRIM='(string|number|boolean|bigint|symbol|undefined|null|any|unknown|never|void|object|date)'

# ---- pass 1: unmistakable key shapes (never subtracted) ----
# The value itself is unmistakably a credential, so these match unconditionally.
# Shared: record-evidence.sh sources this file and calls this same function, so
# the evidence guard and the branch scanner flag identical pass-1 shapes by
# construction. Reads stdin, prints matching lines; grep's status (1 = none).
secret_pass1_grep() {
    grep -Ei \
        -e 'AKIA[0-9A-Z]{16}' \
        -e 'gh[pousr]_[A-Za-z0-9]{20,}' \
        -e 'github_pat_[A-Za-z0-9_]{20,}' \
        -e 'xox[baprs]-[A-Za-z0-9-]{10,}' \
        -e '(bearer|basic)[[:space:]]+[A-Za-z0-9._~+/=-]{16,}' \
        -e '-----BEGIN[ A-Z]*PRIVATE KEY-----'
}

# Reads stdin, prints matching lines, returns 1 when nothing matched.
secret_grep() {
    _sp_input=$(cat)
    _sp_hits=$(
        {
            printf '%s\n' "$_sp_input" | secret_pass1_grep || true

            # ---- pass 2: generic assignments whose VALUE looks like a literal ----
            # First -e: `key = <literal>` / `key: <literal>`.
            # Second -e: `key: <annotation> = <literal>` — an annotation does not make the
            # initializer innocent (`secret: string = "hunter2value"` is still a credential).
            printf '%s\n' "$_sp_input" \
                | grep -Ei \
                    -e "${_SP_KEY}[[:space:]]*[:=][[:space:]]*${_SP_LIT}" \
                    -e "${_SP_KEY}[[:space:]]*:${_SP_ANNOT}=[[:space:]]*${_SP_LIT}" \
                | grep -Eiv \
                    -e "${_SP_KEY}[[:space:]]*[:=][[:space:]]*(process\.env|import\.meta\.env|os\.environ|Deno\.env|ENV\[|getenv|System\.getenv)" \
                    -e "${_SP_KEY}[[:space:]]*:[[:space:]]*${_SP_PRIM}[[:space:]]*\$" \
                || true
        } | grep -v '^[[:space:]]*$' | sort -u
    )
    [ -n "$_sp_hits" ] || return 1
    printf '%s\n' "$_sp_hits"
}
