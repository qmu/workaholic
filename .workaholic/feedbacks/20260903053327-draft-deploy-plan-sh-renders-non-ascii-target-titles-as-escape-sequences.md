---
type: Feedback
title: draft-deploy-plan.sh renders non-ASCII target titles as escape sequences
kind: instruction
source: development
subject: person:a@qmu.jp
created_at: 2026-09-03T05:33:27+09:00
author: a@qmu.jp
supersedes: 
---

# draft-deploy-plan.sh renders non-ASCII target titles as escape sequences

Source: https://github.com/qmu/workaholic/issues/918

`skills/ship/scripts/draft-deploy-plan.sh` builds each deployment target section heading from
the record title as it arrives in JSON, so a non-ASCII title reaches the Release Note as
literal \uXXXX escapes instead of characters. Measured on 2026-09-03 during a /ship run
against a target whose record has a Japanese title, the drafted section came out as escape
sequences and had to be decoded by hand before the note could be committed.

`read-deployments.sh` prints the same escaped form on stdout, so the escaping most likely
survives from that JSON straight into the Markdown writer.

Asked for: decode the JSON string before it is written into the heading, and anywhere else a
record field reaches Markdown, so a non-ASCII deployment title renders as text. The plan is
written to be read by people, and a heading made of escape sequences is unreadable for every
project that does not name its targets in English.
