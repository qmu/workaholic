---
title: Modeless Design
slug: modeless-design
category: design
source: https://qmu.co.jp/implementation/modeless-design
---

# Modeless Design

_Make every operation available without entering a "mode," and prioritize composability over the strength of step-by-step guidance._

Modeless design is a policy that prioritizes keeping every operation available to the user without requiring them to enter a particular "mode." It places composability above the strength of guiding the user step by step. We make modelessness the default in order to leave users the freedom to assemble their own workflow, because that freedom is what sustains the flexibility of the experience over the medium and long term.

## Goal (目標)

The situation this policy aims to achieve is one in which users can choose the combinations of operations themselves. We create a state where users can reach any operation they need at any time, without having to remember what mode the application is currently in.

The outline of the goal is as follows:

- The entry points to operations do not depend on the current mode, step, or wizard state.
- "Going back," "interrupting," and "working in parallel" hold up naturally, with no special handling.
- The UI does not force guidance on the user in situations where they do not need it.
- Focus is introduced only at the moments where concentration is genuinely required (confirming destructive operations, or processing that cannot be reversed once submitted).

## Responsibility (責務)

The situation this policy aims to prevent is one in which the user's freedom to operate is taken away without design justification, and the right to "not have to notice" mode switches is not respected.

States that are not tolerated:

- Flows where modals keep stacking by default. A UI in which a modal appears every time a task advances, so that the previous state disappears from the screen.
- Creating, without design justification, a state where "you cannot perform other operations until you leave this mode." Do not trap the user in a linear sequence of steps in situations where concentration is not required.
- No clearly indicated means of leaving a mode. Leave multiple exits — Esc, the × button, clicking the background, keyboard shortcuts, and so on.
- A modal that traps focus while leaving no way to return from inside it to the external context. Confine focus, but do not confine context.
- A UI that treats "users who do not follow the steps" as exceptions. Wanting to skip a step, go back, or work in parallel is ordinary usage, not an exception.

## Practices (実践)

### Modeless by default, modal only when necessary

When building a new UI, first consider whether it can hold up in a modeless form. Use a modal only in situations where concentration is genuinely useful, such as the following:

- Confirmation of irreversible operations (deletion, submission, payment, and so on).
- When multiple fields logically form a single submission unit and partial submission is not permitted.
- When simultaneous interaction with the background context is physically impossible (full-screen video playback, a 3D selection mode, and the like).

"A wizard would probably make it less confusing for the user" is not a valid basis for adoption. Whether something is confusing is solved through information design and labeling.

### Hold state in the URL

So that users can revisit, share, or work in parallel at any moment they choose, express state in the URL as much as possible. Reflect filters, selections, sorting, the currently open tab, and so on in query parameters or the path.

- The browser's back/forward works as expected.
- Users can share state with others via the URL.
- Different states can be held simultaneously in parallel tabs.

### Organize information vertically while staying modeless

Rather than "splitting things into stages because laying them all out gets cluttered," organize the amount of information along the vertical axis through grouping, collapsing, and lazy loading. Turning something into a modal is a last resort, not a means of papering over insufficient organization.

### Record the trade-off when introducing a mode

When introducing a modal UI, document its adoption — together with the justification for why it could not hold up in a modeless form — in the PR description or an ADR. Make it possible for a later reader to reconstruct "why is this part a modal."

### Close modals with Esc and background click

Even in situations that require a modal, provide multiple exits. Provide at least two paths that respond the moment a user feels "I want to get out of here" — the Esc key, clicking the background, the × in the header, a link outside the form, and so on.

### Strict focus trapping, loose context

While a modal is displayed, confine focus within the modal (do not let external elements be operated with Tab). At the same time, keep the modal's background in a readable state, so that the user does not lose sight from the screen of "what they were in the middle of doing."

### Make state retention the default

When a modal, panel, or sidebar is closed, do not lose the in-progress input it contained. Having a user's work vanish on an unintended exit is a design that takes away freedom.

### Reinforce "going modeless" with shortcuts

Assign keyboard shortcuts to frequent operations, creating a path independent of mouse operation. Make the shortcut table openable with a key such as `?`, and do not hide it (this works in concert with the keyboard path of Accessibility-First).

### Related: Accessibility-First, Tool-First

Modeless design supports the "reachable via multiple paths" principle of Accessibility from the flow side of the visual interface. The typed tools that the same policy deals with are best designed as stateless, one-shot operations, which aligns naturally with modelessness.
