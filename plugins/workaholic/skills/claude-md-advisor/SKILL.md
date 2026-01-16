---
name: claude-md-advisor
description: Propose CLAUDE.md structure with project summary, tech stack, setup, and language preferences.
---

# CLAUDE.md Advisor

Analyze the user's project and propose a CLAUDE.md file with essential project context.

## When to Activate

- User wants to create or improve their CLAUDE.md
- Workaholic command proposes CLAUDE.md creation
- User asks about project documentation for Claude Code

## Instructions

1. Check if user already has CLAUDE.md
2. Analyze project to gather information:
   - package.json, Cargo.toml, go.mod, etc. for tech stack
   - README.md for project description
   - Existing documentation patterns
3. Read template from `references/claude-md-template.md`
4. Propose CLAUDE.md content based on project analysis
5. Ask user to fill in or confirm details
6. Create/update CLAUDE.md

## Reference Templates

- `references/claude-md-template.md` - Recommended CLAUDE.md structure

## Required Sections

### 1. Written Language

Specify the language for all written content:

- Documentation and comments
- Commit messages
- Issues and pull requests

### 2. Project Summary

Brief description of what the project does and its purpose.

### 3. Tech Stack

List of technologies, frameworks, and tools used:

- Runtime/language version
- Major frameworks
- Build tools
- Testing tools

### 4. Setup

Commands to get the project running:

- Install dependencies
- Build commands
- Run development server
- Run tests

## Example Flow

```
User: "Create a CLAUDE.md for my project"

Advisor:
1. Check for existing CLAUDE.md - not found
2. Read package.json - Next.js project with TypeScript
3. Read README.md - "E-commerce platform"

Propose:
"I'll create a CLAUDE.md for your project. Based on analysis:

- Written Language: (need to confirm)
- Project: E-commerce platform
- Tech: Next.js 14, TypeScript, Prisma
- Setup: npm install, npm run dev

What language should documentation and commits be written in?"
```

## Customization Questions

Ask user about:

1. **Written language**: What language for docs/commits? (English, Japanese, etc.)
2. **Project description**: Is the detected summary accurate?
3. **Additional setup steps**: Any environment variables or prerequisites?
