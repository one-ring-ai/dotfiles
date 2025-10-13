const READ_ONLY_COMMANDS = [
  'git status',
  'git diff',
  'git log',
  'cat',
  'ls',
  'pwd',
  'grep',
  'find',
  'rg',
  'head',
  'tail',
  'which',
  'whereis',
  'type',
  'echo',
  'date',
  'whoami'
];

function isReadOnlyCommand(command) {
  const trimmed = command.trim();
  return READ_ONLY_COMMANDS.some(readonly => trimmed.startsWith(readonly));
}

function isOrchestratorOrBuildAgent(input) {
  const agentName = input?.agent?.name || input?.agent_type || '';
  return agentName === 'orchestrator' || agentName === 'build';
}

function createDelegationMessage() {
  return `You are the orchestrator agent. Delegate operations to specialized subagents using the Task tool.

Key principles:
1. **Delegate, don't execute**: Never perform direct actions yourself
2. **One task per subagent session**: Each subagent session should handle a SINGLE, focused task to optimize context and concentration
3. **Parallelize through multiple sessions**: Create multiple parallel subagent sessions for different tasks, but each session works on only one implementation
4. **Coordinate and verify**: Monitor all sessions and verify that everything is executed correctly

This approach optimizes subagent focus while maximizing execution speed through parallelization.`;
}

export const OrchestratorGuard = async ({ project, client, $, directory, worktree }) => {
  return {
    "tool.execute.before": async (input, output) => {
      if (!isOrchestratorOrBuildAgent(input)) {
        return;
      }
      
      const toolName = input.tool;
      
      if (toolName === 'edit' || toolName === 'write') {
        throw new Error(createDelegationMessage());
      }
      
      if (toolName === 'bash') {
        const command = output.args?.command;
        if (command && !isReadOnlyCommand(command)) {
          throw new Error(createDelegationMessage());
        }
      }
    }
  }
}