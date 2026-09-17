cmd_verify_announced_asks() {
    _reader="${REPO_ROOT}/plugins/workaholic/skills/propose/scripts/list-unannounced-closed-asks.sh"
    _catalog="${REPO_ROOT}/plugins/workaholic/skills/notify/reference/notifications.md"
    _ceiling="${REPO_ROOT}/plugins/workaholic/commands/infinite-development.md"
    for _f in "$_reader" "$_catalog" "$_ceiling"; do
        [ -f "$_f" ] || emit_err "announced_asks_unreadable" 4 "$_f is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    _tmp=$(mktemp -d)
    _fx="${_tmp}/fx"
    _bin="${_tmp}/bin"
    _fix="${_tmp}/fix"
    mkdir -p "${_fx}/.workaholic/feedbacks" "$_bin" "$_fix"

    (
        cd "$_fx" \
            && git init -q . >/dev/null 2>&1 \
            && git remote add origin git@github.com:acme-org/source-repo.git
    ) || emit_err "announced_asks_fixture" 4 "could not build the throwaway repository"

    printf -- '---\ntype: Feedback\n---\n\nSource: https://github.com/acme-org/source-repo/issues/917\n' \
        > "${_fx}/.workaholic/feedbacks/20260903052643-an-ask-that-landed.md"

    printf '[]' > "${_fix}/empty-array.json"
    printf '{}' > "${_fix}/empty-object.json"
    # One closed ask, and one ordinary closed issue that is not an ask at all.
    printf '%s' '[{"number":917,"closed_at":"2026-09-02T20:32:35Z","html_url":"https://github.com/acme-org/source-repo/issues/917","title":"[FB] an ask that landed","body":"kind: instruction\n"},{"number":700,"closed_at":"2026-09-02T10:00:00Z","html_url":"https://github.com/acme-org/source-repo/issues/700","title":"ordinary","body":"nothing\n"}]' \
        > "${_fix}/issues.json"
    printf '%s' '[{"event":"cross-referenced","source":{"issue":{"number":922,"title":"[Proposal] an ask that landed","html_url":"https://github.com/acme-org/source-repo/pull/922","pull_request":{"merged_at":"2026-09-02T20:32:34Z"}}}},{"event":"closed"}]' \
        > "${_fix}/timeline-917.json"
    printf '%s' '{"merged_by":{"login":"a-merger"}}' > "${_fix}/pull-922.json"

    # The stub dispatches on the endpoint and applies the `--jq` program the script passed,
    # because `gh api` applies it before any caller sees bytes. A stub printing raw JSON would
    # exercise a shape the real transport never produces.
    cat > "${_bin}/gh" <<STUB
#!/bin/sh
prog=""; url=""
while [ \$# -gt 0 ]; do
  case "\$1" in
    --jq) prog="\$2"; shift 2 ;;
    repos/*) url="\$1"; shift ;;
    *) shift ;;
  esac
done
FIX=${_fix}
f=""
case "\$url" in
  *"/timeline"*) n=\$(printf "%s" "\$url" | sed -e "s#.*/issues/##" -e "s#/timeline.*##")
    f="\$FIX/timeline-\$n.json"; [ -f "\$f" ] || f="\$FIX/empty-array.json" ;;
  *"/pulls/"*) n=\$(printf "%s" "\$url" | sed -e "s#.*/pulls/##" -e "s#[?].*##")
    f="\$FIX/pull-\$n.json"; [ -f "\$f" ] || f="\$FIX/empty-object.json" ;;
  *"/issues?"*) f="\$FIX/issues.json" ;;
esac
[ -n "\$f" ] && [ -f "\$f" ] || { echo "no fixture for \$url" >&2; exit 1; }
jq -r "\$prog" < "\$f"
STUB
    chmod +x "${_bin}/gh"
    cp "${_bin}/gh" "${_bin}/gh-real"

    _read() { ( cd "$_fx" && PATH="${_bin}:$PATH" sh "$_reader" --root "$_fx" 2>&1 ) || true; }

    # 1. THE ITEM GRAIN. `reconcile-candidates.sh` enumerates `work-*` pull requests and can
    #    never see this item; the reader names it and resolves its `fb:<stem>` thread key, and
    #    a closed issue matching neither keep term is not its subject at all.
    _r=$(_read)
    if printf '%s' "$_r" | jq -e '.ok == true and (.candidates | length == 1) and .candidates[0].number == 917 and .candidates[0].stem == "20260903052643-an-ask-that-landed"' >/dev/null 2>&1; then
        add_row "announced_reader_names_the_item" true "the closed ask is one candidate with its feedback stem resolved, and the ordinary closed issue is not" load
    else
        add_row "announced_reader_names_the_item" false "the reader did not name the item: $(one_line "$_r")" load
    fi

    # 2. WHAT LANDED. A finish line must say what merged and by whom; an item nothing merged is
    #    a DIFFERENT sentence and must not read alike.
    if printf '%s' "$_r" | jq -e '.candidates[0].landed | length == 1 and .[0].number == 922 and .[0].merged_by == "a-merger"' >/dev/null 2>&1 \
        && printf '%s' "$_r" | jq -e '.candidates[0].closed_unmerged == false and .candidates[0].landed_read == "ok"' >/dev/null 2>&1; then
        add_row "announced_candidate_carries_what_landed" true "the candidate carries the merged pull request, its merger and its merge time" load
    else
        add_row "announced_candidate_carries_what_landed" false "the candidate did not carry what landed: $(one_line "$_r")" load
    fi

    _hand=$(printf '%s' '[{"event":"closed"}]')
    printf '%s' "$_hand" > "${_fix}/timeline-917.json"
    _r2=$(_read)
    if printf '%s' "$_r2" | jq -e '.candidates[0].closed_unmerged == true and (.candidates[0].landed | length == 0) and .candidates[0].landed_read == "ok"' >/dev/null 2>&1; then
        add_row "announced_hand_closed_is_its_own_sentence" true "an issue closed with nothing merged reads closed_unmerged, positively" load
    else
        add_row "announced_hand_closed_is_its_own_sentence" false "a hand-closed item did not say so: $(one_line "$_r2")" load
    fi

    # 4. AN UNREADABLE LISTING IS NEVER AN EMPTY ONE. `ok: false` with a named reason and
    #    EXIT 0, and no candidate list at all for a caller to misread as *nothing to announce*.
    #    The tick holds silent on this and reports the reader's own reason verbatim.
    cat > "${_bin}/gh" <<'BLIND'
#!/bin/sh
echo "boom" >&2
exit 1
BLIND
    chmod +x "${_bin}/gh"
    _blind=$( ( cd "$_fx" && PATH="${_bin}:$PATH" sh "$_reader" --root "$_fx" 2>&1; printf ' exit=%s' "$?" ) || true)
    case "$_blind" in
        *'"ok": false'*'"reason": "list_failed"'*' exit=0')
            case "$_blind" in
                *candidates*) add_row "announced_blind_is_not_empty" false "a refused listing emitted a candidate list: $(one_line "$_blind")" load ;;
                *) add_row "announced_blind_is_not_empty" true "a refused listing answers ok false with its reason, exit 0, and no candidate list" load ;;
            esac ;;
        *) add_row "announced_blind_is_not_empty" false "expected ok false / list_failed / exit 0, got: $(one_line "$_blind")" load ;;
    esac

    # 5. AN UNREADABLE TIMELINE HOLDS THE CANDIDATE. *Nobody merged anything* and *I could not
    #    see what merged* are different sentences, and only the first may be announced.
    cat > "${_bin}/gh" <<STUB2
#!/bin/sh
case "\$*" in
  *timeline*) echo "boom" >&2; exit 1 ;;
esac
exec ${_bin}/gh-real "\$@"
STUB2
    chmod +x "${_bin}/gh"
    _r3=$(_read)
    if printf '%s' "$_r3" | jq -e '.candidates[0].landed_read == "timeline_unreadable" and .candidates[0].closed_unmerged == false and (.candidates[0].landed | length == 0)' >/dev/null 2>&1; then
        add_row "announced_unreadable_landing_is_held" true "an unreadable timeline is named, never rendered as an item a person closed" load
    else
        add_row "announced_unreadable_landing_is_held" false "an unreadable timeline was not distinguished from a hand-closed item: $(one_line "$_r3")" load
    fi

    # 6. THE BREAKER. Wire a refused listing to answer with an empty candidate list, and the
    #    blind hour becomes indistinguishable from the quiet one.
    _broken="${_tmp}/broken-reader.sh"
    sed -e 's/^    printf .{"ok": false, "reason": "%s", "detail": "%s"}.n. "\$1" "\$detail"$/    printf '"'"'{"ok": true, "slug": "x", "limit": 10, "read": 0, "truncated": false, "candidates": [], "unresolved": []}\\n'"'"'/' \
        "$_reader" > "$_broken"
    cat > "${_bin}/gh" <<'BLIND2'
#!/bin/sh
echo "boom" >&2
exit 1
BLIND2
    chmod +x "${_bin}/gh"
    _bk=$( ( cd "$_fx" && PATH="${_bin}:$PATH" sh "$_broken" --root "$_fx" 2>&1 ) || true)
    if printf '%s' "$_bk" | jq -e '.ok == true and (.candidates | length == 0)' >/dev/null 2>&1; then
        add_row "announced_breaker" true "with the refusal wired to an empty list, a blind hour reads exactly like a quiet one (this drill can fail)" breaker
    else
        add_row "announced_breaker" false "the breaker did not break: the wired-out reader still distinguished blindness ($(one_line "$_bk")), so rows 4 and 5 prove nothing" breaker
    fi

    # 3. THE SHAPE HAS ONE OWNER. The command reaches the catalog only when a finish is due.
    _seg() {
        awk '/^```$/ { if (grab) { print; grab=0; next } }
             /🟢 Implemented \[<ask title>\]\(<issue url>\)/ { grab=1; print prev; print; next }
             { if (grab) print; prev=$0 }
             ' "$1" 2>/dev/null | head -40
    }
    _a=$(_seg "$_catalog")
    if [ -n "$_a" ] \
       && grep -q 'list-unannounced-closed-asks.sh' "$_ceiling" \
       && grep -q 'skills/notify/reference/notifications.md' "$_ceiling"; then
        add_row "announced_shape_is_one_wording" true "the command reaches the one finish-line catalog when a reply is due" load
    else
        add_row "announced_shape_is_one_wording" false "the finish-line catalog or the command route to it is missing" load
    fi

    # 4. NOTHING WAS WRITTEN OUTSIDE THE FIXTURE.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "announced_writes_nothing_outside_the_fixture" true "the checkout is byte-identical after the drill" load
    else
        add_row "announced_writes_nothing_outside_the_fixture" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "announced-asks" 0 "fail" 1
    fi
    emit_verdict "announced-asks" 0 "pass" 0
}

# ---------------------------------------------------------- verify-plan-adjust
# THE LOOP ADJUSTS ITS OWN PLAN (2026-09-01, mission `adjust-the-plan-hourly-not-only-report-it`).
#
# Two mechanisms are drilled together because they fail in opposite directions and a repository
# needs both to be right at once:
#
#   * THE HOLD — `/propose`'s `wip_limit` rung bounds the REPOSITORY, where `work_waiting` and
#     `open_proposal` bound a strategy. A regression that IGNORES a declared limit puts six
#     missions in flight again; a regression that HOLDS a repository which declared nothing
#     stops the loop silently, which is the more dangerous of the two and is why it gets a row
#     of equal weight rather than a footnote.
#   * THE ORDER — `plan-units.sh` offers missions by the nearest `target_date` of the direction
#     each serves. A regression that reorders by DROPPING units is the one that costs work, so
#     the offered SET is asserted beside the sequence.
#
# HERMETIC. The fixture is a throwaway git repository this function builds; the limit is an
# environment variable it sets; the open-proposal read is supplied as a file, which is the same
# seam `direction-health` and `/propose` already take. No network, no `gh`, no Slack, no
# `origin`, no credential.
#
# THE FIXTURE'S VERDICTS DO NOT DEPEND ON THE DAY THE DRILL RUNS. Every `target_date` is
# computed as an offset from today, and the eligible direction's work is ARCHIVED and read
# under a one-second window — so it is neither `quiescent` (which would be refused `arrived` by
# the rung above) nor `work_waiting`, whatever the clock says.
#
# THE BREAKER IS WRITTEN AGAINST THE BEHAVIOUR, not the return shape: wire the `wip_limit` rung
# out of the ladder and the held direction must become eligible again. A breaker satisfied by
# keeping the JSON shape proves nothing, and without it row 1 could pass against a survey that
# never had the gate at all.
