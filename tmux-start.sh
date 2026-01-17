#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
# TMUX Smart Startup - JSON Configuration Driven
# ══════════════════════════════════════════════════════════════════════════════
#
# Användning:
#   ./tmux-start.sh              → Starta alla sessions från config/
#   ./tmux-start.sh jobb         → Starta endast jobb.json
#   ./tmux-start.sh privat       → Starta endast privat.json
#   ./tmux-start.sh --list       → Lista alla konfigurerade sessions
#   ./tmux-start.sh --kill       → Döda alla sessions
#   ./tmux-start.sh --status     → Visa status
#
# ══════════════════════════════════════════════════════════════════════════════

set -e

# ─────────────────────────────────────────────────────────────────────────────
# KONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/config"

# Färger
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
# HJÄLPFUNKTIONER
# ─────────────────────────────────────────────────────────────────────────────

print_header() {
    echo ""
    echo -e "${CYAN}┌──────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}  ${BOLD}🚀 TMUX Smart Startup${NC}                                          ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${DIM}JSON Configuration Driven Environment Manager${NC}                  ${CYAN}│${NC}"
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

log_step() {
    echo -e "  ${MAGENTA}→${NC}  $1"
}

check_dependencies() {
    if ! command -v tmux &> /dev/null; then
        log_error "tmux är inte installerat!"
        echo ""
        echo -e "  Installera med:"
        echo -e "    ${CYAN}brew install tmux${NC}     (macOS)"
        echo -e "    ${CYAN}apt install tmux${NC}      (Ubuntu/Debian)"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        log_error "jq är inte installerat (behövs för JSON-parsing)!"
        echo ""
        echo -e "  Installera med:"
        echo -e "    ${CYAN}brew install jq${NC}       (macOS)"
        echo -e "    ${CYAN}apt install jq${NC}        (Ubuntu/Debian)"
        exit 1
    fi
}

session_exists() {
    tmux has-session -t "$1" 2>/dev/null
}

expand_path() {
    local path="$1"
    echo "${path/#\~/$HOME}"
}

# ─────────────────────────────────────────────────────────────────────────────
# KÄRNFUNKTIONER
# ─────────────────────────────────────────────────────────────────────────────

create_session_from_json() {
    local json_file="$1"
    
    if [[ ! -f "$json_file" ]]; then
        log_error "Config-fil hittades inte: $json_file"
        return 1
    fi

    # Läs session-metadata
    local session_name=$(jq -r '.session' "$json_file")
    local session_icon=$(jq -r '.icon // "📁"' "$json_file")
    local session_desc=$(jq -r '.description // ""' "$json_file")
    local window_count=$(jq '.windows | length' "$json_file")

    # Kolla om session redan finns
    if session_exists "$session_name"; then
        log_success "Session ${BOLD}$session_name${NC} ${session_icon} finns redan"
        return 0
    fi

    echo ""
    log_step "Skapar session: ${BOLD}$session_name${NC} ${session_icon}"
    [[ -n "$session_desc" ]] && echo -e "     ${DIM}$session_desc${NC}"

    # Skapa session med första window
    local first_window_name=$(jq -r '.windows[0].name' "$json_file")
    local first_window_dir=$(jq -r '.windows[0].directory // "~"' "$json_file")
    first_window_dir=$(expand_path "$first_window_dir")
    
    # Skapa katalog om den inte finns
    mkdir -p "$first_window_dir" 2>/dev/null || true
    
    tmux new-session -d -s "$session_name" -n "$first_window_name" -c "$first_window_dir"

    # Skapa panes för första window
    create_panes_for_window "$session_name" "$first_window_name" "$json_file" 0

    # Skapa resterande windows
    for ((w=1; w<window_count; w++)); do
        local window_name=$(jq -r ".windows[$w].name" "$json_file")
        local window_dir=$(jq -r ".windows[$w].directory // \"~\"" "$json_file")
        window_dir=$(expand_path "$window_dir")
        
        mkdir -p "$window_dir" 2>/dev/null || true
        
        tmux new-window -t "$session_name" -n "$window_name" -c "$window_dir"
        create_panes_for_window "$session_name" "$window_name" "$json_file" "$w"
    done

    # Gå tillbaka till första window
    tmux select-window -t "$session_name:1"
    tmux select-pane -t "$session_name:1.1"

    log_success "Session ${BOLD}$session_name${NC} skapad med $window_count windows"
}

create_panes_for_window() {
    local session="$1"
    local window="$2"
    local json_file="$3"
    local window_index="$4"

    local pane_count=$(jq ".windows[$window_index].panes | length" "$json_file")
    local window_dir=$(jq -r ".windows[$window_index].directory // \"~\"" "$json_file")
    window_dir=$(expand_path "$window_dir")

    # Max 4 vertikala panes
    [[ $pane_count -gt 4 ]] && pane_count=4

    # Skapa panes (första finns redan)
    for ((p=1; p<pane_count; p++)); do
        tmux split-window -t "$session:$window" -h -c "$window_dir"
    done

    # Jämna ut layouten
    tmux select-layout -t "$session:$window" even-horizontal

    # Kör kommandon i varje pane
    for ((p=0; p<pane_count; p++)); do
        local pane_name=$(jq -r ".windows[$window_index].panes[$p].name // \"\"" "$json_file")
        local pane_cmd=$(jq -r ".windows[$window_index].panes[$p].command // null" "$json_file")
        
        local pane_num=$((p + 1))

        # Sätt pane title
        if [[ -n "$pane_name" ]]; then
            tmux select-pane -t "$session:$window.$pane_num" -T "$pane_name"
        fi

        # Kör kommando om det finns
        if [[ "$pane_cmd" != "null" && -n "$pane_cmd" ]]; then
            tmux send-keys -t "$session:$window.$pane_num" "$pane_cmd" Enter
        fi
    done

    # Välj första pane
    tmux select-pane -t "$session:$window.1"
}

# ─────────────────────────────────────────────────────────────────────────────
# COMMANDS
# ─────────────────────────────────────────────────────────────────────────────

cmd_start() {
    local target="$1"
    
    print_header
    check_dependencies

    if [[ ! -d "$CONFIG_DIR" ]]; then
        log_error "Config-katalog hittades inte: $CONFIG_DIR"
        log_info "Skapa JSON-filer i: ${CYAN}$CONFIG_DIR/${NC}"
        exit 1
    fi

    local configs_found=0

    if [[ -n "$target" && "$target" != "all" ]]; then
        # Starta specifik session
        local config_file="$CONFIG_DIR/${target}.json"
        if [[ -f "$config_file" ]]; then
            create_session_from_json "$config_file"
            configs_found=1
        else
            log_error "Config-fil hittades inte: $config_file"
            cmd_list
            exit 1
        fi
    else
        # Starta alla sessions
        for config_file in "$CONFIG_DIR"/*.json; do
            [[ -f "$config_file" ]] || continue
            create_session_from_json "$config_file"
            ((configs_found++))
        done
    fi

    if [[ $configs_found -eq 0 ]]; then
        log_warning "Inga config-filer hittades i $CONFIG_DIR/"
        exit 1
    fi

    echo ""
    cmd_status

    # Anslut till första/vald session
    local attach_to="${target:-$(jq -r '.session' "$CONFIG_DIR"/*.json 2>/dev/null | head -1)}"
    
    echo ""
    log_step "Ansluter till ${BOLD}$attach_to${NC}..."
    echo ""

    if [[ -n "$TMUX" ]]; then
        tmux switch-client -t "$attach_to"
    else
        tmux attach-session -t "$attach_to"
    fi
}

cmd_list() {
    echo ""
    echo -e "  ${BOLD}Tillgängliga konfigurationer:${NC}"
    echo ""
    
    for config_file in "$CONFIG_DIR"/*.json; do
        [[ -f "$config_file" ]] || continue
        
        local name=$(jq -r '.session' "$config_file")
        local icon=$(jq -r '.icon // "📁"' "$config_file")
        local desc=$(jq -r '.description // ""' "$config_file")
        local windows=$(jq '.windows | length' "$config_file")
        
        echo -e "    $icon ${BOLD}$name${NC} ${DIM}($windows windows)${NC}"
        [[ -n "$desc" ]] && echo -e "       ${DIM}$desc${NC}"
    done
    echo ""
}

cmd_status() {
    echo -e "${BLUE}┌──────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC}  ${BOLD}Aktiva TMUX Sessions${NC}                                            ${BLUE}│${NC}"
    echo -e "${BLUE}└──────────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    if ! tmux list-sessions &>/dev/null; then
        echo -e "    ${DIM}Inga aktiva sessions${NC}"
        echo ""
        return
    fi

    while IFS= read -r line; do
        local session=$(echo "$line" | cut -d: -f1)
        local info=$(echo "$line" | cut -d: -f2-)
        local attached=""
        
        [[ "$line" == *"attached"* ]] && attached="${GREEN}● attached${NC}"

        # Försök hitta ikon från config
        local icon="📁"
        local config_file="$CONFIG_DIR/${session}.json"
        [[ -f "$config_file" ]] && icon=$(jq -r '.icon // "📁"' "$config_file")

        echo -e "    $icon ${BOLD}$session${NC} $attached"
        
        # Lista windows
        tmux list-windows -t "$session" -F "       └─ #I: #W" 2>/dev/null | head -5
        
    done < <(tmux list-sessions 2>/dev/null)
    
    echo ""
}

cmd_kill() {
    print_header
    
    echo -e "  ${YELLOW}Dödar alla sessions...${NC}"
    echo ""
    
    tmux kill-server 2>/dev/null && log_success "Alla sessions avslutade" || log_info "Inga sessions att döda"
    echo ""
}

cmd_help() {
    print_header
    
    echo -e "  ${BOLD}Användning:${NC}"
    echo ""
    echo -e "    ${CYAN}./tmux-start.sh${NC}              Starta alla sessions"
    echo -e "    ${CYAN}./tmux-start.sh [namn]${NC}       Starta specifik session"
    echo -e "    ${CYAN}./tmux-start.sh --list${NC}       Lista konfigurationer"
    echo -e "    ${CYAN}./tmux-start.sh --status${NC}     Visa aktiva sessions"
    echo -e "    ${CYAN}./tmux-start.sh --kill${NC}       Döda alla sessions"
    echo -e "    ${CYAN}./tmux-start.sh --help${NC}       Visa denna hjälp"
    echo ""
    echo -e "  ${BOLD}Exempel:${NC}"
    echo ""
    echo -e "    ${DIM}# Starta jobb-miljön${NC}"
    echo -e "    ${CYAN}./tmux-start.sh jobb${NC}"
    echo ""
    echo -e "    ${DIM}# Starta allt${NC}"
    echo -e "    ${CYAN}./tmux-start.sh${NC}"
    echo ""
    echo -e "  ${BOLD}Config-struktur:${NC} ${DIM}config/*.json${NC}"
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
        --list|-l)
            cmd_list
            ;;
        --status|-s)
            print_header
            cmd_status
            ;;
        --kill|-k)
            cmd_kill
            ;;
        *)
            cmd_start "$1"
            ;;
    esac
}

main "$@"
