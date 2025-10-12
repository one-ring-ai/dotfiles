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
  return 'You are the orchestrator agent. Please delegate this operation to a specialized subagent using the Task tool instead of performing direct actions.\n\nThis ensures proper separation of concerns and better code quality.';
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