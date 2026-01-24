---
paths:
  - '**/*'
---

# General Rules

- **Never commit without explicit user request** - Only create git commits when the user directly requests via `/commit` or when executing a command that has commit steps (like `/pull-request`, `/drive`)
- **Never use `git -C`** - Run git commands from the working directory, not with `-C` flag
