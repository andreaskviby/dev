# TMUX Smart Startup

A configuration-driven TMUX environment manager with JSON-based sessions.

![Terminal Preview](https://img.shields.io/badge/tmux-ready-green?style=flat-square)
![Shell](https://img.shields.io/badge/shell-bash-blue?style=flat-square)

## Features

- **JSON-driven configuration** - Add new sessions by creating JSON files
- **Vertical 4-pane layout** - Up to 4 vertical panes per window
- **Auto-start commands** - Run commands automatically at startup
- **Smart reconnection** - Creates sessions if they don't exist, otherwise reconnects
- **Nord theme** - Clean, modern status bar and color theme
- **Config manager** - Interactive script to add/remove projects

## Structure

```
tmux-setup/
├── tmux-start.sh      # Main startup script
├── tmux-manage.sh     # Config manager script
├── tmux.conf          # TMUX configuration
├── config/
│   ├── gozero.json    # GoZero session
│   ├── stafe.json     # STAFE session
│   ├── private.json   # Private session
│   ├── aimi.json      # AIMI session
│   ├── saas.json      # SaaS session
│   ├── games.json     # Games session
│   ├── sicily.json    # Sicily session
│   └── *.json         # Add more sessions...
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

# 3. Link tmux.conf
ln -sf "$(pwd)/tmux.conf" ~/.tmux.conf

# 4. Make scripts executable
chmod +x tmux-start.sh tmux-manage.sh

# 5. (Optional) Add to PATH
ln -sf "$(pwd)/tmux-start.sh" ~/.local/bin/tmux-start
ln -sf "$(pwd)/tmux-manage.sh" ~/.local/bin/tmux-manage
```

## Usage

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

## License

MIT
