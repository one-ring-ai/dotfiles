# OpenCode Plugin System

## Overview

OpenCode plugins are **JavaScript/TypeScript modules** that extend the platform's functionality by intercepting events and customizing behaviors. The system is lightweight, flexible, and integrated with OpenCode's client-server architecture.

## Architecture

### Base Structure

A plugin is an async function that receives a **context object** and returns a **hooks object**:

```javascript
export const MyPlugin = async ({ project, client, $, directory, worktree }) => {
  console.log("Plugin initialized!")
  return {
    // Hook implementations go here
  }
}
```

### Context Object

You receive access to:
- **`project`**: Current project information
- **`directory`**: Current working directory
- **`worktree`**: Git worktree path
- **`client`**: Client SDK to interact with the AI
- **`$`**: Bun shell API to execute commands

### Loading

Plugins are loaded from two locations with precedence:
1. **Project**: `.opencode/plugin/` in the project directory
2. **Global**: `~/.config/opencode/plugin/` in the home directory

## Available Trigger Types

### 1. Tool Execution Hooks

Intercept tool execution:

```javascript
"tool.execute.before": async (input, output) => {
  // Executed BEFORE tool execution
  if (input.tool === "read" && output.args.filePath.includes(".env")) {
    throw new Error("Do not read .env files!")
  }
}

"tool.execute.after": async (input, output, result) => {
  // Executed AFTER tool execution
  if (input.tool === "write") {
    await $`npx eslint ${output.args.filePath} --fix`
  }
  return result
}
```

### 2. Event Hooks

Respond to system events:

```javascript
event: async ({ event }) => {
  if (event.type === "session.idle") {
    // Session became idle
  }
  if (event.type === "session.start") {
    // Session started
  }
  if (event.type === "session.end") {
    // Session ended
  }
}
```

### 3. Custom Tools

Register new tools that the AI can use:

```typescript
import { tool } from "@opencode-ai/plugin"

tool: {
  mytool: tool({
    description: "This is a custom tool",
    args: {
      foo: tool.schema.string(),
      bar: tool.schema.number().optional(),
    },
    async execute(args, ctx) {
      return `Result: ${args.foo}`
    },
  }),
}
```

## What You Can Do with Plugins

### 1. Protection and Security

```javascript
export const EnvProtection = async ({ project, client, $, directory, worktree }) => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool === "read" && output.args.filePath.includes(".env")) {
        throw new Error("Access to .env files blocked")
      }
    },
  }
}
```

### 2. Notifications

```javascript
export const NotificationPlugin = async ({ project, client, $, directory, worktree }) => {
  return {
    event: async ({ event }) => {
      if (event.type === "session.idle") {
        await $`osascript -e 'display notification "Session completed!" with title "opencode"'`
      }
    },
  }
}
```

### 3. Automatic Quality Assurance

```javascript
export const CodeQualityPlugin = async ({ project, client, $, directory, worktree }) => {
  return {
    "tool.execute.after": async (input, output, result) => {
      if (input.tool === "write" || input.tool === "edit") {
        const filePath = output.args.filePath
        if (filePath.endsWith('.js') || filePath.endsWith('.ts')) {
          await $`npx eslint ${filePath} --fix`
        }
      }
      return result
    },
  }
}
```

### 4. External Integrations

```javascript
export const SlackPlugin = async ({ project, client, $, directory, worktree }) => {
  const SLACK_WEBHOOK = process.env.SLACK_WEBHOOK_URL
  
  return {
    event: async ({ event }) => {
      if (event.type === "session.end") {
        await fetch(SLACK_WEBHOOK, {
          method: 'POST',
          body: JSON.stringify({
            text: `OpenCode session completed!`
          })
        })
      }
    },
  }
}
```

### 5. Custom Tools for AI

```typescript
export const DatabasePlugin = async (ctx) => {
  return {
    tool: {
      query_db: tool({
        description: "Execute SQL queries on the project database",
        args: {
          query: tool.schema.string(),
          limit: tool.schema.number().optional()
        },
        async execute(args, context) {
          const result = await executeQuery(args.query, args.limit)
          return JSON.stringify(result, null, 2)
        },
      }),
    },
  }
}
```

## How to Create a Plugin

### File Structure

```
.opencode/plugin/
├── security.js         # Security plugin
├── notifications.js    # Notifications
└── custom-tools.ts     # Custom TypeScript tools
```

### Basic JavaScript Template

```javascript
// .opencode/plugin/my-plugin.js
export const MyPlugin = async ({ project, client, $, directory, worktree }) => {
  // Initialization (executed once)
  console.log("Plugin loaded!")
  
  return {
    event: async ({ event }) => {
      // Event handling
    },
    
    "tool.execute.before": async (input, output) => {
      // Intercept before execution
    },
    
    "tool.execute.after": async (input, output, result) => {
      // Intercept after execution
      return result
    },
  }
}
```

### TypeScript Template (with Type Safety)

```typescript
// .opencode/plugin/my-plugin.ts
import type { Plugin } from "@opencode-ai/plugin"
import { tool } from "@opencode-ai/plugin"

export const MyPlugin: Plugin = async ({ project, client, $, directory, worktree }) => {
  return {
    tool: {
      mytool: tool({
        description: "Type-safe tool",
        args: {
          param: tool.schema.string()
        },
        async execute(args, ctx) {
          return `Result: ${args.param}`
        },
      }),
    },
  }
}
```

## Available APIs and SDK

### OpenCode SDK Client

The `client` parameter provides full access to the SDK:

```javascript
// Session management
const sessions = await client.session.list()
const current = await client.session.current()

// File operations
const files = await client.find.files({ query: "*.ts" })
const content = await client.file.read({ query: { path: "src/index.ts" } })

// TUI control
await client.tui.showToast({ 
  body: { message: "Task completed", variant: "success" } 
})

// Configuration
const config = await client.config.get()
```

### Shell Integration (Bun $)

```javascript
// Execute shell commands
const status = await $`git status`
const output = await $`npm run build`

// Cross-platform
if (process.platform === 'darwin') {
  await $`osascript -e 'display notification "Message"'`
}
```

## Best Practices

### 1. Error Handling

```javascript
export const SafePlugin = async (ctx) => {
  return {
    event: async ({ event }) => {
      try {
        // Plugin logic
      } catch (error) {
        console.error("Plugin error:", error)
        // Graceful degradation
      }
    }
  }
}
```

### 2. Performance

```javascript
// Cache expensive operations
export const EfficientPlugin = async ({ client }) => {
  const config = await client.config.get() // Load once
  
  return {
    event: async ({ event }) => {
      // Use cached config
    }
  }
}
```

### 3. Modularity

```javascript
// Separate responsibilities
export const SecurityPlugin = async (ctx) => {
  return { "tool.execute.before": securityChecks }
}

export const NotificationPlugin = async (ctx) => {
  return { event: handleNotifications }
}
```

## Limitations

### Current
- Limited documentation on all available hook types
- Incomplete event list
- No documented sandboxing for plugins
- Full filesystem access (security consideration)

### Technical
- Node.js/Bun runtime required
- Some operations may block the main thread
- No restrictions on network calls

## Advanced Patterns

### Stateful Plugin

```javascript
export const StatefulPlugin = async (ctx) => {
  const state = {
    sessionStart: null,
    operations: []
  }
  
  return {
    event: async ({ event }) => {
      if (event.type === "session.start") {
        state.sessionStart = new Date()
      }
    },
    
    "tool.execute.before": async (input, output) => {
      state.operations.push({
        tool: input.tool,
        timestamp: new Date()
      })
    }
  }
}
```

### Plugin Composition

```javascript
export const ComprehensivePlugin = async (ctx) => {
  const security = await createSecurityPlugin(ctx)
  const notifications = await createNotificationPlugin(ctx)
  
  return { ...security, ...notifications }
}
```

## Conclusion

The OpenCode plugin system is **powerful and flexible**. You can:
- Intercept operations before/after execution
- Respond to system events
- Create custom tools for the AI
- Integrate external services
- Automate quality checks
- Implement custom security

## Community Plugin Examples

> **Important Note**: These are community examples and we have no guarantee they are 100% functional. They may need updates to work with current OpenCode versions. Use them as inspiration and reference, not production-ready code. Always test plugins in a safe environment first.

### 1. Context Analysis Plugin

**Plugin**: Opencode-Context-Analysis-Plugin  
**Author**: IgorWarzocha  
**Repository**: https://github.com/IgorWarzocha/Opencode-Context-Analysis-Plugin  
**Stars**: 5

**Purpose**: Provides detailed token usage analysis for AI sessions, tracking how tokens are distributed across system prompts, user messages, assistant responses, tool outputs, and reasoning traces.

**Hooks Used**: `tool.register` (custom tool registration)

**Code Snippet**:
```typescript
export const ContextUsagePlugin: Plugin = async ({ Tool, z, client }) => {
  const ContextUsage = Tool.define("context_usage", {
    description: "Summarize token usage for the current session",
    parameters: z.object({
      sessionID: z.string().optional(),
      limitMessages: z.number().int().min(1).max(10).optional(),
    }),
    async execute(args, ctx) {
      const sessionID = args.sessionID ?? ctx.sessionID
      const response = await client.session.messages({ path: { id: sessionID } })
      const messages: SessionMessage[] = response.data ?? []
      
      const tokenModel = resolveTokenModel(messages)
      const summary = await buildContextSummary({
        sessionID,
        messages,
        tokenModel,
        entryLimit: args.limitMessages ?? 3,
      })

      return {
        title: `Context usage for ${sessionID}`,
        output: formatSummary(summary),
      }
    },
  })

  return {
    async "tool.register"(_input, { register }) {
      register(ContextUsage)
    },
  }
}
```

**Use Case**: Helps developers understand token consumption patterns, optimize prompts, and manage API costs effectively.

---

### 2. Google AI Search Plugin

**Plugin**: Opencode-Google-AI-Search-Plugin  
**Author**: IgorWarzocha  
**Repository**: https://github.com/IgorWarzocha/Opencode-Google-AI-Search-Plugin  
**Stars**: 5

**Purpose**: Exposes a native tool for querying Google AI Mode (SGE) with Playwright automation, converting responses to markdown format.

**Hooks Used**: `tool.register` (custom tool registration)

**Code Snippet**:
```typescript
export const GoogleAISearchPlugin: Plugin = async ({ Tool, z }) => {
  const GoogleAITool = Tool.define("google_ai_search_plus", {
    description: "Search the web using Google's AI-powered search mode",
    parameters: z.object({
      query: z.string().describe("Question or topic to submit to Google AI Mode"),
      timeout: z.number().min(5).max(120).optional(),
      followUp: z.boolean().optional(),
    }),
    async execute(params: any, ctx: any) {
      const playwright = await loadPlaywright()
      const manager = new GoogleAIModeManager(playwright)
      const timeoutMs = Math.min((params.timeout ?? 30) * 1000, 120000)

      const result = await manager.query(params.query, params.followUp ?? false, timeoutMs, ctx.abort)

      return {
        title: `Google AI Mode: ${params.query}`,
        output: formatAIResponse(result),
        metadata: {
          query: result.query,
          responseTime: result.metadata.responseTime,
          sources: result.sources,
          hasTable: result.tableData.length > 0,
        },
      }
    },
  })

  return {
    async ["tool.register"](_input, { register }) {
      register(GoogleAITool)
    },
  }
}
```

**Use Case**: Enables AI agents to perform real-time web searches with Google's AI-powered search capabilities, providing up-to-date information beyond the training data cutoff.

---

### 3. Command Blocker Plugin

**Plugin**: opencode-plugin-command-blocker  
**Author**: knoopx  
**Repository**: https://github.com/knoopx/opencode-plugin-command-blocker  
**Stars**: 3

**Purpose**: Enforces best practices by blocking potentially harmful commands and file edits, promoting reproducible builds and security.

**Hooks Used**: `tool.execute.before`

**Code Snippet**:
```typescript
export const CommandBlocker: Plugin = async ({ app, client, $ }) => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool === "edit" || input.tool === "write") {
        const filePath = output.args.filePath || output.args.file_path
        checkReadOnlyFileEdit(filePath)
      }

      if (input.tool === "read") {
        const filePath = output.args.filePath || output.args.file_path
        checkSecretFileRead(filePath)
      }

      if (input.tool === "bash") {
        const command = output.args.command
        checkPythonNodeCommand(command)
        checkGitCommand(command)
        checkNixCommand(command)
        checkSecretFileAccessCommand(command)
      }
    },
  }
}
```

**Use Case**: Prevents accidental execution of dangerous commands, protects sensitive files, and enforces development best practices across teams.

---

### 4. Terminal Bell Plugin

**Plugin**: Terminal Bell (Gist)  
**Author**: ahosker (based on CarlosGtrz)  
**Repository**: https://gist.github.com/ahosker/267f375a65378bcb9a867fd9a195db1e  
**Stars**: N/A (Gist)

**Purpose**: Rings the terminal bell when a session goes idle, providing audio notification of task completion.

**Hooks Used**: `event`

**Code Snippet**:
```typescript
export const TerminalBell: Plugin = async ({ project, client, $, directory, worktree }) => {
  return {
    event: async ({ event }) => {
      if (event.type === "session.idle") {
        console.log("Session went idle")
        await Bun.write(Bun.stdout, "\x07")
      }
    }
  }
}
```

**Use Case**: Provides audio feedback when long-running AI tasks complete, allowing developers to work on other tasks while waiting.

---

### 5. Environment Protection Plugin

**Plugin**: Environment Protection (Gist)  
**Author**: ahosker (based on lkhari, dkarter)  
**Repository**: https://gist.github.com/ahosker/267f375a65378bcb9a867fd9a195db1e  
**Stars**: N/A (Gist)

**Purpose**: Blocks access to `.env` files and other sensitive configuration files to prevent accidental exposure of secrets.

**Hooks Used**: `tool.execute.before`

**Code Snippet**:
```typescript
export const EnvProtection = async ({ client, $ }) => {
  return {
    tool: {
      execute: {
        before: async (input, output) => {
          if (input.tool === "read" && output.args.filePath.includes(".env")) {
            throw new Error("Do not read .env files");
          }
        },
      },
    },
  };
};
```

**Use Case**: Prevents AI agents from accidentally accessing or exposing sensitive environment variables and API keys.

---

### 6. OpenAI ChatGPT OAuth Plugin

**Plugin**: opencode-openai-codex-auth  
**Author**: numman-ali  
**Repository**: https://github.com/numman-ali/opencode-openai-codex-auth  
**Stars**: 142

**Purpose**: Enables OpenCode to use OpenAI's Codex backend via ChatGPT Plus/Pro OAuth authentication, allowing use of ChatGPT subscription instead of API credits.

**Hooks Used**: Custom provider implementation (fetch override)

**Code Snippet**:
```typescript
export const OpenAICodexAuthPlugin: Plugin = async ({ Tool, z }) => {
  // Complex OAuth flow and request transformation
  // 7-step fetch flow with token management, URL rewriting, 
  // request transformation, headers, execution, logging, and response handling
  
  return {
    fetch: async (input) => {
      // Transform requests to use ChatGPT OAuth backend
      const transformedRequest = await transformRequest(input)
      const response = await fetchWithAuth(transformedRequest)
      return transformResponse(response)
    }
  }
}
```

**Use Case**: Allows users with ChatGPT Plus/Pro subscriptions to use OpenCode without purchasing separate API credits, leveraging their existing subscription.

---

### 7. Plugin Composition Utilities

**Plugin**: opencode-plugins (monorepo)  
**Author**: ericc-ch  
**Repository**: https://github.com/ericc-ch/opencode-plugins  
**Stars**: 10

**Purpose**: Provides composable utilities for plugin composition, debugging, and notifications.

**Components**:
- **opencode-plugin-compose**: Compose multiple plugins into one
- **opencode-plugin-inspector**: Real-time web interface for debugging
- **opencode-plugin-notification**: Desktop notifications

**Code Snippet**:
```typescript
import { compose } from "opencode-plugin-compose"
import { inspector } from "opencode-plugin-inspector"
import { notification } from "opencode-plugin-notification"

const composedPlugin = compose([
  inspector({ port: 6969 }),
  notification({
    idleTime: 60000,
    notificationCommand: ["notify-send", "--app-name", "opencode"]
  })
])
```

**Use Case**: Provides developer tools for building, debugging, and managing complex plugin ecosystems.

---

### 8. Neovim Integration Plugin

**Plugin**: opencode.nvim  
**Author**: NickvanDyke  
**Repository**: https://github.com/NickvanDyke/opencode.nvim  
**Stars**: 718

**Purpose**: Integrates OpenCode AI assistant with Neovim for editor-aware research, reviews, and requests.

**Hooks Used**: Custom tool registration and session management

**Use Case**: Enables developers to use OpenCode directly within their Neovim editor, providing seamless AI assistance during coding sessions.

---

## Plugin Categories and Patterns

### Security & Protection
- **Command Blocker**: Prevents dangerous commands
- **Environment Protection**: Blocks access to sensitive files
- **Secret File Protection**: Comprehensive secret file blocking

### Monitoring & Analytics
- **Context Analysis**: Token usage tracking
- **Inspector**: Real-time debugging interface
- **Session Monitoring**: Activity tracking

### User Experience
- **Terminal Bell**: Audio notifications
- **Desktop Notifications**: System notifications
- **Neovim Integration**: Editor integration

### External Integrations
- **Google AI Search**: Web search capabilities
- **OpenAI OAuth**: Alternative authentication
- **Slack Notifications**: Team integration

### Developer Tools
- **Plugin Composition**: Utility for combining plugins
- **Debugging Tools**: Development and debugging aids

## Installation Patterns

### Direct File Installation
```bash
# Copy plugin files to project
cp -r plugin-repo/.opencode /path/to/project/
```

### NPM Package Installation
```json
{
  "plugin": [
    "opencode-openai-codex-auth",
    "opencode-plugin-compose"
  ]
}
```

### Local Development
```json
{
  "plugin": [
    "file:///absolute/path/to/plugin"
  ]
}
```

## Resources

- [Official OpenCode Plugins Documentation](https://opencode.ai/docs/plugins/)
- [Awesome OpenCode](https://github.com/awesome-opencode/awesome-opencode) - Curated list of plugins and resources
- Example plugins in this project: `.config/opencode/plugin/`
- [OpenCode Plugin SDK](https://github.com/sst/opencode-sdk-js) - Official TypeScript SDK