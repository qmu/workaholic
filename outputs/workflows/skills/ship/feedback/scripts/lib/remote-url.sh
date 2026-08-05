#!/bin/sh
# Shared origin-URL reader for the cross-repository crossing flow -- the SINGLE answer to
# "what URL does this repository's origin have", sourced by both consumers so they cannot
# drift.
#
#   resolve-target.sh       reports one URL as the destination a human confirms.
#   check-outbound-body.sh  matches the body against every form, as a safety backstop.
#
# THE PROBLEM THIS EXISTS FOR. A repository's origin URL is not one string. git rewrites
# remote URLs through `url.<replacement>.insteadOf <original>` rules, and a host may set
# those in system or global config OR inject them through the GIT_CONFIG_COUNT /
# GIT_CONFIG_KEY_n / GIT_CONFIG_VALUE_n environment triple -- which is invisible to
# `git config --global --list` and therefore easy to miss when diagnosing. The two ways of
# asking git for the URL then disagree:
#
#   git remote get-url origin          -> the REWRITTEN url (what git will contact)
#   git config --get remote.origin.url -> the CONFIGURED url (what the repo records)
#
# Measured 2026-08-04 in the Claude Code on the web container the hourly runner uses:
# `git remote add origin git@github.com:acme-org/source-repo.git` followed by
# `git remote get-url origin` returned `https://github.com/acme-org/source-repo.git`,
# because the environment injected `url.https://github.com/.insteadOf = git@github.com:`.
# An earlier provisioning of the same container also carried
# `url.http://local_proxy@127.0.0.1:.../git/.insteadOf = https://github.com/`, so the
# rewrite target is not stable either -- which is precisely why neither form may be
# hard-coded as "the" URL.
#
# WHICH FORM IS CORRECT DEPENDS ON THE QUESTION, so this library answers both and never
# picks for the caller:
#
#   "where would a colleague clone this from?"  -> remote_url_configured
#   "what will git actually contact?"           -> remote_url_effective
#   "might the developer have written this?"    -> remote_url_forms (ALL of them)
#
# A safety backstop must ask the third question. A developer pastes whichever form their
# tooling showed them -- GitHub's UI gives the canonical one, their shell gives the
# rewritten one -- so checking a body against only one form is a check that silently stops
# firing under a rewrite. That is not hypothetical: the backstop matched only the
# rewritten form, so a body containing this repository's real clone URL fell through the
# clone-URL rule entirely and was caught, if at all, by the unrelated `owner/name` rule --
# which then told the developer to mask something the body did not literally contain.

# The URL as this repository RECORDS it, with no rewrite applied. Empty when there is no
# origin. This is the form a colleague would clone, so it is the one a human confirms.
remote_url_configured() {
    git -C "$1" config --get remote.origin.url 2>/dev/null || true
}

# The URL as git will CONTACT it, with every insteadOf rewrite applied. Empty when there
# is no origin.
remote_url_effective() {
    git -C "$1" remote get-url origin 2>/dev/null || true
}

# Every distinct non-empty form, one per line. Order is configured-then-effective so a
# caller that wants a single preferred answer can take the first line; callers that must
# be exhaustive read all of them. Emits nothing at all when there is no origin, which
# every caller must treat as "these checks do not apply" rather than as an error -- a
# repository with no remote is a legitimate state, not a misconfiguration.
remote_url_forms() {
    _ruf_configured="$(remote_url_configured "$1")"
    _ruf_effective="$(remote_url_effective "$1")"
    [ -z "$_ruf_configured" ] || printf '%s\n' "$_ruf_configured"
    if [ -n "$_ruf_effective" ] && [ "$_ruf_effective" != "$_ruf_configured" ]; then
        printf '%s\n' "$_ruf_effective"
    fi
}
