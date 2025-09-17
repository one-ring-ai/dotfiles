# AGENTS.md

## Subagent Usage Priority

**IMPORTANT**: Before proceeding with any task, identify and utilize any relevant subagents that are specifically designed for that task type. Always prefer specialized subagents over general approaches when they are available and appropriate.

## Docker and Development Standards

## Docker Compose Standards

### Service Field Ordering

When writing Docker Compose files, order service fields in this **exact sequence**:

#### **Core Configuration**
1. `image` - Docker image to use
2. `container_name` - Custom container name
3. `build` - Build configuration
4. `command` - Override default command
5. `entrypoint` - Override entrypoint
6. `working_dir` - Working directory in container

#### **User and Security**
7. `user` - User to run container as
8. `group_add` - Additional groups
9. `privileged` - Privileged execution
10. `cap_add` - Additional capabilities
11. `cap_drop` - Capabilities to remove
12. `security_opt` - Security options
13. `read_only` - Read-only filesystem
14. `userns_mode` - User namespace mode

#### **Runtime and Process Control**
15. `restart` - Restart policy
16. `runtime` - Runtime to use
17. `isolation` - Isolation technology
18. `init` - Init process (PID 1)
19. `stop_signal` - Signal to stop container
20. `stop_grace_period` - Grace period before SIGKILL
21. `tty` - TTY allocation
22. `stdin_open` - Keep stdin open

#### **Dependencies and Lifecycle**
23. `depends_on` - Service dependencies
24. `links` - Container links (deprecated)
25. `external_links` - External container links

#### **Storage and Devices**
26. `volumes` - Volume and bind mounts
27. `volumes_from` - Volumes from other containers
28. `devices` - Device mappings
29. `tmpfs` - tmpfs mounts
30. `storage_opt` - Storage driver options

#### **Networking**
31. `network_mode` - Network mode
32. `networks` - Networks to connect to
33. `ports` - Port mappings
34. `expose` - Internal port exposure
35. `hostname` - Container hostname
36. `domainname` - Domain name
37. `dns` - Custom DNS servers
38. `dns_opt` - DNS options
39. `dns_search` - DNS search domains
40. `extra_hosts` - Additional host mappings
41. `mac_address` - MAC address

#### **Environment and Configuration**
42. `environment` - Environment variables
43. `env_file` - Environment file
44. `labels` - Metadata labels
45. `label_file` - Label file
46. `annotations` - Container annotations
47. `configs` - External configurations
48. `secrets` - Secrets

#### **Resource Management**
49. `cpus` - CPU allocation
50. `cpu_count` - CPU count
51. `cpu_percent` - CPU percentage
52. `cpu_shares` - CPU weight
53. `cpu_period` - CFS scheduler period
54. `cpu_quota` - CFS scheduler quota
55. `cpu_rt_runtime` - Real-time scheduler runtime
56. `cpu_rt_period` - Real-time scheduler period
57. `cpuset` - Specific CPUs to use
58. `mem_limit` - Memory limit
59. `mem_reservation` - Memory reservation
60. `mem_swappiness` - Swap control
61. `memswap_limit` - Swap limit
62. `shm_size` - Shared memory size
63. `pids_limit` - Process limit
64. `ulimits` - User limits
65. `sysctls` - Kernel parameters
66. `oom_kill_disable` - Disable OOM killer
67. `oom_score_adj` - OOM score adjustment

#### **Block I/O Control**
68. `blkio_config` - Block I/O configuration

#### **Special Features**
69. `gpus` - GPU devices
70. `platform` - Target platform
71. `pull_policy` - Image pull policy
72. `healthcheck` - Health check configuration
73. `cgroup` - Cgroup namespace
74. `cgroup_parent` - Parent cgroup
75. `device_cgroup_rules` - Device cgroup rules
76. `ipc` - IPC mode
77. `pid` - PID mode
78. `uts` - UTS namespace

#### **Deployment and Scaling**
79. `deploy` - Deployment configuration
80. `develop` - Development configuration
81. `scale` - Number of replicas
82. `profiles` - Service profiles

#### **Advanced Features**
83. `extends` - Extend from other services
84. `models` - AI models (new)
85. `post_start` - Post-start hooks
86. `pre_stop` - Pre-stop hooks
87. `attach` - Log collection
88. `provider` - External provider
89. `use_api_socket` - Docker API socket access
90. `driver_opts` - Driver-specific options
91. `credential_spec` - Credential specification (Windows)

### Environment Variable Organization

- **5+ environment variables**: Group related variables with descriptive comments
  - Group by common prefixes, functionality, or related service
  - Sort variables alphabetically within each group
  - Use comment format: `# Group Name`
  - Order groups logically (basic config first, then feature-specific)
- **<5 environment variables**: Sort alphabetically without grouping
- Always preserve existing content and formatting

### Docker Compose Version

- Do **NOT** include `version:` field unless working with Docker Swarm
- Use `docker compose` commands (not legacy `docker-compose`)

## Dockerfile Standards

Follow these principles for **all** Dockerfiles:

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

Follow the **Conventional Commits specification** for all commit messages:

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