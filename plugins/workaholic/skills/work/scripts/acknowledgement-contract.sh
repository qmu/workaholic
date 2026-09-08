#!/bin/sh -eu
# Validate and group the facts an inbound Slack acknowledgement must render.
# Usage: acknowledgement-contract.sh --input <facts.json>
#
# The agent still writes the sentence in the person's language. This reader owns
# the load-bearing facts separately: recognizable subject, issue, truthful state,
# source coordinate, grouping, and the reaction owed to every captured message.

INPUT=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --input) INPUT=${2:-}; shift 2 ;;
    *) printf '{"ok":false,"reason":"unknown_argument"}\n'; exit 2 ;;
  esac
done

[ -n "$INPUT" ] && [ -s "$INPUT" ] || {
  printf '{"ok":false,"reason":"input_required"}\n'
  exit 2
}

if ! jq -e '
  type == "object" and
  (.batch_id | type == "string" and length > 0) and
  (.items | type == "array" and length > 0) and
  (all(.items[];
    (.position | type == "number" and . > 0 and floor == .) and
    (.source_ref | type == "string") and
    (.source_ref | test("^[^:[:space:]]+:[0-9]+(\\.[0-9]+)?$")) and
    (.subject | type == "string") and
    (.subject | gsub("[[:space:]]"; "") | length > 0) and
    (.issue_url | type == "string") and
    (.issue_url | test("^https://github\\.com/[^/]+/[^/]+/issues/[0-9]+$")) and
    (.workflow_state == "captured_for_specification" or
     .workflow_state == "deferred_for_decision" or
     .workflow_state == "proposed_for_queue") and
    ((.related_as == null) or ((.related_as | type == "string") and (.related_as | length > 0))))) and
  ([.items[].position] | length == (unique | length)) and
  ([.items[].source_ref] | length == (unique | length))
' "$INPUT" >/dev/null 2>&1; then
  printf '{"ok":false,"reason":"invalid_facts"}\n'
  exit 2
fi

jq -c '
  def next_step:
    if . == "captured_for_specification" then "specificate"
    elif . == "deferred_for_decision" then "human_decision"
    else "implementation_queue"
    end;
  .items |= sort_by(.position) |
  .items |= map(. + {next_step:(.workflow_state | next_step)}) |
  . as $root |
  [ .items[] | . + {
      receipt_key:(if .related_as == null then "source:" + .source_ref else "related:" + .related_as end)
    }
  ] |
  group_by(.receipt_key) |
  map(sort_by(.position) | {
    key:.[0].receipt_key,
    thread_ref:.[0].source_ref,
    items:map({position,source_ref,subject,issue_url,workflow_state,next_step})
  }) |
  sort_by(.items[0].position) |
  {
    ok:true,
    batch_id:$root.batch_id,
    receipt_count:length,
    receipts:.,
    reaction_refs:([$root.items[] | .source_ref]),
    prose:{natural:true,required_language:"person",max_words:80,completion_promise:false}
  }
' "$INPUT"
