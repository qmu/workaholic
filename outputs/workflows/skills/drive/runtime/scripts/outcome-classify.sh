#!/bin/sh -eu
# The ONE declaration of what a loop-finish line's `outcome` says about YIELD, and the one
# reading over it.
#
# Usage: outcome-classify.sh [--list]
#   stdin  — one tick-log SUMMARY per line (`log-append.sh` writes one line per step, so a
#            summary is a line by construction).
#   stdout — one JSON object per input line:
#            {"class": "originated|nothing|unmeasured|unclassified",
#             "outcome": "<the .outcome field, or "">", "reason": "<why, when not read>"}
#   --list — the declared token sets, for a caller that must pin them. Runs no reading.
# ALWAYS exit 0.
#
# WHY IT EXISTS (2026-09-20, ticket `20260920014751`). `/moderate`'s `propose-yield` step
# enumerated this vocabulary on the READER's side, where it can only ever be a guess about what
# writers will produce — its own header conceded as much — and answered `degraded`
# `outcome_unclassified` on every run instead of ever reaching its finding. MEASURED on this
# checkout 2026-09-20 over the newest two day files: seven propose finishes, of which
# `completed`, `published_and_merged` and `published` were outside the reader's set. Those are
# ordinary things a run writes.
#
# THE TERMINAL TOKEN AND THE YIELD ARE TWO AXES, and conflating them is the deeper cause.
# `work/scripts/worker-result.schema.json` already declares the terminal token as a closed
# enum — `ok | pending | blocked | failed` — and it carries NO yield information: a propose tick
# that originated nothing and one that opened a mission both answer `ok`. The richer strings
# (`propose:proposed_0:past_target_date / specificate:proposed_6:formation_turn_closed`) reach
# the log because a native subagent composes its own sentence into that same field. Both are
# real, and neither is renamed here: this script READS what is written and declares only how a
# yield is recognised inside it.
#
# THE READING IS PER SEGMENT WITH A STATED PRECEDENCE. A composite outcome is a real and common
# form, split on ` / `, and the question the one consumer asks is *did the routine produce
# anything* — so ANY segment that originated makes the whole entry `originated`. The retired
# reader took the first arm that matched over the WHOLE line, which silently classified both
# composite rows in the measured window as `nothing`: one contained `proposed_6` and the other
# `proposed_mission`, each an originated token in that reader's own set. That is the dangerous
# defect of the two, because it is silent — once the unreadable entries age out it would raise
# `originated_nothing` against a window in which specificate had ingested a mission and six
# tickets.
#
# IT READS `.outcome` AND NEVER `.reason`. The retired reader tested the whole summary string,
# `reason` included, so a sentence mentioning a token would have classified the entry.
#
# FOUR CLASSES, AND THE LAST TWO ARE NOT ONE CLASS:
#   * `originated`   — a segment names work the routine produced.
#   * `nothing`      — every segment that says anything says it produced nothing.
#   * `unmeasured`   — a RECOGNISED terminal word that carries no yield information at all
#                      (the schema's own four, plus the words the finish seams write around
#                      them). The writer could not say; the reader read it fine.
#   * `unclassified` — a token outside every set, or a summary that is not JSON. The reader
#                      could not read it.
# *The writer cannot say* and *the reader cannot read* are different facts about why a window
# holds no verdict, and one word for both is how a reader is sent to the wrong place. Both hold
# a consumer's finding; neither is ever a silent `nothing`.
#
# AN UNRECOGNISED TOKEN IS `unclassified` AND NEVER GUESSED. The set is closed so that a new
# word shows up as a thing to add here, which is the whole point of declaring it once.
#
# IT CLASSIFIES AND NOTHING ELSE. No write, no log, no network, no gate.

LIST=false
while [ $# -gt 0 ]; do
    case "$1" in
        --list) LIST=true; shift ;;
        *) shift ;;
    esac
done

# --- THE DECLARATION ------------------------------------------------------------------
# Each set is a jq boolean over one trimmed segment bound to `.`.
#
# `originated` — the routine produced something. `published` is matched on its own segment or
# after a role prefix rather than as a bare substring, so a compound that merely contains the
# letters cannot claim it; `published_and_merged` is spelled because its `_` defeats that test.
ORIGINATED='test("proposed_[1-9]") or test("ticket_published") or test("published_and_merged")
            or test("(^|:)published(:|$)") or test("proposal_opened") or test("proposed_mission")
            or test("issue_opened")'
# `nothing` — the routine said it produced nothing. `proposed_0` and the JSON spellings a run
# may embed.
NOTHING='test("no_evolutionary_move") or test("proposed_0") or test("\"proposed\" *: *0")
         or test("proposed: *0")'
# `unmeasured` — a recognised terminal word carrying no yield information. The first four are
# `worker-result.schema.json`'s own enum; `not_executed` and `unreadable` are `codex-loop.sh`'s
# `worker_outcome()` words around it; `completed` is what a run writes when it graded only
# itself. Matched on the whole segment or on its first colon-delimited field, because those
# words carry a `:<reason>` suffix while a composite segment carries a ROLE there instead.
UNMEASURED='(split(":") | .[0]) as $head
            | ["ok","pending","blocked","failed","not_executed","unreadable","completed"]
              as $set
            | any($set[]; . == $head)'

if [ "$LIST" = true ]; then
    jq -cn --arg originated "$ORIGINATED" --arg nothing "$NOTHING" --arg unmeasured "$UNMEASURED" \
        '{readable: true, separator: " / ",
          precedence: ["originated", "nothing", "unmeasured", "unclassified"],
          sets: {originated: $originated, nothing: $nothing, unmeasured: $unmeasured}}'
    exit 0
fi

command -v jq >/dev/null 2>&1 || {
    while IFS= read -r _; do
        printf '{"class": "unclassified", "outcome": "", "reason": "jq_unavailable"}\n'
    done
    exit 0
}

# One jq invocation for the whole window: a per-entry process would cost one fork per tick log
# line for a reading that is pure string work.
jq -R -c "
  . as \$line
  | (try (\$line | fromjson) catch null) as \$obj
  | if (\$obj | type) != \"object\" then
      {class: \"unclassified\", outcome: \"\", reason: \"summary_not_json\"}
    elif (\$obj.outcome | type) != \"string\" or (\$obj.outcome | length) == 0 then
      {class: \"unclassified\", outcome: \"\", reason: \"no_outcome_field\"}
    else
      \$obj.outcome as \$o
      | (\$o | split(\" / \") | map(sub(\"^ +\";\"\") | sub(\" +\$\";\"\")) | map(select(length > 0)))
        as \$segments
      | (\$segments | map(select(${ORIGINATED})) | length) as \$org
      | (\$segments | map(select(${NOTHING})) | length) as \$nil
      | (\$segments | map(select(${UNMEASURED})) | length) as \$unm
      | if   \$org > 0 then {class: \"originated\", outcome: \$o, reason: \"\"}
        elif \$nil > 0 then {class: \"nothing\", outcome: \$o, reason: \"\"}
        elif \$unm > 0 and \$unm == (\$segments | length)
                       then {class: \"unmeasured\", outcome: \$o, reason: \"carries_no_yield\"}
        else {class: \"unclassified\", outcome: \$o, reason: \"token_not_declared\"}
        end
    end
" 2>/dev/null || :
exit 0
