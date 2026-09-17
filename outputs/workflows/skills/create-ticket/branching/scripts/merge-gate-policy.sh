#!/bin/sh -eu
# Select the merge-check gate from the pull request's base branch role.
# Usage: merge-gate-policy.sh <base-ref>

base=${1:-}
case "$base" in
    main|master)
        printf '{"ok":true,"base":"%s","role":"development","remote_checks_required":false,"reason":"development_main_local_proof"}\n' "$base"
        ;;
    release/*)
        printf '{"ok":true,"base":"%s","role":"release","remote_checks_required":true,"reason":"release_promotion"}\n' "$base"
        ;;
    '')
        printf '{"ok":false,"base":"","role":"unknown","remote_checks_required":true,"reason":"base_unreadable"}\n'
        ;;
    *)
        # Unknown branch roles take the stricter release-shaped gate.
        printf '{"ok":false,"base":"%s","role":"unknown","remote_checks_required":true,"reason":"branch_role_unknown"}\n' "$base"
        ;;
esac
