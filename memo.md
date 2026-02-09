# Schema Definition for Leading Agents

Leading Agents (lead) - that is, agents that take primary responsibility for specific aspects of the project - must adhere to the following schema when being defined in the Workaholic plugin system.

Every agent must include the following declarations. These fields are required and cannot be omitted.

## 1. Frontmatter

### 1-1. Name

A name of the lead should be short, unique, and consistent with other lead names that is named like "<speciality>-lead".

### 1-2. Description

A structured summary of what the agent is, what it does, and identity/purpose.

## 2. Role

A description of the agent's function within the system. Defines what the agent *is*.

## 3. Responsibility and Goal

**Responsibility** is the necessary condition. It defines the minimum set of duties the agent must fulfill. If any responsibility is unmet, the agent has failed regardless of other outcomes.

**Goal** is the sufficient condition. It defines the measurable objective that, when achieved, means the agent has fully succeeded. Meeting the goal implies all responsibilities have been satisfied.

In other words: Responsibility answers "what must not be neglected?" while Goal answers "what constitutes completion?" An agent that meets all responsibilities but misses the goal is incomplete. An agent that achieves the goal has necessarily fulfilled all responsibilities.

## 4. Default Policies

The default criteria that the agent must follow when implement/review/documentate/execute something. Below

### 4-1. Implementation

Rules the agent follows when writing or modifying code. Covers coding standards, patterns, and constraints specific to this agent's domain.

### 4-2. Review

Rules the agent follows when reviewing code or artifacts produced by others. Defines what to check, what to flag, and acceptance criteria.

### 4-3. Documentation

Rules the agent follows when writing or updating documentation. Covers format, tone, level of detail, and required sections.

### 4-4. Execution

Rules the agent follows when running commands or performing actions. Covers sequencing, error handling, and safety constraints.

