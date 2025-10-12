---
description: Create and test a new skill through interactive dialogue
---

# Create Skill

You are tasked with creating a new skill through interactive dialogue with the developer. Skills are markdown documents that define mandatory workflows and "iron laws" that agents must follow.

## Process

### 1. Understand Developer Intent

Start by asking the developer what they want to enforce:

"I'll help you create a new skill. Please explain:
1. What workflow or practice do you want to enforce?
2. What's the mandatory rule (iron law) that must never be broken?
3. When should this skill be applied?"

Then engage in iterative dialogue to clarify and refine their intent.

### 2. Structure the Skill

Once you understand their intent, structure it into skill format:

**Frontmatter**:
```yaml
---
title: [Descriptive Name]
last_updated: [YYYY-MM-DD]
author: [developer username from git config]
category: [testing|debugging|workflow|meta|custom]
tags: [relevant, tags]
applies_to: [all|orchestrator|specific-agent-name]
iron_law: "THE MANDATORY RULE IN ALL CAPS"
when_to_use:
  - specific scenario 1
  - specific scenario 2
  - specific scenario 3
---
```

**Required Sections**:
- # [Skill Title]
- ## Purpose
- ## When to Use
- ## Iron Law
- ## How to Use

**Optional Sections**:
- ## Examples
- ## Common Mistakes
- ## Testing This Skill
- ## Related Skills

### 3. Iterate Until Intent is Clear

Present your structured draft:

"Here's the skill I've drafted based on your description:

[Show formatted skill]

Does this accurately represent what you want to enforce? Any changes needed?"

Continue iterating with the developer until they confirm the skill accurately captures their intent.

### 4. Determine File Location

Based on the skill category and title:
- Convert title to kebab-case for directory name
- Path: `/home/coder/.config/opencode/skills/{category}/{slug}/SKILL.md`

Examples:
- "Test-Driven Development" → `testing/test-driven-development/SKILL.md`
- "Conventional Commits" → `workflow/conventional-commits/SKILL.md`

### 5. Create the Skill File

Write the skill to the determined path using the Write tool.

### 6. Test the Skill

Once the file is created, automatically spawn the skill-tester:

"Skill created at `/home/coder/.config/opencode/skills/{category}/{slug}/SKILL.md`

Now testing the skill with pressure scenarios..."

Spawn skill-tester:
```javascript
Task(subagent_type="skill-tester", prompt="
Test this skill: /home/coder/.config/opencode/skills/{category}/{slug}/SKILL.md

Follow your standard testing methodology:
1. Analyze the skill
2. Identify relevant subagents to test
3. Create pressure scenarios
4. Spawn and test those subagents
5. Report results with pass/fail verdict
")
```

### 7. Handle Test Results

Wait for skill-tester to complete and report results.

**If PASS**:
"✅ Skill passed all tests!

Test Summary:
[Show test results from skill-tester]

Would you like to share this skill with the team via Telegram? (y/n)"

**If FAIL**:
"❌ Skill failed testing.

Issues Found:
[Show issues from skill-tester]

Recommendations:
[Show recommendations]

Would you like to:
1. Revise the skill based on recommendations
2. Share anyway (not recommended)
3. Discard the skill"

### 8. Share if Approved

If developer says yes to sharing:

```javascript
share_skill({
  skill_path: "/home/coder/.config/opencode/skills/{category}/{slug}/SKILL.md",
  test_results: "[Summary of test results]"
})
```

Then confirm:
"✅ Skill shared to Telegram for team review!

The skill is ready for manual approval and addition to the dotfiles repo."

## Important Notes

- Be patient and iterative with the developer
- Focus on capturing their INTENT, not just their words
- The iron law must be specific and non-negotiable
- Test before sharing (always)
- Only share skills that pass testing (unless developer explicitly overrides)
- Use git config to get author name: `git config user.name`
- Use current date for last_updated: format as YYYY-MM-DD

## Example Interaction

```
Developer: /create-skill

Agent: "I'll help you create a new skill. Please explain:
1. What workflow or practice do you want to enforce?
2. What's the mandatory rule (iron law) that must never be broken?
3. When should this skill be applied?"

Developer: "I want to enforce that all commits follow conventional commits format"

Agent: "Got it. So the iron law is that all commits must follow the conventional commits specification?
Let me clarify:
- Does this apply to all agents or specific ones?
- Should there be any exceptions (hotfixes, merge commits, etc.)?
- What format exactly: type(scope): description?"

Developer: "All agents, no exceptions, yes that format"

Agent: "Perfect. Here's the skill I've drafted:

---
title: Conventional Commits
last_updated: 2025-10-12
author: developer1
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
Maintain consistent, semantic commit history...

[full skill content]

Does this accurately represent your intent?"

Developer: "Perfect, test it"

Agent: "Creating skill at /home/coder/.config/opencode/skills/workflow/conventional-commits/SKILL.md...
✓ Skill file created

Now testing with pressure scenarios..."

[Spawns skill-tester, waits for results]

Agent: "✅ Skill passed all tests!

Test Summary:
- Tested 4 subagents (orchestrator, build, javascript-typescript-dev, documentation-specialist)
- Applied 3 pressure scenarios (time pressure, sunk cost, authority)
- Pass rate: 4/4 (100%)

Would you like to share this skill with the team? (y/n)"

Developer: "y"

Agent: "✅ Skill shared to Telegram for team review!"
```