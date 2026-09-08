cmd_verify_plan_adjust() {
    _survey="${REPO_ROOT}/plugins/workaholic/skills/propose/scripts/survey-strategies.sh"
    _plan="${REPO_ROOT}/plugins/workaholic/skills/drive/scripts/plan-units.sh"
    for _f in "$_survey" "$_plan"; do
        [ -f "$_f" ] || emit_err "plan_adjust_unreadable" 4 "$_f is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    _tmp=$(mktemp -d)
    _fx="${_tmp}/fx"
    mkdir -p "$_fx"
    _day() { date -u -d "+$1 days" +%Y-%m-%d 2>/dev/null || date -u -v"+$1"d +%Y-%m-%d; }
    _w() { mkdir -p "$(dirname "${_fx}/$1")" && printf '%s' "$2" > "${_fx}/$1"; }

    _strategy() {
        printf -- '---\ntype: Strategy\ntitle: %s t\nslug: %s\nstatus: active\ntarget_date: %s\nassignees: [drill@example.invalid]\nfeedback: [%s]\n---\n\n# %s\n\n## Aim\n\nbuild x\n\n## Schedule\n\ny\n' \
            "$1" "$1" "$2" "$3" "$1"
    }
    _mission() {
        printf -- '---\ntype: Mission\ntitle: %s t\nslug: %s\nstatus: active\ncreated_at: 2026-08-01T00:00:00+09:00\nauthor: drill@example.invalid\nassignees: [drill@example.invalid]\n%s---\n\n# %s\n\n## Experience\n\ne\n\n## Acceptance\n\n- [ ] a\n' \
            "$1" "$1" "$2" "$1"
    }

    (
        cd "$_fx" \
            && git init -q . >/dev/null 2>&1 \
            && git config user.email drill@example.invalid \
            && git config user.name Drill
    ) || emit_err "plan_adjust_fixture" 4 "could not build the throwaway repository"

    _w ".workaholic/feedbacks/20260801000001-free.md" "$(printf -- '---\ntype: Feedback\n---\n\nask\n')"
    # The ELIGIBLE direction: cited, dated, owned, and with its own work all ARCHIVED, so no
    # earlier rung of the ladder fires and the `wip_limit` rung is the one under test.
    _w ".workaholic/strategies/free.md" "$(_strategy free "$(_day 30)" 20260801000001-free.md)"
    _w ".workaholic/missions/archive/m-old/mission.md" "$(printf -- '---\ntype: Mission\ntitle: m-old\nslug: m-old\nstatus: achieved\nfeedback: [20260801000001-free.md]\n---\n\n# m-old\n\n## Experience\n\ne\n\n## Acceptance\n\n- [x] a\n')"
    _w ".workaholic/tickets/archive/w1/20260810000001-old.md" "$(printf -- '---\nmission: m-old\nstatus: done\n---\n\n# done\n')"
    # The dated directions the OFFER ORDER is read against, and the work that is in flight.
    _w ".workaholic/strategies/soon.md" "$(_strategy soon "$(_day 5)" 20260801000002-soon.md)"
    _w ".workaholic/strategies/later.md" "$(_strategy later "$(_day 50)" 20260801000003-later.md)"
    _w ".workaholic/strategies/nodate.md" "$(_strategy nodate "" 20260801000004-nodate.md)"
    _w ".workaholic/missions/active/m-b/mission.md" "$(_mission m-b 'feedback: [20260801000002-soon.md]
')"
    _w ".workaholic/missions/active/m-a/mission.md" "$(_mission m-a 'feedback: [20260801000003-later.md]
')"
    _w ".workaholic/missions/active/m-c/mission.md" "$(_mission m-c 'feedback: [20260801000004-nodate.md]
')"
    _w ".workaholic/missions/active/m-z/mission.md" "$(_mission m-z '')"
    for _m in m-a m-b m-c m-z; do
        _w ".workaholic/tickets/todo/2026081000000-${_m}.md" "$(printf -- '---\ncreated_at: 2026-08-10T00:00:00+00:00\nauthor: drill@example.invalid\nassignees: [drill@example.invalid]\nmission: %s\n---\n\n# q\n' "$_m")"
    done
    # THE COMMIT IS DATED INTO THE PAST, and that is what makes the eligible direction stable.
    # `landed` is a `git log --since` read over the survey's window, so a fixture committed NOW
    # is inside ANY window: the direction then reads `quiescent` and is refused `arrived` by the
    # rung above the one under test — measured, the drill passed or failed depending on whether
    # a second had elapsed between the commit and the survey. `GIT_COMMITTER_DATE` is the same
    # control `verify-cadence-lapse` uses, and for the same reason.
    ( cd "$_fx" && git add -A >/dev/null 2>&1 \
        && GIT_AUTHOR_DATE='2001-01-01T00:00:00+0000' GIT_COMMITTER_DATE='2001-01-01T00:00:00+0000' \
           git commit -q -m 'Seed the plan fixture' >/dev/null 2>&1 ) \
        || emit_err "plan_adjust_fixture" 4 "could not commit the throwaway fixture"

    _open="${_tmp}/open.json"
    printf '{"ok": true, "identity": "drill@example.invalid", "proposals": []}\n' > "$_open"
    # Four active missions carry queued work, so the repository's work in flight is 4.
    # THE FIXTURE ESTABLISHES THE CONDITION IT ASSERTS, INCLUDING THE ABSENCE OF ONE. Row 3 reads
    # the UNDECLARED shape, and the sanctioned home for the declaration is the repository's own
    # `.claude/settings.json` `env` block — so on a repository that has declared a limit the value
    # reached this fixture and row 3 read `{declared: true, limit: 3}`: green in CI, where no such
    # environment exists, and red on the operator's own machine. A drill that depends on what the
    # operator happens to have declared is not hermetic, which is the one property this file has.
    # `env -u` removes it first; the drill's own value, when it has one, is applied after.
    _run_survey() {
        ( cd "$_fx" && env -u WORKAHOLIC_WIP_LIMIT ${1:+WORKAHOLIC_WIP_LIMIT="$1"} sh "$_survey" --open-proposals "$_open" "1 days ago" 2>&1 ) || true
    }

    # 1. ABOVE THE LIMIT: the direction is HELD, by name, with the count and the limit said.
    _held=$(_run_survey 4)
    if printf '%s' "$_held" | jq -e '(.eligible | length == 0) and ([.refused[] | select(.slug=="free" and .reason=="wip_limit")] | length == 1) and (.wip.count == 4) and (.wip.limit == 4)' >/dev/null 2>&1; then
        add_row "plan_adjust_holds_above_the_limit" true "a declared limit holds origination, names the rung, and says the count and the limit" load
    else
        add_row "plan_adjust_holds_above_the_limit" false "the limit did not hold, or did not say why: $(one_line "$_held")" load
    fi

    # 2. BELOW THE LIMIT: origination proceeds exactly as it does without the declaration.
    _room=$(_run_survey 99)
    if printf '%s' "$_room" | jq -e '([.eligible[] | select(.slug=="free")] | length == 1) and (.wip.count == 4) and (.wip.limit == 99)' >/dev/null 2>&1; then
        add_row "plan_adjust_below_the_limit_proceeds" true "a tick below the limit proposes as it does now, and still reports the room it has" load
    else
        add_row "plan_adjust_below_the_limit_proceeds" false "a tick below the limit did not proceed: $(one_line "$_room")" load
    fi

    # 3. NOTHING DECLARED IS BYTE-IDENTICAL TO BEFORE THIS EXISTED — the more dangerous
    #    direction, because a brake nobody asked for stops the loop silently.
    _none=$(_run_survey "")
    if printf '%s' "$_none" | jq -e '([.eligible[] | select(.slug=="free")] | length == 1) and (.wip.declared == false) and (.wip.count == null) and (.wip.reason == "not_declared")' >/dev/null 2>&1; then
        add_row "plan_adjust_absent_holds_nothing" true "an undeclared repository is unchanged: the count is not even taken and the gate is a named no-op" load
    else
        add_row "plan_adjust_absent_holds_nothing" false "an undeclared repository was not left alone: $(one_line "$_none")" load
    fi

    # 4. A GATE THAT CANNOT BE READ IS NOT A GATE.
    _bad=$(_run_survey lots)
    if printf '%s' "$_bad" | jq -e '([.eligible[] | select(.slug=="free")] | length == 1) and (.wip.readable == false) and (.wip.reason == "bad_limit")' >/dev/null 2>&1; then
        add_row "plan_adjust_unreadable_limit_holds_nothing" true "a non-numeric declaration is named and holds nothing, so our own bad read cannot stop the loop" load
    else
        add_row "plan_adjust_unreadable_limit_holds_nothing" false "an unreadable limit was not named, or held something: $(one_line "$_bad")" load
    fi

    # 5. THE OFFER ORDER, and the SET beside it. The walk order is m-a, m-b, m-c, m-z; the
    #    derived order puts the nearest date first, so a survey that returns the walk order has
    #    lost the ordering entirely.
    _p=$( ( cd "$_fx" && sh "$_plan" 2>/dev/null ) || true)
    _order=$(printf '%s' "$_p" | jq -r '[.missions[].slug] | join(",")' 2>/dev/null || printf '')
    _set=$(printf '%s' "$_p" | jq -r '[.missions[].slug] | sort | join(",")' 2>/dev/null || printf '')
    if [ "$_order" = "m-b,m-a,m-c,m-z" ]; then
        add_row "plan_adjust_offer_is_ordered" true "the offer is ordered by the direction's date, then the two named fallbacks" load
    else
        add_row "plan_adjust_offer_is_ordered" false "the offer order was '${_order}', not the stated one" load
    fi
    if [ "$_set" = "m-a,m-b,m-c,m-z" ]; then
        add_row "plan_adjust_offer_set_unchanged" true "ordering changed the order and not which units are offered" load
    else
        add_row "plan_adjust_offer_set_unchanged" false "the offered set was '${_set}': ordering dropped or added a unit" load
    fi
    if printf '%s' "$_p" | jq -e '[.missions[] | select(.order_reason == null)] | length == 0' >/dev/null 2>&1; then
        add_row "plan_adjust_offer_says_why" true "every offered row names why it sorted where it did" load
    else
        add_row "plan_adjust_offer_says_why" false "a row was ordered without saying why: $(one_line "$_p")" load
    fi

    # 6. A RESOLVER WE COULD NOT READ TAKES THE STATED FALLBACK AND IS NAMED — never a silent
    #    walk order, which is indistinguishable from a derived one that happened to agree.
    _brk="${_tmp}/broken-skills"
    mkdir -p "$_brk"
    cp -R "${REPO_ROOT}/plugins/workaholic/skills/." "$_brk/"
    rm -f "${_brk}/strategy/scripts/mission-strategy.sh"
    _pb=$( ( cd "$_fx" && sh "${_brk}/drive/scripts/plan-units.sh" 2>/dev/null ) || true)
    if printf '%s' "$_pb" | jq -e '([.missions[] | select(.order_reason == "direction_unreadable")] | length == 4) and ([.missions[].slug] | join(",")) == "m-a,m-b,m-c,m-z"' >/dev/null 2>&1; then
        add_row "plan_adjust_unreadable_order_is_named" true "with the resolver gone every row is named unreadable and the fallback position is the walk order" load
    else
        add_row "plan_adjust_unreadable_order_is_named" false "an unreadable resolution was not named: $(one_line "$_pb")" load
    fi

    # 7. THE BREAKER, LABELLED AS THE INTENTIONAL FAILURE. Wire the `wip_limit` rung out of the
    #    ladder; the held direction must become eligible again. Without this, row 1 could pass
    #    against a survey that never had the gate at all.
    sed 's|then "wip_limit"|then ""|' "$_survey" > "${_brk}/propose/scripts/survey-strategies.sh"
    chmod +x "${_brk}/propose/scripts/survey-strategies.sh"
    _b=$( ( cd "$_fx" && WORKAHOLIC_WIP_LIMIT=4 sh "${_brk}/propose/scripts/survey-strategies.sh" --open-proposals "$_open" "1 days ago" 2>&1 ) || true)
    if printf '%s' "$_b" | jq -e '[.eligible[] | select(.slug=="free")] | length == 1' >/dev/null 2>&1; then
        add_row "plan_adjust_breaker" true "with the wip_limit rung wired out the held direction originates again (this drill can fail)" breaker
    else
        add_row "plan_adjust_breaker" false "the breaker did not break: the direction stayed held with the rung removed ($(one_line "$_b")), so row 1 proves nothing" breaker
    fi

    # 8. NOTHING WAS WRITTEN OUTSIDE THE FIXTURE.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "plan_adjust_writes_nothing_outside_the_fixture" true "the checkout is byte-identical after the drill" load
    else
        add_row "plan_adjust_writes_nothing_outside_the_fixture" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "plan-adjust" 0 "fail" 1
    fi
    emit_verdict "plan-adjust" 0 "pass" 0
}

# ------------------------------------------------ verify-stranded-publication
# A PUBLICATION THE LOOP OPENED AND COULD NOT MERGE (2026-08-31, mission
# `repair-a-mechanically-resolvable-conflict-instead-of-reporting-it`).
#
# The measured failure ran for a full day with the loop reporting it hourly: three open
# proposals colliding on `.workaholic/feedbacks/index.md` and on nothing else, a repair that was
# three commands, and no reader anywhere in the loop that could see a publication at all. The
# regression this mission must not allow is that repair quietly ceasing to fire, so the whole
# chain is drilled here: reader -> act -> delivery -> re-run -> the question.
#
# HERMETIC. The origin is a BARE LOCAL REPOSITORY (`git push` to a file path needs no network)
# and the GitHub transport is a stub on PATH inside the fixture's own temp directory. No
# credential, no network, no Slack, and nothing outside the fixture is written.
#
# THE ASSERTIONS ARE ABOUT BEHAVIOUR, NOT RETURN SHAPE: the settleable collision is caught up,
# REGENERATED SO BOTH SIDES' RECORDS SURVIVE, pushed and delivered with no person; the content
# one is refused with its branch BYTE-IDENTICAL; a re-run of either moves no ref. A drill
# satisfied by the JSON keys would go on passing through the regression it exists to catch.
#
# AND A PUBLICATION THAT COLLIDES WITH NOTHING AT ALL (2026-09-01, mission
# `deliver-a-stranded-publication-that-needs-nothing-but-a-merge`). The rows above are every one
# about a COLLISION — `content` refused, `mechanical` settled — so the class that needs nothing
# but a merge appeared in none of them, and a regression putting `clean` back to
# `not_mechanical:clean` would have passed the whole drill set. Measured on the morning the class
# was given an owner: five of six open publications read `clean`, the oldest six days old, every
# one green and delivered by nothing. Two rows close it: the act settles such a publication and
# takes NO catch-up, and a re-run over the delivered one moves no ref.
#
# THE BREAKERS ARE WRITTEN AGAINST THE BEHAVIOUR, and both run BEFORE anything is settled —
# afterwards the settleable branch contains the base and the delivered one is closed, so there is
# nothing left to misclassify or refuse. Strip the generated-region proof out of the shared
# classification rule and the settleable collision must read `content`; narrow the act's class
# gate back to `mechanical` alone and the clean publication must be refused `not_mechanical:clean`
# and delivered by nothing. Each is precisely the measured incident, reproduced on demand.
#
# WHAT THIS DRILL DOES NOT PROVE: that the consuming repository's own incident is gone. That
# repository may be on a different plugin version; this exercises this checkout's scripts only.
# ------------------------------------------- verify-stranded-claim-branch
# THE ONE MECHANISM IN THIS LOOP WHOSE REGRESSION DESTROYS WORK RATHER THAN DELAYING IT
# (2026-09-02, mission `prove-a-claim-branch-is-empty-before-deleting-it`).
#
# `superseded` licenses `retire-claim.sh` to DELETE a remote branch. Until 2026-09-01 it proved
# only that the unit's tickets were archived on the base, and the step from there to *the branch
# holds no work* holds only when a branch carries nothing but its own unit's tickets. Measured:
# two branches whose tickets had landed through DIFFERENT branches still held ~300 lines of code
# and a documentation section present on no other ref, and the tick was asking for both to be
# deleted. Only a 403 on `push --delete` had prevented the loss, for five days — which is exactly
# why this drill is owed: the day the transport is repaired is the day a regression here becomes
# a silent loss instead of a reported nuisance.
#
# THE DELETE IS ALLOWED TO ACTUALLY RUN. The origin is a real bare repository over the file
# transport, so `retire-claim.sh`'s `push --delete` succeeds when the proof holds. Asserting a
# return word instead would pass over a delete that happened anyway; the rows below assert the
# REFS and the FILE CONTENT on origin afterwards.
#
# THREE SEEDED CASES, AT BOTH GRAINS: a branch empty against the base outside `.workaholic/`
# (retired), a branch holding a file that is on no other ref (refused, and the file survives),
# and a branch whose emptiness cannot be read (never `superseded`, so the act is never reached).
#
# WHAT IT DOES NOT PROVE, stated rather than implied: it proves the REFUSAL and the derivation
# behind it, not the transport. It cannot show that the production 403 is gone or that a real
# remote delete behaves identically to a file-transport one.
