---
type: Feedback
title: Verify the QFS root map by matching, not by counting, and emit add_reaction
kind: insight
source: development
subject: observer_ai:moderate
created_at: 2026-09-09T22:22:45+09:00
author: a@qmu.jp
supersedes: 
---

# Verify the QFS root map by matching, not by counting, and emit add_reaction

Source: the `/moderate` tick `20260909-130713` on this repository, probing the Slack surface for
its own `inbound-sweep` connector entry. Every command below was run in this checkout at that
tick and its output is quoted verbatim.

## What was measured

Three records written today — `20260909091200`, `20260909104345`, `20260909171204` — each report
the same symptom: `describe-native-qfs.sh` answers `map_verified: false` with the limitation
`root_map_unverified_or_ambiguous`, so `post_root` is offered by no route, so
`resolve-target.sh` defers `operations_unsatisfied`, so nothing the loop owes anybody is
delivered. None of them says **why the map cannot verify**. This record is that diagnosis, and it
falsifies the assumption that the closed mission `make-the-declared-slack-route-speak-be-seen-and-be-named`
would clear the condition: that mission is archived `achieved` and the binding still resolves to
nothing.

**1. The uniqueness test cannot hold, because the path legitimately carries one map per write verb.**
`describe-native-qfs.sh` derives `post_root` from

```
maps_for("/slack/{ws}/{channel}/messages") as $root |
(($root|length)==1 and ($root[0].body|contains("chat.postMessage"))) as $post
```

Asked directly, that path carries **six** maps, not one:

```
qfs run "/sys/drivers |> where kind == 'map' AND name == '/slack/{ws}/{channel}/messages' |> select name, body"
```

returns six rows whose Insert targets are `http.slack.chat.postMessage`, `http.slack.reactions.add`,
`http.slack.pins.add`, `http.slack.pins.remove`, `http.slack.chat.update` and
`http.slack.chat.delete` — one per Slack write verb the driver exposes on the message collection.
Exactly one of them **is** `chat.postMessage`, unambiguously. `($root|length)==1` is therefore
false and can never be true while the driver exposes more than one write verb there, so
`map_verified` is false for a map that is present and correct. The limitation word
`root_map_unverified_or_ambiguous` names an ambiguity that does not exist: the reading is not
ambiguous, the test is.

The script's own header already knew the shape — *"procedures can expose several maps with the
same target, which is not proof that a text INSERT selects chat.postMessage"* — and then guarded
on the count instead of on the match. Selecting the one row whose body contains `chat.postMessage`
is the reading the header describes.

**2. `add_reaction` is emitted by nothing, so a binding that declares it can never resolve.**
The `operations` array in `describe-native-qfs.sh` is built from `read_channel_delta`,
`read_thread`, `search_exact`, and conditionally `list_thread_changes`, `post_root`, `post_reply`.
`add_reaction` appears in no branch, and `reaction_map_unverified` is appended to `limitations`
unconditionally. The `reactions.add` map exists — it is row 2 of the six above — so the capability
is real and is advertised nowhere.

This repository's `AGENTS.md` declares `add_reaction` among its required operations, and
`plugins/workaholic/commands/moderate.md` requires the tick to react `:ballot_box_with_check:` on
an answer it recorded. `resolve-target.sh` verifies the declared operations as one inseparable
binding, so this one unemittable operation alone refuses the whole binding — including the
`post_reply` and `read_channel_delta` the routes **do** offer.

Measured at this tick against the declared binding (`declared_digest 953c1ab7f2f9ab3c395828af767506b6`):

```
required: read_channel_delta, read_thread, list_thread_changes, post_root, post_reply, add_reaction
offered:  post_reply, read_channel_delta, read_thread, search_exact
status:   deferred / operations_unsatisfied
```

`/slack-cc01-qmu` and `/slack-cdx01-qmu` both answer `channel_verified: true` on `C0BLL9J7FMY`;
`/slack-clauyo` and `/slack-yodex` answer `channel_unreadable`. So a route reaches the channel,
can reply into a thread, and is refused wholesale over two operations one describer never emits.

## Why this is not a duplicate of the three records it follows

Those three record the symptom and its consequences: replies refused at `qfs-native.sh:63`
(`20260909091200`), the connector taking over under a person's identity (`20260909104345`), and
the finding brake starved by one issue per hour (`20260909171204`). The last of them names the
repair as *"a code gap, already queued as the active mission
`make-the-declared-slack-route-speak-be-seen-and-be-named`"*. That mission closed `achieved` on
2026-09-09 with all three acceptance items checked — it repaired the preview guard, named the
thread-discovery gap, and made an unprovable sender a refusal — and none of its items touched the
map test or `add_reaction`. The condition it was expected to clear is unchanged.

## What this names

Two bounded readings in `plugins/workaholic/skills/transport/scripts/describe-native-qfs.sh`:

1. Verify the root map by **matching** rather than by counting — select the row at
   `/slack/{ws}/{channel}/messages` whose body targets `chat.postMessage`, exactly as the script's
   own header describes, and keep `root_map_unverified_or_ambiguous` for the case where none
   matches or two do.
2. Derive `add_reaction` the same way from the `reactions.add` map on that path, so
   `reaction_map_unverified` is a reading rather than a constant.

Whether the declaration in `AGENTS.md` should keep requiring `list_thread_changes`, which the
mount answers `threads_not_selectable` for, is a separate operator judgement this record does not
make.

## Non-goals

No Slack credential, no bot identity, no connector fallback, no change to
`resolve-target.sh`'s all-or-nothing binding rule, and no re-proposal of anything #806 carries.
