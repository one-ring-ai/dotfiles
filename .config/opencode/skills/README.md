# OpenCode Skills System

This directory contains skills that enforce mandatory workflows and best practices across all AI agents.

## What are Skills?

Skills are markdown documents that define "iron laws" - non-negotiable rules that agents must follow when performing specific tasks.

## Directory Structure

```
skills/
├── testing/           # Testing-related skills
│   └── tdd-workflow/  # TDD RED-GREEN-REFACTOR cycle
├── workflow/          # General workflow skills  
│   ├── conventional-commits/  # Git commit format
│   └── delegation-first/      # Orchestrator delegation
├── debugging/         # Debugging methodologies
└── meta/             # Skills for creating/managing skills
```

## Using Skills

Skills are automatically loaded at session start. When a skill applies to your task:
1. Agent checks available skills
2. Reads the relevant SKILL.md file
3. Follows the iron law and instructions

Use `/list-skills` to see all available skills.

## Creating New Skills

Use the `/create-skill` command:

```bash
/create-skill
```

This will:
1. Guide you through interactive skill creation
2. Test the skill automatically with pressure scenarios
3. Share it with the team (if it passes tests)

## Skill Format

Each skill has:
- **Frontmatter**: Metadata (title, category, iron law, when_to_use, etc.)
- **Purpose**: Why this skill exists
- **Iron Law**: The mandatory rule in ALL CAPS
- **How to Use**: Step-by-step instructions
- **Examples**: Code examples showing the skill in practice
- **Testing This Skill**: Pressure scenarios for validation

## Available Skills

See [Architecture Documentation](../../../docs/skills-system-architecture.md) for complete details.

Current skills:
- **TDD Workflow**: Write tests before code (RED-GREEN-REFACTOR)
- **Conventional Commits**: Standardized git commit format
- **Delegation First**: Orchestrator delegates all implementation

## Adding Skills to Dotfiles

When a skill is approved:
1. Create the directory: `skills/{category}/{slug}/`
2. Add the `SKILL.md` file
3. Commit to dotfiles repo
4. Skills automatically available in all VMs

## Technical Details

- Skills are loaded via `plugin/skills-enforcement.js`
- Index cached in `.index.json` for performance
- Full documentation: `docs/skills-system-architecture.md`
