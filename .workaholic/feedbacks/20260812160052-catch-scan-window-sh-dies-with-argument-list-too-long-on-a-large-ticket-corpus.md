---
type: Feedback
title: catch scan-window.sh dies with Argument list too long on a large ticket corpus
kind: instruction
source: discussion
created_at: 2026-08-12T16:00:52+00:00
author: a@qmu.jp
supersedes: 
---

# catch scan-window.sh dies with Argument list too long on a large ticket corpus

Source: https://github.com/qmu/workaholic/issues/387

Reported as an inbound issue. `skills/catch/scripts/scan-window.sh` aborts with

    skills/catch/scripts/scan-window.sh: line 257: /usr/bin/jq: Argument list too long

and emits nothing (exit 126), so `/catch` cannot render a report at all.

Reported cause: in the MISSIONS assembly the script passes the full serialized tickets array
(and the mission list) to jq as command-line arguments —

    MISSIONS=$(
      emit_changelog_events | jq -Rs \
        --argjson list "$MLIST" \
        --argjson tickets "$TICKETS" \
        ...

On Linux a single argv entry is capped at MAX_ARG_STRLEN (128 KiB), independently of the much
larger total ARG_MAX. A repository whose `.workaholic/tickets/` corpus is large (observed:
~1,600 ticket files, whose serialized `$TICKETS` JSON is well past 128 KiB) always exceeds the
cap regardless of the window argument — so `/catch` is permanently broken on exactly the mature
repositories it is most useful for.

Reporter's proposed fix: pass the large JSON through files instead of argv, e.g.

    printf '%s' "$MLIST"   > "$tmp/mlist.json"
    printf '%s' "$TICKETS" > "$tmp/tickets.json"
    emit_changelog_events | jq -Rs \
      --slurpfile list_f "$tmp/mlist.json" \
      --slurpfile tickets_f "$tmp/tickets.json" \
      '... ($list_f[0]) as $list | ($tickets_f[0]) as $tickets | ...'

The reporter states this was verified locally: with the change the same scan completes and
emits the full JSON envelope. They add that the script's other `--argjson` uses carry small
scalars and are fine today, but may deserve the same audit.
