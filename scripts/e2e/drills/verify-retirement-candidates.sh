cmd_verify_retirement_candidates() {
    _dr="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts"
    _reader="${_dr}/list-retirable-claims.sh"
    _act="${_dr}/delete-retired-claim-branch.sh"
    _prs="${_dr}/branch-pull-request-state.sh"
    for _f in "$_reader" "$_act" "$_prs"; do
        [ -f "$_f" ] || emit_err "retirement_candidates_unreadable" 4 "$_f is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    _tmp=$(mktemp -d)
    # The origin path's last two segments ARE the slug `gh-rest.sh` derives, so the fixture's
    # local bare repository is placed where it reads as one rather than having its URL rewritten
    # — a rewritten URL is unfetchable, and `claims_fetch` would answer `origin_unreachable`
    # before any of this drill's questions were asked.
    _origin="${_tmp}/acme-org/source-repo"
    _wt="${_tmp}/A"
    _bin="${_tmp}/bin"
    mkdir -p "$_origin" "$_bin"

    _merged=work-20260901-100000
    _closed=work-20260901-100001
    _open=work-20260901-100002
    _nopr=work-20260901-100003
    _live=work-20260901-100004
    _holds=work-20260901-100005
    _unreadable=work-20260901-100006

    ( cd "$_origin" && git -c init.defaultBranch=main init -q --bare ) >/dev/null 2>&1 \
        || emit_err "retirement_candidates_fixture" 4 "could not create the bare origin"
    (
        git clone -q "$_origin" "$_wt" \
            && cd "$_wt" \
            && git config user.email drill@example.invalid \
            && git config user.name Drill \
            && git config commit.gpgsign false \
            && mkdir -p src \
            && printf 'base\n' > src/app.txt \
            && git add -A && git commit -q -m 'Seed the base' && git push -q origin main
    ) >/dev/null 2>&1 || emit_err "retirement_candidates_fixture" 4 "could not seed the fixture"

    # A branch that is EMPTY against the base outside `.workaholic/` — the ordinary shape of a
    # branch whose work has landed. `--allow-empty` is not enough: the emptiness reading excludes
    # `.workaholic/`, so a bookkeeping-only commit is exactly what it is designed to see through.
    _seed_empty() {
        ( cd "$_wt" && git checkout -q -B "$1" origin/main \
            && mkdir -p .workaholic/tickets \
            && printf 'bookkeeping\n' > ".workaholic/tickets/$1.md" \
            && git add -A && git commit -q -m 'Archive a ticket' \
            && git push -q origin "$1" && git checkout -q main ) >/dev/null 2>&1
    }
    # And one that HOLDS WORK found on no other ref — the shape a hand-closed branch can have.
    _seed_work() {
        ( cd "$_wt" && git checkout -q -B "$1" origin/main \
            && printf 'only here\n' > "src/$1.txt" \
            && git add "src/$1.txt" && git commit -q -m 'Work found on no other ref' \
            && git push -q origin "$1" && git checkout -q main ) >/dev/null 2>&1
    }
    for _b in "$_merged" "$_closed" "$_open" "$_nopr" "$_unreadable"; do
        _seed_empty "$_b" || emit_err "retirement_candidates_fixture" 4 "could not seed $_b"
    done
    _seed_work "$_holds" || emit_err "retirement_candidates_fixture" 4 "could not seed $_holds"

    # THE LIVE CLAIM: the `Claim a PR-unit` subject and its `Unit:` trailer, the shape
    # `claims_scan` actually reads, with a tip inside the heartbeat window.
    ( cd "$_wt" && git checkout -q -B "$_live" origin/main \
        && git commit -q --allow-empty -m "Claim a PR-unit" -m "Unit: batch-drilled" \
        && git push -q origin "$_live" && git checkout -q main ) >/dev/null 2>&1 \
        || emit_err "retirement_candidates_fixture" 4 "could not seed the live claim"
    ( cd "$_wt" && git fetch -q --prune origin ) >/dev/null 2>&1 || true

    # The transport, stubbed per branch. `state=all&head=<owner>:<branch>` is the one shape both
    # `branch-pull-request-state.sh` and `claim-merged.sh` ask for, so one `case` answers both.
    # `$1` re-issues the MERGED branch's answer as whatever is passed, which is how row 5 moves a
    # proof between the list and the act without touching anything else.
    _write_gh_stub() {
        _merged_answer="${1:-merged}"
        {
            printf '#!/bin/sh\ncase "$*" in\n'
            printf "  *rate_limit*) printf '5000\\\\n'; exit 0 ;;\n"
            printf "  *DELETE*) printf '{}\\\\n'; exit 0 ;;\n"
            # The act's `pull_request_open` bound probes `state=open` SEPARATELY from the
            # four-state read, so the stub answers it separately too — otherwise the merged
            # branch's own row comes back to that probe and every candidate reads as held open.
            printf "  *state=open*) printf '[]\\\\n'; exit 0 ;;\n"
            printf "  *%s*)\n" "$_unreadable"
            printf "    echo 'API rate limit exceeded' >&2; exit 1 ;;\n"
            printf "  *%s*)\n" "$_merged"
            case "$_merged_answer" in
                merged) printf "    printf '[{\"number\":1,\"state\":\"closed\",\"merged_at\":\"2026-08-20T00:00:00Z\",\"created_at\":\"2026-08-19T00:00:00Z\"}]\\\\n'\n" ;;
                *)      printf "    printf '[{\"number\":1,\"state\":\"open\",\"merged_at\":null,\"created_at\":\"2026-08-19T00:00:00Z\"}]\\\\n'\n" ;;
            esac
            printf "    exit 0 ;;\n"
            for _cb in "$_closed" "$_holds"; do
                printf "  *%s*) printf '[{\"number\":2,\"state\":\"closed\",\"merged_at\":null,\"created_at\":\"2026-08-19T00:00:00Z\"}]\\\\n'; exit 0 ;;\n" "$_cb"
            done
            printf "  *%s*) printf '[{\"number\":3,\"state\":\"open\",\"merged_at\":null,\"created_at\":\"2026-08-19T00:00:00Z\"}]\\\\n'; exit 0 ;;\n" "$_open"
            # The live claim's own pull request is MERGED — which is the point: the live row must
            # beat it. Without this the row would prove nothing.
            printf "  *%s*) printf '[{\"number\":4,\"state\":\"closed\",\"merged_at\":\"2026-08-20T00:00:00Z\",\"created_at\":\"2026-08-19T00:00:00Z\"}]\\\\n'; exit 0 ;;\n" "$_live"
            printf 'esac\n'
            printf "printf '[]\\\\n'\n"
        } > "${_bin}/gh"
        chmod +x "${_bin}/gh"
    }
    _write_gh_stub merged

    _tip() { git -C "$_wt" rev-parse "origin/$1" 2>/dev/null || printf ''; }
    _reason_of() { printf '%s' "$1" | jq -r '.reason // ""' 2>/dev/null || printf ''; }

    # 1. THE READING: exactly the two proved classes are offered, each under its own word.
    _r=$(cd "$_wt" && PATH="${_bin}:$PATH" sh "$_reader" 2>&1 || true)
    if printf '%s' "$_r" | jq -e --arg m "$_merged" --arg c "$_closed" --arg h "$_holds" '
            (.ok == true)
            and ([.candidates[] | select(.branch == $m and .candidate_reason == "pull_request_merged")] | length == 1)
            and ([.candidates[] | select(.branch == $c and .candidate_reason == "pull_request_closed_unmerged")] | length == 1)
            and ([.candidates[] | select(.branch == $h and .candidate_reason == "pull_request_closed_unmerged")] | length == 1)' \
            >/dev/null 2>&1; then
        add_row "retirement_reader_names_both_classes" true "a merged branch and a hand-closed one are each offered under their own candidate_reason" load
    else
        add_row "retirement_reader_names_both_classes" false "the reader did not offer both classes: $(one_line "$_r")" load
    fi

    # 2. AND OFFERS NOTHING ELSE. An open pull request, a branch that never had one, and a branch
    #    whose unit holds a LIVE claim are each excluded — the last however loudly its own pull
    #    request says merged.
    if printf '%s' "$_r" | jq -e --arg o "$_open" --arg n "$_nopr" --arg l "$_live" '
            ([.candidates[] | select(.branch == $o or .branch == $n or .branch == $l)] | length == 0)' \
            >/dev/null 2>&1; then
        add_row "retirement_reader_offers_nothing_else" true "an open pull request, a branch with none, and a live claim over a merged pull request are all excluded" load
    else
        add_row "retirement_reader_offers_nothing_else" false "the reader offered a branch that must not be deleted: $(one_line "$_r")" load
    fi

    # 3. AN UNREADABLE READ CONTRIBUTES NO CANDIDATE *AND NAMES ITS REASON* — never a bare
    #    omission, which reads exactly like a branch whose pull request is open.
    if printf '%s' "$_r" | jq -e --arg u "$_unreadable" '
            ([.candidates[] | select(.branch == $u)] | length == 0)
            and ([.pull_request_unreadable[] | select(.branch == $u and .reason == "rate_limited")] | length == 1)' \
            >/dev/null 2>&1; then
        add_row "retirement_unreadable_names_its_reason" true "a branch whose pull request could not be read is no candidate and is named with its reason" load
    else
        add_row "retirement_unreadable_names_its_reason" false "an unreadable read was dropped rather than named: $(one_line "$_r")" load
    fi

    # 4. THE EMPTINESS READING RIDES THE ROW as evidence, and it is REAL: the branch that holds
    #    work reads `false` while the bookkeeping-only one reads `true`.
    if printf '%s' "$_r" | jq -e --arg c "$_closed" --arg h "$_holds" '
            ([.candidates[] | select(.branch == $c and .branch_empty == "true")] | length == 1)
            and ([.candidates[] | select(.branch == $h and .branch_empty == "false")] | length == 1)' \
            >/dev/null 2>&1; then
        add_row "retirement_row_carries_the_emptiness" true "the emptiness reading rides both rows and tells a bookkeeping-only branch from one holding work" load
    else
        add_row "retirement_row_carries_the_emptiness" false "the emptiness reading did not distinguish the two branches: $(one_line "$_r")" load
    fi

    # 5. THE GAP BETWEEN THE LIST AND THE ACT. The candidate was made when the pull request was
    #    merged; by the time CI runs it is open again. The act must refuse by ITS OWN word with
    #    the branch untouched — this is the whole reason the reading and the act are one verb.
    _write_gh_stub open
    _m_before=$(_tip "$_merged")
    _moved=$(cd "$_wt" && PATH="${_bin}:$PATH" sh "$_act" "" --branch "$_merged" --reason pull_request_merged 2>&1 || true)
    if [ "$(_reason_of "$_moved")" = "not_merged:open" ] && [ "$_m_before" = "$(_tip "$_merged")" ]; then
        add_row "retirement_act_refuses_a_moved_proof" true "a candidate whose pull request re-opened between the list and the act is refused not_merged:open, with nothing deleted (this drill can fail)" breaker
    else
        add_row "retirement_act_refuses_a_moved_proof" false "the act did not refuse a moved proof, or the branch moved: $(one_line "$_moved")" breaker
    fi
    _write_gh_stub merged

    # 6. THE TERM THAT FAILS CLOSED. A hand-closed branch still holding work is refused
    #    `branch_holds_work` and is still on origin afterwards — the direction issue #788 turned
    #    `superseded`, applied to the one class whose proof is authorship rather than emptiness.
    _h_before=$(_tip "$_holds")
    _held=$(cd "$_wt" && PATH="${_bin}:$PATH" sh "$_act" "" --branch "$_holds" --reason pull_request_closed_unmerged 2>&1 || true)
    if [ "$(_reason_of "$_held")" = "branch_holds_work" ] && [ -n "$(_tip "$_holds")" ] \
       && [ "$_h_before" = "$(_tip "$_holds")" ]; then
        add_row "retirement_act_refuses_a_branch_holding_work" true "a hand-closed branch that still holds work is refused branch_holds_work and is still on origin (this drill can fail)" breaker
    else
        add_row "retirement_act_refuses_a_branch_holding_work" false "a branch holding work was not refused, or it moved: $(one_line "$_held")" breaker
    fi

    # 7. AND A LIVE CLAIM IS REFUSED AT THE ACT TOO, re-derived rather than trusted from the list
    #    — first-match resolution returns the OLDEST row, which for this shape is the dead one.
    _l_before=$(_tip "$_live")
    _lv=$(cd "$_wt" && PATH="${_bin}:$PATH" sh "$_act" "" --branch "$_live" --reason pull_request_merged 2>&1 || true)
    case "$(_reason_of "$_lv")" in
        not_superseded:*)
            if [ "$_l_before" = "$(_tip "$_live")" ]; then
                add_row "retirement_act_refuses_a_live_claim" true "a live claim over a merged pull request is refused at the act, branch untouched (this drill can fail)" breaker
            else
                add_row "retirement_act_refuses_a_live_claim" false "the live claim was refused but its branch moved" breaker
            fi ;;
        *) add_row "retirement_act_refuses_a_live_claim" false "a live claim was not refused at the act: $(one_line "$_lv")" breaker ;;
    esac

    # 8. AN ALREADY-GONE BRANCH IS A CLEAN NO-OP, matching Act 2's own word: a re-run over a set
    #    CI already took is not a run full of errors about work that is already done.
    #    The branch is removed from origin while its pull request still reads merged, which is
    #    exactly the state a second CI turn meets after the first one deleted it — a branch that
    #    never existed would be refused one rung earlier, by its own missing proof.
    ( cd "$_origin" && git update-ref -d "refs/heads/${_merged}" ) >/dev/null 2>&1 || true
    ( cd "$_wt" && git fetch -q --prune origin ) >/dev/null 2>&1 || true
    _gone=$(cd "$_wt" && PATH="${_bin}:$PATH" sh "$_act" "" --branch "$_merged" --reason pull_request_merged 2>&1 || true)
    if printf '%s' "$_gone" | jq -e '(.state == "already_gone") and (.deleted == true)' >/dev/null 2>&1; then
        add_row "retirement_act_is_idempotent" true "a branch absent from origin answers already_gone rather than failing" load
    else
        add_row "retirement_act_is_idempotent" false "an absent branch did not answer already_gone: $(one_line "$_gone")" load
    fi

    # 9. NOTHING WAS WRITTEN OUTSIDE THE FIXTURE.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "retirement_writes_nothing_outside_the_fixture" true "the checkout is byte-identical after the drill" load
    else
        add_row "retirement_writes_nothing_outside_the_fixture" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "retirement-candidates" 0 "fail" 1
    fi
    emit_verdict "retirement-candidates" 0 "pass" 0
}
