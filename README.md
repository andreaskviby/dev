# TMUX Smart Startup

A configuration-driven TMUX environment manager with JSON-based sessions, now integrated with **BMAD Method** (Breakthrough Method for Agile AI-Driven Development).

![Terminal Preview](https://img.shields.io/badge/tmux-ready-green?style=flat-square)
![Shell](https://img.shields.io/badge/shell-bash-blue?style=flat-square)
![BMAD](https://img.shields.io/badge/BMAD-integrated-blue?style=flat-square)

## Features

- **JSON-driven configuration** - Add new sessions by creating JSON files
- **Vertical 4-pane layout** - Up to 4 vertical panes per window
- **Auto-start commands** - Run commands automatically at startup
- **Smart reconnection** - Creates sessions if they don't exist, otherwise reconnects
- **Nord theme** - Clean, modern status bar and color theme
- **Config manager** - Interactive script to add/remove projects
- **🆕 BMAD Method Integration** - AI-driven product analysis with specialized agents
- **🆕 make-product command** - Launch 4-panel product analysis sessions

## Structure

```
tmux-setup/
├── tmux-start.sh      # Main startup script
├── tmux-manage.sh     # Config manager script
├── tmux.conf          # TMUX configuration
├── startup            # Quick Claude Code launcher
├── make-product       # 🆕 BMAD product analysis launcher
├── config/
│   ├── gozero.json    # GoZero session
│   ├── stafe.json     # STAFE session
│   ├── private.json   # Private session
│   ├── aimi.json      # AIMI session
│   ├── saas.json      # SaaS session
│   ├── games.json     # Games session
│   ├── sicily.json    # Sicily session
│   ├── bmad.json      # 🆕 BMAD Method session
│   └── *.json         # Add more sessions...
├── _bmad/             # BMAD Method installation
└── README.md
```

## Installation

```bash
# 1. Clone the repo
git clone https://github.com/your-repo/tmux-setup.git
cd tmux-setup

# 2. Install dependencies
brew install tmux jq    # macOS
# or
sudo apt install tmux jq  # Ubuntu/Debian

# 3. Install Node.js (required for BMAD)
# Node.js v20+ is required
# Visit https://nodejs.org or use your package manager

# 4. Install BMAD Method (already installed in this repo)
# If you need to reinstall:
npx bmad-method@alpha install

# 5. Link tmux.conf
ln -sf "$(pwd)/tmux.conf" ~/.tmux.conf

# 6. Make scripts executable
chmod +x tmux-start.sh tmux-manage.sh startup make-product

# 7. (Optional) Add to PATH
ln -sf "$(pwd)/tmux-start.sh" ~/.local/bin/tmux-start
ln -sf "$(pwd)/tmux-manage.sh" ~/.local/bin/tmux-manage
ln -sf "$(pwd)/make-product" ~/.local/bin/make-product
```

## Usage

### 🆕 BMAD Product Analysis (make-product)

Launch a comprehensive 4-panel product analysis session with BMAD Method AI agents:

```bash
# Interactive mode - select project from ~/Herd
./make-product

# Direct mode - specify project path
./make-product ~/Herd/my-project
./make-product /path/to/any/project
```

**What it does:**
- Creates 4 vertical panels in tmux
- Launches Claude Code in each panel
- Automatically starts BMAD workflows:
  - **Panel 1**: Product Brief & Workflow Init (*workflow-init)
  - **Panel 2**: Research & Market Analysis (*research)
  - **Panel 3**: Architecture & Planning (*plan)
  - **Panel 4**: Implementation Status (*workflow-status)

This enables parallel product analysis with specialized AI agents working on different aspects simultaneously.

### Starting Sessions

```bash
# Start all sessions
./tmux-start.sh

# Start specific session
./tmux-start.sh gozero
./tmux-start.sh stafe

# List configurations
./tmux-start.sh --list

# Show status
./tmux-start.sh --status

# Kill all sessions
./tmux-start.sh --kill
```

### Managing Projects

```bash
# Interactive mode
./tmux-manage.sh

# Add a project
./tmux-manage.sh add

# Remove a project
./tmux-manage.sh remove

# List all projects
./tmux-manage.sh list
```

The config manager will:
1. Let you select which session to modify
2. Show available folders in `~/Herd/`
3. Let you choose a pane template (Laravel, Node.js, etc.)
4. Automatically update the JSON config

## Sessions

| Session | Icon | Description |
|---------|------|-------------|
| gozero | 🚀 | GoZero Projects |
| stafe | 🏢 | STAFE Group Projects |
| private | 🏠 | Private Projects |
| aimi | 🤖 | AIMI Projects |
| saas | ☁️ | SaaS Projects |
| games | 🎮 | Game Projects |
| sicily | 🫒 | Sicily Projects |
| **bmad** | **🤖** | **BMAD Method Product Analysis** |

## JSON Configuration

### Schema

```json
{
  "session": "session-name",
  "icon": "🚀",
  "description": "Description",
  "windows": [
    {
      "name": "window-name",
      "directory": "~/Herd/project",
      "panes": [
        { "name": "pane-1", "command": "npm run dev" },
        { "name": "pane-2", "command": null },
        { "name": "pane-3", "command": "tail -f logs" },
        { "name": "pane-4", "command": null }
      ]
    }
  ]
}
```

### Example: Laravel Project

```json
{
  "session": "gozero",
  "icon": "🚀",
  "description": "GoZero Projects",
  "windows": [
    {
      "name": "myapp",
      "directory": "~/Herd/myapp",
      "panes": [
        { "name": "serve", "command": "php artisan serve" },
        { "name": "vite", "command": "npm run dev" },
        { "name": "queue", "command": "php artisan queue:work" },
        { "name": "logs", "command": "tail -f storage/logs/laravel.log" }
      ]
    }
  ]
}
```

## Pane Templates

When adding projects via `./tmux-manage.sh add`, you can choose from these templates:

| Template | Panes | Description |
|----------|-------|-------------|
| Claude Code | claude | Single pane with Claude Code auto-start |
| Laravel + Claude | serve, npm, logs, claude | Full Laravel dev + Claude Code |
| Laravel Full | serve, npm, queue, logs | Laravel with queue worker |
| Laravel Basic | serve, npm, logs, tinker | Standard Laravel setup |
| Node.js | dev, build, logs, shell | Node.js development |
| Basic | 4 empty shells | Four blank panes |
| Minimal | 2 empty shells | Two blank panes |

## Keybindings

| Command | Description |
|---------|-------------|
| `Ctrl+a \|` | Split vertically |
| `Ctrl+a -` | Split horizontally |
| `Ctrl+a c` | New window |
| `Ctrl+a n/p` | Next/previous window |
| `Ctrl+a 1-9` | Go to window # |
| `Alt+←→↑↓` | Navigate panes |
| `Shift+←→` | Resize panes |
| `Ctrl+a Tab` | Toggle last session |
| `Ctrl+a J/K` | Next/previous session |
| `Ctrl+a =` | Even out pane layout |
| `Ctrl+a r` | Reload config |

## Customization

### Add new session

1. Create `config/my-session.json`
2. Run `./tmux-start.sh my-session`

### Change theme

Edit color variables in `tmux.conf`:

```bash
# Nord colors
NORD0="#2E3440"   # Background
NORD8="#88C0D0"   # Accent
# ... etc
```

## Tips

- **Save session state**: Use [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect)
- **Auto start**: Add to `.bashrc`/`.zshrc`:
  ```bash
  [[ -z "$TMUX" ]] && ~/tmux-setup/tmux-start.sh
  ```

## BMAD Method Integration

This repository integrates the **BMAD Method** (Breakthrough Method for Agile AI-Driven Development) - a comprehensive AI-powered development framework with specialized agents and structured workflows.

### What is BMAD?

BMAD is an open-source framework that brings structure and efficiency to AI-driven development through:

- **21 Specialized Agents**: Product Manager, Architect, Developer, QA, UX Designer, and more
- **50+ Guided Workflows**: From brainstorming to deployment
- **Scale-Adaptive Intelligence**: Adjusts complexity based on project needs
- **Documentation-First**: All context and decisions are versioned

### BMAD Workflows Available

The `make-product` command leverages these BMAD workflows:

1. **`*workflow-init`** - Analyzes your project and recommends an appropriate development track
2. **`*research`** - Conducts market analysis and competitive research
3. **`*plan`** - Creates architecture and planning documents
4. **`*workflow-status`** - Tracks implementation progress and next steps

### Learn More

- **BMAD Documentation**: [docs.bmad-method.org](http://docs.bmad-method.org)
- **GitHub Repository**: [github.com/bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD)
- **Discord Community**: [Join Discord](https://discord.gg/gk8jAdXWmj)

### BMAD Commands Reference

When in Claude Code with BMAD installed, you can use:

```bash
*workflow-init        # Initialize and analyze project
*research            # Start research workflow
*plan                # Begin planning workflow
*architect           # Architecture design
*develop             # Development workflow
*test                # Testing workflow
*workflow-status     # Check current status
```

## License

MIT
