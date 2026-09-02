---
type: Feedback
title: A reference to a skill section is what makes a session reach
kind: instruction
source: slack
subject: person:a@qmu.jp
created_at: 2026-09-02T04:37:18+00:00
author: a@qmu.jp
supersedes: 
---

# A reference to a skill section is what makes a session reach

Source: https://github.com/qmu/workaholic/issues/865

The operator has now reported the Moderate, Propose and Implement routines all sitting at
`requires_action`, repeatedly, and has identified the exact shape from the stuck prompts: a
shell read of the plugin's own files, such as

    sed -n '/One thread per feedback item/,/^## /p' $S/skills/notify/SKILL.md | head -50
    sed -n '/stateless/I,/^## /p' $S/skills/notify/SKILL.md

with `$S` the plugin cache under the container's `~/.claude/plugins/cache`.

The command bodies never contain that sed line; they say "see `workaholic:notify`, *One
thread per feedback item*" by reference, and a routine session resolves the reference the
cheapest way it knows — a shell read of a file under `~/.claude` — which the container
classifies as touching Claude's own configuration and parks the run on a prompt nobody
unattended can answer. `rules/shell.md` already says "do not reach for the shape"; it is
not being obeyed, because **the reference is the thing that makes the session reach**.

The operator's instruction: fix it at the source so a routine cannot stall this way again —

- inline the rule text a command needs into the command itself (the command is the
  ceiling), or state explicitly that a skill section is read with the Read tool and never
  with sed/grep/cat,
- and pin in the test suite that no command or skill body sends a session to read a plugin
  file by reference alone.

The operator adds that the earlier feedback on this ("find what raises the prompt") was
itself deficient for not naming this cause; this record names it.
