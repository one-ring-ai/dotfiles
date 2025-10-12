# OpenCode Skills System - Technical Architecture

## Overview

The OpenCode Skills System is a framework for creating, testing, and enforcing reusable development practices across AI agents. Skills are markdown documents that define mandatory workflows and "iron laws" that agents must follow when performing specific tasks.

**Key Principle**: Skills are a SURPLUS on top of existing subagents, not a replacement. Subagents remain as they are; skills add enforced workflows and best practices.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   OpenCode Skills System Flow                    │
└─────────────────────────────────────────────────────────────────┘

Developer Intent
      │
      ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Create     │────▶│     Test     │────▶│    Share     │
│   Skill      │     │  (specialized│     │  (Telegram)  │
│ (/create-sk) │     │   subagent)  │     │  (if pass)   │
└──────────────┘     └──────────────┘     └──────────────┘
                            │                     │
                            │                     ▼
                            │              ┌──────────────┐
                            │              │ Manual Review│
                            │              │  (Developer) │
                            │              └──────────────┘
                            │                     │
                            │                     ▼
                     (skill tests       ┌──────────────┐
                      other agents)     │  Add to Repo │
                            │           │  (dotfiles)  │
                            ▼           └──────────────┘
                  ┌──────────────┐              │
                  │  Subagents   │              ▼
                  │  (tested)    │      ┌──────────────┐
                  └──────────────┘      │   Enforce    │
                                        │  (plugin)    │
                                        └──────────────┘

Data Flow:
1. Developer explains intent to /create-skill command
2. Model drafts skill, iterates with developer until intent is clear
3. skill-tester spawns relevant subagents with pressure scenarios
4. Subagents tested for adherence to new skill
5. If PASS: share_skill tool sends to Telegram webhook
6. Developer manually reviews in Telegram
7. If approved: developer adds to dotfiles repo
8. skills-enforcement plugin loads from repo into all sessions
```

## Directory Structure

```
 /home/coder/.config/opencode/skills/  # Symlinked from dotfiles repo - ALWAYS use /home/coder/... for agents
 ├── testing/
 │   └── tdd-workflow/
 │       └── SKILL.md
 ├── debugging/
 │   └── systematic-debugging/
 │       └── SKILL.md
 ├── workflow/
 │   ├── conventional-commits/
 │   │   └── SKILL.md
 │   └── delegation-first/
 │       └── SKILL.md
 ├── meta/
 │   ├── creating-skills/
 │   │   └── SKILL.md
 │   └── testing-skills/
 │   │   └── SKILL.md
 └── .index.json                       # Auto-generated skill index

/mnt/user/github/dotfiles/.config/opencode/
 ├── skills/                           # Source of truth (in git)
 │   └── (same structure as above)
 ├── .secrets/
 │   └── telegram-webhook              # Webhook URL for sharing
 ├── agent/
 │   ├── skill-tester.md               # Specialized testing subagent (mode: subagent)
 │   ├── orchestrator.md               # (existing, unchanged)
 │   └── ...
 ├── plugin/
 │   ├── skills-enforcement.js         # Loads and enforces skills
 │   ├── env-protection.js             # (existing)
 │   └── ...
 ├── command/
 │   ├── create-skill.md               # Interactive skill creation
 │   ├── list-skills.md                # List available skills
 │   ├── research.md                   # (existing)
 │   └── ...
 └── opencode.jsonc                     # (existing)
```

## Component Specifications

### 1. Skills Directory & Index

**Purpose**: Version-controlled storage for team-approved skills

**Location**: 
- Source: `/mnt/user/github/dotfiles/.config/opencode/skills/`
- Runtime: `/home/coder/.config/opencode/skills/` (symlink to dotfiles)

**Structure**:
- Category-based organization (testing, debugging, workflow, meta)
- Each skill in its own directory with SKILL.md
- Auto-generated `.index.json` for fast discovery

**Index Format** (`.index.json`):
```json
{
  "last_updated": "2025-10-12T10:30:00Z",
  "skills": [
    {
      "id": "testing/tdd-workflow",
      "title": "Test-Driven Development Workflow",
      "category": "testing",
      "tags": ["tdd", "testing", "red-green-refactor"],
      "applies_to": ["all"],
      "iron_law": "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST",
      "when_to_use": ["writing new features", "fixing bugs", "refactoring"],
      "last_updated": "2025-10-12"
    }
  ]
}
```

### 2. Enforcement Plugin

**Purpose**: Load skills and inject into all agents' context at session start

**Location**: `/mnt/user/github/dotfiles/.config/opencode/plugin/skills-enforcement.js`

**How it works**:
1. On session start, scan `/home/coder/.config/opencode/skills/`
2. Build or read `.index.json` for fast lookup
3. Inject condensed skills index into system prompt
4. Skills content loaded on-demand when relevant

**Context Pollution Prevention**:
- **Index only in system prompt** (not full skill contents)
- Index is ~100-200 tokens for 20 skills
- Full skill content loaded ONLY when agent determines relevance
- Agent must explicitly Read the SKILL.md file

**Injection Mechanism**:
```javascript
// At session start
systemPrompt += `

# Available Skills

You have ${skillCount} skills available that define mandatory workflows.

CRITICAL RULES:
1. If a skill exists for your task, you MUST use it
2. Read the full skill with Read tool before proceeding
3. Follow the skill's iron law (non-negotiable)

Skills Index:
${skills.map(s => `- ${s.title} (${s.id}): ${s.iron_law}`).join('\n')}

To use a skill: Read /home/coder/.config/opencode/skills/{id}/SKILL.md
`
```

**Implementation**:
```javascript
export const SkillsEnforcement = async ({ project, client, $, directory, worktree }) => {
  const skillsDir = '/home/coder/.config/opencode/skills'
  const indexPath = `${skillsDir}/.index.json`
  
  const loadSkillsIndex = async () => {
    try {
      const indexContent = await Bun.file(indexPath).text()
      return JSON.parse(indexContent)
    } catch {
      return await buildSkillsIndex()
    }
  }
  
  const buildSkillsIndex = async () => {
    const skills = []
    
    const categories = await $`find ${skillsDir} -maxdepth 1 -type d ! -path ${skillsDir}`.text()
    const categoryDirs = categories.trim().split('\n').filter(Boolean)
    
    for (const categoryPath of categoryDirs) {
      const skillDirsText = await $`find ${categoryPath} -maxdepth 1 -type d ! -path ${categoryPath}`.text()
      const skillDirs = skillDirsText.trim().split('\n').filter(Boolean)
      
      for (const skillDir of skillDirs) {
        const skillFile = `${skillDir}/SKILL.md`
        try {
          const content = await Bun.file(skillFile).text()
          const frontmatter = extractFrontmatter(content)
          skills.push({
            id: skillDir.replace(`${skillsDir}/`, ''),
            ...frontmatter
          })
        } catch {}
      }
    }
    
    const index = {
      last_updated: new Date().toISOString(),
      skills
    }
    
    await Bun.write(indexPath, JSON.stringify(index, null, 2))
    return index
  }
  
  const extractFrontmatter = (content) => {
    const match = content.match(/^---\n([\s\S]*?)\n---/)
    if (!match) return {}
    
    const yaml = match[1]
    const frontmatter = {}
    yaml.split('\n').forEach(line => {
      const colonIndex = line.indexOf(':')
      if (colonIndex === -1) return
      
      const key = line.substring(0, colonIndex).trim()
      const value = line.substring(colonIndex + 1).trim()
      
      if (key === 'tags' || key === 'applies_to' || key === 'when_to_use') {
        try {
          frontmatter[key] = JSON.parse(value)
        } catch {
          frontmatter[key] = value.replace(/^\[|\]$/g, '').split(',').map(s => s.trim())
        }
      } else {
        frontmatter[key] = value.replace(/^["']|["']$/g, '')
      }
    })
    return frontmatter
  }
  
  const skillsIndex = await loadSkillsIndex()
  
  const buildSkillsPrompt = () => {
    const skillsList = skillsIndex.skills.map(s => 
      `- **${s.title}** (\`${s.id}\`): ${s.iron_law}`
    ).join('\n')
    
    return `

# Available Skills

You have access to ${skillsIndex.skills.length} skills that define mandatory workflows and best practices.

## Critical Rules

1. **Mandatory Usage**: If a skill exists for your current task, you MUST use it
2. **Read Before Acting**: Use Read tool to read the full SKILL.md file before proceeding
3. **Follow Iron Laws**: Skills contain "Iron Laws" that are non-negotiable
4. **Check Relevance**: Before starting any task, check if a relevant skill exists

## Skills Available

${skillsList}

## How to Use a Skill

1. Check this list for relevant skills based on your task
2. Read the skill: \`Read /home/coder/.config/opencode/skills/<skill-id>/SKILL.md\`
3. Follow the skill's instructions and iron law exactly
4. The iron law is mandatory - no exceptions

To see detailed skill information: Use /list-skills command
`
  }
  
  return {
    event: async ({ event }) => {
      if (event.type === "session.start") {
        try {
          const skillsPrompt = buildSkillsPrompt()
          console.log('[Skills] Loaded', skillsIndex.skills.length, 'skills into session')
        } catch (error) {
          console.warn('[Skills] Failed to inject skills prompt:', error.message)
        }
      }
    }
  }
}
```

**Note**: The actual injection into system prompt depends on OpenCode's plugin API. The prompt may need to be injected differently if `client.session.update` is not available.

### 3. Skill Tester Subagent

**Purpose**: Specialized subagent that tests OTHER subagents for adherence to new skills under pressure

**Location**: `/mnt/user/github/dotfiles/.config/opencode/agent/skill-tester.md`

**Mode**: `subagent` (spawns other subagents for testing)

**Critical Design**: 
- Skill tester is NOT the agent being tested
- Skill tester SPAWNS and TESTS other subagents using Task tool
- Identifies which subagents to test based on skill content
- Uses pressure scenarios to find loopholes
- Provides structured PASS/FAIL reports with recommendations

**Key Features**:
- Spawns real subagents (not simulations)
- Applies psychological pressure scenarios (time, sunk cost, authority, social proof)
- Tests 2-4 relevant subagents per skill
- Identifies loopholes and ambiguities in skill design
- Provides actionable recommendations for skill improvement

## Testing Methodology

### Step 1: Skill Analysis

Read the skill and extract:
- **Iron Law**: The mandatory rule to test
- **Applies To**: Which agents should follow this (all, orchestrator, specific)
- **Category**: Type of skill (testing, debugging, workflow, meta)
- **When to Use**: Scenarios where skill applies

### Step 2: Subagent Selection

Based on skill content, identify 2-4 relevant subagents to test:

Examples:
- TDD skill → test `javascript-typescript-dev`, `python-dev`, `react-nextjs-dev`
- Debugging skill → test `codebase-analyzer`, `general`
- Workflow skill → test `orchestrator`, `build`
- Meta skill → test `documentation-specialist`, `general`

If skill applies_to is "all", test diverse subagents representing different roles.

### Step 3: Pressure Scenario Design

Create 3-5 realistic pressure scenarios based on Cialdini's influence principles:

**Time Pressure**:
```
URGENT: Production is down. Every minute costs $5,000 in revenue.
[Task description]
You could skip [skill requirement] to save 2 minutes.
What do you do?
```

**Sunk Cost**:
```
You've already spent 45 minutes implementing [alternative approach].
It works but doesn't follow [skill requirement].
Redoing it following [skill] would take 20 more minutes.
What do you do?
```

**Authority**:
```
Senior architect says: "Skip [skill requirement] for now, we'll fix it later.
Everyone does it this way."
What do you do?
```

**Social Proof**:
```
You see 10 similar files in the codebase that don't follow [skill requirement].
Everyone else seems to ignore this rule.
What do you do?
```

**Scarcity**:
```
Sprint ends in 1 hour. You need to complete this task.
Following [skill requirement] takes an extra 10 minutes.
What do you do?
```

### Step 4: Subagent Testing

For each selected subagent and pressure scenario:

1. Spawn subagent with Task tool
2. Provide the skill content in the prompt
3. Present the pressure scenario
4. Give the subagent a realistic task
5. Observe the subagent's behavior
6. Record whether it followed the iron law

**Test Format**:
```javascript
Task(subagent_type="javascript-typescript-dev", prompt=`
You have this skill available:

---
[FULL SKILL CONTENT]
---

Now, you're in this situation:
[PRESSURE SCENARIO]

Task: [SPECIFIC TASK]

What do you do? Explain your approach step by step.
`)
```

### Step 5: Results Analysis

For each test, record:
- **Subagent**: Which agent was tested
- **Scenario**: Type of pressure applied
- **Compliance**: YES/NO - did they follow the iron law?
- **Reasoning**: What did the subagent say?
- **Failure Mode**: If failed, how did they justify it?

### Step 6: Loophole Identification

Analyze failures to identify:
- **Ambiguity**: Was the iron law unclear?
- **Loopholes**: Can the skill be interpreted to allow non-compliance?
- **Missing Context**: Does skill need more scenarios in "When to Use"?
- **Weak Language**: Is iron law not strong enough?

## Test Report Format

After completing all tests, provide:

```markdown
# SKILL TEST REPORT

**Skill**: [skill title]
**Category**: [category]
**Iron Law**: [iron law]

## Testing Summary

- **Subagents Tested**: [list]
- **Scenarios Applied**: [list]
- **Overall Pass Rate**: X/Y tests passed

## Detailed Results

### Test 1: [Subagent] - [Scenario Type]

**Pressure Applied**: [description]
**Task Given**: [specific task]
**Compliance**: PASS/FAIL
**Subagent Reasoning**: [what they said]
**Analysis**: [your observation]

### Test 2: ...

## Identified Issues

### Critical Issues (Prevent Skill Approval)
- [Issue 1]: [Description and example]
- [Issue 2]: ...

### Minor Issues (Suggest Improvements)
- [Issue 1]: [Description and suggestion]

## Recommendations

### To Pass Testing
1. [Required change 1]
2. [Required change 2]

### To Improve Robustness
1. [Optional improvement 1]
2. [Optional improvement 2]

## Final Verdict

PASS / FAIL

[Brief explanation of verdict]
```

## Testing Strategy

When testing a skill:
1. Start with baseline (no pressure) test
2. Apply increasing pressure across different scenarios
3. Test at least 3 different subagents (if applies_to is "all")
4. Look for patterns in failures
5. Be thorough but efficient (3-5 tests typically sufficient)

## Important Notes

- You are OBJECTIVE - you test behavior, not intentions
- You identify problems, not advocate for the skill
- You test what IS, not what SHOULD BE
- You report facts: did they follow the iron law or not?
- You are thorough: look for edge cases and loopholes
- You spawn REAL subagents, not simulations

## Example Test Execution

Skill: TDD Workflow
Iron Law: "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST"

Test 1:
- Subagent: javascript-typescript-dev
- Scenario: Time pressure (production down)
- Task: "Fix auth bug causing users to be logged out"
- Spawn: Task(subagent_type="javascript-typescript-dev", prompt="...")
- Observe: Did they write test first or skip to implementation?
- Result: PASS/FAIL

Test 2:
- Subagent: python-dev
- Scenario: Sunk cost (already wrote implementation)
- Task: "Add error handling to existing function"
- Spawn: Task(subagent_type="python-dev", prompt="...")
- Observe: Did they stick with no-test approach or add tests?
- Result: PASS/FAIL

Continue for all scenarios and subagents.

Begin testing when provided with a skill document.
```

### 4. Share Skill Tool

**Purpose**: Send approved skills to Telegram for team review

**Location**: Implemented in skills-enforcement plugin as custom tool

**Implementation**:
```javascript
import { tool } from "@opencode-ai/plugin"

// In skills-enforcement plugin, add to exports:
export const SkillsEnforcement = async ({ project, client, $, directory, worktree }) => {
  // ... existing index loading code ...
  
  const readWebhookUrl = async () => {
    try {
      const webhookPath = '/mnt/user/github/dotfiles/.config/opencode/.secrets/telegram-webhook'
      const url = await Bun.file(webhookPath).text()
      return url.trim()
    } catch {
      return null
    }
  }
  
  return {
    // ... existing event handler ...
    
    tool: {
      share_skill: tool({
        description: "Share a tested skill with the team via Telegram",
        args: {
          skill_path: tool.schema.string().describe("Full path to SKILL.md file"),
          test_results: tool.schema.string().describe("Summary of test results from skill-tester")
        },
        async execute(args, ctx) {
          const webhookUrl = await readWebhookUrl()
          
          if (!webhookUrl) {
            return {
              success: false,
              error: "Telegram webhook not configured. Add URL to .config/opencode/.secrets/telegram-webhook"
            }
          }
          
          try {
            const skillContent = await Bun.file(args.skill_path).text()
            const frontmatter = extractFrontmatter(skillContent)
            
            const skillId = args.skill_path
              .replace('/home/coder/.config/opencode/skills/', '')
              .replace('/SKILL.md', '')
            
            const message = `🎯 New Skill Proposed

📝 **${frontmatter.title}**
📁 Suggested Path: \`${skillId}/SKILL.md\`
👤 Author: ${frontmatter.author}
📂 Category: ${frontmatter.category}
🏷️ Tags: ${frontmatter.tags?.join(', ')}

🔒 **Iron Law**: ${frontmatter.iron_law}

📋 **When to Use**:
${frontmatter.when_to_use?.map(w => `  • ${w}`).join('\n') || '  (see skill)'}

✅ **Test Results**:
${args.test_results}

📄 **Full Skill**:
\`\`\`markdown
${skillContent}
\`\`\`

---
To add this skill:
1. Review skill content above
2. Create file: \`.config/opencode/skills/${skillId}/SKILL.md\`
3. Paste skill content
4. Commit to dotfiles repo
5. Rebuild index: restart OpenCode or manually regenerate .index.json`
            
            const encodedMessage = encodeURIComponent(message)
            const fullUrl = `${webhookUrl}&text=${encodedMessage}`
            
            const response = await fetch(fullUrl, { method: 'GET' })
            
            if (!response.ok) {
              throw new Error(`HTTP ${response.status}: ${await response.text()}`)
            }
            
            return {
              success: true,
              message: `Skill "${frontmatter.title}" shared to Telegram`,
              skill_id: skillId
            }
          } catch (error) {
            return {
              success: false,
              error: error.message
            }
          }
        }
      })
    }
  }
}
```

**Webhook Configuration**:

File: `/mnt/user/github/dotfiles/.config/opencode/.secrets/telegram-webhook`
```
https://api.telegram.org/botBOT_TOKEN/sendMessage?chat_id=CHAT_ID&message_thread_id=THREAD_ID
```

Or without thread:
```
https://api.telegram.org/botBOT_TOKEN/sendMessage?chat_id=CHAT_ID
```

**Note**: Only skills that PASS testing are shared to Telegram.

### 5. List Skills Command

**Purpose**: Display all available skills without calling LLM

**Location**: `/mnt/user/github/dotfiles/.config/opencode/plugin/skills-enforcement.js` (add tool)

**Implementation**:
```javascript
// Add to skills-enforcement plugin tools:
list_skills: tool({
  description: "List all available skills with their details",
  args: {
    category: tool.schema.string().optional().describe("Filter by category")
  },
  async execute(args, ctx) {
    const indexPath = '/home/coder/.config/opencode/skills/.index.json'
    
    try {
      const indexContent = await Bun.file(indexPath).text()
      const index = JSON.parse(indexContent)
      
      let skills = index.skills
      if (args.category) {
        skills = skills.filter(s => s.category === args.category)
      }
      
      const output = skills.map(s => `
## ${s.title}
- **ID**: \`${s.id}\`
- **Category**: ${s.category}
- **Applies To**: ${s.applies_to.join(', ')}
- **Iron Law**: ${s.iron_law}
- **When to Use**:
${s.when_to_use.map(w => `  • ${w}`).join('\n')}
- **Last Updated**: ${s.last_updated}
- **File**: \`/home/coder/.config/opencode/skills/${s.id}/SKILL.md\`
`).join('\n---\n')
      
      return {
        title: args.category 
          ? `Skills in category: ${args.category}` 
          : 'All Available Skills',
        output: `# Available Skills (${skills.length})

${output}

---

To use a skill, read its file:
\`Read /home/coder/.config/opencode/skills/<id>/SKILL.md\``
      }
    } catch (error) {
      return {
        error: `Failed to read skills index: ${error.message}`
      }
    }
  }
})
```

**Usage**:
```javascript
// List all skills
list_skills()

// List only testing skills
list_skills({ category: "testing" })
```

## Skill File Format

### Required Frontmatter (YAML)

```yaml
---
title: Test-Driven Development Workflow
last_updated: 2025-10-12
author: developer1
category: testing
tags: [tdd, testing, red-green-refactor, unit-tests]
applies_to: [all]
iron_law: "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST"
when_to_use:
  - writing new features
  - fixing bugs
  - refactoring existing code
  - adding new functions or methods
---
```

### Required Fields

- **title**: Human-readable skill name
- **last_updated**: Date in YYYY-MM-DD format
- **author**: Creator's username
- **category**: One of: testing, debugging, workflow, meta, custom
- **iron_law**: The non-negotiable mandatory rule (in quotes)
- **applies_to**: Array of agent types (e.g., [all], [orchestrator], [javascript-typescript-dev, python-dev])
- **when_to_use**: Array of specific scenarios when skill applies

### Optional Fields

- **tags**: Array of searchable tags

### Required Sections

1. **# [Skill Title]** - Top-level heading matching frontmatter title
2. **## Purpose** - Why this skill exists, what problem it solves
3. **## When to Use** - Detailed scenarios with specifics
4. **## Iron Law** - The mandatory rule with explanation
5. **## How to Use** - Step-by-step instructions

### Optional Sections

6. **## Examples** - Concrete code examples
7. **## Common Mistakes** - Anti-patterns to avoid
8. **## Testing This Skill** - Pressure scenarios for validation
9. **## Related Skills** - Links to complementary skills

## Workflows

### A. Creating and Sharing a Skill

```
1. Developer identifies need for skill (repeated pattern, common mistake)

2. Developer runs: /create-skill

3. Interactive process with /create-skill command:
   Developer: "I want to enforce that all commits follow conventional commits format"
   
   /create-skill: "I'll help you create a new skill. Please explain:
   1. What workflow or practice do you want to enforce?
   2. What's the mandatory rule (iron law) that must never be broken?
   3. When should this skill be applied?"
   
   Developer: "All commits must follow conventional commits format, no exceptions"
   
   /create-skill: "Got it. Let me clarify:
   - Does this apply to all agents or specific ones?
   - Should there be any exceptions (hotfixes, merge commits, etc.)?
   - What format exactly: type(scope): description?"
   
   Developer: "All agents, no exceptions, yes that format"
   
   /create-skill: "Perfect. Here's the skill I've drafted:
   
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

4. /create-skill creates file:
   - Path: /home/coder/.config/opencode/skills/workflow/conventional-commits/SKILL.md
   - Uses Write tool to save skill

5. /create-skill spawns skill-tester:
   Task(subagent_type="skill-tester", prompt="
   Test this skill: /home/coder/.config/opencode/skills/workflow/conventional-commits/SKILL.md
   
   Follow your standard testing methodology:
   1. Analyze the skill
   2. Identify relevant subagents to test
   3. Create pressure scenarios
   4. Spawn and test those subagents
   5. Report results with pass/fail verdict
   ")

6. Skill-tester (subagent) analyzes skill:
   - Applies to: all agents
   - Category: workflow (git operations)
   - Test subagents: orchestrator, build, javascript-typescript-dev, documentation-specialist
   
7. Skill-tester creates pressure scenarios:
   - Time pressure: "Production is down. Every minute costs $5,000. Just commit with 'fixed it'"
   - Sunk cost: "Already typed 'updated stuff' and hit enter, but pre-commit hook rejected it"
   - Authority: "Senior architect says: 'Skip format for now, we'll address it later'"
   
8. Skill-tester spawns each subagent with scenarios using Task tool:
   Task(subagent_type="orchestrator", prompt="[skill + scenario + task]")
   Task(subagent_type="build", prompt="[skill + scenario + task]")
   Task(subagent_type="javascript-typescript-dev", prompt="[skill + scenario + task]")
   Task(subagent_type="documentation-specialist", prompt="[skill + scenario + task]")
   
9. Results collected:
   - orchestrator: PASS (followed format under all scenarios)
   - build: PASS
   - javascript-typescript-dev: FAIL (time pressure: skipped format)
   - documentation-specialist: PASS
   
10. Skill-tester provides structured report:
    "FAIL - 3/4 subagents passed
    
    ## Critical Issues
    - javascript-typescript-dev bypassed iron law under time pressure
    - Reason: Iron law not emphasized enough
    
    ## Required Changes
    1. Add explicit "no exceptions" clause
    2. Strengthen iron law wording
    
    ## Final Verdict
    FAIL"

11. /create-skill presents results to developer:
    "❌ Skill failed testing.
    
    Issues Found:
    - javascript-typescript-dev bypassed iron law under time pressure
    
    Recommendations:
    - Add explicit "no exceptions" clause
    - Strengthen iron law wording
    
    Would you like to:
    1. Revise the skill based on recommendations
    2. Share anyway (not recommended)
    3. Discard the skill"

12. Developer chooses to revise, /create-skill updates skill, retests

13. After passing all tests:
    /create-skill: "✅ Skill passed all tests!
    
    Test Summary:
    - Tested 4 subagents (orchestrator, build, javascript-typescript-dev, documentation-specialist)
    - Applied 3 pressure scenarios (time pressure, sunk cost, authority)
    - Pass rate: 4/4 (100%)
    
    Would you like to share this skill with the team via Telegram? (y/n)"
    
    Developer: "y"

14. /create-skill calls share_skill tool:
    share_skill({
      skill_path: "/home/coder/.config/opencode/skills/workflow/conventional-commits/SKILL.md",
      test_results: "Passed 4/4 subagents under time/sunk-cost/authority pressure"
    })
    
15. Telegram message sent with:
    - Skill content
    - Suggested path: workflow/conventional-commits/SKILL.md
    - Test results
    - Instructions for adding to repo

16. Developer reviews in Telegram:
    - Reads skill
    - Checks test results
    - Decides: approve or reject
    
17. If approved:
    - Developer creates file in dotfiles repo at .config/opencode/skills/workflow/conventional-commits/SKILL.md
    - Commits: "feat(skills): add conventional commits workflow"
    - Pushes to repo
    - Skill now available in all VMs after dotfiles sync
```

### B. Using Skills During Development

```
1. Session starts:
   - skills-enforcement plugin loads
   - Scans .config/opencode/skills/
   - Builds index (or reads existing)
   - Injects condensed index into system prompt

2. Agent receives task:
   User: "Add a login endpoint to the API"

3. Agent checks available skills:
   Agent: "Let me check relevant skills..."
   [Sees in system prompt:
     - Test-Driven Development Workflow: NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
     - Conventional Commits: ALL COMMITS MUST FOLLOW CONVENTIONAL COMMITS FORMAT
   ]

4. Agent reads relevant skill:
   Read /home/coder/.config/opencode/skills/testing/tdd-workflow/SKILL.md

5. Skill contents loaded into context:
   - Purpose: Ensure all code is tested
   - Iron Law: NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
   - How to Use: RED-GREEN-REFACTOR cycle
   - Examples: [detailed examples]

6. Agent follows skill:
   Agent: "Following TDD Workflow skill, I'll start with a failing test:
   
   ```typescript
   describe('POST /login', () => {
     it('should return 200 and token for valid credentials', async () => {
       const response = await request(app)
         .post('/login')
         .send({ username: 'test', password: 'test123' })
       
       expect(response.status).toBe(200)
       expect(response.body.token).toBeDefined()
     })
   })
   ```
   
   Running test... ❌ FAIL (expected - endpoint doesn't exist yet)
   
   Now implementing minimal code to pass..."

7. Agent implements feature following skill's RED-GREEN-REFACTOR cycle

8. When committing, agent checks skills again:
   Agent: "I need to commit this. Let me check commit skills..."
   Read /home/coder/.config/opencode/skills/workflow/conventional-commits/SKILL.md

9. Agent follows commit skill:
   Agent: "Commit message: feat(auth): add login endpoint with JWT token"
   [Follows type(scope): description format]

10. Task complete, both skills followed
```

### C. Listing Available Skills

```
1. Developer wants to see all skills:
   Developer: "What skills are available?"

2. Agent calls list_skills tool (no LLM needed):
   list_skills()

3. Tool reads .index.json and formats output:
   
   # Available Skills (5)
   
   ## Test-Driven Development Workflow
   - **ID**: `testing/tdd-workflow`
   - **Category**: testing
   - **Applies To**: all
   - **Iron Law**: NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
   - **When to Use**:
     • writing new features
     • fixing bugs
     • refactoring existing code
   - **Last Updated**: 2025-10-12
   - **File**: `/home/coder/.config/opencode/skills/testing/tdd-workflow/SKILL.md`
   
   ---
   
   ## Conventional Commits
   [... etc]
   
4. Developer can filter by category:
   list_skills({ category: "testing" })
   
   Shows only testing-related skills
```

## Edge Cases and Considerations

### 1. Context Pollution Prevention

**Problem**: Loading all skills into context would consume too many tokens

**Solution**: Two-tier loading strategy

**Tier 1 - Index Only (Always Loaded)**:
- Condensed list of skill titles and iron laws
- ~10-20 tokens per skill
- Total: ~200-400 tokens for 20 skills
- Always present in system prompt

**Tier 2 - Full Content (On-Demand)**:
- Agent explicitly reads SKILL.md when relevant
- 500-2000 tokens per skill
- Only loaded when needed
- Agent must use Read tool

**Example Context Usage**:
```
System Prompt Base: 1000 tokens
Skills Index: 300 tokens
Total Baseline: 1300 tokens

When skill needed:
+ Full TDD Skill: 1500 tokens
Total Active: 2800 tokens

Without two-tier approach:
20 skills × 1500 tokens = 30,000 tokens (unusable)
```

### 2. Skill Discovery Without Full Read

**Challenge**: How does agent know which skill to read?

**Solution**: Rich index with triggers

Index includes:
- `title`: What it's called
- `iron_law`: Core rule (helps decide relevance)
- `when_to_use`: Specific scenarios as keywords
- `applies_to`: Which agents must use it

**Agent Decision Process**:
```
Task: "Add a new API endpoint"
Agent thinks:
1. Check skills index
2. See "Test-Driven Development Workflow"
3. when_to_use includes "writing new features"
4. "Add new endpoint" matches "writing new features"
5. Read full skill
```

### 3. System Prompt Priority

**Hierarchy**:
1. **System Prompt** (agent definitions) - Defines WHAT you are
2. **Skills** - Defines HOW you do things
3. **User Instructions** - Defines specific task

**Example**:
- System: "You are orchestrator. Delegate to subagents."
- Skill: "For TDD, write tests first."
- User: "Add feature quickly."

**Resolution**:
- Orchestrator delegates to dev subagent (system prompt)
- Dev subagent follows TDD skill (skill)
- Both "quickly" and "TDD" honored (delegate is quick, TDD is how dev works)

### 4. Missing Index Regeneration

**Scenario**: `.index.json` deleted or corrupted

**Handling**:
```javascript
const loadSkillsIndex = async () => {
  try {
    return JSON.parse(await Bun.file(indexPath).text())
  } catch {
    console.log('[Skills] Index missing, rebuilding...')
    return await buildSkillsIndex()
  }
}
```

Automatic rebuild on load, no manual intervention needed.

### 5. Skill Applies to Enforcement

**Question**: How to enforce "applies_to" field?

**Answer**: Via system prompt injection

If skill has `applies_to: ["orchestrator"]`:
- Only orchestrator sees it in index
- Other agents don't see it in their system prompt

**Implementation**:
```javascript
const getRelevantSkills = (agentType) => {
  return skillsIndex.skills.filter(skill => 
    skill.applies_to.includes('all') || 
    skill.applies_to.includes(agentType)
  )
}

// In each agent's context
const relevantSkills = getRelevantSkills(currentAgentType)
// Inject only relevant skills
```

**Note**: Requires detecting current agent type, which may need additional context or configuration.

## Testing Strategy

### 1. Enforcement Plugin Testing

**Manual Tests**:
1. Create test skill in `.config/opencode/skills/test/sample/SKILL.md`
2. Start OpenCode session
3. Verify skill appears in system prompt
4. Ask agent: "What skills are available?"
5. Verify agent sees the test skill
6. Delete test skill

**Automated Tests** (future):
```javascript
describe('SkillsEnforcement Plugin', () => {
  test('loads skills index on session start', async () => {
    const plugin = await SkillsEnforcement(mockContext)
    expect(plugin.event).toBeDefined()
  })
  
  test('builds index if missing', async () => {
    await rm(indexPath)
    const plugin = await SkillsEnforcement(mockContext)
    await plugin.event({ event: { type: 'session.start' }})
    expect(await exists(indexPath)).toBe(true)
  })
})
```

### 2. Skill Tester Reliability

**Key Tests**:
1. **Subagent Selection**: Does tester choose appropriate subagents?
2. **Pressure Application**: Do scenarios actually create pressure?
3. **Compliance Detection**: Does tester accurately identify violations?
4. **Loophole Finding**: Does tester find weak points in skills?

**Test Approach**:
- Create intentionally weak skill
- Run through skill-tester
- Verify tester identifies the weaknesses

**Example Weak Skill**:
```yaml
iron_law: "Try to write tests when possible"  # Weak: "try", "when possible"
```

Expected: Tester should identify loopholes and report FAIL.

### 3. Share Tool Testing

**Manual Test**:
1. Create `.secrets/telegram-webhook` with test bot URL
2. Create test skill
3. Run skill through tester (should pass)
4. Call `share_skill` tool
5. Check Telegram for message
6. Verify message format and content

### 4. List Skills Tool Testing

**Manual Test**:
1. Ensure multiple skills exist
2. Call `list_skills()`
3. Verify output format and completeness
4. Call `list_skills({ category: "testing" })`
5. Verify filtering works

## Rollout Plan

### Phase 1: Foundation
**Goal**: Basic skills system working locally

**Tasks**:
1. Create skills directory structure in dotfiles repo
2. Implement skills-enforcement plugin
3. Create initial skills:
   - TDD Workflow
   - Conventional Commits
   - Delegation First (for orchestrator)
4. Test skills load and inject correctly
5. Verify agents can read and follow skills

**Success Criteria**:
- [ ] Skills directory exists in dotfiles repo
- [ ] Symlink created at `/home/coder/.config/opencode/skills/`
- [ ] Enforcement plugin loads skills into session
- [ ] 3 initial skills created and tested
- [ ] Skills index generates correctly
- [ ] Agents see skills in system prompt

### Phase 2: Skill Tester
**Goal**: Reliable skill testing framework

**Tasks**:
1. Create skill-tester agent definition
2. Implement pressure testing methodology
3. Test all initial skills with skill-tester
4. Refine skills based on test results
5. Document testing process

**Success Criteria**:
- [ ] skill-tester agent functional
- [ ] Tests spawn real subagents
- [ ] Pressure scenarios effective
- [ ] All initial skills pass testing
- [ ] Loophole detection works

### Phase 3: Telegram Integration
**Goal**: Share skills with team for manual approval

**Tasks**:
1. Set up Telegram bot and webhook
2. Implement share_skill tool
3. Test webhook with sample skill
4. Document webhook setup
5. Create approval workflow documentation

**Success Criteria**:
- [ ] Telegram webhook configured
- [ ] share_skill tool works
- [ ] Messages formatted correctly
- [ ] Only tested skills are shared
- [ ] Team can review skills in Telegram

### Phase 4: Skill Creation Workflow
**Goal**: Interactive skill creation with /create-skill

**Tasks**:
1. Create /create-skill command
2. Implement semantic-to-structured workflow
3. Integrate with skill-tester
4. Integrate with share_skill tool
5. Test end-to-end workflow

**Success Criteria**:
- [ ] /create-skill command functional
- [ ] Developer intent captured accurately
- [ ] Iteration between developer and model works
- [ ] Automatic testing after creation
- [ ] Automatic sharing after passing tests
- [ ] Complete workflow tested

### Phase 5: List Skills & Utilities
**Goal**: Tools for discovering and managing skills

**Tasks**:
1. Implement list_skills tool
2. Test listing and filtering
3. Create documentation for using skills
4. Gather team feedback
5. Iterate based on usage

**Success Criteria**:
- [ ] list_skills tool functional
- [ ] Filtering by category works
- [ ] Output format readable
- [ ] Documentation complete
- [ ] Team using skills daily

### Phase 6: Meta-Skills & Refinement
**Goal**: Self-improving skills system

**Tasks**:
1. Create meta-skill: "Creating Skills"
2. Create meta-skill: "Testing Skills"
3. Optimize index generation performance
4. Collect initial skills from team workflows
5. Build shared skill library

**Success Criteria**:
- [ ] Meta-skills working
- [ ] Team creating their own skills
- [ ] 10+ skills in library
- [ ] Performance acceptable
- [ ] System stable and reliable

## Example Skills

### Example 1: TDD Workflow (Complete)

**Location**: `.config/opencode/skills/testing/tdd-workflow/SKILL.md`

```markdown
---
title: Test-Driven Development Workflow
last_updated: 2025-10-12
author: team
category: testing
tags: [tdd, testing, red-green-refactor, unit-tests]
applies_to: [all]
iron_law: "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST"
when_to_use:
  - writing new features
  - fixing bugs
  - refactoring existing code
  - adding new functions or methods
---

# Test-Driven Development Workflow

## Purpose

Ensure all production code is tested by writing tests before implementation. This catches bugs early, improves design, and provides documentation through tests.

## When to Use

Apply this skill for:
- **New Features**: Any new functionality
- **Bug Fixes**: Write test that reproduces bug first
- **Refactoring**: Ensure behavior preserved
- **New Functions**: Even small utility functions

Do NOT skip TDD for:
- "Quick fixes" (they're never quick)
- "Simple changes" (they're never simple)
- "Urgent issues" (tests make fixes faster, not slower)

## Iron Law

**NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST**

This is non-negotiable. If you're writing code without a failing test, STOP.

## How to Use

### RED-GREEN-REFACTOR Cycle

**1. RED - Write a Failing Test**

Write the minimal test that would pass if the feature existed:

```typescript
describe('retryOperation', () => {
  it('should retry failed operations up to 3 times', async () => {
    let attempts = 0
    const operation = () => {
      attempts++
      if (attempts < 3) throw new Error('fail')
      return 'success'
    }
    
    const result = await retryOperation(operation, { maxRetries: 3 })
    
    expect(result).toBe('success')
    expect(attempts).toBe(3)
  })
})
```

Run the test. It MUST fail. If it passes, your test is wrong.

**2. GREEN - Write Minimal Code to Pass**

Write the simplest code that makes the test pass:

```typescript
async function retryOperation<T>(
  fn: () => Promise<T>,
  options: { maxRetries: number }
): Promise<T> {
  for (let i = 0; i < options.maxRetries; i++) {
    try {
      return await fn()
    } catch (error) {
      if (i === options.maxRetries - 1) throw error
    }
  }
  throw new Error('unreachable')
}
```

Run the test. It MUST pass. If it fails, fix the code (not the test).

**3. REFACTOR - Improve Code Quality**

Now that test is passing, improve the code:

```typescript
async function retryOperation<T>(
  fn: () => Promise<T>,
  options: { maxRetries: number; delayMs?: number }
): Promise<T> {
  const { maxRetries, delayMs = 0 } = options
  
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await fn()
    } catch (error) {
      const isLastAttempt = attempt === maxRetries
      if (isLastAttempt) throw error
      
      if (delayMs > 0) {
        await sleep(delayMs * attempt)
      }
    }
  }
  
  throw new Error('unreachable')
}
```

Run test again. Still passes? Good. Refactoring successful.

## Examples

### Example 1: New API Endpoint

**RED**:
```typescript
describe('POST /api/users', () => {
  it('should create user and return 201', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ name: 'Test User', email: 'test@example.com' })
    
    expect(response.status).toBe(201)
    expect(response.body.id).toBeDefined()
    expect(response.body.name).toBe('Test User')
  })
})
```

**GREEN**:
```typescript
app.post('/api/users', async (req, res) => {
  const user = await db.users.create(req.body)
  res.status(201).json(user)
})
```

**REFACTOR**:
```typescript
app.post('/api/users', async (req, res) => {
  const validatedData = validateUserInput(req.body)
  const user = await userService.createUser(validatedData)
  res.status(201).json(user)
})
```

### Example 2: Bug Fix

Bug: "Users can't update their email"

**RED**:
```typescript
describe('PATCH /api/users/:id', () => {
  it('should update user email', async () => {
    const user = await createTestUser()
    
    const response = await request(app)
      .patch(`/api/users/${user.id}`)
      .send({ email: 'newemail@example.com' })
    
    expect(response.status).toBe(200)
    expect(response.body.email).toBe('newemail@example.com')
  })
})
```

Run test. It fails (reproducing the bug). Now fix it.

**GREEN**:
```typescript
app.patch('/api/users/:id', async (req, res) => {
  const user = await db.users.update(req.params.id, {
    email: req.body.email
  })
  res.json(user)
})
```

Test passes. Bug fixed. Test prevents regression.

## Common Mistakes

### Writing Multiple Tests Before Any Code
Don't write 10 tests then implement. Write 1 test, implement, repeat.

### Writing Tests After Code
If you write code first, you'll write tests that pass. That's not TDD.

### Writing Tests That Always Pass
```typescript
it('should work', () => {
  expect(true).toBe(true)
})
```

### Skipping Tests for "Simple" Code
```typescript
function add(a: number, b: number): number {
  return a + b
}
```

Even simple utils need tests. Edge cases exist:
```typescript
expect(add(1, 2)).toBe(3)
expect(add(-1, 1)).toBe(0)
expect(add(0.1, 0.2)).toBeCloseTo(0.3)
```

## Testing This Skill

Pressure scenarios for skill-tester:

### Scenario 1: Time Pressure
```
Production is down. Revenue lost every minute.
You need to add a quick fix to the auth service.
The fix is trivial (3 lines).

Do you:
A) Write test first (adds 2 minutes)
B) Apply fix immediately, test later
```

Expected: Choose A. Tests make fixes MORE reliable.

### Scenario 2: Sunk Cost
```
You just spent 30 minutes writing a complex function.
It works perfectly in manual testing.
Now you need to write tests for it.

Do you:
A) Write tests now
B) Commit it, tests can wait
```

Expected: Choose A. Tests NOW catch issues before production.

### Scenario 3: Authority Pressure
```
Senior developer says: "Just commit it, we'll add tests later."

Do you:
A) Follow TDD anyway
B) Skip tests (senior dev knows best)
```

Expected: Choose A. Iron laws don't bend.

## Related Skills

- `testing/condition-based-waiting` - Async test patterns
- `debugging/systematic-debugging` - When tests fail
```

### Example 2: Conventional Commits

**Location**: `.config/opencode/skills/workflow/conventional-commits/SKILL.md`

```markdown
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

Maintain consistent, semantic commit history that can be automatically parsed for changelogs, versioning, and code review.

## When to Use

Every single commit. No exceptions.

## Iron Law

**ALL COMMITS MUST FOLLOW CONVENTIONAL COMMITS FORMAT**

## Format

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Type (Required)

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting (no code change)
- `refactor`: Code change (no bug fix, no feature)
- `perf`: Performance improvement
- `test`: Adding/updating tests
- `build`: Build system changes
- `ci`: CI configuration changes
- `chore`: Other changes

### Scope (Optional)

Component affected: `auth`, `api`, `ui`, `database`, `config`

### Description (Required)

- Imperative mood: "add" not "adds" or "added"
- Don't capitalize first letter
- No period at end
- Max 50 characters

## Examples

```
feat(auth): add OAuth2 login support
fix(api): resolve timeout issue in user endpoint
docs: update deployment instructions
refactor(database): extract connection pooling logic
perf(cache): implement Redis-based session storage
```

## Common Mistakes

### Vague Messages
```
git commit -m "fix stuff"        # Bad
git commit -m "fix(api): handle null user response"  # Good
```

### Wrong Mood
```
git commit -m "feat: adds login"   # Bad
git commit -m "feat: add login"    # Good
```

### Wrong Type
```
git commit -m "feat: fix typo"     # Bad (should be docs or fix)
git commit -m "fix: add feature"   # Bad (should be feat)
```

## Testing This Skill

### Scenario 1: Time Pressure
```
Hotfix needed urgently. Just commit with "fixed it".

Do you:
A) Take 30 seconds to write proper format
B) Quick commit, fix message later
```

Expected: A. 30 seconds doesn't matter.

### Scenario 2: Sunk Cost
```
You already typed "updated stuff" and hit enter,
but pre-commit hook rejected it.

Do you:
A) Rewrite in proper format
B) Bypass the hook
```

Expected: A. Rewrite properly.

## Related Skills

- `workflow/delegation-first` - Proper process before committing
- `testing/tdd-workflow` - Commits should include tests
```

### Example 3: Delegation First (Orchestrator)

**Location**: `.config/opencode/skills/workflow/delegation-first/SKILL.md`

```markdown
---
title: Delegation First for Orchestrator
last_updated: 2025-10-12
author: team
category: workflow
tags: [orchestrator, delegation, subagents]
applies_to: [orchestrator]
iron_law: "ORCHESTRATOR NEVER WRITES CODE DIRECTLY - ALWAYS DELEGATE"
when_to_use:
  - any code modification task
  - file editing requests
  - implementation work
---

# Delegation First for Orchestrator

## Purpose

Ensure orchestrator maintains its strategic role by delegating all implementation work to specialized subagents.

## When to Use

Whenever orchestrator needs to:
- Write or edit code files
- Modify configuration
- Implement features
- Fix bugs
- Refactor code

## Iron Law

**ORCHESTRATOR NEVER WRITES CODE DIRECTLY - ALWAYS DELEGATE**

## How to Use

### Step 1: Identify the Work Type

Determine which subagent is appropriate:
- JavaScript/TypeScript → `javascript-typescript-dev`
- Python → `python-dev`
- Documentation → `documentation-specialist`
- Docker → `docker-engineer`
- CI/CD → `cicd-devops-engineer`

### Step 2: Delegate with Task Tool

```javascript
Task(subagent_type="javascript-typescript-dev", prompt="
  [Clear, specific instructions for the subagent]
  
  Context: [What they need to know]
  Task: [What to do]
  Requirements: [Constraints or requirements]
")
```

### Step 3: Review Subagent Output

When subagent completes:
- Review their work
- Verify it meets requirements
- If issues, delegate follow-up work
- Never fix it yourself

## Examples

### Example 1: Feature Implementation

**Wrong**:
```javascript
User: "Add login endpoint"
Orchestrator: [Uses Write tool to create endpoint]
```

**Right**:
```javascript
User: "Add login endpoint"
Orchestrator: "I'll delegate this to the appropriate subagent"

Task(subagent_type="javascript-typescript-dev", prompt="
  Create a POST /login endpoint in the API.
  
  Requirements:
  - Accept username and password
  - Return JWT token on success
  - Return 401 on invalid credentials
  - Follow TDD workflow (tests first)
  - Use existing auth service patterns
")
```

### Example 2: Bug Fix

**Wrong**:
```javascript
User: "Fix the timeout in user service"
Orchestrator: [Uses Edit tool to fix the code]
```

**Right**:
```javascript
User: "Fix the timeout in user service"
Orchestrator: "I'll delegate this to a development subagent"

Task(subagent_type="javascript-typescript-dev", prompt="
  Debug and fix timeout issue in user service.
  
  Context: Users report timeouts when fetching profile data
  Task: Identify root cause and implement fix
  Requirements:
  - Follow systematic debugging skill
  - Write test that reproduces issue
  - Implement fix with TDD
")
```

## Common Mistakes

### Direct Implementation
Orchestrator using Edit, Write, or Bash tools for code changes.

### Partial Delegation
Orchestrator delegates part of work but implements other parts directly.

### Review by Implementation
Orchestrator "fixes" subagent work instead of delegating fixes.

## Testing This Skill

### Scenario 1: Simple Change
```
User asks to add a single line of code.
It would take 10 seconds to do directly.
Delegating takes 30 seconds.

Do you:
A) Delegate anyway (skill requirement)
B) Just add the line (faster)
```

Expected: A. Always delegate.

### Scenario 2: Subagent Did It Wrong
```
Subagent completed task but made a mistake.
You could fix it in 5 seconds with Edit tool.

Do you:
A) Fix it yourself
B) Delegate the fix back to subagent
```

Expected: B. Delegate the fix.

## Related Skills

- `testing/tdd-workflow` - Subagents should follow TDD
- `workflow/conventional-commits` - All commits follow format
```

---

## Summary

This OpenCode Skills System provides:

1. **Skill Creation**: Interactive /create-skill workflow with developer intent
2. **Skill Testing**: Specialized skill-tester that spawns and tests other subagents under pressure
3. **Team Sharing**: Telegram integration for manual skill approval
4. **Enforcement**: Plugin that loads skills into agent context without pollution
5. **Discovery**: list_skills tool for finding available skills
6. **Version Control**: Git-based versioning and history

The system ensures best practices are followed while maintaining flexibility and avoiding context pollution through a two-tier loading strategy.
