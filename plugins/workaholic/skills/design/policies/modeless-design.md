---
title: Modeless Design
slug: modeless-design
category: design
source: https://qmu.co.jp/implementation/modeless-design
---

# Modeless Design

_Place modelessness at the design starting point; introduce modals only where concentration is truly warranted._

A modal temporarily stops surrounding operations to allow concentration on one task. We make modelessness the starting point of design, introducing modals only in situations where they are truly appropriate. Modals are quick to implement, so without deliberate attention screens tend to be enclosed one by one. The more operations can be combined, the more users can choose their own way of proceeding rather than following a prescribed route. We believe this freedom also connects to the range of actions available to AI agents operating the screen.

## Goal (目標)

The situation this policy aims to achieve is one in which users can choose the combinations of operations themselves. We create a state where users can reach any operation they need at any time, without having to remember what mode the application is currently in. Reaching a state where operations are composable and both humans and AI can act across the entire operation space is placed as the destination of this policy.

## Responsibility (責務)

The situation this policy aims to prevent is one in which the user's freedom to operate is taken away without design justification, and the right to "not have to notice" mode switches is not respected.

Specifically:

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

### Design operations as composable units

Design operations as composable units that do not depend on mode. The more this is the case, the more the operation space is open not only to humans but also to AI agents operating the screen. A guided path that merely follows a predetermined sequence narrows the actions AI can take when deviating from that sequence. If entry points are not constrained by mode, AI can resume midway, proceed multiple operations in parallel, or assemble them in an unanticipated order without requiring special branching. We position making modelessness the default as a decision that both leaves humans free and leaves room for AI to reach the entire operation space.

### Choose modeless as the default you can add modals to later

Making modelessness the default is a decision to default to the side with lower rollback costs. Starting a flow in modeless form and adding a modal later when concentration is found to be needed is a localized addition to the one point where it is needed. Conversely, unraveling a flow enclosed in modals from the start and reopening the operation space requires retracing guided paths built on the assumption of enclosure, tending to increase work. We start with modelessness because we want to default to the side that is cheaper whichever way it goes.

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

Assign keyboard shortcuts to frequent operations, creating a path independent of mouse operation. Make the shortcut table openable with a key such as `?`, and do not hide it.

### Related: Accessibility Open to AI

Related: [Accessibility Open to AI](../../planning/policies/accessibility-first.md).
