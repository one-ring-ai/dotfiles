import type { Plugin } from "@opencode-ai/plugin";
import { tool } from "@opencode-ai/plugin";
import * as fs from "fs";
import * as path from "path";

export const ThoughtsTools: Plugin = async (ctx) => {
  return {
    tool: {
      thoughts_write: tool({
        description: "Write a new markdown document to the thoughts directory",
        schema: {
          type: "object",
          properties: {
            docType: { type: "string", enum: ["research", "plans", "tickets", "handoffs", "implementations"] },
            title: { type: "string" },
            topic: { type: "string" },
            content: { type: "string" },
            ticket: { type: "string" },
            slug: { type: "string" },
            tags: { type: "array", items: { type: "string" } },
            author: { type: "string" },
            metadata: { type: "object" },
            overwrite: { type: "boolean" }
          },
          required: ["docType", "content"]
        },
        async execute(args, ctx) {
          try {
            const root = path.resolve(ctx.directory, "thoughts");
            const subdir = path.join(root, "shared", args.docType);
            
            const today = new Date().toISOString().slice(0, 10);
            const now = new Date().toISOString();
            
            let filename = today;
            if (args.ticket) {
              const ticketNormalized = args.ticket.replace(/_/g, "-");
              filename += `-${ticketNormalized}`;
            }
            
            let slug = args.slug;
            if (!slug) {
              const titleOrTopic = args.title || args.topic || "untitled";
              slug = toKebab(titleOrTopic);
            } else {
              slug = toKebab(slug);
            }
            
            filename += `-${slug}.md`;
            
            const fullPath = path.join(subdir, filename);
            
            if (fs.existsSync(fullPath) && !args.overwrite) {
              return { ok: false, error: `File already exists: ${path.relative(ctx.directory, fullPath)}` };
            }
            
            ensureDir(subdir);
            
            const frontmatter: Record<string, any> = {
              type: args.docType,
              date: now,
              last_updated: today,
              status: "draft",
              ...args.metadata
            };
            
            if (args.title) frontmatter.title = args.title;
            if (args.topic) frontmatter.topic = args.topic;
            if (args.ticket) frontmatter.ticket = args.ticket;
            if (args.tags) frontmatter.tags = args.tags;
            if (args.author) frontmatter.author = args.author;
            
            const frontmatterYaml = serializeFrontmatter(frontmatter);
            const fileContent = `${frontmatterYaml}\n\n${args.content}\n`;
            
            fs.writeFileSync(fullPath, fileContent, "utf8");
            
            return { ok: true, path: path.relative(ctx.directory, fullPath) };
          } catch (error) {
            return { ok: false, error: error instanceof Error ? error.message : String(error) };
          }
        }
      }),
      
      thoughts_update: tool({
        description: "Update an existing markdown document in the thoughts directory",
        schema: {
          type: "object",
          properties: {
            path: { type: "string" },
            frontmatter: { type: "object" },
            sectionTitle: { type: "string" },
            sectionContent: { type: "string" },
            mode: { type: "string", enum: ["replace", "upsert"] },
            author: { type: "string" }
          },
          required: ["path"]
        },
        async execute(args, ctx) {
          try {
            const root = path.resolve(ctx.directory, "thoughts");
            const targetPath = args.path.startsWith("thoughts/") 
              ? args.path.slice(8) 
              : args.path;
            const fullPath = safeJoinUnderRoot(root, targetPath);
            
            if (!fullPath || !fs.existsSync(fullPath)) {
              return { ok: false, error: `File not found: ${args.path}` };
            }
            
            const content = fs.readFileSync(fullPath, "utf8");
            const { frontmatter: existingFrontmatter, body } = parseFrontmatter(content);
            
            const updatedFrontmatter = { ...existingFrontmatter };
            if (args.frontmatter) {
              Object.assign(updatedFrontmatter, args.frontmatter);
            }
            
            const today = new Date().toISOString().slice(0, 10);
            updatedFrontmatter.last_updated = today;
            if (args.author) {
              updatedFrontmatter.last_updated_by = args.author;
            }
            
            let newBody = body;
            
            if (args.sectionTitle) {
              const mode = args.mode || "upsert";
              const headingRegex = /^(#{1,6})\s+(.+)$/gm;
              const headings: Array<{ level: number; title: string; start: number; end?: number }> = [];
              let match;
              
              while ((match = headingRegex.exec(body)) !== null) {
                headings.push({
                  level: match[1].length,
                  title: match[2].trim(),
                  start: match.index
                });
              }
              
              for (let i = 0; i < headings.length; i++) {
                headings[i].end = i < headings.length - 1 ? headings[i + 1].start : body.length;
              }
              
              const targetHeading = headings.find(h => h.title === args.sectionTitle);
              
              if (targetHeading && mode === "replace") {
                const beforeSection = body.substring(0, targetHeading.start);
                const afterSection = body.substring(targetHeading.end || body.length);
                newBody = beforeSection + `#${"#".repeat(targetHeading.level - 1)} ${args.sectionTitle}\n\n${args.sectionContent}\n` + afterSection;
              } else if (!targetHeading && mode === "upsert") {
                newBody = body + (body.endsWith("\n") ? "" : "\n") + `## ${args.sectionTitle}\n\n${args.sectionContent}\n`;
              }
            }
            
            const updatedContent = `${serializeFrontmatter(updatedFrontmatter)}\n\n${newBody}`;
            fs.writeFileSync(fullPath, updatedContent, "utf8");
            
            return { ok: true, path: path.relative(ctx.directory, fullPath) };
          } catch (error) {
            return { ok: false, error: error instanceof Error ? error.message : String(error) };
          }
        }
      }),
      
      thoughts_append_followup: tool({
        description: "Append a follow-up section to a thoughts document",
        schema: {
          type: "object",
          properties: {
            path: { type: "string" },
            content: { type: "string" },
            author: { type: "string" }
          },
          required: ["path", "content"]
        },
        async execute(args, ctx) {
          try {
            const root = path.resolve(ctx.directory, "thoughts");
            const targetPath = args.path.startsWith("thoughts/") 
              ? args.path.slice(8) 
              : args.path;
            const fullPath = safeJoinUnderRoot(root, targetPath);
            
            if (!fullPath || !fs.existsSync(fullPath)) {
              return { ok: false, error: `File not found: ${args.path}` };
            }
            
            const content = fs.readFileSync(fullPath, "utf8");
            const { frontmatter, body } = parseFrontmatter(content);
            
            const today = new Date().toISOString().slice(0, 10);
            const now = new Date().toISOString();
            
            frontmatter.last_updated = today;
            if (args.author) {
              frontmatter.last_updated_by = args.author;
            }
            
            const followupSection = `\n## Follow-up ${now}\n\n${args.content}\n`;
            const newBody = body + (body.endsWith("\n") ? "" : "\n") + followupSection;
            
            const updatedContent = `${serializeFrontmatter(frontmatter)}\n\n${newBody}`;
            fs.writeFileSync(fullPath, updatedContent, "utf8");
            
            return { ok: true, path: path.relative(ctx.directory, fullPath) };
          } catch (error) {
            return { ok: false, error: error instanceof Error ? error.message : String(error) };
          }
        }
      }),
      
      thoughts_list: tool({
        description: "List documents in the thoughts directory",
        schema: {
          type: "object",
          properties: {
            docType: { type: "string", enum: ["research", "plans", "tickets", "handoffs", "implementations"] },
            glob: { type: "string" },
            limit: { type: "number" }
          }
        },
        async execute(args, ctx) {
          try {
            const root = path.resolve(ctx.directory, "thoughts");
            const searchPath = args.docType ? path.join(root, "shared", args.docType) : path.join(root, "shared");
            
            if (!fs.existsSync(searchPath)) {
              return { ok: true, list: [] };
            }
            
            const entries: any[] = [];
            const globPattern = args.glob || "*.md";
            
            const traverse = (dir: string, depth = 0) => {
              if (depth > 10) return;
              
              const items = fs.readdirSync(dir, { withFileTypes: true });
              
              for (const item of items) {
                const fullPath = path.join(dir, item.name);
                
                if (item.isDirectory()) {
                  traverse(fullPath, depth + 1);
                } else if (item.isFile() && item.name.endsWith(".md")) {
                  const stats = fs.statSync(fullPath);
                  const relativePath = path.relative(ctx.directory, fullPath);
                  const docType = path.relative(path.join(root, "shared"), path.dirname(fullPath)).split(path.sep)[0];
                  
                  entries.push({
                    path: relativePath,
                    mtimeMs: stats.mtimeMs,
                    size: stats.size,
                    docType: docType || undefined
                  });
                }
              }
            };
            
            traverse(searchPath);
            
            entries.sort((a, b) => b.mtimeMs - a.mtimeMs);
            
            if (args.limit && args.limit > 0) {
              entries.splice(args.limit);
            }
            
            return { ok: true, list: entries };
          } catch (error) {
            return { ok: false, error: error instanceof Error ? error.message : String(error) };
          }
        }
      })
    }
  };
};

function ensureDir(dir: string): void {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function toKebab(str: string): string {
  return str
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, "")
    .replace(/\s+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");
}

function safeJoinUnderRoot(root: string, targetPath: string): string | null {
  const resolved = path.resolve(root, targetPath);
  if (!resolved.startsWith(root)) {
    return null;
  }
  return resolved;
}

function parseFrontmatter(content: string): { frontmatter: Record<string, any>; body: string } {
  if (!content.startsWith("---")) {
    return { frontmatter: {}, body: content };
  }
  
  const endIndex = content.indexOf("---", 3);
  if (endIndex === -1) {
    return { frontmatter: {}, body: content };
  }
  
  const frontmatterText = content.substring(3, endIndex);
  const body = content.substring(endIndex + 3).replace(/^\n+/, "");
  
  const frontmatter: Record<string, any> = {};
  const lines = frontmatterText.split("\n");
  
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    
    const colonIndex = trimmed.indexOf(":");
    if (colonIndex === -1) continue;
    
    const key = trimmed.substring(0, colonIndex).trim();
    let value = trimmed.substring(colonIndex + 1).trim();
    
    if (value.startsWith("[") && value.endsWith("]")) {
      const arrayContent = value.slice(1, -1);
      const items = arrayContent.split(",").map(item => {
        const trimmed = item.trim();
        return trimmed.startsWith('"') && trimmed.endsWith('"') ? trimmed.slice(1, -1) : trimmed;
      });
      frontmatter[key] = items;
    } else if (value === "true") {
      frontmatter[key] = true;
    } else if (value === "false") {
      frontmatter[key] = false;
    } else if (value.startsWith('"') && value.endsWith('"')) {
      frontmatter[key] = value.slice(1, -1);
    } else if (!isNaN(Number(value)) && value !== "") {
      frontmatter[key] = Number(value);
    } else {
      frontmatter[key] = value;
    }
  }
  
  return { frontmatter, body };
}

function serializeFrontmatter(frontmatter: Record<string, any>): string {
  const lines = ["---"];
  
  for (const [key, value] of Object.entries(frontmatter)) {
    if (value === null || value === undefined) continue;
    
    if (Array.isArray(value)) {
      const items = value.map(item => {
        const str = String(item);
        return str.includes(" ") || str.includes('"') ? `"${str.replace(/"/g, '\\"')}"` : str;
      });
      lines.push(`${key}: [${items.join(", ")}]`);
    } else if (typeof value === "boolean") {
      lines.push(`${key}: ${value}`);
    } else if (typeof value === "number") {
      lines.push(`${key}: ${value}`);
    } else {
      const str = String(value);
      if (str.includes("\n") || str.includes('"')) {
        lines.push(`${key}: "${str.replace(/"/g, '\\"').replace(/\n/g, '\\n')}"`);
      } else {
        lines.push(`${key}: ${str}`);
      }
    }
  }
  
  lines.push("---");
  return lines.join("\n");
}