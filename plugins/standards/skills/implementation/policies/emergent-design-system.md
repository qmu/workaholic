---
title: Emergent Design System
slug: emergent-design-system
category: implementation
source: https://qmu.co.jp/implementation/emergent-design-system
---

# Emergent Design System — Rather than fixing the design system in advance, progressively enforcing the consistency of the rules introduced with each UI component

The emergent design system expresses our front-end's policy of not maintaining a "giant, predefined design system." We let the design system *emerge* in the course of development. Every time a new UI component is added, it introduces *one rule* governing the interaction between the screen and the user, and the front-end engineer becomes the *rule-maker* at that boundary. Every rule must be consistent with the existing rules, and that consistency is not prescribed in advance — it is enforced progressively.

## Goal (目標)

The situation this policy aims to achieve is a state in which the weight of a rule is *directly tied to the judgment made at the moment that rule is introduced*. We do not assemble a giant system of design tokens up front; when a need arises, we derive the rule from that need.

The outline of the goal is as follows:

- The design system can be read as a *record* of past decisions (every fixed convention is derived from the motivation behind some UI change).

- Developers and AI agents who add a new UI component make their design decisions conscious of "which rule am I now becoming the maker of?"

- Rules that have already been introduced are not *silently overwritten* by later components.

- The organizing of rules (refactoring, consolidation) is discussed with the same weight as the introduction of the rules themselves.

## Responsibility (責務)

The situation this policy aims to prevent is a state in which the responsibility for the judgment at the moment a rule is introduced remains ambiguous, and consistency with the existing rules is progressively lost.

States we do not tolerate:

- A movement to "fix the rules in advance." Defining a giant set of design tokens, a typography scale, and a spacing system all at once, before the components themselves exist as concrete entities. This is the opposite of emergence, and rules divorced from actual judgment cease to be observed.

- Overwriting a rule silently. A state in which a new component contradicts the existing rules for the focus ring, error display, or button states, yet that inconsistency is absent from the discussion in the PR.

- "It's different from the existing code because I made it by copy-paste." Transcribing styles from somewhere else without regard for the existing rules.

- Using "because it isn't in the design system" as a reason to get by without creating a rule that is needed. The reason a rule does not exist is simply that no one has yet become its maker. When a need arises, that person becomes the maker.

- Deferring the organizing of rules with "we'll refactor it someday." As the volume of emergent rules grows, organizing / consolidating / turning them into a public API is treated with the same weight as ordinary development work.

## Practices (実践)

### Introduce one rule per component

When you create a new UI component, that component introduces *at least one rule* governing the interaction between the screen and the user. The appearance on focus, the expression of the error state, the behavior on hover, the number of states (disabled / loading / success / error), transitions, spacing — all of these are rules.

The developer or AI agent, each time they write a component, is conscious of "which rule am I making right now?" The rule is recorded in the PR description or in the documentation adjacent to the component.

### Confirm consistency with existing rules first

Before introducing a new rule, perform an *exploration of the existing rules*. The color and width of the focus ring, the position and wording of the error display, the number of button states, the naming of components — if there is an existing convention, adopting it is the default.

A minimal checklist for the search (the same approach as *Respecting Established Expressions*):

- Look for existing implementations of components that play the same role.

- Check shared style variables and CSS custom properties.

- If a Storybook or style guide exists, survey it across the board.

When you cannot make the new rule consistent with the existing rules, treat it as an *evolution of the rule*, and leave that judgment in the PR description.

### Organizing rules is part of ordinary development work

The rules that proliferate through emergence develop a need for organizing as their volume grows. Organizing — that is, refactoring — is treated with the same weight as feature development and is not put off.

- If the same rule is scattered, hand-written, across multiple places, roll it up into a shared variable, a shared component, or a mixin.

- If contradicting rules sit side by side, make one of them canonical and change the other.

### Documentation of a rule records the "decision," not the "usage"

What you write in the design system's documentation is not the usage API of the component, but *the rule that the component introduced*. You leave behind "why this spacing," "why this color," "why this number of states."

The usage API can be left to whatever a tool can generate from the code. The decisions are the record of judgments that a tool cannot generate.

### The questions to ask when writing a component

Each time they write a new component, the developer or AI agent poses the following questions to themselves:

- *Which rule* governing the interaction between the screen and the user does this component introduce?

- Does it not contradict the rules introduced by existing components? If it does, why should it evolve here and now?

- Is this rule made *discoverable* for later developers?

### Examples of rules — the things front-end engineers establish day to day

The rules of a design system sound abstract, but their substance is everyday. Examples:

- Consistency of the focus ring: are the color, width, and offset aligned across pages?

- Position of the error display: directly below the input field, in a summary at the top of the form, or both? Does it not waver from component to component?

- Number of button states: of idle / hover / focus / active / disabled / loading, which ones are expressed? The distinguishability in appearance between disabled and loading.

- The semantics of icons: is the use of an icon on its own permitted, or must it always be accompanied by a label?

- The unit of spacing: 4px steps, 8px steps, or both?

- Animation duration: is there a limited candidate set, such as 100ms / 200ms / 300ms?

- The expression of "loading": a spinner, a skeleton, or a placeholder — which one is chosen in which situation?

These are not "things written in the design system" but "things the author decides each time they write a component." Emergence means deciding these things *consciously rather than unconsciously*.

### Code review is also a review of rule-making / evolution

In the review of a UI-related PR, you read not only the correctness of the code but also *which rule that PR introduced or evolved*. The reviewer is the last line of defense for keeping the rules consistent.

### Use Storybook or a UI catalog as a "record of results"

Storybook (Storybook, Histoire, and the like) is used not to *fix the design system in advance*, but to *organize the emergent rules as results*. Rather than designing the Storybook first, use it as a tool for surveying across the board once the components have come together.

### Related: Accessibility-First, WCAG 2.2 AA

The emergent design system is also the place where the rules of *Accessibility-First* are implemented at the component level. The rules that a new component introduces must not contradict these higher-level policies.
