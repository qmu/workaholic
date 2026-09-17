cmd_verify_runner_advance() {
    _reader="${REPO_ROOT}/plugins/workaholic/skills/loops/scripts/read-runner-advance.sh"
    [ -f "$_reader" ] || emit_err "runner_advance_unreadable" 4 "$_reader is not present in this checkout"

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    _tmp=$(mktemp -d)

    _mkwt() {  # _mkwt <fixture> <unit> <age-arg|now>
        mkdir -p "${_tmp}/$1/.worktrees/$2"
        printf 'work\n' > "${_tmp}/$1/.worktrees/$2/f.md"
        [ "$3" = now ] || touch -d "$3" "${_tmp}/$1/.worktrees/$2/f.md"
    }

    _mkwt frozen unit-a '2 hours ago'; _mkwt frozen unit-b '2 hours ago'
    _mkwt mixed  unit-a '2 hours ago'; _mkwt mixed  unit-b now
    mkdir -p "${_tmp}/none"
    _mkwt blind  unit-a '2 hours ago'; mkdir -p "${_tmp}/blind/.worktrees/unit-b"

    # 1. THE EVIDENCE THE LOCALIZATION PROVED: a claim worktree whose files have not moved
    #    inside the window is `not_advancing`, one that has moved is `advancing`. This is the
    #    only signal that is not flat during a legitimately long ticket — the claim tip and the
    #    tick log both are, which is why neither is read here.
    _r=$(sh "$_reader" --names implement,implement-2 "${_tmp}/mixed" 2>&1 || true)
    if printf '%s' "$_r" | jq -e '
        ([.claims[] | select(.unit=="unit-a" and .verdict=="not_advancing" and .idle_seconds > 3000)] | length == 1)
        and ([.claims[] | select(.unit=="unit-b" and .verdict=="advancing")] | length == 1)' >/dev/null 2>&1; then
        add_row "runner_advance_reads_the_worktree" true "a flat claim worktree reads not_advancing with its idle age; a moving one reads advancing" load
    else
        add_row "runner_advance_reads_the_worktree" false "the reader did not separate a flat worktree from a moving one: $(one_line "$_r")" load
    fi

    # 2. EVERY RUNNER FROZEN, EVERY CLAIM READABLE — the one case a name can be answered
    #    exactly, and the only one that frees a slot.
    _f=$(sh "$_reader" --names implement,implement-2 "${_tmp}/frozen" 2>&1 || true)
    if printf '%s' "$_f" | jq -e '
        (.frozen_count == 2) and (.advancing == 0) and (.running == 2)
        and ([.names[] | select(.verdict=="not_advancing")] | length == 2)' >/dev/null 2>&1; then
        add_row "runner_advance_names_a_frozen_runner" true "with no claim advancing and every claim readable, both names read not_advancing and frozen_count is 2" load
    else
        add_row "runner_advance_names_a_frozen_runner" false "a wholly frozen fixture did not name its runners: $(one_line "$_f")" load
    fi

    # 3. NOTHING BINDS A LOOP NAME TO A WORKTREE, and the reader refuses rather than guessing.
    #    A claim is keyed by unit and `loop-finish-<name>` by role; with some runners advancing
    #    and some not, WHICH name is frozen is not derivable, so every name is `unreadable`.
    if printf '%s' "$_r" | jq -e '
        ([.names[] | select(.verdict=="unreadable" and .reason=="ambiguous_binding")] | length == 2)
        and (.frozen_count == 0)' >/dev/null 2>&1; then
        add_row "runner_advance_refuses_the_binding" true "a partially frozen fixture refuses ambiguous_binding by name and frees nothing" load
    else
        add_row "runner_advance_refuses_the_binding" false "the reader guessed at a binding it cannot make: $(one_line "$_r")" load
    fi

    # 4. AN UNREADABLE READING FREES NOTHING, in every one of its forms. This is the repository's
    #    standing rule — a gate that cannot be read is not a gate — and it is the whole safety
    #    property of this reader: `frozen_count` counts only names actually answered
    #    `not_advancing`, so no consumer can spend a reading the reader refused to make.
    _n=$(sh "$_reader" --names implement "${_tmp}/none" 2>&1 || true)
    _b=$(sh "$_reader" --names implement "${_tmp}/blind" 2>&1 || true)
    _w=$(WORKAHOLIC_RUNNER_ADVANCE_STALE_MINUTES=nope sh "$_reader" --names implement "${_tmp}/frozen" 2>&1 || true)
    _p=$(sh "$_reader" --names propose,moderate "${_tmp}/frozen" 2>&1 || true)
    _ok_unreadable=true
    #    No claim worktree at all: a runner still surveying has claimed nothing yet, so nothing
    #    here distinguishes it from a frozen one.
    printf '%s' "$_n" | jq -e '(.names[0].verdict=="unreadable") and (.names[0].reason=="no_claim_evidence") and (.frozen_count == 0)' >/dev/null 2>&1 || _ok_unreadable=false
    #    A claim whose files could not be read at all: "none is advancing" is not established.
    printf '%s' "$_b" | jq -e '(.names[0].verdict=="unreadable") and (.names[0].reason=="claim_evidence_incomplete") and (.frozen_count == 0)' >/dev/null 2>&1 || _ok_unreadable=false
    #    A window that is not a number holds nothing and says so.
    printf '%s' "$_w" | jq -e '(.readable == false) and (.reason == "bad_window") and (.frozen_count == null)' >/dev/null 2>&1 || _ok_unreadable=false
    #    A role that holds no claim leaves no evidence, so it is refused rather than assumed healthy.
    printf '%s' "$_p" | jq -e '([.names[] | select(.verdict=="unreadable" and .reason=="role_holds_no_claim")] | length == 2) and (.frozen_count == 0)' >/dev/null 2>&1 || _ok_unreadable=false
    if [ "$_ok_unreadable" = "true" ]; then
        add_row "runner_advance_unreadable_frees_nothing" true "no_claim_evidence, claim_evidence_incomplete, bad_window and role_holds_no_claim each name themselves and free no slot" load
    else
        add_row "runner_advance_unreadable_frees_nothing" false "an unreadable reading was rendered as a verdict or freed a slot: $(one_line "$_n") / $(one_line "$_b") / $(one_line "$_w") / $(one_line "$_p")" load
    fi

    # 5. A SUCCESSFUL READ CARRIES NO `readable` FIELD — the `merge_policy` / `status:`
    #    convention, so a consumer tests `readable == false` and never `readable // true`.
    if printf '%s' "$_f" | jq -e 'has("readable") | not' >/dev/null 2>&1; then
        add_row "runner_advance_absent_means_complete" true "a completed read emits no readable field" load
    else
        add_row "runner_advance_absent_means_complete" false "a completed read emitted a readable field: $(one_line "$_f")" load
    fi

    # 6. IT IS A PURE READ. It stops no agent, writes nothing and makes no network call — the
    #    fixture it just read must be byte-identical afterwards.
    _fx_before=$(find "${_tmp}/frozen" -type f -printf '%p %T@\n' 2>/dev/null | sort)
    sh "$_reader" --names implement,implement-2 "${_tmp}/frozen" >/dev/null 2>&1 || true
    _fx_after=$(find "${_tmp}/frozen" -type f -printf '%p %T@\n' 2>/dev/null | sort)
    if [ "$_fx_before" = "$_fx_after" ]; then
        add_row "runner_advance_writes_nothing" true "the reader left the fixture byte-identical" load
    else
        add_row "runner_advance_writes_nothing" false "the reader wrote into the tree it read" load
    fi

    # 7. THE SLOT ARITHMETIC, SPENT ON THE READER'S OWN ANSWER (2026-09-06, ticket
    #    `stop-counting-a-non-advancing-runner-toward-the-fan-out`). Rows 1-6 prove what the
    #    reader ANSWERS; this proves what the allocation DOES with the answer, which is the
    #    behaviour the ticket actually buys. The fan-out is `bound − (running − not_advancing)`,
    #    composed by the agent at run time, so it is computed here from the reader's own output
    #    rather than asserted as a sentence somewhere.
    #
    #    `running` IS THE LISTING'S NUMBER, NOT THE READER'S, and that is the whole safety
    #    property. On a degraded read this reader answers `running: null` BESIDE
    #    `frozen_count: null` (measured: `bad_window` returns both), so an implementation that
    #    took both from it would compute `bound − (null − null)` and hand back EVERY slot on a
    #    reading nobody made — the exact inversion of "an unreadable reading frees nothing".
    #    Only `not_advancing` is the reader's, and an absent count spends as zero.
    _alloc() {  # _alloc <reader-json> <bound> <running-from-the-listing>
        _af=$(printf '%s' "$1" | jq -r '.frozen_count // 0' 2>/dev/null || printf 0)
        printf '%s' "$(( $2 - ($3 - _af) ))"
    }
    _ok_alloc=true
    #    Two runners, both frozen, bound 2: every slot comes back. `bound − running` allowed 0.
    [ "$(_alloc "$_f" 2 2)" = "2" ] || _ok_alloc=false
    #    The SAME fixture read through a window that is not a number frees NOTHING.
    [ "$(_alloc "$_w" 2 2)" = "0" ] || _ok_alloc=false
    #    One frozen and one advancing, the binding refused: nothing may be spent.
    [ "$(_alloc "$_r" 2 2)" = "0" ] || _ok_alloc=false
    #    A role holding no claim frees nothing, and neither does a claim read incompletely.
    [ "$(_alloc "$_p" 2 2)" = "0" ] || _ok_alloc=false
    [ "$(_alloc "$_b" 2 1)" = "1" ] || _ok_alloc=false
    if [ "$_ok_alloc" = "true" ]; then
        add_row "runner_advance_frees_the_slot" true "a wholly frozen fixture gives back every fan-out slot, and each unreadable form -- including the one whose counts are null -- gives back none" load
    else
        add_row "runner_advance_frees_the_slot" false "the fan-out arithmetic over the reader's own output did not free a frozen runner's slot, or freed one on a reading nobody made" load
    fi

    # 8. THE BREAKER, LABELLED AS THE INTENTIONAL FAILURE. Wire the reader so a claim whose
    #    files cannot be read counts as flat rather than unreadable, and the `blind` fixture —
    #    one flat claim beside one that could not be read at all — must then report a runner
    #    `not_advancing` and free its slot, on evidence that was never established. A breaker
    #    satisfied by keeping the JSON shape proves nothing.
    _broken="${_tmp}/broken-reader.sh"
    sed 's/unreadable_claims=\$((unreadable_claims + 1))/:/' "$_reader" > "$_broken"
    chmod +x "$_broken"
    _bb=$(sh "$_broken" --names implement "${_tmp}/blind" 2>&1 || true)
    if printf '%s' "$_bb" | jq -e '(.names[0].verdict=="not_advancing") and (.frozen_count == 1)' >/dev/null 2>&1; then
        add_row "runner_advance_breaker" true "with an unreadable claim counted as flat the reader frees a slot on evidence it never had (this drill can fail)" breaker
    else
        add_row "runner_advance_breaker" false "the breaker did not break: an unreadable claim counted as flat still refused ($(one_line "$_bb")), so row 4 proves nothing" breaker
    fi

    # 9. NOTHING WAS WRITTEN OUTSIDE THE FIXTURE.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "runner_advance_writes_nothing_outside_the_fixture" true "the checkout is byte-identical after the drill" load
    else
        add_row "runner_advance_writes_nothing_outside_the_fixture" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "runner-advance" 0 "fail" 1
    fi
    emit_verdict "runner-advance" 0 "pass" 0
}

# ------------------------------------------------------- verify-announced-asks
# THE FINISHED ASK WHOSE THREAD NEVER HEARD (2026-09-03, mission
# `announce-an-ask-that-landed-outside-a-unit-route-in-its-own-thread`).
#
# `🟢 Implemented` is a PER-UNIT post of `/implement`'s route step, so an ask whose work landed
# through a session working it directly reaches no route step at all and its thread ends at the
# `📥 受理` receipt. Measured 2026-09-02: three merged pull requests, the issue closed, and the
# operator found out by asking a session.
#
# WHAT IS DRILLABLE AND WHAT IS NOT. The POST is an agent act through the connector, and this
# repository already says of the Japanese rule that what a run actually emits is checkable by
# nothing — so the drill covers the two halves that ARE mechanical: the reader that decides
# which items to look at, and the command's route to the one shape catalog. The
# announce-once behaviour is the thread read, which by design leaves no trace in the
# repository; asserting it here would be asserting a fixture, not the mechanism.
#
# HERMETIC. The fixture is a throwaway git repository this function builds and a `gh` stub on
# `PATH` that answers from files. No network, no real `gh`, no Slack, no `origin`, no credential.
#
# THE BREAKER IS WRITTEN AGAINST THE BEHAVIOUR, not the return shape: wire the reader so a
# refused listing answers `ok: true` with an empty candidate list instead of `ok: false` with
# its reason, and a blind hour must then be indistinguishable from a quiet one. That is the
# only way this reading can do harm — the tick would report `no_candidates` over an hour it
# could not see, and this repository has twice measured a reader rendering its own blindness as
# *nothing found*. Without the breaker, rows 4 and 5 could pass against a reader that never had
# the distinction.
