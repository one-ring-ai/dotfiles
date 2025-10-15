export const GitCommitGuard = async ({ project, client, $, directory, worktree }) => {
  return {
    "tool.execute.before": async (input, output) => {
      const agentName = input?.agent?.name || input?.agent_type;
      if (agentName === 'orchestrator') return;
      
      if (input.tool === 'bash' && output.args?.command) {
        const command = output.args.command;
        if (/\bgit\s+add\b/.test(command) || /\bgit\s+commit\b/.test(command)) {
          throw new Error("Git operations are blocked. Do not run 'git add' or 'git commit'. Report the exact file changes you made and the Conventional Commit message you would use. The orchestrator will handle committing.");
        }
      }
    }
  }
}