---
title: Making Full Use of the Weekly Quota
slug: weekly-quota
category: development
source: https://qmu.co.jp/development/weekly-quota
---

# Making Full Use of the Weekly Quota

_Treating the prepaid weekly AI subscription quota as a fixed cost that should produce value before reset, directing unused capacity toward overnight runs, refactoring, security checks, and research._

The cost of an AI subscription is a fixed fee that does not change no matter how much AI is run in a given week. Plans come with a per-week use-it-or-lose-it quota, and any amount unused when the reset arrives does not carry over to the next week. Leaving quota unused means a portion of the prepaid fixed cost does not turn into output, while consuming it only to reach a usage number — without real substance — produces no output either. We organize work on the premise of using the quota close to its limit with valuable work, directing overnight autonomous operation (see [Preparing for Overnight AI Operation](overnight-ai.md)) and consideration with smarter models as the destinations for that consumption.

In the first place, the allocated quota is large, and filling it is not achievable by individual operational ingenuity alone. Quota is filled with valuable work only when there is the planning capability to continuously conceive and execute worthwhile development. Avoiding wasteful consumption goes without saying, but we also consider the ability to make effective use of the quota — using it up — as one of the capabilities we need to cultivate.

## Goal (目標)

We aim for a state in which the weekly quota is filled with valuable work and used up before reset, with the prepaid fixed cost turning into that much output. We aim for a state in which the team has the capacity to plan meaningful development one after another to fill the quota, and AI's processing capacity is turned out into meaningful work — neither letting quota go to waste nor burning it with processing that only fills the count.

## Responsibility (責務)

Our responsibility is to prevent a state in which the prepaid weekly quota ends the week without turning into output. Quota is use-it-or-lose-it and unused portions do not carry over. If too much is directed toward humans consuming things by hand during the day, AI's running volume does not reach the quota before the week ends, and a portion of the paid fee disappears without turning into output. Conversely, if filling the quota becomes the goal and tokens are burned on processing that produces no value, the usage count reaches the limit but no output remains. It is easy to fall toward both letting quota go to waste and meaninglessly using it up, ending a week with fixed costs that did not turn into output.

## Practices (実践)

### Plan development continuously enough to fill the quota

Whether the quota can be used up depends more on whether meaningful development can be readied one after another than on operational ingenuity about how to run. We spend time on proposing, planning, and shaping into a runnable form development that can be handed to AI — rather than on hands-on implementation — so that work to fill the quota is never in short supply.

### Direct quota toward refactoring

We use refactoring — which tends to be pushed back during normal feature development — as a destination for quota when it looks like there will be surplus. Work that restructures without changing behavior has no urgent deadlines, making it a good destination for consuming quota in a valuable form.

### Direct quota toward security checks

We direct quota toward safety-side verification such as vulnerability identification and dependency inspection. We redirect quota toward security checks that tend to be difficult to make time for in weeks when we are not pressed by deadlines.

### Direct quota toward research

We direct quota toward investigation of new methods, libraries, and design alternatives. Investigation that does not immediately move to implementation tends to be pushed back, so we turn quota surplus into time for that.

### Raise the ceiling with smarter models and higher effort

With the arrival of ultracode, the `/goal` command, and the Fable model, we have the option to run the same work with smarter models and higher effort. When quota looks like it will be surplus, we raise effort or token consumption appropriately to replace shallower consideration with deeper work. We increase consumption in the direction of raising output quality, not to fill the quota.

### Make overnight autonomous operation the primary destination for consumption

Because human-driven work alone makes it difficult to use up the quota, we direct overnight autonomous operation (see [Preparing for Overnight AI Operation](overnight-ai.md)) as the primary destination for the quota. We prepare tickets that can be run through the night and redirect the quota that is open during the day to running through them.

### Related: Active Use of Generative AI, Preparing for Overnight AI Operation

Related: [Active Use of Generative AI](ai-utilization.md) and [Preparing for Overnight AI Operation](overnight-ai.md).
