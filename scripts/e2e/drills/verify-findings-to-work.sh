cmd_verify_findings_to_work() {
    _mod="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts"
    _step="${_mod}/step-file-findings.sh"
    _ledger="${_mod}/list-finding-issues.sh"
    _supp="${_mod}/finding-suppression.sh"
    _filer="${REPO_ROOT}/plugins/workaholic/skills/propose/scripts/file-inbound-ask.sh"
    _table="${REPO_ROOT}/plugins/workaholic/skills/moderate/reference/workflow.md"
    for _f in "$_step" "$_ledger" "$_supp" "$_filer" "$_table"; do
        [ -f "$_f" ] || emit_err "findings_unreadable" 4 "$_f is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _tmp=$(mktemp -d)
    _bin="${_tmp}/bin"
    _fx="${_tmp}/fx"
    mkdir -p "$_bin" "${_fx}/.workaholic"
    git -C "$_fx" init -q . >/dev/null 2>&1 || true
    git -C "$_fx" remote add origin git@github.com:acme-org/drill-repo.git >/dev/null 2>&1 || true

    _fid=$(sh -c ". ${_mod}/lib/question-id.sh; question_slug 'finding:retire-claims'")

    # THE STUB IS THE WHOLE NETWORK. It serves the issues listing, applies `--jq` with real jq
    # so the reader's own parse is what is exercised, and records every POST body so the filing
    # can be inspected without opening anything. Any other call exits non-zero: a drill that
    # silently reached the network would be proving nothing about an offline container.
    cat > "${_bin}/gh" <<EOF
#!/bin/sh
_filter=""; _prev=""; _post=0
for a in "\$@"; do
  if [ "\$_prev" = "--jq" ]; then _filter="\$a"; fi
  if [ "\$a" = "POST" ]; then _post=1; fi
  _prev="\$a"
done
if [ "\$_post" = "1" ]; then
  cat > "${_tmp}/posted.json"
  printf '{"number": 42, "html_url": "https://example.invalid/42"}\n'
  exit 0
fi
case "\$*" in
  *"api user"*) printf 'drill-bot\n'; exit 0 ;;
  *"issues?state=all"*)
    case "\${WH_LEDGER:-empty}" in
      empty)  _body='[]' ;;
      open)   _body='[{"number":9,"html_url":"https://example.invalid/9","state":"open","body":"finding: retire-claims / id: ${_fid}\\n"}]' ;;
      closed) _body='[{"number":9,"html_url":"https://example.invalid/9","state":"closed","body":"finding: retire-claims / id: ${_fid}\\n"}]' ;;
      broken) exit 1 ;;
    esac ;;
  *) exit 1 ;;
esac
if [ -n "\$_filter" ]; then printf '%s' "\$_body" | jq -r "\$_filter"; else printf '%s' "\$_body"; fi
EOF
    chmod +x "${_bin}/gh"

    # THE FIXTURE: one repairable finding with an event, one repairable finding that DEGRADED
    # (our own machinery failing is the loop's debt too), one repairable step that found
    # nothing, and one `needs_ruling` step shouting as loudly as it can.
    cat > "${_tmp}/reports.json" <<'EOF'
{"steps": [
 {"step": "retire-claims", "status": "ok", "reason": "", "summary": "1 blocked", "needs_agent": 0, "logged": true, "event": "a claim branch CI could not delete"},
 {"step": "inbound-sweep", "status": "degraded", "reason": "channel_unreadable", "summary": "the channel could not be read", "needs_agent": 0, "logged": true, "event": ""},
 {"step": "doc-drift", "status": "ok", "reason": "", "summary": "no new drift", "needs_agent": 0, "logged": true, "event": ""},
 {"step": "undrivable-units", "status": "blocked", "reason": "", "summary": "2 undrivable", "needs_agent": 2, "logged": true, "event": "2 queued artifacts nobody can drive"}
]}
EOF
    _run_step() {
        ( cd "$_fx" && PATH="${_bin}:${PATH}" WH_LEDGER="$1" \
            WORKAHOLIC_TICK_REPORTS="${_tmp}/reports.json" \
            sh "${2:-$_step}" --tick 20260829-060000 --root "$_fx" 2>&1 || true )
    }
    _cands() { printf '%s' "$1" | jq -r '[.needs_agent[0].candidates[]?.step] | join(",")' 2>/dev/null || printf ''; }
    _field() { printf '%s' "$1" | jq -r "$2" 2>/dev/null || printf ''; }

    # 1. THE CLASSIFICATION NAMES EACH FINDING. The repairable ones become candidates; the
    #    `needs_ruling` one never does. This is the mission's whole safety property.
    _free=$(_run_step empty)
    if [ "$(_cands "$_free")" = "retire-claims,inbound-sweep" ]; then
        add_row "findings_classified" true "both repairable findings are candidates and only those" load
    else
        add_row "findings_classified" false "expected retire-claims,inbound-sweep; got '$(_cands "$_free")' ($(one_line "$_free"))" load
    fi
    case "$(one_line "$_free")" in
        *undrivable-units*)
            add_row "findings_ruling_never_filed" false "a needs_ruling finding reached the filing act" load ;;
        *)
            add_row "findings_ruling_never_filed" true "the needs_ruling finding never reaches the filer, however loudly it reported" load ;;
    esac

    # 2. THE BRAKE HOLDS WHILE ONE IS OPEN, AND RELEASES WHEN IT IS CLOSED.
    _held=$(_run_step open)
    if [ "$(_field "$_held" '.reason')" = "brake_held" ] && [ -z "$(_cands "$_held")" ]; then
        add_row "findings_brake_holds" true "with one finding issue open nothing is filed: $(_field "$_held" '.summary')" load
    else
        add_row "findings_brake_holds" false "the brake did not hold: $(one_line "$_held")" load
    fi
    _closed=$(_run_step closed)
    if [ "$(_cands "$_closed")" = "inbound-sweep" ]; then
        add_row "findings_brake_releases" true "closing the issue releases the brake, and the dedup still drops the finding it carried" load
    else
        add_row "findings_brake_releases" false "expected inbound-sweep alone; got '$(_cands "$_closed")'" load
    fi

    # 3. AN UNREADABLE BRAKE FILES NOTHING AND SAYS SO — distinctly from a held one, because
    #    *one is in flight* and *I could not look* are different facts about the loop.
    _blind=$(_run_step broken)
    if [ "$(_field "$_blind" '.reason')" = "brake_unreadable" ] && [ -z "$(_cands "$_blind")" ]; then
        add_row "findings_brake_unreadable" true "an unreadable ledger files nothing under its own reason" load
    else
        add_row "findings_brake_unreadable" false "expected brake_unreadable with no candidates: $(one_line "$_blind")" load
    fi

    # 4. THE FILING GOES THROUGH THE ONE FILER, WITH THE MARKER AND THE DIRECTION LINE.
    printf 'The tick could not delete a claim branch.\n' > "${_tmp}/body.md"
    _fil=$( cd "$_fx" && PATH="${_bin}:${PATH}" sh "$_filer" \
        --finding "retire-claims:${_fid}" --subject 'observer_ai:drill' --assignee drill-bot \
        --feedback '20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md' \
        acme-org/drill-repo '[FB] a claim branch CI could not delete' "${_tmp}/body.md" 2>&1 || true )
    _posted=$(cat "${_tmp}/posted.json" 2>/dev/null || printf '')
    _pbody=$(printf '%s' "$_posted" | jq -r '.body // ""' 2>/dev/null || printf '')
    case "$_pbody" in
        *"finding: retire-claims / id: ${_fid}"*)
            add_row "findings_marker_written" true "the one filer wrote the visible finding marker the next tick reads back" load ;;
        *)
            add_row "findings_marker_written" false "the marker is missing from the filed body: $(one_line "$_pbody")" load ;;
    esac
    case "$_pbody" in
        *"source: moderate"*"feedback: "*)
            add_row "findings_direction_carried" true "the direction line rides the issue, through the one writer of that line" load ;;
        *)
            add_row "findings_direction_carried" false "expected source: moderate and a feedback line: $(one_line "$_pbody")" load ;;
    esac

    # 5. A SECOND TICK FILES NOTHING. The dedup is STRUCTURAL: the issues are the memory, so
    #    nothing is stored and no cursor exists to forget.
    _second=$(_run_step open)
    if [ -z "$(_cands "$_second")" ]; then
        add_row "findings_second_tick_files_nothing" true "the finding filed by the first tick is not offered again" load
    else
        add_row "findings_second_tick_files_nothing" false "a second tick re-offered: $(_cands "$_second")" load
    fi

    # 6. THE FILED SUBJECT'S QUESTION IS HELD WHILE THE UNFILED ONE STILL ASKS. Keyed on the
    #    SUBJECT: suppressing on `any_open` would silence the whole question queue behind one
    #    filing, which is the bug this is written against.
    _s=$( cd "$_fx" && PATH="${_bin}:${PATH}" WH_LEDGER=open sh "$_supp" 2>&1 || true )
    _hs=$(_field "$_s" '.held.steps | join(",")')
    if [ "$_hs" = "retire-claims" ]; then
        add_row "findings_question_held" true "the filed step's question is held and no other step's is" load
    else
        add_row "findings_question_held" false "expected retire-claims held alone; got '${_hs}'" load
    fi
    _sblind=$( cd "$_fx" && PATH="${_bin}:${PATH}" WH_LEDGER=broken sh "$_supp" 2>&1 || true )
    if [ "$(_field "$_sblind" '.readable')" = "false" ] && [ "$(_field "$_sblind" '.held.steps | length')" = "0" ]; then
        add_row "findings_unreadable_holds_nothing" true "an unreadable suppression read holds nothing and names its reason" load
    else
        add_row "findings_unreadable_holds_nothing" false "an unreadable read suppressed something: $(one_line "$_sblind")" load
    fi

    # 7. FILED, HELD AND LEFT RENDER AS THREE DISTINCT STATEMENTS.
    if [ "$(_field "$_held" '.held | length')" = "2" ] \
       && [ "$(_field "$_closed" '.already_filed | length')" = "1" ] \
       && [ "$(_field "$_free" '.left')" = "1" ]; then
        add_row "findings_reported_three_ways" true "held, already-filed and left are three separate readings on one output" load
    else
        add_row "findings_reported_three_ways" false "the three readings did not separate: held=$(_field "$_held" '.held|length') already=$(_field "$_closed" '.already_filed|length') left=$(_field "$_free" '.left')" load
    fi
    if [ "$(_field "$_free" '.event')" = "" ]; then
        add_row "findings_event_empty" true "the step claims no event: nothing is filed when run.sh reads its line" load
    else
        add_row "findings_event_empty" false "the step announced an act it has not taken: $(_field "$_free" '.event')" load
    fi

    # 8. THE BREAKER ROW, LABELLED AS THE INTENTIONAL FAILURE. Written against the BEHAVIOUR —
    #    a `needs_ruling` finding reaching the filer — rather than against a return shape, on
    #    `verify-checkin-delivery`'s own lesson: a breaker written against the shape passes a
    #    refactor that keeps the shape and loses the bound. Widen the classification to every
    #    finding and row 1 must fail.
    # The WHOLE plugin tree is copied (`verify-residue`'s shape): the step reaches its ledger,
    # which reaches `gather/scripts/gh-rest.sh` two directories up, so a copy of one scripts
    # directory would degrade on the missing closure and the breaker would "fail" for the wrong
    # reason — which is a breaker that proves nothing.
    _broken="${_tmp}/broken"
    mkdir -p "$_broken"
    cp -R "${REPO_ROOT}/plugins/workaholic/." "${_broken}/"
    sed 's/`needs_ruling` |/**`repairable`** |/g' "$_table" \
        > "${_broken}/skills/moderate/reference/workflow.md"
    _bout=$(_run_step empty "${_broken}/skills/moderate/scripts/step-file-findings.sh")
    case "$(_cands "$_bout")" in
        *undrivable-units*)
            add_row "findings_breaker" true "with the classification widened to every finding, a needs_ruling finding reaches the filer (this drill can fail)" breaker ;;
        *)
            add_row "findings_breaker" false "the breaker did not break: widening the classification changed nothing, so row 1 proves nothing ('$(_cands "$_bout")')" breaker ;;
    esac

    # 9. THE NEGATIVE SPACE: nothing outside the fixture was written, and no branch, pull
    #    request, merge or claim was touched — the only outward act available at all was the
    #    stubbed POST the filing makes.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "findings_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "findings_writes_nothing" false "the drill changed the working tree" load
    fi
    if [ -z "$(git -C "$_fx" branch --list 2>/dev/null)" ] \
       && [ ! -d "${_fx}/.worktrees" ] && [ ! -d "${_fx}/.publish" ]; then
        add_row "findings_touches_no_claim" true "no branch, worktree or publish tree was created" load
    else
        add_row "findings_touches_no_claim" false "the drill created a branch or a tree the tick may not create" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "findings-to-work" 0 "fail" 1
    fi
    emit_verdict "findings-to-work" 0 "pass" 0
}
