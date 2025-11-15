# terminal quickstart guide

## table of contents

- [opencode](#opencode)
- [tmux](#tmux)
- [Additional Tools](#additional-tools)
- [Useful Commands](#useful-commands)
- [Next Steps](#next-steps)

## creator's note

this guide is meant to quickstart you with this setup and give you instruction on how to use tools like opencode.

i'm assuming you're using this in a new environment where you have your permanent storage placed under the path `/mnt/user/` and that your home folder is not persistent. if your hom folder *is* persistent, i advise you to fork this repository and adapt it to your needs.
    
## opencode

### before starting

*if you're having issues with the new TUI*, you can use `oc-rollback` to rvert to th last stable vrsion before the new TUI.

after, *you need to run* `copy-secrets` to copy your secret keys from `/mnt/user/.secrets` to `/home/coder/.config/opencode/.secrets`

now you can safely start opencode with the command `opencode` and below you can find a through review of our setup

### agents and subagents

we have 3 main agents:

**1-orchestrator** is the agent that you should use to do stuff or to implement plans (more on this later)

**2-planner** is the agent that you should run for creating plans and do research on your codebase 

**3-commit** is the only agent able to run git commands that are not read-only (still, i don't feel like it should run commands like git push or similar). it's meant to help you with the git cli and automate git commits

we have a lot of subagents, and you can guess each one task and proficiency by it's name and description. feel free to open a PR if you feel like the system prompt given to a particular subagent or agent could b improved.

### commands

commands are pre-made prompts useful for repeating tasks.
we have:
- `/commit` - this command call the agent *3-commit* and give the task to gather infos about your edits and do sensible commits based on your commit message history and rules defined by a contributing file 
- `/create_handoff` - you should use this one when you are in the middle of implementing somthing but you cannot end that task now. it will create a document telling what's being done and what's left (though we're not really using these anymore thanks to the new *operations* thoughts)
- `/implement_plan` - this is the third step of our tested spec driven development and must pair with the agent *1-orchestrator*. after the command has run, you should feed the orchestrator with a plan and the orchestrator will make sure to complete each step of that plan
- `/plan` - this is the second step of our tested spec driven development and must pair with the agent *2-planner*. you can use this with or without a research (in case you're starting fresh or are working on a simple task) and you should explain to the planner agent what end result you expect to obtain. you'll end with a plan explaining each step needed to reach your implementation goal. you should proceed with the *implement_plan* command
- `/research` - this is the first step of our tested spec driven development and must pair with the agent *2-planner*. you should use this when you're working on an existing codebase (it's pointless to run a research when starting fresh) and you should task the planner to research a sction of interest. you'll end with a research citing files, code lines, documentation and everything that an agent should know about that code implementation you asked for. next, you should proceed with the *plan* command
- `/resume_handoff` - this pairs with the *create_handoff* and should be used with the *1-orchestrator*. this just resume the handoff created and will try to complete each step left.
- `/review` - this should be used with the *2-planner* agent, and should be used just before using the *commit* command. it instruct the agent to look into contributing rules and make sure you're respecting them. it's just a check to make sure full adherence to rules before committing changes (i also advise you not to track reviews with git, they would just pollute your documentation. i may be move the review folder somewhere else in the future)

### plugin

we use only one plugin that stops agents to read files named `.env` for obvious reason

### main config file

this file defines models, custom models, mcp server and command we do not want ai to run. if you are in YOLO mood, you can change `"*": "ask"` into `"*": "allow"` to let ai run almost any command without asking for permissions (be careful with that)

some notes about models we use:
- our main model is **GPT 5 codex**, it's the one we use for the agents *1-orchestrator* and *2-planner*. we found that, beside being really slow at times, it's the best at following rules, has less verbosity than almost any other model and has great performance when planning and coordinating subagents
- our small model is a mixture of **grok code fast 1** and **glm 4.6**. we found that, while **glm 4.6** gave us better results overall, **grok code fast 1**, by being free and with limited loss of quality, it's overall the best small model to use atm
- we have some exceptions were we use **glm 4.6** or **GPT 5 codex** as the subagent model for reasons like proficency in specific coding languages and / or better rules adherence for specific languages or task 

## tmux

tmux is a terminal multiplexer for managing multiple sessions.

### Starting tmux

```bash
tmux          # Start new session
tmux attach   # Attach to existing session
tmux ls       # List sessions
```

### Key Shortcuts (Prefix: Ctrl-b)

- `c` - Create new window
- `n` - Next window
- `p` - Previous window
- `&` - Kill current window
- `%` - Split vertically
- `"` - Split horizontally
- `x` - Kill pane
- `d` - Detach session

### Navigation

- Switch windows: `Ctrl-b <number>`
- Switch panes: `Ctrl-b <arrow key>`
- Resize panes: `Ctrl-b :resize-pane -D 10` (etc.)

## Additional Tools

### zoxide (Smart Directory Navigation)

```bash
z <directory>    # Jump to directory
zi <keyword>     # Interactive selection
zoxide query     # List recent directories
```

### fzf (Fuzzy Finder)

- `Ctrl-r` - Search command history
- `Ctrl-t` - Fuzzy file finder
- `Alt-c` - Change directory

### fastfetch (System Information)

```bash
fastfetch        # Display system info
```

### Starship (Shell Prompt)

- Custom prompt with git status and more
- Configuration: `starship.toml`

## Useful Commands

### File Operations

```bash
lla                  # List all files with details
..                   # Go to previous directory
pwd                  # Print working directory
find . -name "*.md"  # Find all markdown files in current directory
```

### Process Management

```bash
ps aux           # List processes
kill <pid>       # Kill process
htop             # Interactive process viewer
```

### Git Basics

```bash
git status       # Check repository status
git add .        # Stage all changes
git commit -m "message"  # Commit changes
git log --oneline  # View commit history
```

### Text Processing

```bash
grep "pattern" file.txt    # Search in file
cat file.txt | head -20    # First 20 lines
cat file.txt | tail -20    # Last 20 lines
wc -l file.txt             # Count lines