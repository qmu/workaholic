---
type: Feedback
title: Say when the thread resolver could not see, not that nothing was there
kind: instruction
source: development
subject: observer_ai:tamura.yoshiya@gmail.com
created_at: 2026-09-06T14:16:10+09:00
author: a@qmu.jp
supersedes: 
---

# Say when the thread resolver could not see, not that nothing was there

An observing AI session reports that the finish-line step in `commands/infinite-development.md` resolves an item's thread with a Slack **search** for the `fb:<stem>` exact string, and that in a consuming workspace that search cannot see the messages it must find — so the step has never announced anything, and it reports its own blindness in a word that reads as absence.

Source: https://github.com/qmu/workaholic/issues/1025

## What the ask reports

`list-unannounced-closed-asks.sh` returned ten candidates, every one with `landed_read: "ok"` and a populated `landed[]`. Every `fb:<stem>` search returned no results. One of those roots demonstrably exists: the connector's channel reader returns it in full, posted that morning, carrying the literal `fb:` line the search was given. Two further searches narrowed to the channel with bots included — one on a short fragment of the stem, one on the message's own visible Japanese title — also returned nothing. The messages are posted through an integration and are not indexed by search in that workspace.

## Why the reported word makes it worse

The contract's outcome for this is `thread_unresolved: <reason>`, defined as *the search matched nothing, or matched more than one thread*. A conformant run therefore reports what reads as *this item has no thread*, when the true fact is *I could not see the thread*. The command body elsewhere insists on exactly that distinction ("*Nothing finished* and *I could not see what finished* send a reader to different places"), and the blindness guard that exists was written for the candidate reader (`ok: false`), never for the thread resolver.

## What it asks for

- Give the thread resolver its own blindness word, so a search that matched nothing while working is told apart from a resolver that cannot see.
- Allow the connector's channel reader as a resolution path, at least as a fallback when search returns nothing. It is the same connector and the same exact-string match on content the run has already fetched, so it does not touch the *Fuzzy matching is prohibited* rule the search-only design was protecting. Its honest bound is that channel history is finite, which `thread_unresolved: out_of_window` would state truthfully.
- Keep the tie going to silence either way; nothing here argues for posting into a guessed thread.

## How this run judged it

**Record-only, `self_authored`.** The ask carries `subject: observer_ai:tamura.yoshiya@gmail.com`, so `feedback/scripts/ask-origin.sh` reads `machine`; its subject is the loop's own apparatus — the tick's announcement step and the stateless thread lookup. `plugins/workaholic/rules/workaholic.md`, *What May Originate a Mission*, is explicit that such a record may not originate a mission. The finding is kept as knowledge; a human ask naming this work is what would originate it.
