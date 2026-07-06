---
type: Engineering Policy
title: "Accessibility Open to AI"
description: "Placing accessibility at the start of the experience, holding WCAG 2.2 AA as the floor, and opening the product to AI agents as both operators and information consumers alongside human users."
resource: https://qmu.co.jp/planning/accessibility-first
tags:
  - planning
  - accessibility-first
---

# Accessibility Open to AI

_Place accessibility at the start of the experience, hold WCAG 2.2 AA as the floor, and open the product to AI agents as operators and information consumers alongside human users._

> "The power of the Web is in its universality. Access by everyone regardless of disability is an essential aspect." — Tim Berners-Lee

We value accessibility for AI alongside usability for users who operate screens themselves — and as a means of enhancing that experience. This makes it easier for users to choose the approach of asking AI to handle tasks and having AI execute them on their behalf, which we believe itself becomes one means of supporting accessibility.

That said, converging everything into chat interaction alone tends to make it difficult to see what is possible, what state things are currently in, and which operations can be chosen next. We therefore believe that while securing a path for delegating to AI, the role of UI in supporting human recognition and operation should also continue to be valued, rather than everything converging to a chat UI. As long as such UI continues to be the foundation of the user experience, we continue to value established accessibility standards.

## Goal (目標)

We aim for a state in which the software is not merely usable but becomes an experience that brings joy to those who use it. Accessibility that leaves no one unable to use the software comes first as the foundation, with the ideal being that the experience reaches the level of "joy of use" on top of that. The forms that joy can take are many, but one example we imagine is software that becomes a tool for self-improvement, where proficiency and practice lead to greater results.

## Responsibility (責務)

Our responsibility is to prevent a state in which the experience falls into "cannot use" and produces people or AI agents who cannot reach the product. We prevent states such as: status communicated by color alone; primary operations unreachable by keyboard alone; operations remaining that can only be reached from the visual UI. We ensure that WCAG 2.2 AA, the lower limit, is not undershot and shipped without verification.

## Practices (実践)

### Start from semantic HTML

When building a new UI, we start by building the skeleton from semantic HTML. Elements such as `<button>`, `<nav>`, `<main>`, and `<form>` each carry a clear promise to assistive technologies. We add ARIA as a supplement for interactions that cannot be fully expressed with semantic elements alone, but we do not use it as a replacement for semantic elements. All interactive elements are given accessible names that assistive technologies can read.

### WCAG 2.2 AA as the minimum standard

We reference WCAG 2.2 AA as the minimum standard for accessibility. For criteria such as contrast, keyboard operation, identification of input errors, and consistency of navigation, we reference this standard and operate it with verification means paired with achievement means. AAA is applied not uniformly across the board, but narrowed to contexts such as public services or high-confidentiality flows. We do not enumerate individual success criteria here; we use WCAG 2.2 AA as the shared reference point.

### Design UI considering AI interfaces as well

The ideal is to design so that what is displayed to humans on the UI and the operations prompted are the same from AI's perspective as well. Concretely, WebMCP support is one possibility, but since it remains immature at this stage, we proceed with defining read/write tool definitions compatible with WebMCP with OpenAI's Realtime API — which enables tool use in the browser — in mind.

### Name tools with domain vocabulary

For tool names and argument names, we use business operation terms such as `submitOrder` or `cancelReservation` rather than generic terms like `doAction` (in keeping with [Codifying Domain Terminology](/planning/terminology.md)). Tool names appearing in WebMCP are objects for both AI to read and for developers and business stakeholders to read. Tool definitions are treated as extending [Preferring Rich Typing](/implementation/type-driven-design.md) to the UI boundary, expressing the range of values and branching of arguments in types.

### AI as information consumer

In the preceding sections we treated AI as the subject operating the UI, but relationships are also increasing where AI references the content itself as an information source and becomes a reader that cites it. Separately from the tool path for operation, we want to anticipate situations where the explanations and states written on a page are read by AI as a machine-readable information source.

We handle this aspect with the aim of opening content as structured, machine-readable information — not as a measure for improving search rankings. By straightforwardly maintaining heading hierarchy, element semantics, and the structure of tables and definition lists, we want to make it easy for both humans and AI to read, in the same form, what is written under which subject. In addition, we make it a basic principle to leave stable link destinations and reference points at the heading level, so that referenced content can be traced back to which page and which section it originates from.

The means used here largely overlap with the structure described in "Start from semantic HTML." The skeleton built with semantic elements and the structure conforming to WCAG 2.2 AA is a promise for assistive technologies to follow the content, and at the same time serves as a clue for AI to read content as an information source. We treat this as a relationship where structure aligned for accessibility also contributes to machine-readability.

### Question "visually obvious" assumptions

For information conveyed only by color, size, or position, we layer additional paths. For example, errors are conveyed not only by color but also by text or icons; required fields are indicated not only by color but also by labels. For state changes as well, we use `aria-live` rather than relying on vision alone.

### Verify reachability

For tickets involving UI, we confirm that primary functions can be reached by screen reader (VoiceOver, NVDA, etc.) and keyboard alone. We also confirm that AI agents can reach the same operations through browser automation or WebMCP. Paths that AI agents cannot reach are treated as signs that the path is also difficult to reach for people using assistive technologies. These automated verifications are incorporated into [Local CI/CD Execution](/operation/ci-cd.md).

### Related: Modeless Design, Preferring Rich Typing

The accessibility that starts from this foundation is supported by [Modeless Design](/design/modeless-design.md) (reaching operations without entering a particular mode) and [Preferring Rich Typing](/implementation/type-driven-design.md) (handling tool arguments and return values in types). Tools designed as stateless, one-shot operations are judged to align naturally with modeless UI.
