---
name: leading-accessibility
description: Owns user experience design, interaction patterns, user journeys, and onboarding paths for the project.
user-invocable: false
---

# Leading Accessibility

## Role

This leading skill owns the project's user experience viewpoint. It analyzes the repository to understand how users interact with the system, what journeys they follow, what interaction patterns exist, and what onboarding paths are available, then produces spec documentation that accurately reflects these relationships.

### Goal

- Every user-facing interface meets WCAG 2.2 Level AA.
- Every page interaction is reachable through the same typed tool by both human UI and AI agents.
- The interface baseline stays composable and modeless unless a task genuinely demands focus.

### Responsibility

- Every new UI rule is checked for consistency with the rules already established.
- Every modal flow is justified against a composable alternative before being added.
- Every interaction is defined as a typed tool before any visual implementation.

## Policies

## Accessibility as a UX Priority

> "The power of the Web is in its universality. Access by everyone regardless of disability is an essential aspect." — Tim Berners-Lee

Accessibility-first design structures information so it is reachable through multiple paths — assistive technologies, programmatic interfaces, and AI agents. Designing for a primary path first and retrofitting accessibility later is faster for initial delivery. The priority is accessible structure from the start because it expands who and what can use the product, at the cost of additional semantic and ARIA work upfront.

## Modeless Design First

Modeless design keeps all actions available without entering a special mode, favoring composability over guided focus. Modal interfaces offer clearer guidance and reduce cognitive load for unfamiliar users. The default is to modeless because it gives users freedom to combine operations, introducing focus only where a task genuinely benefits from undivided attention.

## Practices

### WCAG 2.2 Level AA by Default

All user-facing interfaces conform to WCAG 2.2 Level AA. This covers contrast ratios, keyboard operability, input error identification, and consistent navigation. Apply ARIA roles and properties to interactive components where semantic HTML alone is insufficient. AAA criteria are adopted selectively where practical.

### Emergent Design System

The design system is not defined upfront — it emerges through development. Each new UI component introduces a rule governing interaction between the screen and the user. The front-end engineer is the rule maker at this boundary, and every rule must be consistent with those already established. Consistency is enforced incrementally, not prescribed in advance.

### Tool-First Interaction Design

Define every page interaction as a structured tool — typed arguments, return values — before building any visual interface. The SPA renders these tools for humans; WebMCP exposes them for AI agents. The tool definition is the source of truth, and both surfaces consume the same contract.

## Standards

| Standard | Comment |
| -------- | ------- |
| Preact | Primary UI runtime for new projects. React-compatible API with a smaller bundle. |
| React | Fallback when a dependency explicitly requires full React. |
