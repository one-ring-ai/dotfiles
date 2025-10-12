---
title: Conventional Commits
last_updated: 2025-10-12
author: team
category: workflow
tags: [git, commits, versioning]
applies_to: [all]
iron_law: "ALL COMMITS MUST FOLLOW CONVENTIONAL COMMITS FORMAT"
when_to_use:
  - creating any git commit
  - writing commit messages
---

# Conventional Commits

## Purpose
To provide a standardized commit message format that enables automated changelog generation, semantic versioning, and clear project history.

## When to Use
- Creating any git commit
- Writing commit messages

## Iron Law
**ALL COMMITS MUST FOLLOW CONVENTIONAL COMMITS FORMAT**

## Format

### Basic Structure
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Commit Types

- `feat`: New feature for the user
- `fix`: Bug fix for the user
- `docs`: Documentation changes
- `style`: Code formatting, missing semi colons, etc (no production code change)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Code change that improves performance
- `test`: Adding missing tests or correcting existing tests
- `build`: Changes affecting build system or external dependencies
- `ci`: Changes to CI configuration files and scripts
- `chore`: Other changes that don't modify src or test files
- `revert`: Reverts a previous commit

### Scope
Optional scope in parentheses to indicate the section of the codebase affected:
```
feat(auth): add OAuth2 login support
fix(api): resolve timeout issue in user endpoint
```

### Description
- Use imperative mood ("add" not "adds" or "added")
- Don't capitalize first letter
- No period at the end
- Keep under 50 characters

### Body (Optional)
Detailed explanation of the change, wrapped at 72 characters:
```
feat(auth): add OAuth2 login support

This commit introduces OAuth2 authentication using the auth0 library.
Users can now login using Google, GitHub, and Microsoft accounts.

The implementation includes:
- OAuth2 provider configuration
- Token validation and refresh
- User profile synchronization
```

### Footer (Optional)
Used for breaking changes and issue references:
```
feat(api): add user pagination

BREAKING CHANGE: The user endpoint now returns paginated results
instead of a complete user list.

Closes #123
```

## Examples

### Simple Features
```
feat(ui): add dark mode toggle
feat(auth): implement password reset
feat(api): add rate limiting
```

### Bug Fixes
```
fix(login): resolve authentication timeout
fix(database): handle connection pool exhaustion
fix(ui): correct mobile layout issues
```

### Documentation
```
docs: update API documentation
docs: add deployment guide
docs: fix installation instructions
```

### Refactoring
```
refactor(auth): extract token validation logic
refactor(database): simplify query builder
refactor(ui): component composition cleanup
```

### Breaking Changes
```
feat(api): change user response format

BREAKING CHANGE: User object now includes nested profile
information instead of flat structure.

Closes #456
```

### Reverts
```
revert: feat(api): add experimental endpoint

This reverts commit 1a2b3c4d due to performance issues
```

## Common Mistakes

1. **Not using imperative mood**: "Added feature" instead of "add feature"
2. **Capitalizing description**: "Add feature" instead of "add feature"
3. **Adding period to description**: "add feature." instead of "add feature"
4. **Making description too long**: Keep it under 50 characters
5. **Using wrong type**: `feat` for bug fixes or `fix` for features
6. **Missing scope when helpful**: Not specifying which part is affected
7. **Vague descriptions**: "update code" instead of "validate user input"
8. **Multiple changes in one commit**: Separate concerns into different commits

## Testing This Skill

### Pressure Scenario 1: Quick Fix
**Situation**: Need to commit a quick one-line fix
**Conventional Commits Response**: Still use proper format
```
fix(api): correct null pointer exception
```

### Pressure Scenario 2: Large Refactor
**Situation**: Major refactoring affecting multiple files
**Conventional Commits Response**: Use appropriate type and scope
```
refactor(auth): simplify token management system
```

### Pressure Scenario 3: Emergency Hotfix
**Situation**: Critical production issue needs immediate fix
**Conventional Commits Response**: Maintain format even under pressure
```
fix(payment): resolve transaction failure
```

## Related Skills

- [Git Workflow](../workflow/git-workflow/SKILL.md)
- [Code Review](../workflow/code-review/SKILL.md)
- [Semantic Versioning](../workflow/semantic-versioning/SKILL.md)
- [Changelog Generation](../workflow/changelog-generation/SKILL.md)