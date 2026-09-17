cmd_verify_stranded_publication() {
    _br="${REPO_ROOT}/plugins/workaholic/skills/branching/scripts"
    _reader="${_br}/list-stranded-publications.sh"
    _act="${_br}/settle-stranded-publication.sh"
    _step="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts/step-stranded-publications.sh"
    for _f in "$_reader" "$_act" "$_step"; do
        [ -f "$_f" ] || emit_err "stranded_publication_unreadable" 4 "$_f is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    _tmp=$(mktemp -d)
    _origin="${_tmp}/origin"
    _wt="${_tmp}/A"
    _bin="${_tmp}/bin"
    mkdir -p "$_origin" "$_bin"

    # What `refresh-index.sh` writes for a flat area: a sorted list between the markers.
    _idx() {
        printf '# feedbacks\n\n<!-- okf:generated:begin -->\n'
        for _s in "$@"; do printf '* [%s](%s.md)\n' "$_s" "$_s"; done
        printf '%s\n' '<!-- okf:generated:end -->'
    }
    _write_mech() {
        printf -- '---\ntype: Feedback\n---\n\n# b\n' > .workaholic/feedbacks/20260102000000-b.md
        _idx 20260101000000-a 20260102000000-b > .workaholic/feedbacks/index.md
    }
    _write_content() { printf 'alpha\nbeta-branch\ngamma\n' > src/app.txt; }
    # A publication that touches a path NOTHING else touches: no collision to classify, so the
    # class is `clean` and the branch is mergeable exactly as it stands.
    _write_clean() { printf 'untouched-by-the-base\n' > src/other.txt; }

    # One publication: an ordinary commit on a `work-*` branch and NO claim commit, which is
    # exactly what `publish-tree-pr.sh` pushes.
    _pub() {
        _pb="$1"
        _pw="$2"
        ( cd "$_wt" && git worktree add -q -b "$_pb" "${_tmp}/${_pb}" origin/main ) >/dev/null 2>&1 || return 1
        ( cd "${_tmp}/${_pb}" && $_pw ) >/dev/null 2>&1 || return 1
        ( cd "${_tmp}/${_pb}" && git add -A && git commit -q -m 'Publish an artifact' \
            && git push -q origin "$_pb" ) >/dev/null 2>&1 || return 1
        ( cd "$_wt" && git worktree remove --force "${_tmp}/${_pb}" && git branch -q -D "$_pb" \
            && git fetch -q --prune origin ) >/dev/null 2>&1 || return 1
    }

    ( cd "$_origin" && git -c init.defaultBranch=main init -q --bare ) >/dev/null 2>&1 \
        || emit_err "stranded_publication_fixture" 4 "could not create the bare origin"
    (
        git clone -q "$_origin" "$_wt" \
            && cd "$_wt" \
            && git config user.email drill@example.invalid \
            && git config user.name Drill \
            && git config commit.gpgsign false \
            && mkdir -p .workaholic/feedbacks src \
            && printf -- '---\ntype: Feedback\n---\n\n# a\n' > .workaholic/feedbacks/20260101000000-a.md \
            && printf 'alpha\nbeta\ngamma\n' > src/app.txt
    ) >/dev/null 2>&1 || emit_err "stranded_publication_fixture" 4 "could not seed the fixture"
    _idx 20260101000000-a > "${_wt}/.workaholic/feedbacks/index.md"
    ( cd "$_wt" && git add -A && git commit -q -m 'Seed the base' && git push -q origin main ) \
        >/dev/null 2>&1 || emit_err "stranded_publication_fixture" 4 "could not push the base"

    _mech=work-20260831-100000
    _content=work-20260831-100001
    _clean=work-20260831-100002
    _pub "$_mech" _write_mech \
        || emit_err "stranded_publication_fixture" 4 "could not publish the settleable branch"
    _pub "$_content" _write_content \
        || emit_err "stranded_publication_fixture" 4 "could not publish the content branch"
    _pub "$_clean" _write_clean \
        || emit_err "stranded_publication_fixture" 4 "could not publish the clean branch"

    # The base moves the way a merged sibling proposal moves it: another record, the index
    # regenerated around it, and the same source line the content branch touched.
    _idx 20260101000000-a 20260103000000-c > "${_wt}/.workaholic/feedbacks/index.md"
    (
        cd "$_wt" \
            && printf -- '---\ntype: Feedback\n---\n\n# c\n' > .workaholic/feedbacks/20260103000000-c.md \
            && printf 'alpha\nbeta-base\ngamma\n' > src/app.txt \
            && git add -A && git commit -q -m 'Advance the base' && git push -q origin main \
            && git fetch -q --prune origin
    ) >/dev/null 2>&1 || emit_err "stranded_publication_fixture" 4 "could not advance the base"

    # The transport, stubbed: the list endpoint answers the TSV projection the reader asks for,
    # each pull's `files` answers what the publication-refusal rule reads, and the one `PUT
    # .../merge` succeeds.
# `_write_gh_stub <open-pull-number>...` re-issues it with exactly the pull requests named still
# open. A merge CLOSES a pull request, so after a delivery the reader must stop naming it — that
# is the act's real idempotency guard, and modelling it is what lets row 10 assert a refusal
# rather than a second settlement of a publication it would now be right to deliver.
    _write_gh_stub() {
        {
            printf '#!/bin/sh\ncase "$*" in\n'
            printf "  *rate_limit*) printf '5000\\\\n'; exit 0 ;;\n"
            printf "  *\"/merge\"*) printf '{\"merged\":true,\"sha\":\"fixture-merge-sha\"}\\\\n'; exit 0 ;;\n"
            printf "  *\"pulls/41/files\"*) printf '[{\"status\":\"added\",\"filename\":\".workaholic/feedbacks/20260102000000-b.md\",\"patch\":\"+x\"},{\"status\":\"modified\",\"filename\":\".workaholic/feedbacks/index.md\",\"patch\":\"+x\"}]\\\\n'; exit 0 ;;\n"
            printf "  *\"pulls/42/files\"*) printf '[{\"status\":\"modified\",\"filename\":\"src/app.txt\",\"patch\":\"+x\"}]\\\\n'; exit 0 ;;\n"
            printf "  *\"pulls/43/files\"*) printf '[{\"status\":\"added\",\"filename\":\"src/other.txt\",\"patch\":\"+x\"}]\\\\n'; exit 0 ;;\n"
            printf "  *\"pulls/41\") sha=\$(git rev-parse origin/${_mech}); printf '{\"state\":\"open\",\"merged\":false,\"head\":{\"sha\":\"%%s\"}}\\\\n' \"\$sha\"; exit 0 ;;\n"
            printf "  *\"pulls/42\") sha=\$(git rev-parse origin/${_content}); printf '{\"state\":\"open\",\"merged\":false,\"head\":{\"sha\":\"%%s\"}}\\\\n' \"\$sha\"; exit 0 ;;\n"
            printf "  *\"pulls/43\") sha=\$(git rev-parse origin/${_clean}); printf '{\"state\":\"open\",\"merged\":false,\"head\":{\"sha\":\"%%s\"}}\\\\n' \"\$sha\"; exit 0 ;;\n"
            printf "  *\"check-runs\"*) printf '{\"total_count\":0,\"check_runs\":[]}\\\\n'; exit 0 ;;\n"
            printf '  *"pulls?state=open"*)\n'
            for _n in "$@"; do
                case "$_n" in
                    41) printf "    printf '41\\\\thttps://example.invalid/pr/41\\\\t[Proposal] b\\\\t2026-08-31T10:00:00Z\\\\tclaude[bot]\\\\t%s\\\\n'\n" "$_mech" ;;
                    42) printf "    printf '42\\\\thttps://example.invalid/pr/42\\\\t[Proposal] app\\\\t2026-08-31T10:00:01Z\\\\tclaude[bot]\\\\t%s\\\\n'\n" "$_content" ;;
                    43) printf "    printf '43\\\\thttps://example.invalid/pr/43\\\\t[Proposal] other\\\\t2026-08-31T10:00:02Z\\\\tclaude[bot]\\\\t%s\\\\n'\n" "$_clean" ;;
                esac
            done
            printf '    exit 0 ;;\nesac\n'
            printf "printf '[]\\\\n'\n"
        } > "${_bin}/gh"
        chmod +x "${_bin}/gh"
    }
    _write_gh_stub 41 42 43

    _tip() { git -C "$_wt" rev-parse "origin/$1" 2>/dev/null || printf ''; }

    # 1. THE READER SEES A PUBLICATION AT ALL — the seam that had no reader before this mission.
    _r=$(cd "$_wt" && PATH="${_bin}:$PATH" sh "$_reader" 2>&1 || true)
    if printf '%s' "$_r" | jq -e '(.ok == true) and ([.publications[] | select(.number == 41 and .mergeability == "mechanical")] | length == 1) and ([.publications[] | select(.number == 42 and .mergeability == "content")] | length == 1) and ([.publications[] | select(.number == 43 and .mergeability == "clean")] | length == 1)' >/dev/null 2>&1; then
        add_row "stranded_reader_sees_a_publication" true "a publication with no claim commit is read, with each of the three classes derived" load
    else
        add_row "stranded_reader_sees_a_publication" false "the reader did not classify all three publications: $(one_line "$_r")" load
    fi

    # 2. THE BREAKER, LABELLED AS THE INTENTIONAL FAILURE, and run BEFORE anything is settled —
    #    afterwards the settleable branch contains the base and there is no collision left to
    #    misclassify. Strip the generated-region proof and the settleable collision must read
    #    `content`, i.e. be reported rather than repaired: the measured incident on demand.
    _broken="${_tmp}/broken"
    mkdir -p "$_broken"
    cp -R "${REPO_ROOT}/plugins/workaholic/skills/." "${_broken}/"
    sed 's|^conflict_class_generated_region() {|conflict_class_generated_region() { return 1;|' \
        "${REPO_ROOT}/plugins/workaholic/skills/ship/scripts/lib/conflict-class.sh" \
        > "${_broken}/ship/scripts/lib/conflict-class.sh"
    _b=$(cd "$_wt" && PATH="${_bin}:$PATH" sh "${_broken}/branching/scripts/list-stranded-publications.sh" 2>&1 || true)
    if printf '%s' "$_b" | jq -e '[.publications[]? | select(.number == 41 and .mergeability == "content")] | length == 1' >/dev/null 2>&1; then
        add_row "stranded_breaker" true "with the generated-region proof removed the settleable collision reads content, so it would be reported rather than repaired (this drill can fail)" breaker
    else
        add_row "stranded_breaker" false "the breaker did not break: the settleable collision still read mechanical without the proof ($(one_line "$_b")), so rows 1 and 4 prove nothing" breaker
    fi

    # 2b. THE SECOND BREAKER, against the behaviour the 2026-09-01 mission added and under the
    #     same ordering constraint: narrow the act's class gate back to `mechanical` alone and the
    #     clean publication must be refused `not_mechanical:clean` with nothing attempted — the
    #     measured incident, in which five green publications were read, named and delivered by
    #     nothing. It is a SEPARATE broken copy: the first breaker's tree has the classification
    #     rule stripped, which would confound what this one is asserting.
    _broken2="${_tmp}/broken2"
    mkdir -p "$_broken2"
    cp -R "${REPO_ROOT}/plugins/workaholic/skills/." "${_broken2}/"
    sed '/clean) NEEDS_CATCHUP=false ;;/d' \
        "${REPO_ROOT}/plugins/workaholic/skills/branching/scripts/prepare-publication.sh" \
        > "${_broken2}/branching/scripts/prepare-publication.sh"
    _cl_before=$(_tip "$_clean")
    _b2=$(cd "$_wt" && PATH="${_bin}:$PATH" sh "${_broken2}/branching/scripts/settle-stranded-publication.sh" 43 2>&1 || true)
    if printf '%s' "$_b2" | jq -e '(.outcome == "settle_refused") and (.reason == "not_mechanical:clean") and (.delivery == "not_attempted")' >/dev/null 2>&1 \
       && [ "$_cl_before" = "$(_tip "$_clean")" ]; then
        add_row "stranded_clean_breaker" true "with the class gate narrowed back to mechanical the clean publication is refused not_mechanical:clean and delivered by nothing (this drill can fail)" breaker
    else
        add_row "stranded_clean_breaker" false "the breaker did not break: the clean publication was still acted on with the gate narrowed ($(one_line "$_b2")), so rows 9 and 10 prove nothing" breaker
    fi

    # 3. A COLLISION ONLY A PERSON CAN SETTLE IS REFUSED, BRANCH BYTE-IDENTICAL.
    _c_before=$(_tip "$_content")
    _refused=$(cd "$_wt" && PATH="${_bin}:$PATH" sh "$_act" 42 2>&1 || true)
    _c_after=$(_tip "$_content")
    if printf '%s' "$_refused" | jq -e '(.outcome == "settle_refused") and (.pushed == false)' >/dev/null 2>&1 \
       && [ "$_c_before" = "$_c_after" ]; then
        add_row "stranded_content_is_refused" true "a content collision is refused by its own word and its branch is byte-identical" load
    else
        add_row "stranded_content_is_refused" false "a content collision was not refused, or its branch moved: $(one_line "$_refused")" load
    fi

    # 4. A COLLISION A GENERATOR SETTLES IS SETTLED AND DELIVERED, WITH NO PERSON — and the
    #    repair is real: the branch contains the base and the regenerated index carries BOTH
    #    sides' records rather than one side's stale copy.
    _settled=$(cd "$_wt" && PATH="${_bin}:$PATH" sh "$_act" 41 2>&1 || true)
    _ok_settled=true
    printf '%s' "$_settled" | jq -e '(.outcome == "settled") and (.pushed == true) and (.delivery == "merged")' >/dev/null 2>&1 || _ok_settled=false
    ( cd "$_wt" && git fetch -q --prune origin ) >/dev/null 2>&1 || true
    ( cd "$_wt" && git merge-base --is-ancestor origin/main "origin/${_mech}" ) >/dev/null 2>&1 || _ok_settled=false
    _merged_idx=$(git -C "$_wt" show "origin/${_mech}:.workaholic/feedbacks/index.md" 2>/dev/null || printf '')
    case "$_merged_idx" in
        *20260102000000-b*)
            case "$_merged_idx" in *20260103000000-c*) ;; *) _ok_settled=false ;; esac ;;
        *) _ok_settled=false ;;
    esac
    if [ "$_ok_settled" = "true" ]; then
        add_row "stranded_mechanical_is_settled" true "the settleable collision is caught up, regenerated with both records, pushed and delivered with no person" load
    else
        add_row "stranded_mechanical_is_settled" false "the settleable collision was not settled and delivered: $(one_line "$_settled")" load
    fi

    # 5. NO WORKTREE IS LEFT BEHIND by either path.
    if [ ! -d "${_wt}/.worktrees/publication-41" ] && [ ! -d "${_wt}/.worktrees/publication-42" ]; then
        add_row "stranded_leaves_no_worktree" true "the act left no worktree behind on either path" load
    else
        add_row "stranded_leaves_no_worktree" false "a worktree was left behind under .worktrees/" load
    fi

    # 6. A RE-RUN OF EITHER IS A NO-OP REPORTING ITS OWN WORD — nothing pushed, no ref moved.
    _m_before=$(_tip "$_mech")
    _again_m=$(cd "$_wt" && PATH="${_bin}:$PATH" sh "$_act" 41 2>&1 || true)
    _again_c=$(cd "$_wt" && PATH="${_bin}:$PATH" sh "$_act" 42 2>&1 || true)
    _m_after=$(_tip "$_mech")
    if printf '%s' "$_again_m" | jq -e '.pushed == false' >/dev/null 2>&1 \
       && printf '%s' "$_again_c" | jq -e '.pushed == false' >/dev/null 2>&1 \
       && [ "$_m_before" = "$_m_after" ]; then
        add_row "stranded_rerun_is_a_noop" true "a second run over either publication pushes nothing and moves no ref" load
    else
        add_row "stranded_rerun_is_a_noop" false "a re-run was not a no-op: $(one_line "$_again_m") / $(one_line "$_again_c")" load
    fi

    # 6b. A PUBLICATION THAT NEEDS NOTHING BUT A MERGE IS SETTLED AND DELIVERED, AND TAKES NO
    #    CATCH-UP AT ALL (2026-09-01). The behaviour, not the return shape: nothing was merged,
    #    regenerated, validated or pushed, the branch is byte-identical after the act, and the
    #    delivery is reported in the merge vocabulary. A regression that puts the class back to
    #    `not_mechanical:clean` fails here.
    _cl_before=$(_tip "$_clean")
    _cl=$(cd "$_wt" && PATH="${_bin}:$PATH" sh "$_act" 43 2>&1 || true)
    ( cd "$_wt" && git fetch -q --prune origin ) >/dev/null 2>&1 || true
    if printf '%s' "$_cl" | jq -e '(.outcome == "settled") and (.class == "clean") and (.merged == false) and (.regenerated == false) and (.validated == false) and (.pushed == false) and (.delivery == "merged")' >/dev/null 2>&1 \
       && [ "$_cl_before" = "$(_tip "$_clean")" ] \
       && [ ! -d "${_wt}/.worktrees/publication-43" ]; then
        add_row "stranded_clean_is_settled" true "a publication that collides with nothing is delivered with no catch-up, no ref written and no worktree left behind" load
    else
        add_row "stranded_clean_is_settled" false "the clean publication was not settled and delivered without a catch-up: $(one_line "$_cl")" load
    fi

    # 6c. AND A RE-RUN OVER THE DELIVERED ONE REFUSES BY NAME AND MOVES NO REF. The merge closed
    #     the pull request, so the reader stops naming it — the guard that actually holds in
    #     production, and the only one that survives `clean` being an accepted class: a branch
    #     that already contains the base reads `clean`, so a fixture keeping the merged pull
    #     request open would be asserting a refusal of work the act is now right to do.
    _write_gh_stub 41 42
    _cl_before=$(_tip "$_clean")
    _cl_again=$(cd "$_wt" && PATH="${_bin}:$PATH" sh "$_act" 43 2>&1 || true)
    if printf '%s' "$_cl_again" | jq -e '(.outcome == "settle_refused") and (.reason == "not_a_stranded_publication") and (.pushed == false) and (.delivery == "not_attempted")' >/dev/null 2>&1 \
       && [ "$_cl_before" = "$(_tip "$_clean")" ]; then
        add_row "stranded_clean_rerun_is_a_noop" true "a second run over the delivered publication refuses by name, attempts no delivery and moves no ref" load
    else
        add_row "stranded_clean_rerun_is_a_noop" false "a re-run over the delivered publication was not a refusing no-op: $(one_line "$_cl_again")" load
    fi

    # 7. A CONTENT COLLISION IS COUNTED AND ASKED ABOUT BY NOBODY (2026-09-02, ticket
    # `20260902042630-retire-the-surfaces-that-defer-a-conflict-to-a-claim-holder.md`). It used
    # to draw a question keyed `stranded-publication:<n>`; the operator's ruling is that a
    # conflict handed to an author who never comes makes parked work read as progress. The act
    # now attempts every class, and what the merge itself cannot settle is reported where the
    # attempt happened. The reading survives — the count is still in the summary and the event
    # still names the repository fact — and only the DEFERRAL is gone.
    _s=$(cd "$_wt" && PATH="${_bin}:$PATH" sh "$_step" --tick 20260831-130000 --root "$_wt" 2>&1 || true)
    if printf '%s' "$_s" | jq -e '(.status == "ok") and ([.needs_agent[]?.stranded[]?] | length == 0) and (.summary | test("colliding on content"))' >/dev/null 2>&1; then
        add_row "stranded_content_asks_nobody" true "the content collision is counted in the summary and reaches no question -- the next tick attempts it and the act reports what it cannot settle" load
    else
        add_row "stranded_content_asks_nobody" false "a content collision still defers to the publication author, or stopped being counted: $(one_line "$_s")" load
    fi

    # 8. NOTHING WAS WRITTEN OUTSIDE THE FIXTURE.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "stranded_writes_nothing_outside_the_fixture" true "the checkout is byte-identical after the drill" load
    else
        add_row "stranded_writes_nothing_outside_the_fixture" false "the drill changed the working tree" load
    fi

    ( cd "$_wt" && git worktree prune ) >/dev/null 2>&1 || true
    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "stranded-publication" 0 "fail" 1
    fi
    emit_verdict "stranded-publication" 0 "pass" 0
}

# ------------------------------------------------------- verify-tick-thread
# THE DAY-KEYED ROOT AND THE STABILIZED POST GATE (2026-09-01, mission
# `let-the-tick-add-to-a-standing-thread-instead-of-restating-itself`).
#
# Two behaviours ship together and BOTH are only observable through Slack, which no hermetic
# test can reach — so without this drill the regression that returns the tick to an hourly
# root is invisible until somebody reads the channel and counts. Measured before the change:
# 14 roots in one window, 12 of them carrying no question, and `stuck-prs` opening a root on
# a `<number>:<blocked_by>` list GitHub merely answered differently across nine consecutive
# ticks in which the repository did not move.
#
# HERMETIC. The key derivation is a pure function of a tick id and a zone; the post gate's
# whole input is a JSON document on stdin and a tick log the fixture writes through
# `log-append.sh`, THE REAL WRITER. `step-stuck-prs.sh` is driven against a stub `gh` inside
# a throwaway git repository — no network, no credential, no Slack.
#
# THE ROWS ARE WRITTEN AGAINST THE BEHAVIOUR, NOT A RETURN SHAPE, and each is phrased as the
# failure it would catch. Two of them are the silences the mission bought, so each is paired
# with its opposite: a drill that only proved the silence would pass a change that silenced
# everything.
