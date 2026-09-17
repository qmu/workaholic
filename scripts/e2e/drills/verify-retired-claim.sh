cmd_verify_retired_claim() {
    _dr="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts"
    _mstate="${_dr}/claim-mission-state.sh"
    _reader="${_dr}/list-retirable-claims.sh"
    _act="${_dr}/delete-retired-claim-branch.sh"
    _step="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/step-stalled-units.sh"
    for _f in "$_mstate" "$_reader" "$_act" "$_step"; do
        [ -f "$_f" ] || emit_err "retired_claim_unreadable" 4 "$_f is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    _tmp=$(mktemp -d)
    # The origin path's last two segments ARE the slug `gh-rest.sh` derives — the sibling drill's
    # reason, kept identical: a rewritten URL is unfetchable and `claims_fetch` would answer
    # `origin_unreachable` before any question here was asked.
    _origin="${_tmp}/acme-org/source-repo"
    _wt="${_tmp}/A"
    _bin="${_tmp}/bin"
    mkdir -p "$_origin" "$_bin"

    _ended=work-20260902-200000
    _living=work-20260902-200001
    _old="2026-08-01T00:00:00+00:00"

    ( cd "$_origin" && git -c init.defaultBranch=main init -q --bare ) >/dev/null 2>&1 \
        || emit_err "retired_claim_fixture" 4 "could not create the bare origin"
    (
        git clone -q "$_origin" "$_wt" \
            && cd "$_wt" \
            && git config user.email drill@example.invalid \
            && git config user.name Drill \
            && git config commit.gpgsign false \
            && mkdir -p .workaholic/missions/archive/ended-mission \
                        .workaholic/missions/active/living-mission src \
            && printf 'base\n' > src/app.txt \
            && printf -- '---\ntype: Mission\nslug: ended-mission\nstatus: abandoned\nassignees: [drill@example.invalid]\n---\n\n# Ended\n\n## Experience\n\nx\n\n## Acceptance\n\n- [ ] a\n' \
                 > .workaholic/missions/archive/ended-mission/mission.md \
            && printf -- '---\ntype: Mission\nslug: living-mission\nstatus: active\nassignees: [drill@example.invalid]\n---\n\n# Living\n\n## Experience\n\nx\n\n## Acceptance\n\n- [ ] a\n' \
                 > .workaholic/missions/active/living-mission/mission.md \
            && git add -A && git commit -q -m 'Seed the base' && git push -q origin main
    ) >/dev/null 2>&1 || emit_err "retired_claim_fixture" 4 "could not seed the fixture"

    # Two claims, identical in every respect but the state of the mission each names, and both
    # aged out of the heartbeat window so neither reads `claim_active`. Each is EMPTY against the
    # base outside `.workaholic/`, so the act's emptiness gate is not what tells them apart.
    _seed_claim() {
        ( cd "$_wt" && git checkout -q -B "$1" origin/main \
            && GIT_COMMITTER_DATE="$_old" GIT_AUTHOR_DATE="$_old" \
               git commit -q --allow-empty -m "Claim a PR-unit" -m "Unit: $2" \
            && mkdir -p .workaholic/tickets \
            && printf 'bookkeeping\n' > ".workaholic/tickets/$1.md" \
            && git add -A \
            && GIT_COMMITTER_DATE="$_old" GIT_AUTHOR_DATE="$_old" \
               git commit -q -m 'Archive a ticket' \
            && git push -q origin "$1" && git checkout -q main ) >/dev/null 2>&1
    }
    _seed_claim "$_ended" ended-mission || emit_err "retired_claim_fixture" 4 "could not seed $_ended"
    _seed_claim "$_living" living-mission || emit_err "retired_claim_fixture" 4 "could not seed $_living"
    ( cd "$_wt" && git fetch -q --prune origin ) >/dev/null 2>&1 || true

    # The transport. Neither branch's pull request is OPEN — an open one is deliberately offered
    # to nothing, so it would hide the mission bound behind a different refusal.
    {
        printf '#!/bin/sh\ncase "$*" in\n'
        printf "  *rate_limit*) printf '5000\\\\n'; exit 0 ;;\n"
        printf "  *DELETE*) printf '{}\\\\n'; exit 0 ;;\n"
        printf "  *state=open*) printf '[]\\\\n'; exit 0 ;;\n"
        printf 'esac\n'
        printf "printf '[]\\\\n'\n"
    } > "${_bin}/gh"
    chmod +x "${_bin}/gh"

    # 1. THE READING ITSELF: the area decides, `status` rides along, a batch unit is a real
    #    answer and an unknown mission is a named absence with no `state` key at all.
    _ms() { cd "$_wt" && sh "$_mstate" "$1" 2>&1 || true; }
    if printf '%s' "$(_ms ended-mission)" | jq -e '.ok and .state == "not_active" and .status == "abandoned"' >/dev/null 2>&1 \
       && printf '%s' "$(_ms living-mission)" | jq -e '.ok and .state == "active"' >/dev/null 2>&1 \
       && printf '%s' "$(_ms batch-20260902-010203)" | jq -e '.ok and .kind == "batch" and (has("state") | not)' >/dev/null 2>&1 \
       && printf '%s' "$(_ms no-such-mission)" | jq -e '(.ok == false) and (has("state") | not)' >/dev/null 2>&1; then
        add_row "retired_claim_mission_state" true "an archived mission reads not_active with its status, an active one active, a batch unit its own kind, and an unknown one a named absence" load
    else
        add_row "retired_claim_mission_state" false "the mission reading is wrong: ended=$(one_line "$(_ms ended-mission)") living=$(one_line "$(_ms living-mission)")" load
    fi

    # 2. THE CANDIDATE: the ended mission's claim is offered under its own word, and the living
    #    mission's — identical in every other respect — is offered by nothing.
    _r=$(cd "$_wt" && PATH="${_bin}:$PATH" sh "$_reader" 2>&1 || true)
    if printf '%s' "$_r" | jq -e --arg e "$_ended" --arg l "$_living" '
            (.ok == true)
            and ([.candidates[] | select(.branch == $e and .candidate_reason == "mission_not_active"
                                         and .mission_status == "abandoned")] | length == 1)
            and ([.candidates[] | select(.branch == $l)] | length == 0)' >/dev/null 2>&1; then
        add_row "retired_claim_is_a_candidate" true "the ended mission's claim is offered as mission_not_active with its status; the living one is offered by nothing" load
    else
        add_row "retired_claim_is_a_candidate" false "the candidate reading is wrong: $(one_line "$_r")" load
    fi

    # 3. THE BREAKER, WRITTEN AGAINST THE BEHAVIOUR. Move the ended mission back to `active/`:
    #    the candidate must vanish. A reader that ignored the mission would offer the branch in
    #    both states, which is exactly the defect this class exists to close — so rows 1-2 prove
    #    nothing unless this row can fail.
    ( cd "$_wt" && git checkout -q main && git pull -q --ff-only origin main \
        && git mv .workaholic/missions/archive/ended-mission .workaholic/missions/active/ended-mission \
        && git commit -q -m 'Reopen the mission' && git push -q origin main \
        && git fetch -q --prune origin ) >/dev/null 2>&1 || true
    _rb=$(cd "$_wt" && PATH="${_bin}:$PATH" sh "$_reader" 2>&1 || true)
    if printf '%s' "$_rb" | jq -e --arg e "$_ended" '[.candidates[] | select(.branch == $e)] | length == 0' >/dev/null 2>&1; then
        add_row "retired_claim_breaker" true "with the mission back in active/ the candidate disappears, so the reader is reading the mission and this drill can fail" breaker
    else
        add_row "retired_claim_breaker" false "the breaker did not break: the branch is still a candidate with its mission active, so rows 1-2 prove nothing: $(one_line "$_rb")" breaker
    fi
    # Put it back for the acting and filtering rows.
    ( cd "$_wt" && git mv .workaholic/missions/active/ended-mission .workaholic/missions/archive/ended-mission \
        && git commit -q -m 'End the mission again' && git push -q origin main \
        && git fetch -q --prune origin ) >/dev/null 2>&1 || true

    # 4. THE ACT re-derives the class and refuses the living mission by its own word, while
    #    taking the ended one — the two answers a candidate list alone cannot prove.
    _a_live=$(cd "$_wt" && PATH="${_bin}:$PATH" sh "$_act" living-mission --branch "$_living" --reason mission_not_active 2>&1 || true)
    _a_end=$(cd "$_wt" && PATH="${_bin}:$PATH" sh "$_act" ended-mission --branch "$_ended" --reason mission_not_active 2>&1 || true)
    if printf '%s' "$_a_live" | jq -e '(.deleted == false) and (.reason | startswith("mission_still_active"))' >/dev/null 2>&1 \
       && printf '%s' "$_a_end" | jq -e '(.deleted == true) and (.state == "deleted")' >/dev/null 2>&1; then
        add_row "retired_claim_act_re_derives" true "the act refuses a living mission's branch by name and takes the ended one" load
    else
        add_row "retired_claim_act_re_derives" false "living=$(one_line "$_a_live") ended=$(one_line "$_a_end")" load
    fi

    # 5. AND THE STUCK-WORK QUESTION STOPS BEING ASKED. Both claims are past the staleness
    #    threshold; only the one the retirement path owns must be subtracted, and the
    #    subtraction must be COUNTED rather than silent.
    _s=$(cd "$_wt" && PATH="${_bin}:$PATH" WORKAHOLIC_CLAIM_STALE_HOURS=0 \
        sh "$_step" --tick 20260902-200000 --root "$_wt" 2>&1 || true)
    _asked=$(printf '%s' "$_s" | jq -r '[.needs_agent[]?.stalled[]?.unit] | sort | join(",")' 2>/dev/null || printf '?')
    if [ "$_asked" = "living-mission" ] \
       && printf '%s' "$_s" | jq -e '.summary | test("1 already owned by the retirement path")' >/dev/null 2>&1; then
        add_row "retired_claim_draws_no_question" true "only the living mission's claim is asked about, and the subtraction is counted in the summary" load
    else
        add_row "retired_claim_draws_no_question" false "asked=[$_asked] summary=$(printf '%s' "$_s" | jq -r '.summary // ""' 2>/dev/null)" load
    fi

    # 6. NOTHING WAS WRITTEN OUTSIDE THE FIXTURE.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "retired_claim_writes_nothing_outside_the_fixture" true "the checkout is byte-identical after the drill" load
    else
        add_row "retired_claim_writes_nothing_outside_the_fixture" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "retired-claim" 0 "fail" 1
    fi
    emit_verdict "retired-claim" 0 "pass" 0
}

# ------------------------------------------------- verify-retirement-candidates

# THE TWO RETIREMENT CANDIDATE READINGS, AND THE ACT THEY FEED (2026-09-01, mission
# `leave-only-live-work-in-the-unmerged-branch-list`). The mechanism is DESTRUCTIVE — it deletes
# remote branches — so the behaviour drilled is precisely the one that must not happen: a branch
# that must NOT be deleted being offered as a candidate, or the act taking a candidate whose
# proof moved between the list and the act.
#
# THE READING AND THE ACT ARE ONE VERB, DELIBERATELY. The failure this exists to catch lives in
# the GAP between them — a candidate list that was right when it was made and wrong by the time
# CI ran — and two separate drills would each pass over exactly that gap.
#
# IT IS HERMETIC. Everything but the pull-request state is derived from a local fixture; that one
# fact is stubbed at the `gh` seam, which is why the previous ticket put the read in its own
# script instead of inlining it. No network, no credential, no `qfs`.
