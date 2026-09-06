---
type: Feedback
title: A scratchpad redirect must not assume > truncates
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-09-07T07:03:09+09:00
author: a@qmu.jp
supersedes: 
---

# A scratchpad redirect must not assume > truncates

# A scratchpad redirect must not assume `>` truncates

Source: https://github.com/qmu/workaholic/issues/1061

State, where an unattended run will read it, that a shell redirect into the scratchpad must not assume `>` truncates. This machine's shell has `noclobber` set; under it a `>` onto an **existing** path fails and writes nothing, and a run that does not check the exit status then reads whatever was already there.

Measured twice in one session. A `/moderate` tick redirected `run.sh`'s output with `>` onto an existing scratch path, the write failed, and the run began reading a **17-hour-old** JSON from a different tick before noticing. A `/specificate` run wrote a feedback record body with a heredoc onto an existing scratch path; the write failed and the **stale contents of a different issue (#1012)** were carried into the record. That run caught it and rewrote the body before publishing, so what landed on `main` is correct — but the correct content survived by the run's own vigilance, not by anything mechanical. The second occurrence is why this was filed: the first was caught and worked around by the same run that hit it, and the judgement then was to wait for a case where it actually corrupted data. This is that case.

`noclobber` is the operator's own profile setting and is not this repository's to change. Every agent composing a command in this session inherits it, and the failure mode is the dangerous one: **not an error the run sees, but a stale file it reads as fresh.** A run that redirects, then parses, then acts, has no signal that anything went wrong.

The shape asked for is one line in `rules/shell.md`, where composed-shell rules already live: a redirect into the scratchpad uses `>|`, or a filename unique to the run. Not a hook, not a check — the composition happens at run time and appears in no file this repository could scan. It must say two things, because either alone is insufficient: `>` may fail on an existing path and write nothing; and the consequence is a **stale read**, not an empty one.

Non-goals, in the reporter's own words: do not change the operator's shell configuration; do not add a `PreToolUse` guard, because a deny would turn a silent failure into a mid-run refusal, which is a different failure and not obviously better; and do not clean the scratchpad on a schedule, because the directory is session-scoped and its residue is not the defect.
