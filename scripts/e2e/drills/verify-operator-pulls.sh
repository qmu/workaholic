cmd_verify_operator_pulls() {
    _mod="${REPO_ROOT}/plugins/workaholic/skills/moderate/scripts"
    _branch="${REPO_ROOT}/plugins/workaholic/skills/branching/scripts"
    _lister="${_branch}/list-operator-facing-pulls.sh"
    _effect="${_branch}/publication-effect.sh"
    _step="${_mod}/step-operator-pulls.sh"
    _supp="${_mod}/ruling-suppression.sh"
    _rule="${_branch}/lib/publication-refusal.sh"
    for _f in "$_lister" "$_effect" "$_step" "$_supp" "$_rule"; do
        [ -f "$_f" ] || emit_err "operator_pulls_unreadable" 4 "$_f is not present in this checkout"
    done

    _before=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)

    _tmp=$(mktemp -d)
    _bin="${_tmp}/bin"
    _fx="${_tmp}/fx"
    mkdir -p "$_bin" "${_fx}/.workaholic"
    git -C "$_fx" init -q . >/dev/null 2>&1 || true
    git -C "$_fx" remote add origin git@github.com:acme-org/drill-repo.git >/dev/null 2>&1 || true

    # THE FIXTURE NEEDS THREE PUBLICATIONS WITH DIFFERENT PROVENANCE. A stub answering one
    # shape for every pull request would let a title-keyed derivation pass without ever
    # exercising the refusal word.
    #   701  a ruling whose title says nothing about rulings   -> the trap
    #   702  a strategy amendment, titled `[Ruling] ...`       -> a title would misclassify it
    #   703  an ordinary `[Proposal]` that auto-merged         -> never a member
    _t18=$(_iso_hours_ago 18)
    _t3=$(_iso_hours_ago 3)
    _t40=$(_iso_hours_ago 40)
    _t1=$(_iso_hours_ago 1)
    cat > "${_bin}/gh" <<EOF
#!/bin/sh
_filter=""; _prev=""
for a in "\$@"; do
  if [ "\$_prev" = "--jq" ]; then _filter="\$a"; fi
  _prev="\$a"
done
case "\$2" in
  rate_limit) echo 5000; exit 0 ;;
esac
case "\$*" in
  *"pulls?state=open"*)
    printf '701\thttps://x/701\tHand the routine-rename decision to a person\t${_t18}\tclaude[bot]\n'
    printf '702\thttps://x/702\t[Ruling] Revise the direction\t${_t3}\tclaude[bot]\n'
    printf '703\thttps://x/703\t[Proposal] Say when the loop has run out of direction\t${_t40}\tclaude[bot]\n'
    exit 0 ;;
  *"pulls/701/files"*)
    _b='[{"status":"modified","filename":".workaholic/missions/active/m1/mission.md","patch":"@@\n-feedback: [a.md]\n+feedback: [a.md, b.md]\n"}]' ;;
  *"pulls/702/files"*)
    _b='[{"status":"modified","filename":".workaholic/strategies/dir1.md","patch":"@@\n+## Schedule\n"}]' ;;
  *"pulls/703/files"*)
    _b='[{"status":"added","filename":".workaholic/missions/active/m9/mission.md","patch":"@@\n+feedback: [z.md]\n"}]' ;;
  *"pulls/701"*)
    _b='{"number":701,"html_url":"https://x/701","state":"open","merged_at":null,"created_at":"${_t18}"}' ;;
  *"pulls/702"*)
    if [ -f "${_tmp}/702-merged" ]; then
      _b="{\"number\":702,\"html_url\":\"https://x/702\",\"state\":\"closed\",\"merged_at\":\"${_t1}\",\"created_at\":\"${_t3}\"}"
    else
      _b='{"number":702,"html_url":"https://x/702","state":"open","merged_at":null,"created_at":"${_t3}"}'
    fi ;;
  *"pulls/703"*)
    _b='{"number":703,"html_url":"https://x/703","state":"closed","merged_at":null,"created_at":"${_t40}"}' ;;
  *) exit 1 ;;
esac
if [ -n "\$_filter" ]; then printf '%s' "\$_b" | jq -r "\$_filter"; else printf '%s' "\$_b"; fi
EOF
    chmod +x "${_bin}/gh"
    PATH="${_bin}:${PATH}"
    export PATH

    # 1. THE RULE ITSELF, over the normalised stream both callers adapt into. The shape test is
    #    what tells a carried attribution from a brand-new mission, and every `/specificate`
    #    proposal writes one of the second kind — catching those would stop the loop merging.
    _cls() { printf '%s' "$1" | ( . "$_rule"; publication_refusal_word ); }
    _r1=$(_cls "M	.workaholic/missions/active/m/mission.md	1
")
    _r2=$(_cls "A	.workaholic/missions/active/m/mission.md	1
")
    _r3=$(_cls "M	.workaholic/strategies/d.md	0
")
    if [ "$_r1" = "ruling_touching" ] && [ "$_r2" = "" ] && [ "$_r3" = "strategy_touching" ]; then
        add_row "opul_rule_is_the_shape" true "an existing mission whose feedback line moves is a ruling, a brand-new one is not, a strategy is its own word" load
    else
        add_row "opul_rule_is_the_shape" false "the shape test misclassified: existing=$_r1 new=$_r2 strategy=$_r3" load
    fi

    # 2. THE DERIVATION over the fixture: the retitled ruling IS a member, the auto-merged
    #    proposal is NOT, and the strategy publication carries its own word.
    _list=$(cd "$_fx" && sh "$_lister" 2>&1 || true)
    _members=$(printf '%s' "$_list" | jq -r '[.pulls[]?.number] | sort | join(",")' 2>/dev/null || printf '?')
    if [ "$_members" = "701,702" ]; then
        add_row "opul_membership_is_the_refusal_word" true "the derivation names 701 (retitled ruling) and 702 (strategy) and excludes the auto-merged proposal" load
    else
        add_row "opul_membership_is_the_refusal_word" false "expected 701,702 — got [$_members]: $(one_line "$_list")" load
    fi
    _w701=$(printf '%s' "$_list" | jq -r '[.pulls[]? | select(.number==701) | .refusal_word] | first // ""' 2>/dev/null || printf '')
    _w702=$(printf '%s' "$_list" | jq -r '[.pulls[]? | select(.number==702) | .refusal_word] | first // ""' 2>/dev/null || printf '')
    if [ "$_w701" = "ruling_touching" ] && [ "$_w702" = "strategy_touching" ]; then
        add_row "opul_words_are_the_seams" true "each member carries the seam's own refusal word, never a third vocabulary" load
    else
        add_row "opul_words_are_the_seams" false "701=$_w701 702=$_w702" load
    fi

    # 3. THE FOUR EFFECT WORDS, and the NULL age on `unreadable` — a zero would read as *just
    #    opened*, the most urgent thing this vocabulary can say, for a read we could not make.
    _e701=$(cd "$_fx" && sh "$_effect" 701 2>&1 || true)
    _e703=$(cd "$_fx" && sh "$_effect" 703 2>&1 || true)
    _e999=$(cd "$_fx" && sh "$_effect" 999 2>&1 || true)
    _eff() { printf '%s' "$1" | jq -r '.effect // ""' 2>/dev/null || printf ''; }
    _age() { printf '%s' "$1" | jq -r '.age_hours // "null"' 2>/dev/null || printf '?'; }
    case "$(_eff "$_e701")" in
        open:1[678]|open:19) add_row "opul_open_reads_its_age" true "an un-acted pull request reads open:<age> in whole hours" load ;;
        *) add_row "opul_open_reads_its_age" false "expected open:~18, got $(one_line "$_e701")" load ;;
    esac
    if [ "$(_eff "$_e703")" = "closed" ] && [ "$(_age "$_e703")" = "null" ]; then
        add_row "opul_closed_is_a_refusal" true "a closed-unmerged pull request reads closed — the operator's refusal, never a merge" load
    else
        add_row "opul_closed_is_a_refusal" false "$(one_line "$_e703")" load
    fi
    if [ "$(_eff "$_e999")" = "unreadable" ] && [ "$(_age "$_e999")" = "null" ]; then
        add_row "opul_unreadable_has_a_null_age" true "a read we could not make is unreadable with a NULL age, never a zero" load
    else
        add_row "opul_unreadable_has_a_null_age" false "$(one_line "$_e999")" load
    fi
    : > "${_tmp}/702-merged"
    _e702=$(cd "$_fx" && sh "$_effect" 702 2>&1 || true)
    rm -f "${_tmp}/702-merged"
    if [ "$(_eff "$_e702")" = "merged" ]; then
        add_row "opul_merged_is_settled" true "a merged pull request reads merged — the operator ruled, and it landed" load
    else
        add_row "opul_merged_is_settled" false "$(one_line "$_e702")" load
    fi

    # 4. THE QUESTION REACHES ITS PERSON EXACTLY ONCE. The step names the candidates; the gate
    #    is `ask-question.sh`'s, unchanged, keyed on the pull request's number.
    _s1=$(cd "$_fx" && sh "$_step" --tick 20260829-140000 --root . 2>&1 || true)
    _keys=$(printf '%s' "$_s1" | jq -r '[.needs_agent[]?.pulls[]?.key] | sort | join(",")' 2>/dev/null || printf '?')
    if [ "$_keys" = "operator-pull:701,operator-pull:702" ]; then
        add_row "opul_asks_per_pull_request" true "one question per un-acted pull request, keyed on its number" load
    else
        add_row "opul_asks_per_pull_request" false "expected two keyed questions, got [$_keys]: $(one_line "$_s1")" load
    fi
    _ev=$(printf '%s' "$_s1" | jq -r '.event // ""' 2>/dev/null || printf '')
    if [ -n "$_ev" ]; then
        add_row "opul_candidate_supplies_an_event" true "a candidate supplies an event, so the root carries a line" load
    else
        add_row "opul_candidate_supplies_an_event" false "no event for a tick with two un-acted pull requests" load
    fi

    _ask="${_mod}/ask-question.sh"
    _when="--hour 14 --weekday 3"
    _log="${_mod}/log-append.sh"
    _a1=$(cd "$_fx" && sh "$_ask" --root . --tick 20260829-140000 --key "operator-pull:701" $_when 2>&1 || true)
    # `run.sh` writes the log line, not the gate, so the drill plays that part before asking
    # again — otherwise the second call would be testing an empty ledger rather than the gate.
    _a1step=$(printf '%s' "$_a1" | sed -n 's/.*"log_step": *"\([^"]*\)".*/\1/p' | head -1)
    [ -z "$_a1step" ] || ( cd "$_fx" && sh "$_log" --root . --tick 20260829-140000 \
        --step "$_a1step" --status filed --summary "asked the operator about 701" ) >/dev/null 2>&1 || true
    _a2=$(cd "$_fx" && sh "$_ask" --root . --tick 20260829-150000 --key "operator-pull:701" $_when 2>&1 || true)
    case "${_a1}|${_a2}" in
        *'"ask": true'*'"already_asked"'*)
            add_row "opul_asked_exactly_once" true "the first tick asks and the second is refused already_asked — the gate is untouched" load ;;
        *)
            add_row "opul_asked_exactly_once" false "first=$(one_line "$_a1") second=$(one_line "$_a2")" load ;;
    esac

    # 5. THE SETTLED CASE ASKS NOBODY AND RENDERS NO ROOT LINE. `merged` and `closed` are the
    #    operator having answered; an hourly restatement of that is what two roots were retired
    #    for.
    : > "${_tmp}/702-merged"
    _s2=$(cd "$_fx" && sh "$_step" --tick 20260829-160000 --root . 2>&1 || true)
    rm -f "${_tmp}/702-merged"
    _n2=$(printf '%s' "$_s2" | jq -r '[.needs_agent[]?.pulls[]?.key] | length' 2>/dev/null || printf '?')
    if [ "$_n2" = "1" ]; then
        add_row "opul_settled_asks_nobody" true "the merged pull request drops out of the candidate set; only the un-acted one is asked about" load
    else
        add_row "opul_settled_asks_nobody" false "expected one remaining candidate, got $_n2: $(one_line "$_s2")" load
    fi

    # 6. THE HOLD IS THE RULING'S OWN, AND THIS QUESTION IS WHAT BREAKS THE SILENCE. Both
    #    readings compose `ruling-suppression.sh`, so they cannot diverge about what a ruling
    #    holds — and nothing here releases the hold, which would ask one person twice.
    _stepsrc=$(sed 's/^[[:space:]]*#.*$//' "$_step")
    case "$_stepsrc" in
        *ruling-suppression.sh*)
            add_row "opul_shares_the_hold_reading" true "the step composes ruling-suppression.sh rather than re-deriving what a ruling holds" load ;;
        *)
            add_row "opul_shares_the_hold_reading" false "the step derives the held subjects itself, so the two readings can diverge" load ;;
    esac
    _suppsrc=$(cat "$_supp")
    case "$_suppsrc" in
        *"keyed on the SUBJECT"*|*"KEYED ON THE SUBJECT"*)
            add_row "opul_hold_stays_keyed_on_the_subject" true "the hold is still keyed on the subject, never on the existence of a ruling" load ;;
        *)
            add_row "opul_hold_stays_keyed_on_the_subject" false "the hold's subject-keying rule is no longer stated where it is enforced" load ;;
    esac

    # 7. IT MERGES, CLOSES AND GATES NOTHING. Call sites, never words: the step's prose says in
    #    English that it never merges, so a word-level ban would fail on the sentence stating
    #    the rule.
    _acted=""
    for _act in "--method PUT" "--method PATCH" "--method DELETE" "/merge" "publish-tree-pr.sh" \
                "publish-tree-commit.sh" "git push" "plan-units.sh" "close.sh"; do
        case "$_stepsrc" in *"$_act"*) _acted="${_acted}${_acted:+, }${_act}" ;; esac
    done
    if [ -z "$_acted" ]; then
        add_row "opul_asks_and_nothing_else" true "the step reaches no merge, close, push, gate or survey call site" load
    else
        add_row "opul_asks_and_nothing_else" false "the step reaches: $_acted" load
    fi

    # 8. THE BREAKER, LABELLED AS THE INTENTIONAL FAILURE. A copy of the derivation wired at the
    #    pull request's TITLE — which is what `list-open-rulings.sh` does on purpose, for a
    #    brake — must lose the retitled ruling. Written against the behaviour rather than the
    #    return shape, so a refactor that keeps the JSON and loses the bound still fires it.
    # The whole `branching/scripts` tree is copied so the broken derivation keeps a real
    # `lib/publication-refusal.sh` beside it — otherwise it would refuse `no_refusal_rule` and
    # the row would pass for a reason that has nothing to do with the bound being tested.
    _broken="${_tmp}/broken"
    mkdir -p "$_broken"
    cp -R "${_branch}/." "$_broken/"
    sed 's#^\( *\)word="$(printf .*publication_refusal_word)"#\1case "$title" in "[Ruling] "*) word=ruling_touching ;; *) word="" ;; esac#' \
        "$_lister" > "${_broken}/list-operator-facing-pulls.sh"
    chmod +x "${_broken}/list-operator-facing-pulls.sh"
    _bl=$(cd "$_fx" && sh "${_broken}/list-operator-facing-pulls.sh" 2>&1 || true)
    _bm=$(printf '%s' "$_bl" | jq -r '[.pulls[]?.number] | sort | join(",")' 2>/dev/null || printf '?')
    if [ "$_bm" != "701,702" ]; then
        add_row "opul_breaker" true "wired at the title the derivation loses the retitled ruling (members became [$_bm]) — this drill can fail" breaker
    else
        add_row "opul_breaker" false "the breaker did not break: a title-keyed derivation still named [$_bm], so row 2 proves nothing" breaker
    fi

    # 9. NOTHING WAS WRITTEN OUTSIDE THE FIXTURE.
    _after=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null | sort)
    if [ "$_before" = "$_after" ]; then
        add_row "opul_writes_nothing" true "the checkout is byte-identical after the drill" load
    else
        add_row "opul_writes_nothing" false "the drill changed the working tree" load
    fi

    rm -rf "$_tmp"
    if [ "$LOAD_FAILED" -gt 0 ]; then
        emit_verdict "operator-pulls" 0 "fail" 1
    fi
    emit_verdict "operator-pulls" 0 "pass" 0
}
