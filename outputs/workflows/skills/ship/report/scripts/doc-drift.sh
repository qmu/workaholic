#!/bin/sh -eu
# doc-drift.sh -- emit documentation-drift FACTS (not verdicts) for the report
# workflow's release-readiness judge.
#
# Compares <base>..HEAD and reports two things:
#   1. Which STRUCTURAL files changed presence (skills / commands / agents /
#      hooks added, removed, or renamed; top-level scripts/ added or removed).
#   2. Whether the index/meta docs that enumerate that structure (CLAUDE.md,
#      README.md, and docs/ when the directory exists) were touched in the same
#      range.
# When a structural presence change lands without its index doc being touched,
# the script emits a `candidate` -- a fact the release-readiness leaf then
# JUDGES (against the diff and the doc's content) as real drift or not.
#
# Deliberately narrow to keep false positives low (operation policy: must never
# false-block an otherwise-shippable branch): only presence changes (A/D/R) are
# structural -- plain content edits are NOT flagged. Excludes outputs/ staleness
# and version/manifest drift entirely; the Outputs Freshness CI and
# validate-metadata.mjs own those domains.
#
# Usage: doc-drift.sh [base-branch]   (default base: main)
# Output: JSON facts to stdout. Always exits 0 -- a missing base ref or repo
# quirk degrades to a not_applicable result rather than erroring the report.

set -eu

BASE="${1:-main}"

emit_not_applicable() {
    cat <<EOF
{
  "base": "${BASE}",
  "not_applicable": "$1",
  "structural_changes": [],
  "meta_docs": {},
  "docs_dir_present": false,
  "candidates": []
}
EOF
    exit 0
}

# Degrade gracefully: a missing or detached base ref must not error the report.
if ! git rev-parse --verify --quiet "${BASE}" >/dev/null 2>&1; then
    emit_not_applicable "base_ref_not_found"
fi

NAMES=$(git diff "${BASE}..HEAD" --name-only 2>/dev/null || true)
STATUS=$(git diff "${BASE}..HEAD" --name-status 2>/dev/null || true)

# Did a given exact path change in this range?
changed() {
    printf '%s\n' "${NAMES}" | grep -Fxq "$1"
}

CLAUDE_PRESENT=false; [ -f CLAUDE.md ] && CLAUDE_PRESENT=true
README_PRESENT=false; [ -f README.md ] && README_PRESENT=true
DOCS_PRESENT=false;   [ -d docs ] && DOCS_PRESENT=true

CLAUDE_CHANGED=false; changed "CLAUDE.md" && CLAUDE_CHANGED=true
README_CHANGED=false; changed "README.md" && README_CHANGED=true
DOCS_CHANGED=false
if [ "${DOCS_PRESENT}" = true ]; then
    printf '%s\n' "${NAMES}" | grep -q '^docs/' && DOCS_CHANGED=true
fi

# Classify presence changes into structural categories. Run the loop in the
# current shell (input redirected from a temp file, not a pipe) so the category
# flags it sets survive.
TMP=$(mktemp)
trap 'rm -f "${TMP}"' EXIT
printf '%s\n' "${STATUS}" > "${TMP}"

SC=""
skill_kind=""; cmd_kind=""; agent_kind=""; hook_kind=""; script_kind=""
TAB=$(printf '\t')

while IFS="${TAB}" read -r st p1 p2; do
    [ -n "${st}" ] || continue
    case "${st}" in
        A*) verb="added" ;;
        D*) verb="removed" ;;
        R*) verb="renamed" ;;
        C*) verb="added" ;;
        *) continue ;;   # M / T / U: content edits are not structural presence changes
    esac
    # For renames/copies the new path is the third field; otherwise the second.
    path="${p1}"
    [ -n "${p2:-}" ] && path="${p2}"
    case "${path}" in
        plugins/workaholic/skills/*/SKILL.md) cat="skill" ;;
        plugins/workaholic/commands/*)        cat="command" ;;
        plugins/workaholic/agents/*)          cat="agent" ;;
        plugins/workaholic/hooks/*)           cat="hook" ;;
        scripts/*)                            cat="script" ;;
        *) continue ;;
    esac
    SC="${SC},{\"kind\":\"${cat}_${verb}\",\"path\":\"${path}\"}"
    case "${cat}" in
        skill)   [ -z "${skill_kind}" ]  && skill_kind="skill_${verb}" ;;
        command) [ -z "${cmd_kind}" ]    && cmd_kind="command_${verb}" ;;
        agent)   [ -z "${agent_kind}" ]  && agent_kind="agent_${verb}" ;;
        hook)    [ -z "${hook_kind}" ]   && hook_kind="hook_${verb}" ;;
        script)  [ -z "${script_kind}" ] && script_kind="script_${verb}" ;;
    esac
done < "${TMP}"

SC_OUT=$(printf '%s' "${SC}" | sed 's/^,//')

# Build candidates: each structural category maps to the index doc(s) that
# enumerate it. A candidate is raised only when the doc is present and was NOT
# touched in this range.
CAND=""
add_candidate() {
    # $1 signal, $2 doc, $3 reason
    CAND="${CAND},{\"signal\":\"$1\",\"doc\":\"$2\",\"reason\":\"$3\"}"
}

# CLAUDE.md enumerates skills, commands, agents, and hooks.
if [ "${CLAUDE_PRESENT}" = true ] && [ "${CLAUDE_CHANGED}" = false ]; then
    [ -n "${skill_kind}" ]  && add_candidate "${skill_kind}"  "CLAUDE.md" "a skill was ${skill_kind#skill_} but CLAUDE.md (which enumerates the plugin's skills) was not updated"
    [ -n "${cmd_kind}" ]    && add_candidate "${cmd_kind}"    "CLAUDE.md" "a command was ${cmd_kind#command_} but CLAUDE.md (which lists the commands) was not updated"
    [ -n "${agent_kind}" ]  && add_candidate "${agent_kind}"  "CLAUDE.md" "an agent was ${agent_kind#agent_} but CLAUDE.md (which documents the agents) was not updated"
    [ -n "${hook_kind}" ]   && add_candidate "${hook_kind}"   "CLAUDE.md" "a hook was ${hook_kind#hook_} but CLAUDE.md (which documents the hooks) was not updated"
    [ -n "${script_kind}" ] && add_candidate "${script_kind}" "CLAUDE.md" "a top-level script was ${script_kind#script_} but CLAUDE.md (Local Verification / scripts) was not updated"
fi

# README.md carries the project structure and the commands table.
if [ "${README_PRESENT}" = true ] && [ "${README_CHANGED}" = false ]; then
    [ -n "${skill_kind}" ] && add_candidate "${skill_kind}" "README.md" "a skill was ${skill_kind#skill_} but README.md was not updated"
    [ -n "${cmd_kind}" ]   && add_candidate "${cmd_kind}"   "README.md" "a command was ${cmd_kind#command_} but README.md was not updated"
fi

# docs/ (forward-looking; only when the directory exists in this repo).
if [ "${DOCS_PRESENT}" = true ] && [ "${DOCS_CHANGED}" = false ] && [ -n "${SC_OUT}" ]; then
    add_candidate "structural_change" "docs/" "structural files changed but nothing under docs/ was updated"
fi

CAND_OUT=$(printf '%s' "${CAND}" | sed 's/^,//')

cat <<EOF
{
  "base": "${BASE}",
  "structural_changes": [${SC_OUT}],
  "meta_docs": {
    "CLAUDE.md": {"present": ${CLAUDE_PRESENT}, "changed": ${CLAUDE_CHANGED}},
    "README.md": {"present": ${README_PRESENT}, "changed": ${README_CHANGED}}
  },
  "docs_dir_present": ${DOCS_PRESENT},
  "candidates": [${CAND_OUT}]
}
EOF
