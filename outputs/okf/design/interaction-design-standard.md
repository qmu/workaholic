---
type: Engineering Policy
title: "Interactive Design Standards"
description: "Standardizing the interactive behaviors of components — loading, error, empty, and success states — so users learn the product once rather than re-learning each screen."
resource: https://qmu.co.jp/design/interaction-design-standard
tags:
  - design
  - interaction-design-standard
---

# Interactive Design Standards

_Standardize the interactive behaviors of components — loading states, error states, empty states, and transitions — so that users learn the product once rather than re-learning each screen._

A product with consistent interactive behavior is a product that users can form reliable mental models of. When the loading indicator, the error state, and the empty state behave consistently from screen to screen, users spend cognitive effort on their actual tasks rather than on "how does this particular screen work." Consistency also reduces implementation surface: a standard loading pattern defined once is tested once and applied everywhere, rather than being reimplemented per screen with subtle variations.

## Goal (目標)

The situation this policy aims to achieve is one in which the interactive behaviors of every screen in the product are instances of a shared pattern library, and deviations are deliberate and documented.

- Every interactive state (loading, error, empty, disabled, success) has a defined standard pattern that is used by default.
- The pattern library is available to implementers in a form that requires no inference — components, not descriptions.
- Deviations from standard patterns are reviewed and recorded, as with any other departure from defaults.

## Responsibility (責務)

The situation this policy aims to prevent is one in which interactive behavior varies between screens because each screen was implemented without reference to a standard.

States we do not tolerate:

- Loading states that vary between screens: spinner on one, skeleton on another, no indicator on a third, with no principle distinguishing them.
- Error states that vary between screens in their placement, language, and severity signaling.
- Empty states that are absent — a blank area where content will eventually appear, with no explanation or call to action.
- Form behaviors that differ between forms: some validate on blur, others on submit; some show errors inline, others in a banner.

## Practices (実践)

### Define standards for the four interactive states before building the second screen

Loading, empty, error, and success/confirmation states are defined as standards — at minimum as documented patterns, ideally as shared components — before the second screen in the product is built. The first screen is always the starting point; the second screen is when the pattern should be extracted and the standard established.

### Use skeleton screens for content loading, spinners for user-initiated actions

As a default heuristic: content loading (page load, data fetch in the background) uses a skeleton screen that mirrors the content layout. User-initiated asynchronous actions (submit, save, upload) use a spinner or progress indicator on the control that was activated, leaving the rest of the screen readable.

### Standardize keyboard navigation behavior

Tab order follows the visual layout. Interactive elements are reachable by keyboard. Dialogs and popovers trap focus when open and restore it when closed. These are not screen-specific behaviors; they are product-wide standards, applied through shared components.

### Record interaction decisions in the design system

When a new interaction pattern is introduced — a new kind of empty state, a new confirmation flow — document it in the design system's interaction notes, alongside the component. This creates a searchable record of "why did we choose this pattern" and prevents quiet re-derivation of the same choices across future screens.

### Related: Modeless Design, UI That Requires No Manual, Accessibility Open to AI

Consistent interaction states support [Modeless Design](/design/modeless-design.md) by making the modeless surface learnable. Well-defined states remove the need for documentation — [UI That Requires No Manual](/design/self-explanatory-ui.md). Keyboard navigation and ARIA state consistency connect directly to [Accessibility Open to AI](/planning/accessibility-first.md).
