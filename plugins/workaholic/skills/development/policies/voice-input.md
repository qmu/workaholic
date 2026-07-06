---
title: Active Use of Voice Input
slug: voice-input
category: development
source: https://qmu.co.jp/development/voice-input
---

# Active Use of Voice Input

_Using voice input in place of keyboard entry when conveying design intent or exploring ideas with AI agents, to keep the speed of thought aligned with the speed of input._

In situations where developers are conveying intent to AI agents, we actively use voice input rather than keyboard entry. Short corrections and brief confirmation responses stay on the keyboard, but for situations such as conveying design intent, brainstorming, and exploratory expansion of ideas, speaking and inputting tends to complete more quickly.

## Goal (目標)

We aim for a state in which the speed of getting ideas from one's head to the outside is short, so that the remaining capacity can be directed toward organizing and examining. When voice input tools combine with LLMs so that fillers and hesitations are removed and the result is organized into well-formed sentences, that capacity becomes available for AI agent interaction. We aim for a state in which developers can engage with AI in extended, exploratory exchanges without their thinking being rate-limited by input speed.

## Responsibility (責務)

Our responsibility is to neither mandate voice input nor dismiss the psychological and environmental hurdles that come with speaking aloud in a shared workspace. The resistance to voice input — embarrassment about speaking while inputting, difficulty speaking in an office or meeting room, a sense of unfamiliarity with "thinking while talking" when not yet accustomed — exists among our developers too. We do not try to eliminate this resistance. We continue using voice input because the differences described below are large enough to want even while holding resistance, but we do not treat the hurdles as non-existent.

## Practices (実践)

### Why we use voice input

Voice input tools that combine with LLMs — removing fillers and hesitations and organizing the result into well-formed sentences — have made it possible to incorporate voice input into our development workflow. Many of our developers currently use Typeless on a daily basis.

The reasons we have adopted voice input are roughly three. First, we can produce high-quality output in a short time: while typing on a keyboard, thinking is rate-limited by input speed; speaking is faster than typing, so the time from having an idea to getting it outside is shorter, and that capacity can be redirected to organizing and examining. AI agent input involves many situations where long instructions and background explanations are passed in one batch, so voice pairs well with it. Second, we can engage with AI while maintaining the momentum of thinking: having the thread of thought fade while rewriting or adjusting wording is something we have experienced many times in our development; switching to a form of thinking while speaking lets the line of thought be extended all the way to the end without cutting it. This difference shows up prominently in brainstorming and exploratory examination. Third, we can try ideas nimbly and broadly: instructions spoken into voice land directly in the AI's context once transcribed; the friction of trying multiple options or switching direction in short exchanges goes down, so the number of times ideas can be tried increases.

### Keyboard and voice: how we use each

We have not stopped using keyboard input. Short corrections, command input, brief confirmation responses, fine-grained code adjustments — in these situations keyboard has less friction, so we continue using it as before.

We use voice for extended intent transmission, design examination, brainstorming, and initial instructions to AI agents — situations where we want to expand thinking and put it into words. Which to choose in each situation is left to the developer's judgment without binding it with rules. We do not set a mandatory form such as "this kind of input must always be voice."
