---
name: pull-request-advisor
description: Advise on pull request best practices and help create well-structured PRs. Use when user asks about PRs, wants to create a PR, or needs help with PR descriptions.
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

# Pull Request Advisor

Help users create well-structured, reviewable pull requests.

## When to Activate

- User wants to create a pull request
- User asks about PR best practices
- User needs help writing PR descriptions
- User wants to review changes before PR

## Guidance to Provide

### PR Title Format

```
<type>: <concise description>
```

Types: feat, fix, docs, refactor, test, chore

### PR Description Template

```markdown
## Summary
<1-3 bullet points of what this PR does>

## Changes
- <specific change 1>
- <specific change 2>

## Test Plan
- [ ] <how to test this>
- [ ] <edge cases considered>

## Screenshots (if UI changes)
<before/after if applicable>
```

### Best Practices

1. **Small PRs**: Easier to review, faster to merge
2. **Clear scope**: One feature/fix per PR
3. **Self-review first**: Check your own diff before requesting review
4. **Link issues**: Reference related issues/tickets

## Actions

1. Run `git log main..HEAD` to see commits in branch
2. Run `git diff main...HEAD` to see all changes
3. Analyze changes and suggest PR structure
4. Propose PR title and description
5. Check if PR should be split

## Example Advice

```
Analyzing your branch (feature/user-auth):
- 5 commits, 8 files changed
- Main changes: auth logic, user model, tests

Suggested PR:

Title: feat: Add user authentication system

## Summary
- Add JWT-based authentication
- Create user model with password hashing
- Add login/logout endpoints

## Test Plan
- [ ] Test login with valid credentials
- [ ] Test login with invalid credentials
- [ ] Verify token expiration

Ready to create this PR?
```
