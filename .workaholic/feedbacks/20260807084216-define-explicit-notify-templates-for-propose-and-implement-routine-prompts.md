---
type: Feedback
title: Define explicit notify templates for /propose and /implement routine prompts
kind: instruction
source: slack
created_at: 2026-08-07T08:42:16+00:00
author: a@qmu.jp
supersedes: 
---

# Define explicit notify templates for /propose and /implement routine prompts

Follow-up to #298/#299 (agents must not self-authorize notification formats beyond what
the routine prompt specifies). This issue supplies the explicit templates that the
`workaholic:notify` routine prompts for `/propose` and `/implement` should use, so agents
have a specified format to follow rather than inferring one.

## Templates

### [Propose]

Read the feedback (FB) from the Issue and find its reply thread (the `workaholic:notify`
lookup).

Notify the thread that the design process has started:
```
:triangular_ruler: Proposing for [#123 FB Issue Title](https://github.com/org/repo/pull/123)
by Claude Code on the Web of <@U…>
```

After running `/propose [FB]`, notify the thread in the following format:
```
:white_check_mark: Proposed [#123 [Proposal] PR Title](https://github.com/org/repo/pull/123)
by Claude Code on the Web of <@U…>
```

### [Implement]

Read the Mission/Ticket from the PR and find its reply thread (the `workaholic:notify`
lookup).

Notify the thread that implementation has started:
```
:hammer_and_wrench: Implementing for [#123 Proposal PR Title](https://github.com/org/repo/pull/123)
by [Claude Code on the Web](https://claude.ai/code/session_***) of <@U…>
```

After running `/implement [Mission/Ticket]`, notify the thread in the following format:
```
:white_check_mark: Implemented [#123 Title](https://github.com/org/repo/pull/123)
by [Claude Code on the Web](https://claude.ai/code/session_***) of <@U…>
```

## Ask

Update the `workaholic:notify` skill/routine-prompt documentation to encode these
templates exactly, as the sole sanctioned notification formats for these two routines.

Source: https://github.com/qmu/workaholic/issues/300
