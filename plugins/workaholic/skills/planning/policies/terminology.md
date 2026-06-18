---
title: Codifying Domain Terminology
slug: terminology
category: planning
source: https://qmu.co.jp/planning/terminology
---

# Codifying Domain Terminology

_Collect established project and codebase terms into a dictionary with one word per concept, used consistently across code, documents, commits, diagrams, and conversation to grow a ubiquitous language._

We collect established terms in a project or codebase into a dictionary, with one word per concept, and use the same term throughout code, documents, commits, diagrams, and conversation. Before creating a new term, we search for existing ones; when we find them, we follow their original usage and grow the ubiquitous language as a dictionary.

## Goal (目標)

We aim for a state in which one concept is referred to by one word, consistently across code, documents, commits, diagrams, and conversation. The codebase becomes self-explanatory — reading the code alone lets a reader see the shape of the business concept — both for people and for AI agents that learn concept boundaries from the consistency of terminology in context.

## Responsibility (責務)

Our responsibility is to prevent a state in which the same concept splits across multiple words and it becomes impossible to tell which name is correct.

Coexistence of synonyms such as `User`, `Account`, `Member`, and `Customer` forces every reader to judge, each time, whether they refer to the same concept or different ones, and breaks the completeness of search (grep, symbol search). In a firm where generative AI is our default author, synonyms and notational variation (including the mixing of romaji and English) tend to multiply in the course of producing features in quantity, and AI itself may learn incorrect concept boundaries from varied vocabulary and introduce mistaken edits.

## Practices (実践)

### Search for existing terms before introducing new ones

When introducing a new type, function, variable, or filename, first search the existing codebase. If a term already refers to the same concept, use it. Check candidate English words, Japanese translations, and likely synonyms with grep; inspect naming in adjacent layers and domains, existing documents, and glossaries. Only when nothing is found should a new term be introduced.

### One concept, one word

One concept is expressed in one word as the first priority. Names that accumulate modifiers (such as `getUserAccountInformationData`) are read as a sign that a concept has not yet been decomposed; before adding words, suspect first whether the type or responsibility can be split. Context-obvious prefixes like `get_`, `do_`, or `handle_` are not added either. Near-synonym pairs (`delete` and `remove`, `fetch` and `get`) and generic words like `Manager`, `Helper`, or `Util` tend to conceal unresolved concepts; we move toward concrete words that represent a role.

### Update all affected areas when renaming or merging

When renaming or merging a term, update everything within the affected scope — code, documents, configuration, templates, test fixtures, logs, and error messages — in the same change. A state where only part has been updated leaves old and new terms coexisting and becomes a source of variation. For things that cannot easily be changed — like published external API names or database column names — we make the boundary explicit in the code and leave the correspondence with the internal term traceable.

### Flag contradictions when found

When we find a contradiction where the same concept is referenced by different terms in different files, we record it — even in parts we are not directly touching. Even when an immediate rename is difficult, we consider it valuable to create a state where the variation is recognized. In changes that introduce a new term, we leave a record of why that term was chosen and which candidates were rejected, so later readers have material to use when considering a rename. In instructions to AI agents, we use the same terms as those used in the codebase, leaving no room for different names to be interpreted as different concepts.

### Related: Requirements Analysis through Modeling

Related: [Requirements Analysis through Modeling](modeling-centric-design.md).
