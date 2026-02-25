# terminal quickstart guide

## table of contents

- [opencode](#opencode)
- [tmux](#tmux)
- [Additional Tools](#additional-tools)
- [Useful Commands](#useful-commands)

## creator's note

this guide is meant to quickstart you with this setup and give you instruction on how to use tools like opencode.

i'm assuming you're using this in a new environment where you have your permanent storage placed under the path `/mnt/user/` and that your home folder is not persistent. if your hom folder *is* persistent, i advise you to fork this repository and adapt it to your needs.

## everyday aliases

### initial setup

```bash
init-vm              # download files, setup backup and copy secrets
```

### file operations

```bash
mnt                  # cd into /mnt/user
lla                  # list all files with details
..                   # go to previous directory
find . -name "*.md"  # find all markdown files in current directory
```

## opencode

### before starting

*if you're having issues with the new TUI*, you can use `oc-rollback` to revert to the last stable version before the new TUI.

after, `init-vm` should have copied your secret keys from `/mnt/user/.secrets` to `/home/coder/.config/opencode/.secrets`. if not, just run `copy-secrets` in the terminal

now you can safely start opencode with the command `opencode` and below you can find a through review of our setup

### agents and subagents

we have 3 main agents:

**orchestrator** is the agent that you should use to do stuff or to implement plans (more on this later)

**planner** is the agent that you should run for creating plans and do research on your codebase

**commit** is the only agent able to run git commands that are not read-only (still, i don't feel like it should run commands like git push or similar). it's meant to help you with the git cli and automate git commits

we have a lot of subagents, and you can guess each one task and proficiency by it's name and description. feel free to open a PR if you feel like the system prompt given to a particular subagent or agent could be improved.

### commands

commands are pre-made prompts useful for repeating tasks.
we have:

- `/commit` this command call the agent *1-commit* and give the task to gather infos about your edits and do sensible commits based on your commit message history and rules defined by a contributing file
- `/review` this should be used with the *2-planner* agent, and should be used just before using the *commit* command. it instruct the agent to look into contributing rules and make sure you're respecting them. it's just a check to make sure full adherence to rules before committing changes (i also advise you not to track reviews with git, they would just pollute your documentation. i may be move the review folder somewhere else in the future)

### plugin

we use only one plugin that stops agents to read files named `.env` for obvious reason

### main config file

this file defines models, custom models, mcp server and command we do not want ai to run. if you are in YOLO mood, you can change `"*": "ask"` into `"*": "allow"` to let ai run almost any command without asking for permissions (be careful with that)

some notes about models we use:

- our main model is **GPT codex**, it's the one we use for the agents *orchestrator* and *planner*. we found that, beside being really slow at times, it's the best at following rules, has less verbosity than almost any other model and has great performance when planning and coordinating subagents
- our subagent model is **Kimi K2.5**. we have some exceptions were we use **GPT codex** as the subagent model for reasons like proficiency in specific coding languages and / or better rules adherence for specific languages or task

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
