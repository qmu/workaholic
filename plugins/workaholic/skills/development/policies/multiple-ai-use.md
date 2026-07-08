---
title: Maintaining Use of Multiple AIs
slug: multiple-ai-use
category: development
source: https://qmu.co.jp/development/multiple-ai-use
---

# Maintaining Use of Multiple AIs

_Keeping multiple coding agents — such as Claude Code and Codex — regularly usable so that a failure, rate limit, quality change, or specification change at any single provider does not stop AI-assisted development._

The more AI-assisted development becomes the default approach, the more downtime for any AI service used directly becomes downtime for development. Rather than depending on a single coding agent or LLM provider, keeping multiple generative AI services regularly available — as with Claude Code and Codex together — prevents a failure, rate limit, quality degradation, or specification change at any one service from stopping development itself.

LLM providers and coding agents face outages, rate limits, model behavior changes, and specification changes with some regularity. The same design thinking we apply when building products to be resilient against external service failures applies equally to the development process that builds those products. Diversification applies not only to the running product but to the capacity to keep making it.

## Goal (目標)

The situation this policy aims to achieve is one where major development work can be started and continued with at least two coding agents. If one service goes down, AI-assisted development continues with the other, and the ability to develop with AI does not stop. Not only product availability, but the availability of the process that makes the product is maintained by being able to use multiple AI services. That is the destination we aim for.

Additionally, policy plugins and skills work the same way across multiple coding agents, so that whichever agent development starts from, the same standards enter the working context.

## Responsibility (責務)

The situation this policy aims to prevent is one where tickets, commands, verification procedures, plugins, permissions, and proficiency become so concentrated on only Claude Code, only Codex, or only a single LLM vendor that when that service goes down, development falls back to manual work or stops entirely.

In development where generative AI is the default approach, daily work naturally optimizes toward a specific agent's characteristics and features. Individual optimizations are small, but when the way tickets are written, commands, authentication, and proficiency all converge on a single service, there is no substitute when that service fails. Working fully committed to one agent until an outage arrives — and only then discovering that a fallback has not been maintained — is what this policy aims to prevent.

## Practices (実践)

### Use multiple coding agents daily

Multiple coding agents — such as Claude Code and Codex — are used as part of daily development, not held in reserve as a backup. Even on days when one is used more heavily, the other is kept in working order, and occasionally progressing the same work on a different agent keeps familiarity with both from going stale.

### Do not make tickets, commands, and verification procedures too specific to one agent

Tickets, commands, and verification procedures are written at a level of specificity that can be read and executed by a different agent, rather than being tailored too closely to one agent's particular conventions. When a procedure that only works with one agent is noticed, it is normalized into a form that works with both.

### Keep policy plugins updated on multiple agents

Policy documents and plugin skills are kept updated in a state where they work with both Claude Code and Codex. When a policy is updated, a state where one agent's plugin is at the new version while the other is left at the old version is avoided; the availability of both is confirmed at the same version (see [Policies Distributed as Plugins](policy-as-plugin.md)).

### Maintain the minimum setup to continue on either agent

Authentication, permissions, and environments sufficient to switch quickly to the other agent when one service goes down are prepared in normal operation. Rather than beginning configuration for the first time after a failure, the steps to switch are kept small.

### Observe quota, outages, and model quality changes, and periodically review usage

Each provider's quota, outages, and model behavior changes are observed continuously, and the balance of which work to direct toward which agent is reviewed periodically. Usage patterns are not set once and fixed, but adjusted in response to changes on the service side.

### Related

Multiple AI usage presupposes [Active Use of Generative AI](ai-utilization.md) and does not override any project-level agreements about which data may enter which AI services. When contracts or security conditions limit which AI services can be used, diversification happens within those constraints. Preparedness for not stopping overnight autonomous runs is handled by [Preparing for Overnight AI Operation](overnight-ai.md); the approach of treating multiple services' quotas as sustained capability is handled by [Making Full Use of the Weekly Quota](weekly-quota.md).
