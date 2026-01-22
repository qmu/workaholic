# FAQ

## General

### What is this marketplace?

An internal marketplace for Claude Code plugins, hosting the "core" and "tdd" plugins for productive development workflows.

### How do I install plugins?

```
/plugin install <plugin-name>@qmu/cc-market-place-internal
```

## Commands

### When should I use `/ticket` vs just asking Claude?

Use `/ticket` when you want a documented implementation plan that can be:

- Reviewed before implementation
- Implemented later with `/drive`
- Tracked and archived

### Why does `/drive` update documentation?

Auto-documentation ensures docs stay in sync with code changes. When implementing tickets, `/drive` updates relevant documentation files before committing.

## Troubleshooting

### My ticket wasn't archived after commit

Ensure the ticket file is in `doc/tickets/` and matches the implemented changes.

### Documentation files weren't created

The `doc/specs/` directory must exist. Create it manually or let the first commit create it.
