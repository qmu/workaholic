---
title: UI That Requires No Manual
slug: self-explanatory-ui
category: design
source: https://qmu.co.jp/design/self-explanatory-ui
---

# UI That Requires No Manual

_Design every interface element so that its purpose and correct usage are apparent from the element itself; if a manual is needed to explain a screen, the screen needs redesign._

A user who reaches a screen and cannot tell what to do, or a user who completes a flow but is unsure whether it worked, is experiencing a design failure. The remedy is not documentation but better information design: clearer labels, visible affordances, explicit feedback, and a layout that guides attention without prescribing a path. A UI that does not need documentation to operate also tends to be more accessible, more testable, and more easily navigated by AI agents.

## Goal (目標)

The situation this policy aims to achieve is one in which a new user can accomplish primary tasks on their first encounter with the interface, without consulting documentation or asking for help.

- Every action's label describes what it does, not what it is named in the database or codebase.
- State changes produce immediate, legible feedback. A user who has completed an action knows they have completed it.
- Error messages explain what happened and what the user can do next, rather than reporting a technical condition.
- Empty states and loading states are designed — they are not absence of content.

## Responsibility (責務)

The situation this policy aims to prevent is one in which the interface's correct operation depends on prior knowledge, documentation, or training.

States we do not tolerate:

- Icon-only controls without labels or accessible text, whose meaning is not inferrable from context.
- Forms that accept input but do not validate it until submission, then report errors that offer no guidance on correction.
- Success or failure states that are not signaled. A user who submits a form and sees nothing happen does not know whether to try again.
- Empty states that display nothing. A table with no rows should explain why — "No items yet. Add one to get started." — rather than presenting a blank.
- Onboarding that consists of a tooltip walkthrough over a feature-complete interface. Onboarding that is needed is a signal that the interface is not yet self-explanatory.

## Practices (実践)

### Write labels from the user's vocabulary, not the system's

Labels, placeholders, and help text use the words the user would naturally use to describe the action, not the technical names of the underlying operations. "Save draft" rather than "PUT /articles/:id/draft". "Remove from project" rather than "Delete assignment record".

### Design every state: loading, empty, error, and success

Before a screen is considered complete, all four states have been specified: what it looks like while loading, what it looks like when empty, what it looks like when an error has occurred, and what it looks like when an operation has succeeded. A design that only specifies the "data present, no error" state is incomplete.

### Make error messages actionable

Error messages include: what happened, and what the user can do about it. "Something went wrong" is not an error message. "Couldn't save — check your connection and try again" is. For form validation errors, position the message adjacent to the field that caused it.

### Related: Modeless Design, Elimination of Dark Patterns, Accessibility Open to AI

Self-explanatory UI and [Modeless Design](modeless-design.md) are complementary: modeless design keeps all operations reachable; self-explanatory UI ensures those operations can be understood without guidance. Both connect to [Accessibility Open to AI](../../planning/policies/accessibility-first.md), since clear labels and defined states are the foundation of accessible interaction. [Elimination of Dark Patterns](no-dark-patterns.md) defines what the UI should avoid.
