cmd_verify_stranded_claim_branch() {
    _lib="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/lib/claims.sh"
    _lister="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/list-claims.sh"
    _retirer="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/retire-claim.sh"
    for _f in "$_lib" "$_lister" "$_retirer"; do
        [ -f "$_f" ] || emit_err "stranded_branch_seam_unreadable" 4 "${_f} is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _tmp=$(mktemp -d)
    _origin="${_tmp}/origin"; _work="${_tmp}/work"; _read="${_tmp}/read"; _bin="${_tmp}/bin"
    mkdir -p "$_origin" "$_bin"
    _me=$(cd "$REPO_ROOT" && git config user.email 2>/dev/null || echo drill@example.com)
    _git() { git -c user.email="$_me" -c user.name=Drill -c commit.gpgsign=false "$@"; }

    # The transport is stubbed for the PULL REQUEST half alone. The branch delete is real.
    printf '#!/bin/sh\ncase "$2" in rate_limit) echo 5000 ;; *) echo "[]" ;; esac\n' > "${_bin}/gh"
    chmod +x "${_bin}/gh"

    ( cd "$_origin" && git -c init.defaultBranch=main init -q --bare ) || true
    ( cd "$_tmp" && git clone -q "$_origin" work ) || true
    mkdir -p "${_work}/.workaholic/tickets/todo" "${_work}/.workaholic/missions/active/m-stranded" "${_work}/src"
    for _n in 1 2; do
        printf -- '---\ncreated_at: 2026-01-01T00:00:0%s+09:00\nauthor: %s\n---\n\n# T%s\n' \
            "$_n" "$_me" "$_n" > "${_work}/.workaholic/tickets/todo/2026010100000${_n}-t.md"
    done
    # THE MISSION GRAIN'S LOCAL TEST NEEDS A TICKET THAT NAMES THE MISSION. Without one
    # `claims_mission_landed` cannot answer and the verdict falls through to the
    # merged-pull-request lookup, which is deliberately disabled here so the drill measures the
    # verdict rather than the transport.
    printf -- '---\ncreated_at: 2026-01-01T00:00:03+09:00\nauthor: %s\nmission: m-stranded\n---\n\n# T3\n' \
        "$_me" > "${_work}/.workaholic/tickets/todo/20260101000003-t.md"
    printf -- '---\ntype: Mission\ntitle: M\nslug: m-stranded\nstatus: active\nassignees: [%s]\n---\n\n# M\n\n## Acceptance\n\n- [ ] x\n' \
        "$_me" > "${_work}/.workaholic/missions/active/m-stranded/mission.md"
    printf 'on the base\n' > "${_work}/src/base.txt"
    ( cd "$_work" && _git add -A && _git commit -qm seed && git push -q origin main ) || true

    _stamp() { # $1 = branch, $2 = ticket basename
        printf -- '---\ncreated_at: 2026-01-01T00:00:00+09:00\nauthor: %s\nclaim: %s\n---\n\n# T\n\nclaimed\n' \
            "$_me" "$1" > "${_work}/.workaholic/tickets/todo/$2"
    }

    # CASE 1 -- EMPTY AGAINST THE BASE. Its own archive directory and nothing else, which is
    # what the ordinary superseded twin looks like: the two trees differ inside `.workaholic/`
    # BY CONSTRUCTION, and a bare diff would call every genuine retirement stranded.
    ( cd "$_work" && git checkout -q -b work-20260101-000010 main \
      && _stamp work-20260101-000010 20260101000001-t.md \
      && _git commit -qam "Claim a PR-unit" -m "Unit: batch-empty" \
      && git push -q origin work-20260101-000010 ) >/dev/null 2>&1 || true

    # CASE 2 -- HOLDS WORK, BATCH GRAIN. A file on this branch and on no other ref.
    ( cd "$_work" && git checkout -q -b work-20260101-000011 main \
      && _stamp work-20260101-000011 20260101000002-t.md \
      && printf 'work that exists on no other ref\n' > src/orphan.txt \
      && _git add -A && _git commit -qm "Claim a PR-unit" -m "Unit: batch-holds" \
      && git push -q origin work-20260101-000011 ) >/dev/null 2>&1 || true

    # CASE 3 -- HOLDS WORK, MISSION GRAIN. The artifact is `mission.md`, which routes through a
    # different arm of `claims_superseded`; both arms must reach the same refusal.
    ( cd "$_work" && git checkout -q -b work-20260101-000012 main \
      && printf -- '---\ntype: Mission\ntitle: M\nslug: m-stranded\nstatus: active\nassignees: [%s]\nclaim: work-20260101-000012\n---\n\n# M\n\n## Acceptance\n\n- [ ] x\n' \
         "$_me" > .workaholic/missions/active/m-stranded/mission.md \
      && printf 'a verifier nothing else has\n' > src/verifier.mjs \
      && _git add -A && _git commit -qm "Claim a PR-unit" -m "Unit: m-stranded" \
      && git push -q origin work-20260101-000012 ) >/dev/null 2>&1 || true

    # THE BASE LANDS EVERY UNIT'S TICKETS THROUGH ANOTHER BRANCH -- the measured shape, and the
    # only reason any of these read as finished at all.
    ( cd "$_work" && git checkout -q main \
      && mkdir -p .workaholic/tickets/archive/work-20260101-000099 \
      && git mv .workaholic/tickets/todo/20260101000001-t.md .workaholic/tickets/archive/work-20260101-000099/ \
      && git mv .workaholic/tickets/todo/20260101000002-t.md .workaholic/tickets/archive/work-20260101-000099/ \
      && git mv .workaholic/tickets/todo/20260101000003-t.md .workaholic/tickets/archive/work-20260101-000099/ \
      && _git commit -qm "Archive the tickets elsewhere" && git push -q origin main ) >/dev/null 2>&1 || true

    ( cd "$_tmp" && git clone -q "$_origin" read ) >/dev/null 2>&1 || true
    ( cd "$_read" && git config user.email "$_me" && git config user.name Drill ) >/dev/null 2>&1 || true

    _rows=$( ( cd "$_read" && PATH="${_bin}:$PATH" WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 \
        WORKAHOLIC_CLAIM_MERGED_LOOKUP=0 sh "$_lister" ) 2>/dev/null || printf '' )
    _verdict() { printf '%s' "$_rows" | jq -r --arg u "$1" '[.claims[]? | select(.unit == $u) | .resume_reason] | first // ""' 2>/dev/null || printf ''; }

    if [ "$(_verdict batch-empty)" = "superseded" ]; then
        add_row "stranded_empty_branch_is_superseded" true "a branch differing from the base only inside .workaholic/ is still proved empty" load
    else
        add_row "stranded_empty_branch_is_superseded" false "the ordinary retirement stopped firing: batch-empty read '$(_verdict batch-empty)'" load
    fi
    if [ "$(_verdict batch-holds)" = "stranded" ] && [ "$(_verdict m-stranded)" = "stranded" ]; then
        add_row "stranded_holding_branch_is_stranded" true "at both grains a branch whose tickets landed while it still holds work reads stranded, never superseded" load
    else
        add_row "stranded_holding_branch_is_stranded" false "a branch holding work was not named stranded: batch=$(_verdict batch-holds) mission=$(_verdict m-stranded)" load
    fi

    # THE FILES RIDE THE ROW, so the question that reaches a person can name them.
    _files=$(printf '%s' "$_rows" | jq -r '[.claims[]? | select(.unit == "batch-holds") | .stranded_files[]?] | join(",")' 2>/dev/null || printf '')
    if printf '%s' "$_files" | grep -q 'src/orphan.txt'; then
        add_row "stranded_row_names_the_files" true "the row names what the branch holds, so a person can rule on the work" load
    else
        add_row "stranded_row_names_the_files" false "the row named no files: [$_files]" load
    fi

    # AN EMPTINESS THAT CANNOT BE READ IS NEVER `superseded`. Asserted on the derivation, where
    # the absence is reproducible offline: a ref the reader cannot resolve.
    _unknown=$( ( cd "$_read" && sh -c ". \"$_lib\"; claims_branch_emptiness origin/main origin/work-does-not-exist" ) 2>/dev/null | cut -f1,2 || printf '' )
    _unreadable_verdict=$( ( cd "$_read" && WORKAHOLIC_CLAIM_MERGED_LOOKUP=0 sh -c ". \"$_lib\"; claims_superseded origin/main '.workaholic/tickets/todo/20260101000001-t.md' work-does-not-exist origin/work-does-not-exist" ) 2>/dev/null || printf '' )
    if printf '%s' "$_unknown" | grep -q '^unknown' && [ "$_unreadable_verdict" = "stranded" ]; then
        add_row "stranded_unreadable_is_never_superseded" true "an emptiness nobody could read answers unknown and the verdict answers stranded, so no delete is licensed" load
    else
        add_row "stranded_unreadable_is_never_superseded" false "an unreadable emptiness did not refuse: reading=[$_unknown] verdict=[$_unreadable_verdict]" load
    fi

    # THE ACT, WITH THE DELETE ALLOWED TO RUN. The proved-empty branch really goes.
    _r1=$( ( cd "$_read" && PATH="${_bin}:$PATH" WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 \
        WORKAHOLIC_CLAIM_MERGED_LOOKUP=0 sh "$_retirer" batch-empty ) 2>&1 || true )
    if ! ( cd "$_origin" && git rev-parse --verify --quiet refs/heads/work-20260101-000010 >/dev/null 2>&1 ); then
        add_row "stranded_proved_branch_is_deleted" true "the proof still licenses the delete and the branch is gone from origin" load
    else
        add_row "stranded_proved_branch_is_deleted" false "the proved-empty branch was not deleted: $(one_line "$_r1")" load
    fi

    # THE BREAKER, WRITTEN AGAINST THE BEHAVIOUR AND NOT AGAINST A RETURN SHAPE. The branch
    # holding work is handed straight to the act, at both grains, with the delete permitted. The
    # assertion is that the REF and its FILE CONTENT are still on origin afterwards -- a refactor
    # that keeps the JSON and loses the emptiness term deletes them and this row goes red.
    _r2=$( ( cd "$_read" && PATH="${_bin}:$PATH" WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 \
        WORKAHOLIC_CLAIM_MERGED_LOOKUP=0 sh "$_retirer" batch-holds ) 2>&1 || true )
    _r3=$( ( cd "$_read" && PATH="${_bin}:$PATH" WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES=0 \
        WORKAHOLIC_CLAIM_MERGED_LOOKUP=0 sh "$_retirer" m-stranded ) 2>&1 || true )
    _kept_b=$( ( cd "$_origin" && git show work-20260101-000011:src/orphan.txt ) 2>/dev/null || printf '' )
    _kept_m=$( ( cd "$_origin" && git show work-20260101-000012:src/verifier.mjs ) 2>/dev/null || printf '' )
    if [ -n "$_kept_b" ] && [ -n "$_kept_m" ] \
        && printf '%s' "$_r2" | grep -q 'not_superseded' && printf '%s' "$_r3" | grep -q 'not_superseded'; then
        add_row "stranded_holding_branch_survives_the_act" true "at both grains the act refuses by name and the work that would have been lost is still on origin -- this drill can fail" breaker
    else
        add_row "stranded_holding_branch_survives_the_act" false "work was lost or the refusal was not named: batch=$(one_line "$_r2") mission=$(one_line "$_r3")" breaker
    fi

    # NOTHING OUTSIDE THE FIXTURE IS WRITTEN.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "stranded_branch_checkout_untouched" true "the drill left this checkout exactly as it found it" load
    else
        add_row "stranded_branch_checkout_untouched" false "the drill changed this checkout" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -eq 0 ]; then
        emit_verdict "stranded-claim-branch" 0 "pass" 0
    fi
    emit_verdict "stranded-claim-branch" 0 "fail" 1
}
