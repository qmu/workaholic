#!/bin/sh -eu
# loop-table.sh — THE ONE DECLARATION of the local loops: name | interval | the prompt
# `/loop` repeats. Sourced by spawn-loops.sh, loop-status.sh and stop-loops.sh; nothing
# else may carry a second copy of a cadence or a prompt.
#
# The prompt is a `/loop` argument, so it is what an interactive session would type: a
# slash command, or a short sentence naming two of them in order. Every runtime rule stays
# in the command it names (the command is the ceiling, `workaholic:notify`).
#
#   propose    5m   supplies the ask (Slack replies, the inbound sweep, the strategy
#                   judgement) and then ingests it — the FB half is inside propose
#   implement  5m   drives what is queued, in claim worktrees of its own clone
#   moderate   30m  the maintenance tick, at a beat its acts are actually made for

loop_table() {
  printf '%s\n' \
    'propose|5m|Run /propose, then run /specificate.' \
    'implement|5m|Run /implement.' \
    'moderate|30m|Run /moderate.'
}
