# Docker and Development Standards

## Docker Compose Standards

### Service Field Ordering
When writing Docker Compose files, order service fields in this exact sequence:
1. image
2. container_name
3. user
4. restart
5. runtime
6. cap_add
7. devices
8. network_mode
9. depends_on
10. volumes
11. networks
12. ports
13. environment
14. healthcheck
15. deploy
16. labels

### Environment Variable Organization
- **5+ environment variables**: Group related variables with descriptive comments
  - Group by common prefixes, functionality, or related service
  - Sort variables alphabetically within each group
  - Use comment format: `# Group Name`
  - Order groups logically (basic config first, then feature-specific)
- **<5 environment variables**: Sort alphabetically without grouping
- Always preserve existing content and formatting

### Docker Compose Version
- Do NOT include `version:` field unless working with Docker Swarm
- Use `docker compose` commands (not legacy `docker-compose`)

## Dockerfile Standards

Follow these principles for all Dockerfiles:
- **Base images**: Use Alpine or Ubuntu only
- **Architecture**: Build multi-architecture containers
- **Security**: Run as rootless (non-root user)
- **Versioning**: Use semantic versioning for container tags
- **Process model**: One process per container
- **Logging**: Log to stdout only
- **Simplicity**: Follow KISS principle, avoid s6-overlay and similar tools

## Code Comment Standards

### Comment Policy
- **Never write comments in the codebase** - Code should be self-explanatory through clear naming and structure
- If a file is too complex to understand without comments, it should be simplified and split into multiple files
- Follow sensible semantic organization and file structure
- Use descriptive variable names, function names, and file names instead of comments

## Git Conventions

### Conventional Commits
Follow the Conventional Commits specification for all commit messages:

**Format**: `<type>[optional scope]: <description>`

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

### Examples
```
feat(auth): add OAuth2 login support
fix(api): resolve timeout issue in user endpoint
docs: update deployment instructions
refactor(database): extract connection pooling logic
perf(cache): implement Redis-based session storage
test(user): add integration tests for registration flow
```

### Commit Message Rules
- Use imperative mood ("add" not "adds" or "added")
- Don't capitalize first letter of description
- No period at the end of description
- Include issue number when applicable: `fix(api): resolve timeout (#123)`
- Keep description under 50 characters
- Use body for detailed explanations when needed
- **Never mention Claude Code in commit messages** - Keep commits focused on the actual changes made
- **After completing a todo list**: Always write a commit message in chat summarizing what was accomplished