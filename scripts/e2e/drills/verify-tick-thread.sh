cmd_verify_tick_thread() {
    _mod="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts"
    _key="${_mod}/lib/tick-thread-key.sh"
    _render="${_mod}/render-tick-post.sh"
    _log="${_mod}/log-append.sh"
    _stuck="${_mod}/step-stuck-prs.sh"
    for _f in "$_key" "$_render" "$_log" "$_stuck"; do
        [ -f "$_f" ] || emit_err "tick_thread_unreadable" 4 "$_f is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    _tmp=$(mktemp -d)
    _fx="${_tmp}/fx"
    mkdir -p "${_fx}/.workaholic"

    # THE ZONE IS NAMED, never inherited. The key is the operator's day, so a drill reading
    # whatever zone the runner happens to carry would pass or fail by geography.
    _tz=Asia/Tokyo
    _keyof() { WORKAHOLIC_QUIET_TZ="$_tz" sh "$_key" "$1" 2>/dev/null | sed -n 's/.*"key": "\([^"]*\)".*/\1/p'; }

    # 1. ONE DAY, ONE KEY. Two ticks an hour apart resolve the same string, which is the whole
    #    point: under `tick:<tick-id>` this fails by construction, because the string an hour
    #    searches for is one no earlier message can contain.
    _k1=$(_keyof 20260901-020000)
    _k2=$(_keyof 20260901-030000)
    if [ -n "$_k1" ] && [ "$_k1" = "$_k2" ]; then
        add_row "tick_thread_one_day_one_key" true "two ticks an hour apart on one local day resolve one key (${_k1})" load
    else
        add_row "tick_thread_one_day_one_key" false "the hour still keys the root: ${_k1} vs ${_k2}" load
    fi

    # 2. AND THE DAY STILL ENDS — the opposite row. A key that never changed would put a week
    #    in one thread, which is the failure a coarser key would introduce.
    _k3=$(_keyof 20260901-140000)
    _k4=$(_keyof 20260901-160000)
    if [ -n "$_k3" ] && [ -n "$_k4" ] && [ "$_k3" != "$_k4" ]; then
        add_row "tick_thread_day_boundary_splits" true "ticks either side of the local day boundary get their own root (${_k3} vs ${_k4})" load
    else
        add_row "tick_thread_day_boundary_splits" false "the local day boundary opened no new root: ${_k3} vs ${_k4}" load
    fi

    # 3. THE KEY IS A FUNCTION OF THE TICK AND THE ZONE AND NOTHING ELSE — stable across a
    #    re-entered tick, and never a recency match, which is what keeps
    #    `workaholic:notify`'s fuzzy-match prohibition true rather than carved out.
    if [ "$(_keyof 20260901-020000)" = "$_k1" ]; then
        add_row "tick_thread_key_is_stable" true "the same tick id derives the same key twice — an exact string, never recency" load
    else
        add_row "tick_thread_key_is_stable" false "the key moved between two reads of one tick id" load
    fi

    # --- the post gate -----------------------------------------------------------------
    # `render-tick-post.sh` compares `(step, status, stabilized summary)` against the previous
    # tick's. `stuck-prs` is `blocked`, so it rides the IMPAIRMENT diff — the path by which a
    # per-pull state list opened a root every time GitHub reassigned a class.
    _mkrun() {
        printf '{"tick": "fixture", "steps": [{"step": "open-log", "status": "ok", "reason": "", "summary": "log opened", "needs_agent": 0, "logged": true, "event": ""}, {"step": "stuck-prs", "status": "blocked", "reason": "", "summary": "%s", "needs_agent": 0, "logged": true, "event": ""}]}\n' "$1"
    }
    _logtick() {
        sh "$_log" --root "$_fx" --tick "$1" --step open-log --status ok --summary "log opened" >/dev/null 2>&1 || true
        sh "$_log" --root "$_fx" --tick "$1" --step stuck-prs --status blocked --summary "$2" >/dev/null 2>&1 || true
    }
    _render_at() {
        sh "$_render" --tick "$1" --root "$_fx" --questions 0 --hour 10 --weekday 3 < "$2" 2>&1 || true
    }

    _s_same='2 pull requests stuck: conflict, review — candidates for step 10, never a status post'
    _s_grew='3 pull requests stuck: checks, conflict, review — candidates for step 10, never a status post'
    _logtick 20260901-020000 "$_s_same"

    # 4. A RE-SHUFFLE IS SILENT. The same two pull requests and the same two classes, only
    #    which one holds which has moved — so the summary is unchanged and the gate has
    #    nothing to say. Under the old summary the pair list differed and this posted.
    _mkrun "$_s_same" > "${_tmp}/same.json"
    _same=$(_render_at 20260901-030000 "${_tmp}/same.json")
    case "$_same" in
        *'"post": false'*) add_row "tick_thread_reshuffle_is_silent" true "a summary that moved only because a transport answered differently opens no root" load ;;
        *) add_row "tick_thread_reshuffle_is_silent" false "a transport re-shuffle still opened a root: $(one_line "$_same")" load ;;
    esac

    # 5. AND THE SET MOVING STILL SPEAKS — the row that stops row 4 passing because everything
    #    went quiet. A pull request entering the stuck set changes the count and the class set.
    _mkrun "$_s_grew" > "${_tmp}/grew.json"
    _grew=$(_render_at 20260901-030000 "${_tmp}/grew.json")
    case "$_grew" in
        *'"post": true'*) add_row "tick_thread_set_change_speaks" true "a pull request entering the stuck set still opens a root" load ;;
        *) add_row "tick_thread_set_change_speaks" false "a real change to the stuck set was swallowed: $(one_line "$_grew")" load ;;
    esac

    # 6. TWO FORMS OFF ONE BODY. The day's first speaking tick posts `root_text`; every later
    #    one posts `reply_text`, the same body WITHOUT the head. A reply that restated the head
    #    would be the hourly root under another name.
    _rt=$(printf '%s' "$_grew" | sed -n 's/.*"root_text": "\([^"]*\)".*/\1/p' | head -1)
    _ry=$(printf '%s' "$_grew" | sed -n 's/.*"reply_text": "\([^"]*\)".*/\1/p' | head -1)
    _in_root=no; _in_reply=no
    case "$_rt" in *Moderation*) _in_root=yes ;; esac
    case "$_ry" in *Moderation*) _in_reply=yes ;; esac
    if [ "$_in_root" = yes ] && [ "$_in_reply" = no ] && [ -n "$_ry" ]; then
        add_row "tick_thread_reply_has_no_head" true "the delta reply carries the hour's lines and no restated head" load
    else
        add_row "tick_thread_reply_has_no_head" false "root_head=${_in_root} reply_head=${_in_reply} reply=$(one_line "$_ry")" load
    fi

    # 7. AND NEITHER FORM CARRIES A MENTION TOKEN. A change line names a repository event and
    #    asks nobody for anything; the mention belongs on the question below it.
    case "${_rt}${_ry}" in
        *'<@'*) add_row "tick_thread_carries_no_mention" false "a mention token reached an orientation post" load ;;
        *) add_row "tick_thread_carries_no_mention" true "neither the root nor the delta reply carries a mention token" load ;;
    esac

    # 8. A HELD TICK POSTS NEITHER FORM. Every gate above this is untouched: outside the
    #    speaking window there is no root and no reply, and `reply_text` is empty exactly as
    #    `root_text` has always been.
    _quiet=$(sh "$_render" --tick 20260901-030000 --root "$_fx" --questions 0 --hour 3 --weekday 3 < "${_tmp}/grew.json" 2>&1 || true)
    _held_ok=no
    case "$_quiet" in *'"post": false'*) case "$_quiet" in *'"reply_text": ""'*) _held_ok=yes ;; esac ;; esac
    if [ "$_held_ok" = yes ]; then
        add_row "tick_thread_held_tick_posts_neither" true "a tick the speaking window holds renders neither a root nor a reply" load
    else
        add_row "tick_thread_held_tick_posts_neither" false "a held tick rendered something: $(one_line "$_quiet")" load
    fi

    # --- the value handed to the gate ---------------------------------------------------
    # Rows 4 and 5 are about the gate; these are about what the step puts into it, driven
    # through the REAL step against a stub `gh`.
    _repo="${_tmp}/repo"
    mkdir -p "$_repo"
    ( cd "$_repo" && git init -q . && git remote add origin https://github.com/qmu/drill.git ) >/dev/null 2>&1 || true
    _stub() { # $1 dir  $2 n1 $3 mergeable1 $4 state1  $5 n2 $6 mergeable2 $7 state2
        mkdir -p "$1"
        cat > "$1/gh" <<STUB
#!/bin/sh
path=""; jqexpr=""; seen=0
while [ \$# -gt 0 ]; do
  case "\$1" in
    api) seen=1 ;;
    --jq) jqexpr="\$2"; shift ;;
    -*) ;;
    *) if [ "\$seen" = 1 ] && [ -z "\$path" ]; then path="\$1"; fi ;;
  esac
  shift
done
emit() { if [ -n "\$jqexpr" ]; then printf '%s' "\$1" | jq -r "\$jqexpr"; else printf '%s' "\$1"; fi; }
case "\$path" in
  repos/*/pulls/$2) emit '{"number": $2, "html_url": "https://x/$2", "head": {"ref": "work-20260901-010101"}, "draft": false, "mergeable": $3, "mergeable_state": "$4", "title": "One"}' ;;
  repos/*/pulls/$5) emit '{"number": $5, "html_url": "https://x/$5", "head": {"ref": "work-20260901-010101"}, "draft": false, "mergeable": $6, "mergeable_state": "$7", "title": "One"}' ;;
  repos/*/pulls[?]*) emit '[{"number": $2}, {"number": $5}]' ;;
  *) emit '[]' ;;
esac
STUB
        chmod +x "$1/gh"
    }
    _stub "${_tmp}/binA" 41 false dirty 42 true blocked
    _stub "${_tmp}/binB" 41 true blocked 42 false dirty
    _field_of() { # $1 script  $2 stub dir  $3 field
        ( cd "$_repo" && PATH="$2:$PATH" sh "$1" --tick 20260901-030000 --root . 2>/dev/null ) \
            | sed -n "s/.*\"$3\": \"\([^\"]*\)\".*/\1/p" | head -1
    }

    # 9. THE STEP NO LONGER PUTS A PER-PULL STATE LIST IN THE COMPARED STRING.
    _sa=$(_field_of "$_stuck" "${_tmp}/binA" summary)
    _sb=$(_field_of "$_stuck" "${_tmp}/binB" summary)
    if [ -n "$_sa" ] && [ "$_sa" = "$_sb" ]; then
        add_row "tick_thread_summary_drops_the_pair_list" true "the step's compared summary is identical across a class re-shuffle (${_sa})" load
    else
        add_row "tick_thread_summary_drops_the_pair_list" false "the step still varies its summary with the transport's answer: [${_sa}] vs [${_sb}]" load
    fi

    # 10. THE QUESTION SIDE LOSES NOTHING. The coarsening is of the compared string alone — the
    #     ask key still moves with the per-pull state, so the ledger can still tell one state
    #     from another and nothing a person is asked loses detail.
    _ka=$(_field_of "$_stuck" "${_tmp}/binA" ask_key)
    _kb=$(_field_of "$_stuck" "${_tmp}/binB" ask_key)
    if [ -n "$_ka" ] && [ "$_ka" != "$_kb" ]; then
        add_row "tick_thread_ask_key_keeps_the_detail" true "the ask key still moves with the per-pull state (${_ka} vs ${_kb})" load
    else
        add_row "tick_thread_ask_key_keeps_the_detail" false "the coarsening reached the ask key: ${_ka} vs ${_kb}" load
    fi

    # 11. THE BREAKER, LABELLED AS THE INTENTIONAL FAILURE and written against BOTH behaviours,
    #     because reverting either one alone must turn this drill red. Half A restores the
    #     per-tick key; half B restores the pair list in the compared summary.
    #
    #     THE COPY KEEPS THE PLUGIN'S OWN SHAPE (`skills/<name>/scripts`) because
    #     `pulls-state.sh` reaches `../../gather/scripts` for the one GitHub transport; a flat
    #     copy would fail for the wrong reason and the breaker would "break" without proving
    #     anything.
    _bskills="${_tmp}/skills"
    mkdir -p "${_bskills}/moderate"
    cp -R "$_mod" "${_bskills}/moderate/scripts"
    ln -s "${REPO_ROOT}/plugins/workaholic/skills/gather" "${_bskills}/gather"
    _broken="${_bskills}/moderate/scripts"
    sed 's|TTK_KEY="tick-day:${_ttk_day}"|TTK_KEY="tick:${1:-}"|' "$_key" > "${_broken}/lib/tick-thread-key.sh"
    #     THE ARGUMENT LINE CARRIES `$uncomputed` SINCE 2026-09-02 (mission
    #     `resolve-a-conflicted-pull-request-in-the-tick-not-report-it`), so the anchor matches
    #     it. This is the failure mode a breaker has that an ordinary assertion does not: when
    #     the anchor stops matching, half B silently does not apply and the drill reports
    #     `noisy=no` — which is the breaker doing its job, saying the rows above no longer prove
    #     anything. Re-anchor it rather than relaxing the pattern; a loose anchor is a breaker
    #     that stops noticing.
    sed -e 's|"summary": "%s — candidates for step 10|"summary": "%s (%s) — candidates for step 10|' \
        -e 's|^    "\$HEADLINE" "\$HEADLINE" "\$needs" "\$ASK_KEY" "\$uncomputed"$|    "$HEADLINE" "$pairs" "$HEADLINE" "$needs" "$ASK_KEY" "$uncomputed"|' \
        "$_stuck" > "${_broken}/step-stuck-prs.sh"
    chmod +x "${_broken}/lib/tick-thread-key.sh" "${_broken}/step-stuck-prs.sh"

    _bk1=$(WORKAHOLIC_QUIET_TZ="$_tz" sh "${_broken}/lib/tick-thread-key.sh" 20260901-020000 2>/dev/null | sed -n 's/.*"key": "\([^"]*\)".*/\1/p')
    _bk2=$(WORKAHOLIC_QUIET_TZ="$_tz" sh "${_broken}/lib/tick-thread-key.sh" 20260901-030000 2>/dev/null | sed -n 's/.*"key": "\([^"]*\)".*/\1/p')
    _bsa=$(_field_of "${_broken}/step-stuck-prs.sh" "${_tmp}/binA" summary)
    _bsb=$(_field_of "${_broken}/step-stuck-prs.sh" "${_tmp}/binB" summary)
    _hourly=no; _noisy=no
    [ -n "$_bk1" ] && [ "$_bk1" != "$_bk2" ] && _hourly=yes
    [ -n "$_bsa" ] && [ "$_bsa" != "$_bsb" ] && _noisy=yes
    if [ "$_hourly" = yes ] && [ "$_noisy" = yes ]; then
        add_row "tick_thread_breaker" true "with the day key and the coarsened summary reverted, the hour keys its own root AND a re-shuffle moves the compared string (this drill can fail)" breaker
    else
        add_row "tick_thread_breaker" false "the breaker did not break: hourly=${_hourly} noisy=${_noisy}, so the rows above prove nothing" breaker
    fi

    # 12. NOTHING WAS WRITTEN OUTSIDE THE FIXTURE.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "tick_thread_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "tick_thread_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "tick-thread" 0 "fail" 1
    fi
    emit_verdict "tick-thread" 0 "pass" 0
}

# ------------------------------------------------------- verify-retired-claim

# A CLAIM WHOSE MISSION HAS ENDED, AND THE QUESTION IT MUST NO LONGER DRAW (2026-09-02, mission
# `retire-a-claim-whose-work-is-finished-or-abandoned`).
#
# Measured: the operator closed a pull request and closed its mission `abandoned`, and the tick
# reported that branch as stuck work every hour until a person deleted it by hand. Two readings
# ship for it and they are two halves of one behaviour — the retirement path must OWN such a
# claim, and the stuck-work question must stop being asked about it — so one drill walks both.
# Split in two, each half would pass while the pair stayed broken: a candidate nobody filters on
# and a filter with nothing to filter are each individually green.
#
# THE MECHANISM IS DESTRUCTIVE, so what is drilled is precisely what must not happen: a branch
# whose mission is still ACTIVE being offered, and a claim a run is DRIVING being offered however
# ended its mission.
#
# IT IS HERMETIC. Everything but the pull-request state is derived from a local fixture; that one
# fact is stubbed at the `gh` seam. No network, no credential.
#
# THE BREAKER IS WRITTEN AGAINST THE BEHAVIOUR: the ended mission is moved back to `active/` and
# the candidate must disappear. A reader that ignored the mission — the whole defect — would
# offer the branch in both states, so a refactor that keeps the JSON shape and loses the bound
# still turns this row red.
