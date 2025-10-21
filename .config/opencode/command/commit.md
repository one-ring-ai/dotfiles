---
description: Commit changes
model: openrouter/z-ai/glm-4.6
---

# Commit Changes

You are tasked with creating git commits for the changes made during this session.

## Process:

1. **Check repository standards:**
   - Look for `.github/CONTRIBUTING.md` or `CONTRIBUTING.md` in the repository
   - If present, read and follow its commit message conventions and guidelines
   - Repository-specific standards always take precedence over general conventions

2. **Think about what changed:**
   - Review the conversation history and understand what was accomplished
   - Run `git status` to see current changes
   - Run `git diff` to understand the modifications
   - Consider whether changes should be one commit or multiple logical commits

3. **Plan your commit(s):**
   - Identify which files belong together
   - Draft clear, descriptive conventional commit messages following repository standards
   - Use imperative mood in commit messages
   - Focus on why the changes were made, not just what

4. **Execute:**
   - For each planned commit, stage exactly its files and create the commit immediately
   - Prefer `git add <files> && git commit -m "message"` per commit to avoid mixing files
   - Alternatively, run `git add <files>` then `git commit -m "message"` per commit
   - Never use `-A` or `.` with git add
   - Show the result with `git log --oneline -n [number]`

## Important:
- **NEVER add co-author information or Claude attribution**
- Commits should be authored solely by the user
- Do not include any "Generated with Claude" messages
- Do not add "Co-Authored-By" lines
- Write commit messages as if the user wrote them

## Remember:
- You have the full context of what was done in this session
- Group related changes together
- Keep commits focused and atomic when possible
- The user trusts your judgment - they asked you to commit