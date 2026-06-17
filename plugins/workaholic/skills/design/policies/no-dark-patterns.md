---
title: Elimination of Dark Patterns
slug: no-dark-patterns
category: design
source: https://qmu.co.jp/design/no-dark-patterns
---

# Elimination of Dark Patterns

_Identify and remove interface patterns that work against users' interests by manipulating attention, obscuring choices, or making it harder to do what users actually want to do._

Dark patterns are interface designs that work against users' interests while appearing to serve the product. Common examples include confirmshaming ("No thanks, I don't want to save money"), roach motels (easy to get into, hard to get out of), disguised advertising, misdirection of attention away from cancel or decline options, and defaults that assume consent for things users have not consented to. We commit to eliminating these patterns because they erode user trust and, when regulated, create legal exposure.

## Goal (目標)

The situation this policy aims to achieve is one in which every interaction the product offers is in the user's interest, and where no element of the interface is designed to manipulate rather than inform.

- Cancellation, deletion, and opting out are as easy as their counterparts.
- Consent is obtained through a plain, unambiguous question with a genuinely optional answer.
- Default states reflect user interest, not product interest.
- The product does not pressure, shame, or create artificial urgency.

## Responsibility (責務)

The situation this policy aims to prevent is one in which product or commercial pressure leads to interface choices that serve engagement or conversion metrics at the cost of user trust.

States we do not tolerate:

- Confirmshaming: labeling the "decline" option of an offer with guilt-inducing language ("No thanks, I prefer slower loading times").
- Roach motel flows: making a subscription or commitment trivial to enter and difficult to exit.
- Hidden costs revealed only at the final step of checkout or signup.
- Pre-checked consent checkboxes for marketing communications, data sharing, or non-essential cookies.
- Misleading urgency or scarcity signals ("Only 3 left!" when inventory is effectively unlimited).
- Intentional visual de-emphasis of cancel, opt-out, or unsubscribe controls.

## Practices (実践)

### Review new flows against a dark-pattern catalog

Before shipping a flow that involves consent, subscription, pricing, or a choice with commercial stakes, review the design against a dark-pattern catalog (the Deceptive Design catalogue, the EU's list of prohibited commercial practices, or equivalent). This review takes a few minutes and surfaces patterns that are easy to miss when designing under conversion pressure.

### Make opt-out symmetric with opt-in

Every choice to enter a state — subscribe, enable notifications, share data — has a corresponding choice to leave that state, and the two paths are symmetric in their accessibility. If enabling a feature takes one click, disabling it takes one click.

### Obtain consent with plain language and a genuine choice

Consent dialogues state clearly what is being consented to, present the options without visual asymmetry between agree and decline, and do not use pre-checked defaults for non-essential purposes. The "decline" option is labeled to describe the choice, not to shame the user for making it.

### Related: UI That Requires No Manual, Recording of Policy Changes and Consent, Respecting User Data Sovereignty

Eliminating dark patterns and designing [UI That Requires No Manual](self-explanatory-ui.md) share a common standard: the interface should work for users, not against them. Consent management practices connect to [Recording of Policy Changes and Consent](consent-recording.md) and [Respecting User Data Sovereignty](data-sovereignty.md).
