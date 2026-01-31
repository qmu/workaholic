---
paths:
  - '**/*.md'
---

# Diagrams

**Use Mermaid, not ASCII art** for all diagrams in documentation and code comments.

## Why Mermaid

- Renders natively in GitHub, VS Code, and most documentation systems
- Version-controllable and diffable
- Consistent rendering across platforms
- Interactive (zoomable, clickable in some renderers)

## Prohibited

- Box-drawing characters (`+--+`, `|`, `└──`)
- ASCII arrow combinations (`-->`, `==>`, `->`)
- Manual alignment with spaces for visual structure

## Required Format

Use fenced code blocks with `mermaid` language:

````markdown
```mermaid
flowchart LR
    A[Input] --> B[Process] --> C[Output]
```
````

## Node Labels (REQUIRED)

**MUST quote labels** containing special characters (`/`, `{`, `}`, `[`, `]`):

```mermaid
flowchart TD
    A["Start"] --> B["/command"]
    B --> C{"Decision?"}
```

**Why**: Unquoted `/` causes GitHub to fail with `Lexical error on line N. Unrecognized text.`

Common violations:
- `A[/story command]` ❌ → `A["/story command"]` ✓
- `B[path/to/file]` ❌ → `B["path/to/file"]` ✓

## Common Diagram Types

**Flowchart** for process flows:

```mermaid
flowchart TD
    Start --> Decision{"Condition?"}
    Decision -->|Yes| Action1
    Decision -->|No| Action2
```

**Sequence** for interactions:

```mermaid
sequenceDiagram
    Client->>Server: Request
    Server-->>Client: Response
```

**Class** for architecture:

```mermaid
classDiagram
    class Service {
        +method()
    }
```

## Exceptions

- Simple inline arrows in code comments (`// A -> B`) are acceptable for quick explanations
- Complex diagrams requiring external tools (e.g., network topologies) should link to external images
