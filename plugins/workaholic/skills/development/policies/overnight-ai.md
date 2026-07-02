---
title: Preparing for Overnight AI Operation
slug: overnight-ai
category: development
source: https://qmu.co.jp/development/overnight-ai
---

# Preparing for Overnight AI Operation

_Structuring the workday around creating well-specified tickets and pre-answering anticipated judgment calls so AI can run uninterrupted through the night._

The hours when humans work and the hours when AI can run are not the same. Because AI can keep running through the night while humans rest, preparing to allow long autonomous operation after business hours means the effective working time per day can be extended to a scale of over ten hours rather than a human's eight. Business hours are better spent not consuming tickets yourself, but creating tickets that AI can run through all night and pre-answering judgment calls in advance.

## Goal (目標)

We aim for a state in which AI keeps running without stopping while humans rest, and the results of the previous night's run are organized by morning. We aim for a state in which judgment is pre-answered sufficiently, AI does not stop through the night waiting for human confirmation, and the prepared tickets are run through to completion.

## Responsibility (責務)

Our responsibility is to prevent a state where AI is stopped by unanswered judgment calls during hours it could be running through the night, or where no one verifies the output and the results are trusted as-is. Overnight operation operates on the premise that humans are not there. If tickets are sent through with points where AI would want to ask for judgment left unresolved, AI stops there and the time that could have been run for a long stretch is wasted. Conversely, if AI is given a blank check to avoid stopping it, unverified inferences pile up in the code. It is easy to fall into a state where neither the work of pre-answering judgment nor the path for humans to verify after completion has been arranged, and the overnight run is left on its own.

## Practices (実践)

### Prepare to run for a long stretch after business hours

At end of business, we put together the conditions for AI to run autonomously through the night. We launch with the `/goal` command, lock the screen, and extend the time until sleep. We also confirm the execution environment and permission preconditions before the end of business so the run does not stop midway.

### Spend business hours on ticket creation rather than ticket consumption

During the day, we spend more time on creating tickets that AI can run through overnight than on consuming tickets ourselves. We increase time spent on scoping what to build and shaping it into a runnable form, rather than on hands-on implementation.

### Pre-answer judgment calls AI would want to ask

When creating tickets, we identify in advance the points where AI would want to ask for judgment and write the answers to those questions into the ticket. We eliminate the causes of stopping in the night before the run starts.

### Collect remaining judgment calls for verification after completion

Judgment calls that still require human input even so are not left as a stopping point — they are carried over and verified by humans together after all tickets have been run through. We let AI run as far as it can through the night, and collect judgment calls for morning verification.

### Begin the workday by reviewing the previous night's results

Each day's work begins by reviewing the results of the previous night's run. After seeing what was run through and where judgment is needed, we move on to that day's ticket creation.

### Related: Active Use of Generative AI, Code Review as a Non-Default Practice

Related: [Active Use of Generative AI](ai-utilization.md) and [Code Review as a Non-Default Practice](review.md).
