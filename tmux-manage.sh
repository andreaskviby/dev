#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
# TMUX Config Manager - Add/Edit/Remove sites from session configs
# ══════════════════════════════════════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/config"
HERD_DIR="$HOME/Herd"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# ─────────────────────────────────────────────────────────────────────────────
# HELPER FUNCTIONS
# ─────────────────────────────────────────────────────────────────────────────

print_header() {
    echo ""
    echo -e "${CYAN}┌──────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}  ${BOLD}🔧 TMUX Config Manager${NC}                                         ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${DIM}Add, edit, and remove sites from session configs${NC}               ${CYAN}│${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

log_info() {
    echo -e "  ${BLUE}ℹ${NC}  $1"
}

log_success() {
    echo -e "  ${GREEN}✓${NC}  $1"
}

log_warning() {
    echo -e "  ${YELLOW}⚠${NC}  $1"
}

log_error() {
    echo -e "  ${RED}✗${NC}  $1"
}

check_dependencies() {
    if ! command -v jq &> /dev/null; then
        log_error "jq is not installed!"
        echo ""
        echo -e "  Install with:"
        echo -e "    ${CYAN}brew install jq${NC}     (macOS)"
        echo -e "    ${CYAN}apt install jq${NC}      (Ubuntu/Debian)"
        exit 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# SESSION FUNCTIONS
# ─────────────────────────────────────────────────────────────────────────────

get_sessions() {
    for config_file in "$CONFIG_DIR"/*.json; do
        [[ -f "$config_file" ]] || continue
        basename "$config_file" .json
    done
}

show_sessions_menu() {
    echo -e "  ${BOLD}Available sessions:${NC}"
    echo ""
    local i=1
    local sessions=()
    for config_file in "$CONFIG_DIR"/*.json; do
        [[ -f "$config_file" ]] || continue
        local name=$(jq -r '.session' "$config_file")
        local icon=$(jq -r '.icon // "📁"' "$config_file")
        local desc=$(jq -r '.description // ""' "$config_file")
        local window_count=$(jq '.windows | length' "$config_file")
        sessions+=("$name")
        echo -e "    ${CYAN}$i)${NC} $icon ${BOLD}$name${NC} ${DIM}($window_count projects)${NC}"
        [[ -n "$desc" ]] && echo -e "       ${DIM}$desc${NC}"
        ((i++))
    done
    echo ""

    # Store sessions in global array
    SESSION_LIST=("${sessions[@]}")
}

select_session() {
    show_sessions_menu

    while true; do
        read -p "  Select session (1-${#SESSION_LIST[@]}): " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#SESSION_LIST[@]}" ]; then
            SELECTED_SESSION="${SESSION_LIST[$((choice-1))]}"
            return 0
        fi
        log_error "Invalid selection. Please try again."
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# PROJECT FUNCTIONS
# ─────────────────────────────────────────────────────────────────────────────

list_herd_folders() {
    echo -e "  ${BOLD}Available Herd folders:${NC}"
    echo ""
    local i=1
    local folders=()

    for dir in "$HERD_DIR"/*/; do
        [[ -d "$dir" ]] || continue
        local name=$(basename "$dir")
        # Skip hidden folders and common non-project folders
        [[ "$name" == .* ]] && continue
        folders+=("$name")
        echo -e "    ${CYAN}$i)${NC} $name"
        ((i++))
    done
    echo ""
    echo -e "    ${CYAN}0)${NC} Enter custom path"
    echo ""

    FOLDER_LIST=("${folders[@]}")
}

select_folder() {
    list_herd_folders

    while true; do
        read -p "  Select folder (0-${#FOLDER_LIST[@]}): " choice
        if [[ "$choice" == "0" ]]; then
            read -p "  Enter custom path (relative to ~): " custom_path
            SELECTED_FOLDER="~/$custom_path"
            SELECTED_NAME=$(basename "$custom_path")
            return 0
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#FOLDER_LIST[@]}" ]; then
            local folder="${FOLDER_LIST[$((choice-1))]}"
            SELECTED_FOLDER="~/Herd/$folder"
            SELECTED_NAME="$folder"
            return 0
        fi
        log_error "Invalid selection. Please try again."
    done
}

show_projects_in_session() {
    local session="$1"
    local config_file="$CONFIG_DIR/${session}.json"

    if [[ ! -f "$config_file" ]]; then
        log_error "Session config not found: $session"
        return 1
    fi

    local icon=$(jq -r '.icon // "📁"' "$config_file")
    local window_count=$(jq '.windows | length' "$config_file")

    echo ""
    echo -e "  $icon ${BOLD}$session${NC} - Projects:"
    echo ""

    if [[ "$window_count" -eq 0 ]]; then
        echo -e "    ${DIM}(no projects yet)${NC}"
    else
        for ((i=0; i<window_count; i++)); do
            local name=$(jq -r ".windows[$i].name" "$config_file")
            local dir=$(jq -r ".windows[$i].directory" "$config_file")
            local pane_count=$(jq ".windows[$i].panes | length" "$config_file")
            echo -e "    ${CYAN}$((i+1)))${NC} ${BOLD}$name${NC} ${DIM}($dir, $pane_count panes)${NC}"
        done
    fi
    echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# PANE TEMPLATES
# ─────────────────────────────────────────────────────────────────────────────

select_pane_template() {
    echo -e "  ${BOLD}Select pane template:${NC}"
    echo ""
    echo -e "    ${CYAN}1)${NC} Claude Code (claude auto-start)"
    echo -e "    ${CYAN}2)${NC} Laravel + Claude (serve, npm, logs, claude)"
    echo -e "    ${CYAN}3)${NC} Laravel Full (serve, npm, queue, logs)"
    echo -e "    ${CYAN}4)${NC} Laravel Basic (serve, npm, logs, tinker)"
    echo -e "    ${CYAN}5)${NC} Node.js (npm dev, build, logs, shell)"
    echo -e "    ${CYAN}6)${NC} Basic (4 empty shells)"
    echo -e "    ${CYAN}7)${NC} Minimal (2 empty shells)"
    echo ""

    while true; do
        read -p "  Select template (1-7): " choice
        case "$choice" in
            1)
                PANE_TEMPLATE='[
                    { "name": "claude", "command": "claude" }
                ]'
                return 0
                ;;
            2)
                PANE_TEMPLATE='[
                    { "name": "artisan", "command": "php artisan serve" },
                    { "name": "npm", "command": "npm run dev" },
                    { "name": "logs", "command": "tail -f storage/logs/laravel.log" },
                    { "name": "claude", "command": "claude" }
                ]'
                return 0
                ;;
            3)
                PANE_TEMPLATE='[
                    { "name": "artisan", "command": "php artisan serve" },
                    { "name": "npm", "command": "npm run dev" },
                    { "name": "queue", "command": "php artisan queue:work" },
                    { "name": "logs", "command": "tail -f storage/logs/laravel.log" }
                ]'
                return 0
                ;;
            4)
                PANE_TEMPLATE='[
                    { "name": "artisan", "command": "php artisan serve" },
                    { "name": "npm", "command": "npm run dev" },
                    { "name": "logs", "command": "tail -f storage/logs/laravel.log" },
                    { "name": "tinker", "command": null }
                ]'
                return 0
                ;;
            5)
                PANE_TEMPLATE='[
                    { "name": "dev", "command": "npm run dev" },
                    { "name": "build", "command": null },
                    { "name": "logs", "command": null },
                    { "name": "shell", "command": null }
                ]'
                return 0
                ;;
            6)
                PANE_TEMPLATE='[
                    { "name": "shell-1", "command": null },
                    { "name": "shell-2", "command": null },
                    { "name": "shell-3", "command": null },
                    { "name": "shell-4", "command": null }
                ]'
                return 0
                ;;
            7)
                PANE_TEMPLATE='[
                    { "name": "main", "command": null },
                    { "name": "secondary", "command": null }
                ]'
                return 0
                ;;
            *)
                log_error "Invalid selection. Please try again."
                ;;
        esac
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# COMMANDS
# ─────────────────────────────────────────────────────────────────────────────

cmd_add() {
    print_header
    check_dependencies

    log_info "Adding a new project to a session"
    echo ""

    # Select session
    select_session
    log_success "Selected session: ${BOLD}$SELECTED_SESSION${NC}"
    echo ""

    # Select folder
    select_folder
    log_success "Selected folder: ${BOLD}$SELECTED_FOLDER${NC}"
    echo ""

    # Ask for project name
    read -p "  Project name [${SELECTED_NAME}]: " project_name
    project_name="${project_name:-$SELECTED_NAME}"

    # Select pane template
    echo ""
    select_pane_template

    # Add to config
    local config_file="$CONFIG_DIR/${SELECTED_SESSION}.json"
    local new_window=$(cat <<EOF
{
    "name": "$project_name",
    "directory": "$SELECTED_FOLDER",
    "panes": $PANE_TEMPLATE
}
EOF
)

    # Add window to config using jq
    local tmp_file=$(mktemp)
    jq --argjson window "$new_window" '.windows += [$window]' "$config_file" > "$tmp_file"
    mv "$tmp_file" "$config_file"

    echo ""
    log_success "Added ${BOLD}$project_name${NC} to ${BOLD}$SELECTED_SESSION${NC}"
    echo ""

    show_projects_in_session "$SELECTED_SESSION"
}

cmd_remove() {
    print_header
    check_dependencies

    log_info "Removing a project from a session"
    echo ""

    # Select session
    select_session

    local config_file="$CONFIG_DIR/${SELECTED_SESSION}.json"
    local window_count=$(jq '.windows | length' "$config_file")

    if [[ "$window_count" -eq 0 ]]; then
        log_warning "No projects in $SELECTED_SESSION to remove"
        return 0
    fi

    show_projects_in_session "$SELECTED_SESSION"

    read -p "  Select project to remove (1-$window_count): " choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$window_count" ]; then
        local project_name=$(jq -r ".windows[$((choice-1))].name" "$config_file")

        read -p "  Are you sure you want to remove '$project_name'? (y/N): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            local tmp_file=$(mktemp)
            jq "del(.windows[$((choice-1))])" "$config_file" > "$tmp_file"
            mv "$tmp_file" "$config_file"

            log_success "Removed ${BOLD}$project_name${NC} from ${BOLD}$SELECTED_SESSION${NC}"
        else
            log_info "Cancelled"
        fi
    else
        log_error "Invalid selection"
    fi
}

cmd_list() {
    print_header
    check_dependencies

    for config_file in "$CONFIG_DIR"/*.json; do
        [[ -f "$config_file" ]] || continue
        local session=$(jq -r '.session' "$config_file")
        show_projects_in_session "$session"
    done
}

cmd_interactive() {
    print_header
    check_dependencies

    while true; do
        echo -e "  ${BOLD}What would you like to do?${NC}"
        echo ""
        echo -e "    ${CYAN}1)${NC} Add a project to a session"
        echo -e "    ${CYAN}2)${NC} Remove a project from a session"
        echo -e "    ${CYAN}3)${NC} List all projects"
        echo -e "    ${CYAN}4)${NC} Exit"
        echo ""

        read -p "  Select option (1-4): " choice
        echo ""

        case "$choice" in
            1) cmd_add ;;
            2) cmd_remove ;;
            3) cmd_list ;;
            4)
                log_info "Goodbye!"
                exit 0
                ;;
            *)
                log_error "Invalid selection"
                ;;
        esac

        echo ""
        echo -e "  ${DIM}─────────────────────────────────────────────────────────${NC}"
        echo ""
    done
}

cmd_help() {
    print_header

    echo -e "  ${BOLD}Usage:${NC}"
    echo ""
    echo -e "    ${CYAN}./tmux-manage.sh${NC}              Interactive mode"
    echo -e "    ${CYAN}./tmux-manage.sh add${NC}          Add a project"
    echo -e "    ${CYAN}./tmux-manage.sh remove${NC}       Remove a project"
    echo -e "    ${CYAN}./tmux-manage.sh list${NC}         List all projects"
    echo -e "    ${CYAN}./tmux-manage.sh --help${NC}       Show this help"
    echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

main() {
    case "${1:-}" in
        --help|-h)
            cmd_help
            ;;
        add|a)
            cmd_add
            ;;
        remove|rm|r)
            cmd_remove
            ;;
        list|ls|l)
            cmd_list
            ;;
        *)
            cmd_interactive
            ;;
    esac
}

main "$@"
