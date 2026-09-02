#!/bin/sh -eu
# Step 19 — retire the claims the oracle proved hold nothing.
#
# WHY THIS STEP EXISTS (2026-08-27, mission `deliver-and-retire-what-the-loop-already-proved-finished`).
# `superseded` proves a claim's content already reached the base, and it has been *reported, never
# acted on* since it shipped — so its branch, its worktree and its open pull request stayed
# forever and the claim table only ever grew. Measured 2026-08-27 on this repository: 7 claims,
# 4 of them `superseded`, two naming missions archived days ago, the oldest branch last touched
# 2026-08-21. `retire-claim.sh` is the writer; this is its ONLY caller, deliberately, because one
# caller is what keeps the retirement's bounds checkable.
#
# IT ASKS NOBODY ANYTHING ABOUT A RETIREMENT THAT SUCCEEDED, and `needs_agent` is empty for that
# reason. A completed retirement is not a person's business: the claim is proved empty, so there
# is no judgement to make and nothing for a human to weigh. This is the sharpest contrast with
# `stalled-units`, `undrivable-units` and `undelivered-units` beside it — each of those hands a
# person a reading it cannot act on, while this one acts and reports. Spending a question on a
# fact nobody needs to rule on is exactly what `strategy-pace` refuses to do with our own
# degradations.
#
# THE RULE IS NARROWED, NOT REVERSED (2026-08-27, mission
# `finish-the-retirement-the-loop-cannot-complete`). It was written when every retirement either
# succeeded or was refused on a JUDGEMENT, and it is wrong the moment a PROOF the loop acted on
# leaves one act UNDONE. Act 2 — the remote branch delete — is refused in the container the loop
# runs in (measured; `../../drive/scripts/retire-claim.sh`, Act 2), so the branch stays on
# origin, the claim never leaves the table, and this step reported `0 retired` hour after hour
# with nobody told. That unit is then exactly the shape `undelivered-units` and `handoff-units`
# exist for: a reading the machine cannot act on, addressed to one person. One question per
# blocked unit, keyed `retire-blocked:<unit>`, addressed to the claim holder, naming the branch —
# and still nothing at all for a retirement that worked.
#
# AND NARROWED ONCE MORE, TO WHAT CI COULD NOT TAKE EITHER (2026-08-28, mission
# `finish-a-proved-retirement-where-the-write-is-permitted`). Act 2 now runs in
# `.github/workflows/claim-retirement.yml`, where the write is permitted, so a blocked unit whose
# branch a workflow is about to delete must draw NO question: asking a person, once per unit and
# forever, for an act CI was about to perform is not merely noise — the ask is wrong. The reading
# is `../../drive/scripts/ci-retirement-turn.sh`.
#
# THAT READING RESTED ON A PREMISE WHICH WAS THE DESIGN AND NOT THE BEHAVIOUR, and the sentence
# is corrected here rather than deleted (2026-08-29, mission
# `read-back-whether-the-loop-s-own-act-took-effect`). It read: *CI DELETES the branch on success
# and unmerged remote branches are the only claim oracle, so a successful turn removes the claim
# row and the candidate with it; a completed run at the base tip this tick is reading therefore
# means CI saw exactly this tree and the branch survived it.* That holds only if every completed
# turn actually REACHED ITS ACT. Measured 2026-08-29: `claim-retirement.yml` was green on every
# run while three proved-`superseded` claims stood on origin, and this step's own log line said,
# hour after hour, *"ci_turn: taken so CI could not take the delete either"* — an assertion about
# a second executor that nothing established. (The live cause: the CI-side act refuses
# `gh_unavailable` before its proof gate.)
#
# WHAT REPLACED IT: the turn RECORDS what it attempted and what each act answered, and the
# reading answers PER UNIT from that record. It is still STORE-FREE — nothing is stored anywhere,
# and only which part of the run is consulted moved. `taken` (the act succeeded here) and
# `pending` (no completed run at this tip yet) suppress this unit's question, `pending` for this
# tick only — the asked-once ledger keys on the unit and its refusal word, so a branch that
# outlives CI's turn is still asked about later. `refused:<word>`, `unavailable`, a read this
# step could not make and a repository with no such workflow all leave the question exactly where
# it was: an over-eager question is better than a silently dropped one, and this repository has
# measured the cost of a blocked act nobody was told about.
#
# EVERYTHING ELSE ABOUT THE QUESTION IS BYTE-IDENTICAL: the asked-once gate, the addressee, the
# per-tick cap, the quiet hours and the working-day hold. (The KEY gained the refusal word in the
# same 2026-08-29 change, so it is asked once per (unit, refusal word) rather than once per unit
# ever — see the key rule further down.) Only the candidate set narrows — and the SUMMARY is
# deliberately untouched by the reading, so that a held block keeps rendering identically (see
# the stability rule below); the CI reading
# moves in and out of `needs_agent` and nowhere else.
#
# IT ACTS DIRECTLY RATHER THAN HANDING OFF, which is where it diverges from `closable-missions`
# and for a stated reason. That step hands its act to the agent because `close.sh` WRITES INTO
# THE TREE and needs a publish tree to do it. `retire-claim.sh` writes nothing into the tree at
# all — one REST `PATCH`, one branch delete, one local worktree reap — so there is no tree seam
# to cross and no reason to spend a round trip. The tick's *writes nothing but its own log line*
# contract is intact.
#
# THE RE-PROOF IS THE WRITER'S OWN, AT THE MOMENT OF THE ACT. This step reads `list-claims.sh`
# once for candidates, and `retire-claim.sh` then re-reads the oracle and re-derives the verdict
# itself before touching anything — so a row that went stale between the two reads is refused by
# the writer rather than acted on from this step's snapshot. That is the `closable-missions`
# precedent (2026-08-24) applied where it belongs: the proof is re-taken where the act happens,
# not trusted from an earlier read. A row the re-proof rejects is REPORTED, not retired.
#
# IT READS `list-claims.sh`, NEVER `plan-units.sh` — the rule `undelivered-units` and
# `undrivable-units` carry and `closable-missions` first recorded. The survey reaches the mission
# readers, which run the living migrations and STAGE what they converge; a step whose contract is
# *writes nothing into the tree* may not reach it through something that writes. `list-claims.sh`
# is a pure read.
#
# A DEGRADED READ RETIRES NOTHING. Unmerged remote branches are the only claim oracle, so a scan
# that could not reach the remote has not found "nothing to retire" — it has found nothing at
# all, and a proof that could not be read is not a proof. Reported `degraded` by name.
#
# A RETIREMENT IS A REPOSITORY EVENT, AND THIS LINE IS NOT A POSTING GATE. The root posts only
# when the tick has at least one QUESTION, and this step never has one — so its line is visible
# on a root some OTHER step's question already opened, and on a tick with no questions it is
# visible only in the log below. That is correct and deliberate: the root exists to carry
# questions, and a retirement addressed to nobody is exactly the status line two keyed roots were
# already retired for. Stated here so a later reader does not read the event as a reason to post.
#
# THE SUMMARY CARRIES NO AGE AND NO TIMESTAMP, for the correctness reason `stalled-units`'
# header records: the root calls a step changed when its summary differs from the same step's an
# hour ago, and only a timestamp, a bare hex object name and a clock time are normalised out. A
# count of what was retired this tick is stable when nothing happens, which is what the diff
# needs.
#
# AND A STANDING BLOCKED RETIREMENT MUST NOT READ AS AN HOURLY CHANGE (2026-08-27, mission
# `finish-the-retirement-the-loop-cannot-complete`). `0 retired` over a unit already asked about
# is a HELD condition, not a new one, and this repository has measured the same shape three
# times: a status restated hourly is read by nobody by the second day (`📦 Release Preparation`,
# one step over). Every term below is therefore a function of the CLAIM SET AND THE ACT STATES
# and of nothing else — the same units, the same acts standing and the same refusal render the
# same string, tick after tick — so a held block produces an identical summary and therefore no
# root line at all. It is not a suppression list: a NEWLY blocked unit moves the unit set, so the
# summary moves and the block is visible the hour it happens. Suppress by nothing; let the diff
# work. The question's own repetition is bounded by `ask-question.sh`'s asked-once ledger, which
# is a separate concern deliberately — a second per-unit ledger beside it is how the two drift.
#
# WHICH GUARD HOLDS WHICH CASE, since 2026-08-29 (mission
# `read-back-whether-the-loop-s-own-act-took-effect`). There were two — an unchanged summary AND
# an empty `event` — and a blocked retirement now supplies an event, because an act the loop
# believed it took and did not is a repository fact a person should see the hour it appears. So:
# a tick whose acts all TOOK is held by the empty event, and a STANDING block is held by the
# summary diff alone. That is exactly why the summary must carry no CI term — the one guard left
# on that path is the one the CI reading would break. Re-implementing the diff inside this step
# to suppress a repeated event was refused: the renderer already owns that comparison, and a
# second copy of it here is how the two would disagree.
#
# Usage: step-retire-claims.sh --tick <tick-id> [--root <repo-root>]
# Output: one JSON line — {step, status, reason, summary, needs_agent, event}

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
. "${SCRIPT_DIR}/lib/read-age.sh"
DRIVE_SCRIPTS="${SCRIPT_DIR}/../../drive/scripts"

TICK=""
ROOT="."
while [ $# -gt 0 ]; do
    case "$1" in
        --tick) TICK="${2:-}"; shift 2 ;;
        --root) ROOT="${2:-.}"; shift 2 ;;
        *) shift ;;
    esac
done
: "${TICK:?}"

# `event` is the POST-facing phrase, beside the LOG-facing `summary` and never instead of it.
# Empty means nothing happened here, and the renderer then emits no line at all — which is
# exactly the state of a tick that retired nothing.
emit() {
    printf '{"step": "retire-claims", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$3" "${4:-}" "${5:-}"
    exit 0
}

lister="${DRIVE_SCRIPTS}/list-claims.sh"
[ -f "$lister" ] || emit degraded no_claim_reader "list-claims.sh is not present beside this skill"

retirer="${DRIVE_SCRIPTS}/retire-claim.sh"
[ -f "$retirer" ] || emit degraded no_retirement_writer "retire-claim.sh is not present beside this skill"

out=$( ( cd "$ROOT" && sh "$lister" ) 2>/dev/null || true )
[ -n "$out" ] || emit degraded claims_unreadable "list-claims.sh produced no output"

printf '%s' "$out" | jq -e . >/dev/null 2>&1 \
    || emit degraded claims_unparseable "list-claims.sh produced output this step could not parse"

fetched=$(printf '%s' "$out" | jq -r '.fetched // false')
shallow=$(printf '%s' "$out" | jq -r '.shallow // false')

[ "$fetched" = "true" ] || emit degraded origin_unreachable \
    "the claim scan could not reach the remote; nothing was proved and nothing retired"
[ "$shallow" = "true" ] && emit degraded shallow_history \
    "the claim scan ran over truncated history; a superseded claim is indistinguishable from a live one, so nothing was retired"

total=$(printf '%s' "$out" | jq '[.claims[]?] | length')
units=$(printf '%s' "$out" | jq -r '[.claims[]? | select(.resume_reason == "superseded") | .unit] | unique | .[]' 2>/dev/null || true)

# STRANDED UNITS ARE THIS STEP'S TOO, AND THEY ARE ASKED ABOUT, NEVER ACTED ON (2026-09-01,
# issue #788). A `stranded` row is a claim whose tickets are archived on the base while its
# branch still holds content found on no other ref — measured as two branches carrying ~300
# lines of code and a documentation section that the tick was asking to delete. It is not a
# retirement candidate by construction (`retire-claim.sh` refuses anything but `superseded`),
# and it is the same shape of finding this step already owns: *a claim that looks finished and
# is not*. So it is asked here rather than growing a step of its own.
stranded=$(printf '%s' "$out" | jq -r '[.claims[]? | select(.resume_reason == "stranded") | .unit] | unique | .[]' 2>/dev/null || true)
sn=0
for _ in $stranded; do sn=$((sn + 1)); done

# THE BRANCH AND THE FILES IT HOLDS RIDE THE QUESTION (2026-09-02, ticket
# `20260831203454-tell-a-person-about-a-stranded-claim-branch`). Under the catalog's
# composition contract the question must lead with what happened and then name the identifier;
# "this unit's branch holds work nothing else has" is unanswerable to a person who cannot see
# WHAT. `list-claims.sh` already put the bounded names and the true count on the row, so this
# reads them there rather than calling the emptiness reader a second time.
stranded_detail=$(printf '%s' "$out" | jq -c '[.claims[]? | select(.resume_reason == "stranded")
    | {unit: .unit, branch: .branch, files: (.stranded_files // []), file_count: (.stranded_file_count // 0),
       key: ("stranded-unit:" + .unit)}] | unique_by(.unit)' 2>/dev/null || printf '[]')

n=0
for _ in $units; do n=$((n + 1)); done

if [ "$n" -eq 0 ] && [ "$sn" -eq 0 ]; then
    emit ok "" "${total} claimed unit(s); none proved superseded"
fi

# THE PER-ROW DETAIL LIVES IN `summary`, WHICH IS THE LOG-FACING FIELD — the tick log is the
# audit trail, and this step's outcomes are exactly what somebody diagnosing a retirement needs.
# `needs_agent` is NOT the home for it: that field is a request to the agent, and a payload with
# no action would be read as one. A retired row names all three acts and a refused row names its
# reason, so `retired` and `refused` are never a bare count somebody has to go digging behind.
# WHICH EXECUTOR TOOK THE DELETE, WITHOUT A FIELD THAT SAYS SO (2026-08-28, mission
# `finish-a-proved-retirement-where-the-write-is-permitted`). Two things can now make a branch
# disappear — this tick's own Act 2, and `claim-retirement.yml` — and a reader must be able to
# tell them apart. The fact is ALREADY on the writer's row and needs no new field: `deleted`
# means this tick performed the delete, and `already_gone` means the ref was not on origin when
# this tick looked, which asserts nothing about who removed it. Only the WORDING was wrong,
# rendering both as bare state names, so a delete CI had taken read as one this container took.
# A `deleted_by: ci|container` field is refused for the reason every second derivation is: the
# answer is already derivable, and a stored one eventually disagrees with the derived one.
# `already_gone` keeps rendering as the SUCCESS it is — the rule `already_closed` and `absent`
# already carry — and `failed` / `not_attempted` are byte-identical to what they were.
BRANCH_PHRASE='def branch_phrase:
    if .remote_branch_deleted == "deleted" then "branch deleted here"
    elif .remote_branch_deleted == "already_gone" then "branch removed elsewhere"
    else "branch " + .remote_branch_deleted end;'

retired=0
refused=0
blocked=0
detail=""
rows=""
rsep=""
for unit in $units; do
    [ -n "$unit" ] || continue
    res=$( ( cd "$ROOT" && sh "$retirer" "$unit" ) 2>/dev/null || true )
    if [ -z "$res" ] || ! printf '%s' "$res" | jq -e . >/dev/null 2>&1; then
        res=$(printf '{"retired": false, "unit": "%s", "branch": "", "pull_request_closed": "not_attempted", "remote_branch_deleted": "not_attempted", "worktree_reaped": "not_attempted", "reason": "writer_unreadable"}' "$unit")
    fi
    if printf '%s' "$res" | jq -e '.retired == true' >/dev/null 2>&1; then
        retired=$((retired + 1))
        line=$(printf '%s' "$res" | jq -r "${BRANCH_PHRASE}"'"\(.unit) retired (pr \(.pull_request_closed), \(branch_phrase), worktree \(.worktree_reaped))"' 2>/dev/null || printf '')
    else
        refused=$((refused + 1))
        # A REFUSED ROW NAMES THE ACTS THAT STAND, exactly as the retired row does (2026-08-27,
        # mission `finish-the-retirement-the-loop-cannot-complete`). It rendered `<unit> refused
        # (<reason>)` until then, dropping the acts that SUCCEEDED — so a re-run read as a re-run
        # of three acts when it is a re-run of one, and three units whose pull requests had been
        # closed days earlier still read as bare refusals on every tick. The three states are
        # already on the writer's row; this reads them and derives nothing. `already_closed`,
        # `already_gone`, `absent` and `none` therefore render as the SUCCESSES they are, and
        # `not_attempted` stays distinct from `failed` — a gate that never ran made no finding
        # about the world, so the refusal path must keep saying so.
        line=$(printf '%s' "$res" | jq -r "${BRANCH_PHRASE}"'"\(.unit) refused (\(if (.reason // "") == "" then "unstated" else .reason end); pr \(.pull_request_closed), \(branch_phrase), worktree \(.worktree_reaped))"' 2>/dev/null || printf '')
        # A RETIREMENT BLOCKED ON THE DELETE IS THE ONE REFUSAL A PERSON CAN ACT ON, and it is
        # the candidate set for the question below. Narrowed to the delete deliberately: a
        # refused reap is local to this runner and tells its holder nothing they can do
        # remotely, and a refused close is a different act with a different repair. The branch
        # is read off the writer's own row, so the question names the branch the writer actually
        # tried to delete rather than one this step resolved a second time.
        if printf '%s' "$res" | jq -e '.remote_branch_deleted == "failed"' >/dev/null 2>&1; then
            blocked=$((blocked + 1))
            branch=$(printf '%s' "$res" | jq -r '.branch // ""')
            row=$(printf '%s' "$out" | jq -c --arg b "$branch" --argjson r "$res" '
                ([.claims[]? | select(.branch == $b) | .author] | first) as $a
                | {unit: $r.unit, branch: $r.branch,
                   owner: (if ($a // "") == "" then "unknown" else $a end),
                   refusal: $r.reason,
                   acts_that_stand: ("pull request " + $r.pull_request_closed
                                     + ", worktree " + $r.worktree_reaped)}' 2>/dev/null || printf '')
            if [ -n "$row" ]; then
                rows="${rows}${rsep}${row}"
                rsep=","
            fi
        fi
    fi
    [ -n "$line" ] || continue
    # The summary is one JSON string on one line; a quote or a control character from a unit id
    # would break the line the log and the diff both read.
    line=$(printf '%s' "$line" | sed -e 's/\\/\\\\/g' -e 's/"/'"'"'/g' -e 's/[[:cntrl:]]/ /g')
    detail="${detail:+${detail}; }${line}"
done
rows="[${rows}]"

summary="${total} claimed unit(s); ${n} proved superseded, ${retired} retired, ${refused} refused${detail:+ — ${detail}}"

# A RETIREMENT IS A REPOSITORY EVENT (2026-08-23's rule): a pull request was closed, a branch
# deleted, a worktree reaped. A tick that retired NOTHING supplies no event and so renders no
# line at all — the independent guard against a nothing-happened line reaching the root. A tick
# that only refused is in that same class: a refusal is this step's bookkeeping, and the row is
# in the log for whoever diagnoses the tick.
# THE EVENT NAMES NO IDENTIFIER (2026-09-01, the developer's instruction). It used to paste the
# unit slugs into the root -- two of them, sixty characters each, unlinked -- and the developer's
# answer was *まるまるいらない*. A root line is addressed to nobody and is read at a glance; a
# slug is addressed to whoever can act on it, and that is the QUESTION's job
# (`retire-blocked:<unit>:<word>`), which names the unit, its branch and its refusal word to the
# claim holder. Saying it in both places puts the identifier where it cannot be acted on and
# lengthens the one line everybody reads. The count stays: *how many* is news, *which* is a task.
event=""
if [ "$retired" -eq 1 ]; then
    event="a claim proved finished was retired — its pull request closed and its branch deleted"
elif [ "$retired" -gt 1 ]; then
    event="${retired} claims proved finished were retired — their pull requests closed and their branches deleted"
fi

# `needs_agent` IS EMPTY FOR A RETIREMENT THAT SUCCEEDED, and carries one question per
# retirement BLOCKED ON THE DELETE (2026-08-27, mission
# `finish-the-retirement-the-loop-cannot-complete`). The original rule — *this step asks nobody
# anything* — was correct while every retirement either succeeded or was refused on a JUDGEMENT,
# and wrong the moment a PROOF the loop acted on left one act undone: the branch stays on origin,
# the claim never leaves the table, and nothing addressed anybody. It is NARROWED, NOT REVERSED —
# a successful retirement still asks nothing, because there is still no judgement for a person to
# make, which is what separates this step from the three beside it.
#
# WHOSE QUESTION IT IS: the CLAIM HOLDER's, following `stalled-units` and `undelivered-units` —
# a real person who drove the unit and can delete its branch. The running identity is never
# consulted, following `undrivable-units`: a branch left on origin is a fact about the
# repository, so an hourly question that depended on which container asked it would answer
# differently per account. The address is the claim row's own `author`.
#
# ONE UNIT NEVER DRAWS TWO QUESTIONS. Every candidate here reads `superseded`, and
# `step-stalled-units.sh` filters exactly that verdict out of its own candidates and counts it
# as a finding instead — so the pair is already honest and nothing new had to be filtered. The
# other two claim-reading steps key on `report_undelivered` and `awaiting_verification`, which
# no `superseded` row can also be.
#
# IT ASKS AND NOTHING ELSE. No claim is released, no pull request reopened, no verdict changed,
# no delete re-run on the strength of an answer — the proof gate and the retirement's other two
# acts are exactly what they were.
#
# AND THE CANDIDATE SET IS NARROWED TO WHAT CI COULD NOT TAKE EITHER (2026-08-28, mission
# `finish-a-proved-retirement-where-the-write-is-permitted`). See the header: the reading is
# store-free and three-valued, `pending` suppresses this tick's question only, and both a
# degraded read and a repository without the workflow leave the question exactly where it was.
# The narrowing is NOT A SUPPRESSION LIST — every term is still a function of the claim set, the
# act states and one live reading, so a newly blocked unit is visible the hour it appears.
ci_turn="unavailable"
ci_readable="false"
if [ "$blocked" -gt 0 ]; then
    turner="${DRIVE_SCRIPTS}/ci-retirement-turn.sh"
    if [ -f "$turner" ]; then
        # THE READING IS PER UNIT, AND SO IS THE SUPPRESSION (2026-08-29, mission
        # `read-back-whether-the-loop-s-own-act-took-effect`). It was one run-level word applied
        # to every blocked unit at once, on the retired premise that a completed run at the base
        # tip meant CI had reached its act. It had not: the turn now RECORDS what each act
        # answered, and a unit is held only on its own answer.
        blocked_units=$(printf '%s' "$rows" | jq -r '.[]? | .unit' 2>/dev/null || true)
        # shellcheck disable=SC2086
        turn_out=$( ( cd "$ROOT" && sh "$turner" $blocked_units ) 2>/dev/null || true )
        if printf '%s' "$turn_out" | jq -e . >/dev/null 2>&1; then
            ci_readable=$(printf '%s' "$turn_out" | jq -r '.readable // false')
            ci_turn=$(printf '%s' "$turn_out" | jq -r '.ci_turn // "unavailable"')
        fi
    fi
    # ONLY `taken` AND `pending` HOLD. `taken` means the act SUCCEEDED for this unit, so its
    # branch is gone and nothing is owed; `pending` means CI may still take it, which delays the
    # question for this tick only — the asked-once ledger keys on the unit, so a branch that
    # outlives CI's turn is asked about later. `refused:<word>` is precisely the case a person
    # must hear about, and `unreadable` holds nothing either: an over-eager question is better
    # than a silently dropped one. A unit the reading never answered keeps its question BY
    # CONSTRUCTION, because only units it named `taken` or `pending` are removed.
    if [ "$ci_readable" = "true" ]; then
        ci_held=$(printf '%s' "$turn_out" | jq -r \
            '[.units[]? | select(.ci_turn == "taken" or .ci_turn == "pending") | .unit] | .[]' \
            2>/dev/null || true)
        for ci_u in $ci_held; do
            rows=$(printf '%s' "$rows" | jq -c --arg u "$ci_u" '[.[]? | select(.unit != $u)]' 2>/dev/null || printf '%s' "$rows")
        done
        blocked=$(printf '%s' "$rows" | jq 'length' 2>/dev/null || printf '%s' "$blocked")
    fi
fi

# THE KEY CARRIES THE REFUSAL WORD (2026-08-29, mission
# `read-back-whether-the-loop-s-own-act-took-effect`). `retire-blocked:<unit>` was asked exactly
# once per unit, EVER. That gate is right for an unchanging block — an hourly restatement of the
# same refusal is the noise two keyed roots were retired for — and wrong the moment the WORD
# changes: a unit first blocked on `branch_delete_failed` and later on `pull_request_open` is a
# different fact needing a different act, and the second one reached nobody.
#
# THE ASKED-ONCE GATE NEEDED NO CHANGE AT ALL, which is the property this was shaped for. The
# narrowing lives in what the key is MADE OF, so `ask-question.sh` stays one mechanism that
# cannot drift from itself, and every existing hold — quiet hours, working days, the per-tick cap
# and the day cap — applies to a re-ask unchanged, because a re-ask is just one more question.
#
# THE WORD IS THE ONE A PERSON MUST ACT ON: CI's refusal where the effect reading names one,
# because that is the executor that was actually going to take the delete, and the container's
# own refusal otherwise. One word, not two, and it is the same word the question names.
#
# THE SUMMARY IS DELIBERATELY LEFT OUT OF THIS. CI runs on every merge to `main`, so between a
# merge and its run completing the effect reading genuinely oscillates `pending` -> `refused:…`
# hour to hour; putting that word in the summary would move the diff most hours and render a root
# line for a block that had not changed, which is precisely what the stability rule above exists
# to prevent. The key is safe from the same oscillation by construction: a `pending` unit is
# suppressed above and never reaches `ask-question.sh`, so no key is ever composed with it.
if [ "$blocked" -gt 0 ]; then
    ci_units=$(printf '%s' "$turn_out" | jq -c '[.units[]?]' 2>/dev/null || printf '[]')
    rows=$(printf '%s' "$rows" | jq -c --argjson t "$ci_units" '
        [ .[]? | . as $r
          | ([$t[]? | select(.unit == $r.unit) | .ci_turn] | first // "") as $w
          | (if ($w | startswith("refused:")) then ($w | sub("^refused:"; "")) else "" end) as $ci
          | ($r.refusal // "unstated") as $own
          | $r + {ci_turn: $w,
                  blocking_refusal: (if $ci != "" then $ci else $own end)}
          | . + {key: ("retire-blocked:" + .unit + ":" + .blocking_refusal)} ]' \
        2>/dev/null || printf '%s' "$rows")
fi

# AND THE QUESTION IS HELD ONCE THIS FINDING HAS BECOME WORK (2026-08-29, mission
# `let-the-tick-s-own-findings-become-the-loop-s-work`). While an open finding issue carries
# this step's finding, the loop is already driving the repair, and asking a person about it is
# asking them — the same person, in the same hour — about the thing that is in flight.
#
# KEYED ON THE SUBJECT, never on the existence of a filing: a filing about a DIFFERENT step's
# finding must not silence this one. An UNREADABLE read holds nothing (`ci-retirement-turn.sh`'s
# discipline), and the suppression is DERIVED — merging or closing the issue makes the question
# reachable again with no state anywhere. `ask-question.sh`, the key, the addressee, the caps and
# the holds are untouched. It holds the QUESTION only: the retirement's three acts above have
# already run, and holding an act rather than a question is the opposite of what this is for.
finding_held=false
suppression="${SCRIPT_DIR}/finding-suppression.sh"
if [ "$blocked" -gt 0 ] && [ -f "$suppression" ]; then
    fsupp=$( ( cd "$ROOT" && sh "$suppression" ) 2>/dev/null || true )
    if [ -n "$fsupp" ] && printf '%s' "$fsupp" | jq -e '.readable // false' >/dev/null 2>&1; then
        if printf '%s' "$fsupp" | jq -e '.held.steps | index("retire-claims")' >/dev/null 2>&1; then
            finding_held=true
        fi
    fi
fi
if [ "$finding_held" = "true" ]; then
    blocked=0
    rows="[]"
fi

# AN ACT THE LOOP BELIEVED IT TOOK AND DID NOT IS A REPOSITORY EVENT (2026-08-29, mission
# `read-back-whether-the-loop-s-own-act-took-effect`). A retirement that WORKED still supplies
# the event above; this adds the other outcome, which until now was visible only in the log.
#
# IT NAMES THE UNITS, NOT A COUNT OF STEPS THAT RAN — the 2026-08-23 rule that a root line is a
# repository fact rather than the tick's bookkeeping.
#
# THE TWO EXISTING GUARDS ARE RELIED ON RATHER THAN RE-IMPLEMENTED, which is what keeps this
# from becoming the hourly status line addressed to nobody that two keyed roots were retired for:
# the root renders a step's line only when its SUMMARY differs from the same step's an hour ago,
# and the summary is a function of the claim set and the container's act states alone — so a
# standing block renders an identical summary and NO line, while a newly blocked unit moves the
# unit set and is visible the hour it appears. A tick whose acts all took supplies no event here
# at all, and *a step with no event renders no line* covers the rest.
#
# It is computed AFTER both suppressions on purpose: a unit CI is about to delete, and one whose
# finding is already in flight as work, are not things to announce.
if [ "$blocked" -eq 1 ]; then
    ev_units=$(printf '%s' "$rows" | jq -r '[.[]? | .unit] | join(", ")' 2>/dev/null || printf '')
    event="a claim proved finished is still standing — neither the container nor CI could delete its branch"
elif [ "$blocked" -gt 1 ]; then
    ev_units=$(printf '%s' "$rows" | jq -r '[.[]? | .unit] | join(", ")' 2>/dev/null || printf '')
    event="${blocked} claims proved finished are still standing — neither the container nor CI could delete their branches"
fi

# HOW LONG THIS BLOCK HAS BEEN ASKED ABOUT (2026-08-30, mission
# `say-how-long-the-loop-has-been-stuck`). Attached LAST, after the key is composed and after
# both suppressions: the key carries the refusal word, so an age read under any earlier key
# would answer about a different question.
#
# A CHANGED REFUSAL RESETS THE AGE, AND THAT IS CORRECT. `retire-blocked:<unit>:<word>` starts a
# new key when the word changes, so `first_seen` reads null on the first tick of the new word.
# It is a different question — a person is being told something new — and the composer must not
# read the reset as the block having cleared: the unit's branch has been standing all along, and
# only what is blocking its delete has moved.
if [ "$blocked" -gt 0 ]; then
    rows=$(
        printf '%s' "$rows" | jq -c '.[]?' 2>/dev/null | while IFS= read -r row; do
            [ -n "$row" ] || continue
            key=$(printf '%s' "$row" | jq -r '.key // ""' 2>/dev/null || printf '')
            age=$(read_age "$key" "$ROOT")
            printf '%s' "$row" | jq -c --argjson a "$age" '. + {age: $a}' 2>/dev/null || printf '%s' "$row"
        done | jq -sc '.' 2>/dev/null || printf '%s' "$rows"
    )
fi

# THE STRANDED SET, ASKED SEPARATELY BECAUSE IT IS A DIFFERENT QUESTION (2026-09-01, issue
# #788). A blocked retirement asks *please delete this branch*; a stranded claim asks the
# opposite -- *do not delete this, it holds work nothing else has*. One `needs_agent` payload
# carrying both would be one instruction with two contradictory actions.
stranded_needs=""
if [ "$sn" -gt 0 ]; then
    # THE AGE RIDES IT TOO, through the one reader every other aged question in this tick uses,
    # keyed on the key the step already composed. A branch stranded for weeks with nobody
    # answering is a real possibility, and the question is asked ONCE — so the only thing that
    # can say how long it has been standing is the age.
    stranded_rows=$(
        printf '%s' "$stranded_detail" | jq -c '.[]?' 2>/dev/null | while IFS= read -r row; do
            [ -n "$row" ] || continue
            key=$(printf '%s' "$row" | jq -r '.key // ""' 2>/dev/null || printf '')
            age=$(read_age "$key" "$ROOT")
            printf '%s' "$row" | jq -c --argjson a "$age" '. + {age: $a}' 2>/dev/null || printf '%s' "$row"
        done | jq -sc '.' 2>/dev/null || printf '%s' "$stranded_detail"
    )
    [ -n "$stranded_rows" ] || stranded_rows="$stranded_detail"
    stranded_needs=$(printf '%s' "$stranded_rows" | jq -c '{action: "tell_the_claim_holder_their_branch_holds_work_nothing_else_has",
        bound: "one question per unit, addressed to the claim holder, keyed on `key` so it is asked once. The tick asks and does nothing else: it never deletes the branch, never merges it, never releases the claim and never re-drives a ticket. THIS UNIT IS NOT A RETIREMENT CANDIDATE and must never be offered as one.",
        compose: "lead with what happened in words a reader outside the repository understands -- this unit'"'"'s tickets are archived on the base while its branch still carries files that exist on no other ref -- and name the unit and the exact branch AFTER that, never before. Name the files from `files` (they are already bounded; when `file_count` is larger, say `and N more`), because a person cannot rule on work they cannot see. Say plainly that deleting the branch would lose it. Ask what should happen to it -- landed on the base, or discarded deliberately -- and never suggest deleting the branch. When `age.first_seen` is set, say how long this has been ASKED ABOUT (`age.ticks` ticks since `age.first_seen`, `at least` that when `age.first_seen_is_floor`); when `age.readable` is false, name it as an age we could not read, by its `age.reason`.",
        stranded_claims: .}' 2>/dev/null || echo '')
fi

needs=""
if [ "$blocked" -gt 0 ]; then
    needs=$(printf '%s' "$rows" | jq -c --arg turn "$ci_turn" '{action: "ask_the_claim_holder_to_delete_the_branch_neither_the_container_nor_ci_could",
        bound: "one question per (unit, refusal word), addressed to the claim holder, keyed on `key` so an unchanged block is asked once and a CHANGED refusal word is asked once more; the tick asks and never releases a claim, reopens a pull request, or re-runs the delete",
        compose: "name the unit, the exact branch left on origin, the refusal in `blocking_refusal` that is blocking the delete now, and the acts that already stand -- a question that does not name the branch does not say what to delete. When `age.first_seen` is set, say how long this block has been ASKED ABOUT (`age.ticks` ticks since `age.first_seen`, `at least` that when `age.first_seen_is_floor`); the key carries the refusal word, so a null age on a unit whose word just changed means a NEW question rather than a block that cleared -- never say the block just started. When `age.readable` is false, name it as an age we could not read, by its `age.reason`.",
        ci_turn: $turn,
        blocked_retirements: .}' 2>/dev/null || echo '')
fi

# BOTH PAYLOADS RIDE, and a run that has only one sends only that one.
if [ -n "$stranded_needs" ]; then
    if [ -n "$needs" ]; then
        needs="${needs}, ${stranded_needs}"
    else
        needs="$stranded_needs"
    fi
fi
if [ "$sn" -gt 0 ]; then
    summary="${summary}; ${sn} claim(s) stranded — tickets archived, branch still holds work"
    if [ -n "$event" ]; then
        event="${event}; ${sn} claim(s) look finished but their branches still hold work nothing else has"
    else
        event="${sn} claim(s) look finished but their branches still hold work nothing else has"
    fi
fi

emit ok "" "$summary" "$needs" "$event"
