---
type: Engineering Policy
title: "Accessibility for Humans and AI"
resource: https://qmu.co.jp/implementation/accessibility-first
tags:
  - implementation
  - accessibility-first
---

# Accessibility for Humans and AI

"The power of the Web is in its universality. Access by everyone regardless of disability is an essential aspect." — Tim Berners-Lee

Just as we value the usability of people operating the screen themselves, and in order to improve that experience, we also place importance on accessibility for AI. This makes it easier to choose the approach in which a user asks an AI to carry out a task and the AI performs it on their behalf, and we believe that this approach is itself one means of underpinning accessibility.

That said, when everything is funneled into nothing but chat exchanges, it tends to become hard to see what can be done, what state things are currently in, and which operation to choose next. For that reason, while we secure a path for delegating to AI, we believe the role of the UI—which supports the user's cognition and operation from the user's own perspective—should continue to be valued rather than collapsing everything into a chat UI. As long as such a UI remains the foundation of the user experience, we likewise continue to value established accessibility standards.

## Goal (目標)

We aim for a state in which software is not merely usable but is an experience that brings joy to the people who use it. First, accessibility must hold as a foundation so that no one is left behind as "unable to use it"; on top of that, our ideal is for the experience to reach "the joy of using it." There are many ways that joy can manifest, but one example we envision is software becoming a tool for self-improvement, where mastery and disciplined practice lead to greater results.

## Responsibility (責務)

We do not tolerate a state in which the experience falls into "cannot use it," producing people or AI agents who cannot reach it. We prevent conditions such as conveying state through color alone, primary operations being unreachable by keyboard alone, or operations remaining that can only be traced through the visual UI; and we ensure that nothing is shipped without verification while still falling below the floor of WCAG 2.2 AA.

## Practices (実践)

### Start from semantic HTML (セマンティック HTML から出発する)

When building a new UI, we first frame its skeleton with semantic HTML. This is because elements such as `<button>`, `<nav>`, `<main>`, and `<form>` each carry a clear promise to assistive technologies. For interactions that cannot be fully expressed with semantic elements alone, we add ARIA as a supplement—but never as a substitute for semantic elements. We give every interactive element an accessible name that assistive technologies can read aloud.

### Treat WCAG 2.2 AA as the minimum standard (WCAG 2.2 AA を最低基準とする)

As the minimum standard for accessibility, we refer to WCAG 2.2 AA. For criteria such as contrast, keyboard operation, identifying input errors, and consistency of navigation, we refer to this standard while operating with a means of achievement and a means of verification paired together. We do not extend AAA uniformly; we choose it for narrowly scoped contexts such as public services and highly sensitive flows. We do not enumerate the individual success criteria here, but use WCAG 2.2 AA as a shared point of reference.

### Design the UI while also considering the interface for AI (UI は AI 向けインターフェースも考慮しつつ設計する)

We design with the ideal that the content displayed and the operations prompted to humans on the UI appear the same when seen from an AI. Concretely, support for WebMCP comes to mind, but because it is still immature at this stage, we are advancing read/write tool definitions that are compatible with WebMCP, assuming OpenAI's Realtime API, which enables tool use within the browser.

### Name tools in the vocabulary of the domain (ツールをドメインの語彙で命名する)

For tool names and argument names, we use words for business actions such as `submitOrder` or `cancelReservation`, rather than generic terms like `doAction` (in conformance with Respecting Domain-Specific Expression). This is because the tool names that appear in WebMCP are read by AI and, at the same time, read by developers and business stakeholders. We treat tool definitions as extending the Recommendation for Thick Typing out to the UI boundary, expressing the value ranges and case distinctions of arguments in types.

### Question "it's obvious from the visuals" (視覚で当たり前に分かる、を疑う)

For information that is conveyed by color, size, or position alone, we layer on another path. For example, errors are conveyed not only by color but also by text and icons, and required fields are indicated not only by color but also by labels. As for state changes, too, we convey them with `aria-live` rather than relying on the visual alone.

### Actually confirm reachability (到達を実際に確かめる)

For tickets that involve the UI, we confirm that primary features can be reached using a screen reader (VoiceOver, NVDA, etc.) and the keyboard alone. Together with this, we also confirm—through browser automation and WebMCP—that an AI agent can reach the same operations. A path that an AI agent cannot reach is treated as a sign of a path that is also hard to reach for people using assistive technologies. We incorporate these automated verifications into CI/CD Automation.

### Related: Modeless Design and Thick Typing (関連: モードレス設計・厚い型付け)

Accessibility as a starting point is supported by Modeless Design (being able to reach operations without entering a particular mode) and by the Recommendation for Thick Typing (handling a tool's arguments and return values with types). We judge that tools designed as stateless, one-shot operations align naturally with a modeless UI.
