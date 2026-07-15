---
paths:
  - '**/*'
---

# General Rules

- **Never modify another repository** - Every write, edit, move, and commit lands inside the current repository or one of its own worktrees (`git worktree list`). Never write into a sibling checkout, never `cd` to another project and work there, never target a path outside `git rev-parse --show-toplevel`. To raise work against a different repository, use `/request` - it is the only sanctioned way, and it exists so that this rule never has to be broken.
- **Never carry one repository's context into another's artifacts** - When work here is motivated by something observed elsewhere, describe it generically: "a consumer repo", "a tree that has drifted". Do not name the other repository, quote its paths, list its components, reproduce its filenames, or copy its data - and do not ground an example in a real customer's file, label, hostname, or infrastructure name. This holds for tickets, stories, commit messages, PR bodies, code comments, and test fixtures alike; a fixture copied from a real system is the same disclosure as a document pasted into a ticket. Reach for a synthetic example instead: if a placeholder would carry the point, the concrete detail was never load-bearing.
  - **Why this is a rule and not a preference:** these artifacts are committed, and a repository's history is permanent and often public. A name written once survives every later correction - `git` keeps it, and a host keeps pull-request refs even after a force-push. There is no automated gate behind you here. The branch-safety scan matches credential shapes and terms someone already listed; it cannot recognise a customer's vocabulary, because that is semantic and does not exist as a term to list until the moment it leaks. You are the control.
- **Never commit without explicit user request** - Only create git commits when executing a command that has commit steps (`/drive`, `/report`, `/ship`)
- **Never use `git -C`** - Run git commands from the working directory, not with `-C` flag
- **Link markdown files when referenced** - When mentioning `.md` files in documentation, use markdown links: `[filename.md](path/to/file.md)` not just backticks. Especially important for stable docs (specs, terms, stories).
- **Number headings in documentation** - Use numbered headings for h2 and h3 levels: `## 1. Section`, `### 1-1. Subsection`. For h4, number only when it helps identify topics. Applies to specs, terms, stories, and skills. Exceptions: READMEs and configuration docs.
