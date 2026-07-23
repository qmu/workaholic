---
title: Maintaining Multiple AI Options
slug: multiple-ai-use
category: development
source: https://qmu.co.jp/development/multiple-ai-use
---

# Maintaining Multiple AI Options

_Keeping multiple generative AI tools available in daily development instead of depending on a single coding agent or LLM provider, so one service outage does not directly stop AI-assisted development._

The more generative AI becomes the default means of development, the more time lost by an AI service becomes development time lost as-is. We do not depend only on a single coding agent or LLM provider. By keeping multiple generative AI tools, such as Claude Code and Codex, available in daily work, we aim to avoid a state where an outage, rate limit, quality change, or specification change in one service stops development itself.

LLM providers and coding agents face outages, rate limits, changes in model behavior, and specification changes with some regularity. We apply the same way of thinking used when designing products against external service failure to the development process that creates those products. The object of diversification is not only the product that runs, but also the capability to keep building it.

## Goal (目標)

We aim for a state where major development work can be started and continued by at least two coding agents. Even if one service stops, AI-assisted development continues through the other, and development with AI itself keeps moving. The availability we preserve is not only product availability but also the availability of the process that builds the product. That is the direction we set.

At the same time, we aim for a state where policy plugins and skills can be used in the same way from multiple coding agents, so the same standards enter the work context no matter which agent starts the work.

## Responsibility (責務)

We avoid a state where procedures, tickets, plugins, permissions, and proficiency lean only toward Claude Code, only toward Codex, or only toward a single LLM vendor, so that development returns to manual work or stops when that one service stops.

In development where generative AI is the default means, daily work tends to become optimized around the habits and features of a specific agent. Each optimization may be small, but if ticket writing, commands, authentication, and proficiency all lean into one service, there is no substitute on the day that service stops. A team can keep running while leaning completely to one side, and only notice during an outage that the alternative path has not been cultivated.

## Practices (実践)

### Use multiple coding agents in daily work

Use multiple coding agents, such as Claude Code and Codex, in everyday development rather than only as backups. Even on days when one is primary, keep the other in a working state, and occasionally move the same work forward with the other agent so the practical sense for both does not dull.

### Do not make tickets, commands, or verification procedures too agent-specific

Write tickets, commands, and verification procedures at a granularity another agent can read and execute, without leaning too far into the notation specific to one agent. When a procedure is found to work only with one agent, smooth it into a form that both can run.

### Keep policy plugins updated across multiple agents

Keep policy documents and plugin skills updated in a state usable by both Claude Code and Codex. When a policy is updated, avoid leaving only one plugin fresh while the other remains old; confirm both agents' availability against the same version ([Policy as Plugin](policy-as-plugin.md)).

### Keep the minimum setup needed to continue on either side

Prepare authentication, permissions, and environment settings in normal times so that when one service stops, work can immediately switch to the other. Do not leave setup to begin only after an outage; keep the number of steps for switching small.

### Observe quota, outages, and model-quality changes, and revisit usage split

Continuously observe each provider's quota, outages, and changes in model behavior, and periodically revisit which work should lean toward which agent. The split is not something decided once and fixed; it continues to be adjusted as services change.

### Related: Active Use of Generative AI and Policy as Plugin

Multiple AI use assumes [Active Use of Generative AI](ai-utilization.md) and does not override project-by-project agreements about what information may be entered into AI. When contract or security conditions limit which AI services may be used, diversification happens within that range. Preparing so overnight autonomous work does not stop is covered by [Preparing for After-Hours AI Work](overnight-ai.md), and treating multiple services' quotas as continued capability is covered by [Using the Weekly Quota Fully](weekly-quota.md).
