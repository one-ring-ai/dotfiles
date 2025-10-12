# Testing OpenCode Plugins

## How to Verify Plugins Are Loading

### 1. Enable Debug Logging

Start OpenCode with logging enabled:

```bash
opencode --print-logs --log-level DEBUG
```

Or just:

```bash
opencode --print-logs
```

### 2. Check Plugin Loading Messages

When OpenCode starts, you should see messages like:

```
INFO  service=plugin path=file:///home/coder/.config/opencode/plugin/skills-enforcement.js loading plugin
[Skills Plugin] Loading skills enforcement plugin...
[Skills Plugin] Session started, initializing skills...
[Skills Plugin] Found 3 skills
[Skills Plugin] Skills initialized
```

### 3. Test Plugin Tools

#### Test list_skills Tool

In an OpenCode session, the AI can use the `list_skills` tool. You should see:

```
[Skills Plugin] list_skills tool called
```

#### Test share_skill Tool

When a skill is shared, you should see:

```
[Skills Plugin] share_skill tool called with: testing/tdd-workflow
```

### 4. Check Plugin Files

Verify plugins are present:

```bash
ls -la ~/.config/opencode/plugin/
```

Expected output:

```
-rw-r--r-- 1 coder coder  266 Oct 12 13:29 env-protection.js
-rw-r--r-- 1 coder coder 1431 Oct 12 13:29 orchestrator-guard.js
-rw-r--r-- 1 coder coder 9500 Oct 12 13:35 skills-enforcement.js
```

### 5. Verify Skills Directory

Check that skills are present:

```bash
find ~/.config/opencode/skills -name "SKILL.md"
```

Expected output:

```
/home/coder/.config/opencode/skills/testing/tdd-workflow/SKILL.md
/home/coder/.config/opencode/skills/workflow/conventional-commits/SKILL.md
/home/coder/.config/opencode/skills/workflow/delegation-first/SKILL.md
```

### 6. Check Skills Index

The plugin creates an index file:

```bash
cat ~/.config/opencode/skills/.index.json | jq '.skills[] | {id, title}'
```

## Common Issues

### Plugin Not Loading

**ERROR**: `fn2 is not a function`

**Solution**: Plugin export structure is wrong. Must export async function returning hooks.

### Skills Not Found

**Symptom**: `[Skills Plugin] Found 0 skills`

**Check**:
1. Skills directory exists: `ls ~/.config/opencode/skills`
2. Skills are symlinked from dotfiles
3. SKILL.md files have proper frontmatter

### Tool Not Available

**Symptom**: AI says "I don't have a list_skills tool"

**Check**:
1. Plugin loaded successfully (check logs)
2. Tool export structure is correct
3. Restart OpenCode session

## Plugin Hooks in Action

### orchestrator-guard.js

This plugin prevents the orchestrator from editing files directly.

**Test**: Try to use Write/Edit tool as orchestrator → Should get error message

**Log**: No logs (silently throws error before tool execution)

### skills-enforcement.js

This plugin loads skills and provides tools.

**Test**: Skills should be in system prompt, tools available

**Log**: Multiple log messages showing initialization and tool usage

### env-protection.js

This plugin prevents reading .env files.

**Test**: Try to read a .env file → Should get error

**Log**: No logs (silently throws error before tool execution)

## Debugging Tips

1. **Add console.log** to your plugin
2. **Use --print-logs** when starting OpenCode
3. **Check ~/.config/opencode/opencode.jsonc** for plugin configuration
4. **Verify plugin syntax**: `node --check ~/.config/opencode/plugin/your-plugin.js`
5. **Test plugin isolation**: Temporarily rename other plugins to .js.disabled

## Quick Test Script

```bash
#!/bin/bash
echo "=== Plugin Files ==="
ls -la ~/.config/opencode/plugin/

echo -e "\n=== Skills Files ==="
find ~/.config/opencode/skills -name "SKILL.md"

echo -e "\n=== Skills Index ==="
cat ~/.config/opencode/skills/.index.json 2>/dev/null | jq -r '.skills[] | "- \(.id): \(.title)"' || echo "No index found"

echo -e "\n=== Test OpenCode Start ==="
echo "Starting OpenCode with logging... (will timeout in 5s)"
timeout 5 opencode --print-logs 2>&1 | grep -E "(plugin|Skills)" || echo "No plugin logs captured"
```

Save as `test-plugins.sh` and run with `bash test-plugins.sh`
```