#!/bin/bash
# X1-Aether Installer & Configuration Tool
# Lightweight Non-Voting Verification Node for X1 Blockchain
#
# Usage:
#   curl -sSfL https://raw.githubusercontent.com/fortiblox/X1-Aether/main/install.sh | bash
#   x1-aether-config         # After installation, use this for configuration
#   install.sh --config      # Or run installer with --config flag

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Configuration
AETHER_VERSION="1.0.0"
TACHYON_REPO="x1-labs/tachyon"
INSTALL_DIR="/opt/x1-aether"
CONFIG_DIR="$HOME/.config/x1-aether"
DATA_DIR="/mnt/x1-aether"
BIN_DIR="/usr/local/bin"
RPC_URL="https://rpc.mainnet.x1.xyz"
SETTINGS_FILE="$CONFIG_DIR/settings.conf"

# X1 Mainnet Configuration
ENTRYPOINTS=(
    "entrypoint0.mainnet.x1.xyz:8001"
    "entrypoint1.mainnet.x1.xyz:8001"
    "entrypoint2.mainnet.x1.xyz:8001"
)
KNOWN_VALIDATORS=(
    "7ufaUVtQKzGu5tpFtii9Cg8kR4jcpjQSXwsF3oVPSMZA"
    "5Rzytnub9yGTFHqSmauFLsAbdXFbehMwPBLiuEgKajUN"
    "4V2QkkWce8bwTzvvwPiNRNQ4W433ZsGQi9aWU12Q8uBF"
    "CkMwg4TM6jaSC5rJALQjvLc51XFY5pJ1H9f1Tmu5Qdxs"
    "7J5wJaH55ZYjCCmCMt7Gb3QL6FGFmjz5U8b6NcbzfoTy"
)

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; }

print_step() {
    local step=$1
    local total=$2
    local desc=$3
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Step ${step}/${total}: ${desc}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════
# Settings Management
# ═══════════════════════════════════════════════════════════════

load_settings() {
    AUTOSTART_ENABLED="true"
    AUTOUPDATE_ENABLED="false"
    NODE_NAME=""
    NODE_WEBSITE=""
    NODE_ICON=""

    if [[ -f "$SETTINGS_FILE" ]]; then
        source "$SETTINGS_FILE"
    fi
}

save_settings() {
    mkdir -p "$CONFIG_DIR"
    cat > "$SETTINGS_FILE" << EOF
# X1-Aether Settings
AUTOSTART_ENABLED="$AUTOSTART_ENABLED"
AUTOUPDATE_ENABLED="$AUTOUPDATE_ENABLED"
NODE_NAME="$NODE_NAME"
NODE_WEBSITE="$NODE_WEBSITE"
NODE_ICON="$NODE_ICON"
EOF
}

# ═══════════════════════════════════════════════════════════════
# Configuration Menu (Post-Install)
# ═══════════════════════════════════════════════════════════════

show_config_menu() {
    load_settings

    while true; do
        clear
        echo ""
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}   ${GREEN}${BOLD}X1-Aether Configuration${NC}                                ${CYAN}║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo ""

        if [[ -f "$CONFIG_DIR/identity.json" ]]; then
            IDENTITY_PUBKEY=$(solana-keygen pubkey "$CONFIG_DIR/identity.json" 2>/dev/null || echo "invalid")
            echo -e "  Identity: ${GREEN}$IDENTITY_PUBKEY${NC}"
        else
            echo -e "  Identity: ${RED}Not configured${NC}"
        fi

        if [[ -n "$NODE_NAME" ]]; then
            echo -e "  Node Name: ${GREEN}$NODE_NAME${NC}"
        else
            echo -e "  Node Name: ${DIM}Not set${NC}"
        fi

        if systemctl is-enabled x1-aether &>/dev/null; then
            echo -e "  Auto-start: ${GREEN}Enabled${NC}"
        else
            echo -e "  Auto-start: ${YELLOW}Disabled${NC}"
        fi

        if [[ "$AUTOUPDATE_ENABLED" == "true" ]]; then
            echo -e "  Auto-update: ${GREEN}Enabled${NC}"
        else
            echo -e "  Auto-update: ${YELLOW}Disabled${NC}"
        fi

        if systemctl is-active x1-aether &>/dev/null; then
            echo -e "  Service: ${GREEN}Running${NC}"
        else
            echo -e "  Service: ${YELLOW}Stopped${NC}"
        fi

        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "  1) Identity Management"
        echo "  2) Node Identity (name, website, icon)"
        echo "  3) Toggle Auto-Start on Boot"
        echo "  4) Toggle Auto-Update"
        echo "  5) Reconfigure Firewall"
        echo "  6) View Node Info"
        echo "  7) Rebuild Binary"
        echo -e "  8) ${RED}Uninstall X1-Aether${NC}"
        echo ""
        echo "  0) Exit"
        echo ""
        echo -e "${DIM}You are responsible for securing your private keys.${NC}"
        echo -e "${DIM}We do not store or manage your keys.${NC}"
        echo ""
        read -p "Select option: " config_choice

        case $config_choice in
            1) identity_menu ;;
            2) node_identity_menu ;;
            3) toggle_autostart ;;
            4) toggle_autoupdate ;;
            5) configure_firewall; read -p "Press Enter to continue..." ;;
            6) show_node_info; read -p "Press Enter to continue..." ;;
            7) rebuild_binary; read -p "Press Enter to continue..." ;;
            8) uninstall_aether ;;
            0) exit 0 ;;
            *) ;;
        esac
    done
}

identity_menu() {
    while true; do
        clear
        echo ""
        echo -e "${BOLD}Identity Management${NC}"
        echo ""

        if [[ -f "$CONFIG_DIR/identity.json" ]]; then
            echo -e "  Current: $(solana-keygen pubkey $CONFIG_DIR/identity.json 2>/dev/null)"
        fi

        echo ""
        echo "  1) View identity public key"
        echo "  2) Import identity from file"
        echo "  3) Import identity from bytes"
        echo "  4) Generate new identity (backup first!)"
        echo ""
        echo "  0) Back"
        echo ""
        read -p "Select option: " choice

        case $choice in
            1)
                echo ""
                echo "Identity: $(solana-keygen pubkey $CONFIG_DIR/identity.json 2>/dev/null || echo 'Not found')"
                read -p "Press Enter to continue..."
                ;;
            2)
                echo ""
                read -p "Path to identity.json: " import_path
                import_path="${import_path/#\~/$HOME}"
                if [[ -f "$import_path" ]] && solana-keygen pubkey "$import_path" &>/dev/null; then
                    cp "$import_path" "$CONFIG_DIR/identity.json"
                    chmod 600 "$CONFIG_DIR/identity.json"
                    log_success "Identity imported"
                else
                    log_error "Invalid file"
                fi
                read -p "Press Enter to continue..."
                ;;
            3)
                echo ""
                echo "Paste private key bytes (JSON array):"
                read -r bytes
                echo "$bytes" > "$CONFIG_DIR/identity.json"
                chmod 600 "$CONFIG_DIR/identity.json"
                if solana-keygen pubkey "$CONFIG_DIR/identity.json" &>/dev/null; then
                    log_success "Identity imported"
                else
                    log_error "Invalid bytes"
                    rm -f "$CONFIG_DIR/identity.json"
                fi
                read -p "Press Enter to continue..."
                ;;
            4)
                echo ""
                echo -e "${RED}WARNING: This will overwrite your current identity!${NC}"
                read -p "Type YES to confirm: " confirm
                if [[ "$confirm" == "YES" ]]; then
                    if [[ -f "$CONFIG_DIR/identity.json" ]]; then
                        mv "$CONFIG_DIR/identity.json" "$CONFIG_DIR/identity.json.backup.$(date +%s)"
                    fi
                    solana-keygen new -o "$CONFIG_DIR/identity.json" --no-passphrase --force
                    chmod 600 "$CONFIG_DIR/identity.json"
                    log_success "New identity generated"
                fi
                read -p "Press Enter to continue..."
                ;;
            0) return ;;
        esac
    done
}

node_identity_menu() {
    load_settings

    while true; do
        clear
        echo ""
        echo -e "${BOLD}Node Identity & Branding${NC}"
        echo ""
        echo "Set your node's public identity on the X1 network."
        echo ""

        echo -e "  Current Name:    ${NODE_NAME:-${DIM}Not set${NC}}"
        echo -e "  Current Website: ${NODE_WEBSITE:-${DIM}Not set${NC}}"
        echo -e "  Current Icon:    ${NODE_ICON:-${DIM}Not set${NC}}"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "  1) Set Node Name"
        echo "  2) Set Website URL"
        echo "  3) Set Icon/Image URL"
        echo "  4) Publish to Network"
        echo "  5) View Current On-Chain Info"
        echo ""
        echo "  0) Back"
        echo ""
        read -p "Select option: " choice

        case $choice in
            1)
                echo ""
                echo "Enter your node name (e.g., 'MyNode', 'Verification Node #1'):"
                read -p "> " new_name
                if [[ -n "$new_name" ]]; then
                    NODE_NAME="$new_name"
                    save_settings
                    log_success "Name set to: $NODE_NAME"
                fi
                read -p "Press Enter to continue..."
                ;;
            2)
                echo ""
                echo "Enter your website URL (e.g., 'https://mynode.com'):"
                read -p "> " new_website
                if [[ -n "$new_website" ]]; then
                    NODE_WEBSITE="$new_website"
                    save_settings
                    log_success "Website set to: $NODE_WEBSITE"
                fi
                read -p "Press Enter to continue..."
                ;;
            3)
                echo ""
                echo "Enter your icon/image URL (must be publicly accessible)"
                echo ""
                echo -e "${DIM}Examples:${NC}"
                echo "  - https://pbs.twimg.com/profile_images/xxxxx/image.jpg"
                echo "  - https://i.imgur.com/xxxxx.png"
                echo "  - https://yoursite.com/logo.png"
                echo ""
                read -p "> " new_icon
                if [[ -n "$new_icon" ]]; then
                    NODE_ICON="$new_icon"
                    save_settings
                    log_success "Icon set to: $NODE_ICON"
                fi
                read -p "Press Enter to continue..."
                ;;
            4)
                publish_node_info
                read -p "Press Enter to continue..."
                ;;
            5)
                echo ""
                echo "Fetching on-chain info..."
                if [[ -f "$CONFIG_DIR/identity.json" ]]; then
                    solana validator-info get --keypair "$CONFIG_DIR/identity.json" --url $RPC_URL 2>/dev/null || echo "No info published yet"
                else
                    echo "Identity not found"
                fi
                read -p "Press Enter to continue..."
                ;;
            0) return ;;
        esac
    done
}

publish_node_info() {
    load_settings

    echo ""
    if [[ -z "$NODE_NAME" ]]; then
        log_error "Node name is required. Set it first."
        return
    fi

    if [[ ! -f "$CONFIG_DIR/identity.json" ]]; then
        log_error "Identity not found"
        return
    fi

    echo "Publishing node info..."
    echo ""
    echo "  Name:    $NODE_NAME"
    echo "  Website: ${NODE_WEBSITE:-Not set}"
    echo "  Icon:    ${NODE_ICON:-Not set}"
    echo ""

    CMD="solana validator-info publish \"$NODE_NAME\""
    CMD="$CMD --keypair \"$CONFIG_DIR/identity.json\""
    CMD="$CMD --url $RPC_URL"

    if [[ -n "$NODE_WEBSITE" ]]; then
        CMD="$CMD --website \"$NODE_WEBSITE\""
    fi

    if [[ -n "$NODE_ICON" ]]; then
        CMD="$CMD --icon-url \"$NODE_ICON\""
    fi

    if eval $CMD; then
        log_success "Node info published!"
    else
        log_error "Failed to publish. Your identity may need XNT for the transaction."
    fi
}

toggle_autostart() {
    if systemctl is-enabled x1-aether &>/dev/null; then
        sudo systemctl disable x1-aether
        log_success "Auto-start disabled"
    else
        sudo systemctl enable x1-aether
        log_success "Auto-start enabled"
    fi
    sleep 1
}

toggle_autoupdate() {
    load_settings

    if [[ "$AUTOUPDATE_ENABLED" == "true" ]]; then
        AUTOUPDATE_ENABLED="false"
        (crontab -l 2>/dev/null | grep -v "x1-aether-update") | crontab -
        log_success "Auto-update disabled"
    else
        AUTOUPDATE_ENABLED="true"
        install_autoupdater
        log_success "Auto-update enabled (checks daily at 4 AM)"
    fi

    save_settings
    sleep 1
}

install_autoupdater() {
    sudo tee "$INSTALL_DIR/bin/x1-aether-update" > /dev/null << 'UPDATER'
#!/bin/bash
INSTALL_DIR="/opt/x1-aether"
TACHYON_REPO="x1-labs/tachyon"
LOG_FILE="/var/log/x1-aether-update.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"; }

log "Starting update check..."

cd /tmp
rm -rf tachyon-check
git clone --depth 1 https://github.com/$TACHYON_REPO.git tachyon-check 2>/dev/null

if [[ -d tachyon-check ]]; then
    NEW_COMMIT=$(cd tachyon-check && git rev-parse HEAD)
    CURRENT_COMMIT=$(cat "$INSTALL_DIR/commit" 2>/dev/null || echo "none")

    if [[ "$NEW_COMMIT" != "$CURRENT_COMMIT" ]]; then
        log "Update available: $CURRENT_COMMIT -> $NEW_COMMIT"

        cd tachyon-check
        export RUSTFLAGS="-C target-cpu=native"
        if cargo build --release -p tachyon-validator >> "$LOG_FILE" 2>&1; then
            systemctl stop x1-aether 2>/dev/null
            cp "$INSTALL_DIR/bin/x1-aether" "$INSTALL_DIR/bin/x1-aether.backup" 2>/dev/null
            cp target/release/tachyon-validator "$INSTALL_DIR/bin/x1-aether"
            chmod +x "$INSTALL_DIR/bin/x1-aether"
            echo "$NEW_COMMIT" > "$INSTALL_DIR/commit"
            systemctl start x1-aether 2>/dev/null
            log "Update completed"
        else
            log "Build failed"
        fi
    else
        log "Already up to date"
    fi
    rm -rf /tmp/tachyon-check
fi
UPDATER
    sudo chmod +x "$INSTALL_DIR/bin/x1-aether-update"
    (crontab -l 2>/dev/null | grep -v "x1-aether-update"; echo "0 4 * * * $INSTALL_DIR/bin/x1-aether-update") | crontab -
}

show_node_info() {
    echo ""
    echo -e "${BOLD}Node Information${NC}"
    echo ""

    if [[ -f "$CONFIG_DIR/identity.json" ]]; then
        echo "Identity: $(solana-keygen pubkey $CONFIG_DIR/identity.json)"
    fi

    echo ""
    echo "Binary Version: $(cat $INSTALL_DIR/version 2>/dev/null || echo 'Unknown')"
    echo "Service Status: $(systemctl is-active x1-aether 2>/dev/null || echo 'Unknown')"
}

rebuild_binary() {
    echo ""
    log_info "Rebuilding from source..."
    read -p "Continue? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return
    fi

    if systemctl is-active x1-aether &>/dev/null; then
        sudo systemctl stop x1-aether
    fi

    cd /tmp
    rm -rf tachyon-build
    git clone --depth 1 https://github.com/$TACHYON_REPO.git tachyon-build
    cd tachyon-build

    export RUSTFLAGS="-C target-cpu=native"
    cargo build --release -p tachyon-validator

    sudo cp target/release/tachyon-validator "$INSTALL_DIR/bin/x1-aether"
    sudo chmod +x "$INSTALL_DIR/bin/x1-aether"

    cd /
    rm -rf /tmp/tachyon-build

    log_success "Binary rebuilt"

    read -p "Start service? (Y/n): " start
    if [[ ! "$start" =~ ^[Nn]$ ]]; then
        sudo systemctl start x1-aether
    fi
}

uninstall_aether() {
    clear
    echo ""
    echo -e "${RED}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}${BOLD}║   UNINSTALL X1-AETHER                                     ║${NC}"
    echo -e "${RED}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}This will completely remove X1-Aether from your system.${NC}"
    echo ""
    echo "The following will be deleted:"
    echo "  - Service: x1-aether.service"
    echo "  - Binary: /opt/x1-aether/"
    echo "  - Data: /mnt/x1-aether/"
    echo "  - CLI tools: /usr/local/bin/x1-aether*"
    echo ""
    echo -e "${CYAN}Your identity file will NOT be deleted:${NC}"
    echo "  ~/.config/x1-aether/identity.json"
    echo ""
    echo -e "${RED}${BOLD}This action cannot be undone!${NC}"
    echo ""
    read -p "Type 'UNINSTALL' to confirm: " confirm

    if [[ "$confirm" != "UNINSTALL" ]]; then
        echo "Cancelled."
        read -p "Press Enter to continue..."
        return
    fi

    echo ""
    log_info "Stopping service..."
    sudo systemctl stop x1-aether 2>/dev/null || true
    sudo systemctl disable x1-aether 2>/dev/null || true

    log_info "Removing service file..."
    sudo rm -f /etc/systemd/system/x1-aether.service
    sudo systemctl daemon-reload

    log_info "Removing binary and data..."
    sudo rm -rf /opt/x1-aether
    sudo rm -rf /mnt/x1-aether

    log_info "Removing CLI tools..."
    sudo rm -f /usr/local/bin/x1-aether
    sudo rm -f /usr/local/bin/x1-aether-config

    log_info "Removing cron jobs..."
    (crontab -l 2>/dev/null | grep -v "x1-aether") | crontab - 2>/dev/null || true

    echo ""
    log_success "X1-Aether has been uninstalled."
    echo ""
    echo -e "${CYAN}Your identity file was preserved at:${NC}"
    echo "  ~/.config/x1-aether/identity.json"
    echo ""
    echo -e "${DIM}To remove it: rm -rf ~/.config/x1-aether${NC}"
    echo ""
    read -p "Press Enter to exit..."
    exit 0
}

# ═══════════════════════════════════════════════════════════════
# Installation Functions
# ═══════════════════════════════════════════════════════════════

print_banner() {
    clear
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                                                           ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${BOLD}${GREEN}X1-Aether${NC} - Verification Node for X1 Blockchain      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   Version: ${AETHER_VERSION}                                         ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                           ${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}X1-Aether verifies the blockchain but does NOT vote or earn rewards.${NC}"
    echo -e "${YELLOW}For staking rewards, use X1-Forge instead.${NC}"
    echo ""
}

print_overview() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}What This Script Will Do:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  1. Check system requirements (RAM, CPU, disk space)"
    echo "  2. Install build tools, Rust, and Solana CLI"
    echo "  3. Generate or import your node identity"
    echo "  4. Set node identity (name, website, icon) - optional"
    echo "  5. Build the node from source (compiles Tachyon)"
    echo "  6. Configure firewall ports (8000-8020, 8899)"
    echo "  7. Optionally install as systemd service"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}What You'll Need:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  - sudo/root access"
    echo "  - Stable internet connection"
    echo "  - 15-30 minutes for compilation"
    echo ""
    echo -e "${DIM}  Optional: Existing identity.json file if migrating${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Minimum Requirements:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  - 8 GB RAM (16 GB recommended)"
    echo "  - 4 CPU cores (8 recommended)"
    echo "  - 500 GB NVMe storage (1 TB recommended)"
    echo "  - Ports 8000-8020, 8899 open"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}After Installation:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  Run 'x1-aether-config' to:"
    echo "  - Manage identity"
    echo "  - Toggle auto-start on boot"
    echo "  - Enable/disable auto-updates"
    echo "  - Update node branding"
    echo ""
}

check_requirements() {
    print_step 1 7 "Checking System Requirements"

    OS=$(uname -s)
    ARCH=$(uname -m)

    if [[ "$OS" != "Linux" ]]; then
        log_error "X1-Aether only supports Linux. Detected: $OS"
        exit 1
    fi

    CPU_CORES=$(nproc)
    RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    RAM_GB=$((RAM_KB / 1024 / 1024))
    DISK_FREE_GB=$(df -BG /mnt 2>/dev/null | awk 'NR==2 {print $4}' | tr -d 'G' || df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')

    echo "Scanning system..."
    echo ""

    local errors=0
    local warnings=0

    if [[ $RAM_GB -ge 16 ]]; then
        log_success "RAM: ${RAM_GB}GB (recommended: 16GB+)"
    elif [[ $RAM_GB -ge 7 ]]; then
        log_warn "RAM: ${RAM_GB}GB (minimum met, 16GB recommended)"
        warnings=$((warnings + 1))
    else
        log_error "RAM: ${RAM_GB}GB (minimum 8GB required)"
        errors=$((errors + 1))
    fi

    if [[ $CPU_CORES -ge 8 ]]; then
        log_success "CPU: ${CPU_CORES} cores (recommended: 8+)"
    elif [[ $CPU_CORES -ge 4 ]]; then
        log_warn "CPU: ${CPU_CORES} cores (minimum met, 8 recommended)"
        warnings=$((warnings + 1))
    else
        log_error "CPU: ${CPU_CORES} cores (minimum 4 required)"
        errors=$((errors + 1))
    fi

    if [[ $DISK_FREE_GB -ge 1000 ]]; then
        log_success "Disk: ${DISK_FREE_GB}GB free (recommended: 1TB+)"
    elif [[ $DISK_FREE_GB -ge 500 ]]; then
        log_warn "Disk: ${DISK_FREE_GB}GB free (minimum met, 1TB recommended)"
        warnings=$((warnings + 1))
    else
        log_error "Disk: ${DISK_FREE_GB}GB free (minimum 500GB required)"
        errors=$((errors + 1))
    fi

    if command -v ss &>/dev/null && ss -tuln | grep -q ':8899 '; then
        log_warn "Port 8899 already in use"
        warnings=$((warnings + 1))
    else
        log_success "Port 8899: Available"
    fi

    echo ""

    if [[ $errors -gt 0 ]]; then
        echo -e "${RED}${BOLD}System does not meet minimum requirements ($errors issue(s))${NC}"
        echo ""
        echo -e "${YELLOW}Proceeding may result in poor performance or failure.${NC}"
        read -t 0.1 -n 10000 discard 2>/dev/null || true  # Clear input buffer
        read -p "Continue anyway? (y/N): " override_choice
        if [[ ! "$override_choice" =~ ^[Yy] ]]; then
            exit 1
        fi
        echo -e "${YELLOW}Proceeding with installation...${NC}"
    elif [[ $warnings -gt 0 ]]; then
        echo -e "${YELLOW}System meets minimum requirements with $warnings warning(s)${NC}"
    else
        echo -e "${GREEN}All requirements met!${NC}"
    fi
}

install_dependencies() {
    print_step 2 7 "Installing Dependencies"

    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq
        sudo apt-get install -y -qq \
            build-essential pkg-config libssl-dev libudev-dev \
            libclang-dev protobuf-compiler curl wget git jq zstd
    elif command -v yum &>/dev/null; then
        sudo yum install -y \
            gcc gcc-c++ make pkgconfig openssl-devel systemd-devel \
            clang protobuf-compiler curl wget git jq zstd
    fi
    log_success "System packages installed"

    if command -v rustc &>/dev/null; then
        log_success "Rust already installed"
    else
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        log_success "Rust installed"
    fi

    if command -v solana-keygen &>/dev/null; then
        log_success "Solana CLI already installed"
    else
        sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"
        export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
        log_success "Solana CLI installed"
    fi
}

backup_wallet() {
    local wallet_file="$1"
    local wallet_name="$2"

    if [[ -f "$wallet_file" ]]; then
        local backup_dir="$CONFIG_DIR/backups"
        local timestamp=$(date +%Y-%m-%d_%H-%M-%S)
        local backup_file="$backup_dir/${wallet_name}_${timestamp}.json"

        mkdir -p "$backup_dir"
        cp "$wallet_file" "$backup_file"
        chmod 600 "$backup_file"

        log_success "Backed up to: $backup_file"
    fi
}

setup_identity() {
    print_step 3 7 "Node Identity Setup"

    mkdir -p "$CONFIG_DIR"
    IDENTITY_PATH="$CONFIG_DIR/identity.json"

    if [[ -f "$IDENTITY_PATH" ]]; then
        EXISTING=$(solana-keygen pubkey "$IDENTITY_PATH" 2>/dev/null || echo "unknown")
        echo ""
        echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  WARNING: EXISTING WALLET FOUND                           ║${NC}"
        echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  Pubkey: ${CYAN}$EXISTING${NC}"
        echo -e "  File:   ${CYAN}$IDENTITY_PATH${NC}"
        echo ""
        echo -e "${YELLOW}If you overwrite this wallet without a backup, it will be${NC}"
        echo -e "${YELLOW}LOST FOREVER. We cannot recover it for you.${NC}"
        echo ""
        echo "  1) Keep existing identity (recommended)"
        echo "  2) Import from file (will backup existing)"
        echo "  3) Import from bytes (will backup existing)"
        echo "  4) Generate NEW identity (will backup existing)"
        echo ""
        read -p "Select [1-4]: " choice
    else
        echo "No existing identity found."
        echo ""
        echo "  1) Generate new identity"
        echo "  2) Import from file"
        echo "  3) Import from bytes"
        echo ""
        read -p "Select [1-3]: " choice
        case $choice in
            1) choice=4 ;;
            2) choice=2 ;;
            3) choice=3 ;;
        esac
    fi

    case $choice in
        1) log_success "Keeping existing identity" ;;
        2)
            if [[ -f "$IDENTITY_PATH" ]]; then
                log_info "Backing up existing wallet..."
                backup_wallet "$IDENTITY_PATH" "identity"
            fi
            read -p "Path to identity.json: " path
            path="${path/#\~/$HOME}"
            cp "$path" "$IDENTITY_PATH"
            chmod 600 "$IDENTITY_PATH"
            log_success "Imported: $(solana-keygen pubkey $IDENTITY_PATH)"
            ;;
        3)
            if [[ -f "$IDENTITY_PATH" ]]; then
                log_info "Backing up existing wallet..."
                backup_wallet "$IDENTITY_PATH" "identity"
            fi
            echo "Paste bytes:"
            read -r bytes
            echo "$bytes" > "$IDENTITY_PATH"
            chmod 600 "$IDENTITY_PATH"
            log_success "Imported: $(solana-keygen pubkey $IDENTITY_PATH)"
            ;;
        4)
            if [[ -f "$IDENTITY_PATH" ]]; then
                log_info "Backing up existing wallet..."
                backup_wallet "$IDENTITY_PATH" "identity"
            fi
            solana-keygen new -o "$IDENTITY_PATH" --no-passphrase --force
            chmod 600 "$IDENTITY_PATH"
            log_success "Generated: $(solana-keygen pubkey $IDENTITY_PATH)"
            ;;
    esac

    echo ""
    echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  BACKUP YOUR IDENTITY FILE                                ║${NC}"
    echo -e "${YELLOW}║  $IDENTITY_PATH${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    if [[ -d "$CONFIG_DIR/backups" ]]; then
        echo -e "${DIM}Previous backups stored in: $CONFIG_DIR/backups/${NC}"
    fi
    read -p "Press Enter to continue..."
}

setup_node_identity() {
    print_step 4 7 "Node Identity (Optional)"

    echo "Set your node's public identity on the network."
    echo ""
    read -p "Configure now? (y/N): " configure
    if [[ ! "$configure" =~ ^[Yy]$ ]]; then
        log_info "Skipped. Run 'x1-aether-config' later."
        return
    fi

    echo ""
    echo "Node name (e.g., 'MyNode', 'Verification Node #1'):"
    read -p "> " NODE_NAME

    echo ""
    echo "Website URL (optional):"
    read -p "> " NODE_WEBSITE

    echo ""
    echo "Icon/Image URL (optional)"
    echo -e "${DIM}Examples:${NC}"
    echo "  - https://pbs.twimg.com/profile_images/xxxxx/image.jpg"
    echo "  - https://i.imgur.com/xxxxx.png"
    echo ""
    read -p "> " NODE_ICON

    save_settings

    if [[ -n "$NODE_NAME" ]]; then
        log_info "Publishing node info..."
        CMD="solana validator-info publish \"$NODE_NAME\" --keypair \"$CONFIG_DIR/identity.json\" --url $RPC_URL"
        [[ -n "$NODE_WEBSITE" ]] && CMD="$CMD --website \"$NODE_WEBSITE\""
        [[ -n "$NODE_ICON" ]] && CMD="$CMD --icon-url \"$NODE_ICON\""
        eval $CMD 2>/dev/null && log_success "Published!" || log_warn "Could not publish now. Retry via x1-aether-config."
    fi
}

build_node() {
    print_step 5 7 "Building X1-Aether"

    log_warn "Building from source (15-30 minutes)..."
    echo ""

    sudo mkdir -p "$INSTALL_DIR"/{bin,lib}
    sudo mkdir -p "$DATA_DIR"/ledger
    sudo chown -R "$USER:$USER" "$DATA_DIR" 2>/dev/null || true

    cd /tmp
    rm -rf tachyon-build
    git clone --depth 1 https://github.com/$TACHYON_REPO.git tachyon-build
    cd tachyon-build

    export RUSTFLAGS="-C target-cpu=native"
    cargo build --release -p tachyon-validator

    sudo cp target/release/tachyon-validator "$INSTALL_DIR/bin/x1-aether"
    sudo chmod +x "$INSTALL_DIR/bin/x1-aether"
    echo "$AETHER_VERSION" | sudo tee "$INSTALL_DIR/version" > /dev/null
    git rev-parse HEAD | sudo tee "$INSTALL_DIR/commit" > /dev/null

    cd /
    rm -rf /tmp/tachyon-build

    log_success "Binary built"

    # Install wrappers
    sudo tee "$BIN_DIR/x1-aether" > /dev/null << 'WRAPPER'
#!/bin/bash
case "$1" in
    start)   sudo systemctl start x1-aether ;;
    stop)    sudo systemctl stop x1-aether ;;
    restart) sudo systemctl restart x1-aether ;;
    status)  sudo systemctl status x1-aether ;;
    logs)    journalctl -u x1-aether -f ;;
    catchup) solana catchup --our-localhost ;;
    *)       echo "Commands: start|stop|restart|status|logs|catchup" ;;
esac
WRAPPER
    sudo chmod +x "$BIN_DIR/x1-aether"

    sudo tee "$BIN_DIR/x1-aether-config" > /dev/null << 'CONFIG'
#!/bin/bash
curl -sSfL https://raw.githubusercontent.com/fortiblox/X1-Aether/main/install.sh | bash -s -- --config
CONFIG
    sudo chmod +x "$BIN_DIR/x1-aether-config"
}

configure_firewall() {
    print_step 6 7 "Configuring Firewall"

    echo "Required ports: 8000-8020 (UDP/TCP), 8899 (TCP)"
    echo ""

    if command -v ufw &>/dev/null && sudo ufw status | grep -q "Status: active"; then
        sudo ufw allow 8000:8020/tcp >/dev/null 2>&1
        sudo ufw allow 8000:8020/udp >/dev/null 2>&1
        sudo ufw allow 8899/tcp >/dev/null 2>&1
        log_success "UFW configured"
    elif command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld; then
        sudo firewall-cmd --permanent --add-port=8000-8020/tcp >/dev/null 2>&1
        sudo firewall-cmd --permanent --add-port=8000-8020/udp >/dev/null 2>&1
        sudo firewall-cmd --permanent --add-port=8899/tcp >/dev/null 2>&1
        sudo firewall-cmd --reload >/dev/null 2>&1
        log_success "Firewalld configured"
    elif command -v iptables &>/dev/null; then
        sudo iptables -A INPUT -p tcp --dport 8000:8020 -j ACCEPT 2>/dev/null || true
        sudo iptables -A INPUT -p udp --dport 8000:8020 -j ACCEPT 2>/dev/null || true
        sudo iptables -A INPUT -p tcp --dport 8899 -j ACCEPT 2>/dev/null || true
        log_success "iptables configured"
    else
        log_warn "No firewall detected"
    fi

    echo -e "${DIM}Note: Configure cloud security groups separately.${NC}"
}

setup_service() {
    print_step 7 7 "Service Setup"

    echo "Install as systemd service?"
    read -p "(Y/n): " install_svc
    if [[ "$install_svc" =~ ^[Nn]$ ]]; then
        log_info "Skipped service installation"
        return
    fi

    DISK_FREE_GB=$(df -BG /mnt 2>/dev/null | awk 'NR==2 {print $4}' | tr -d 'G' || df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
    LEDGER_LIMIT=$((DISK_FREE_GB * 1000000 / 2))
    [[ $LEDGER_LIMIT -gt 50000000 ]] && LEDGER_LIMIT=50000000

    sudo tee /etc/systemd/system/x1-aether.service > /dev/null << EOF
[Unit]
Description=X1-Aether Non-Voting Verification Node
After=network.target

[Service]
Type=simple
User=$USER
Environment="RUST_LOG=solana_metrics=warn,info"
WorkingDirectory=$DATA_DIR

ExecStart=$INSTALL_DIR/bin/x1-aether \\
    --identity $CONFIG_DIR/identity.json \\
    --ledger $DATA_DIR/ledger \\
    --entrypoint entrypoint0.mainnet.x1.xyz:8001 \\
    --entrypoint entrypoint1.mainnet.x1.xyz:8001 \\
    --entrypoint entrypoint2.mainnet.x1.xyz:8001 \\
    --known-validator 7ufaUVtQKzGu5tpFtii9Cg8kR4jcpjQSXwsF3oVPSMZA \\
    --known-validator 5Rzytnub9yGTFHqSmauFLsAbdXFbehMwPBLiuEgKajUN \\
    --known-validator 4V2QkkWce8bwTzvvwPiNRNQ4W433ZsGQi9aWU12Q8uBF \\
    --known-validator CkMwg4TM6jaSC5rJALQjvLc51XFY5pJ1H9f1Tmu5Qdxs \\
    --known-validator 7J5wJaH55ZYjCCmCMt7Gb3QL6FGFmjz5U8b6NcbzfoTy \\
    --only-known-rpc \\
    --no-voting \\
    --private-rpc \\
    --rpc-port 8899 \\
    --dynamic-port-range 8000-8020 \\
    --wal-recovery-mode skip_any_corrupted_record \\
    --limit-ledger-size $LEDGER_LIMIT \\
    --log $DATA_DIR/aether.log

Restart=on-failure
RestartSec=30
LimitNOFILE=500000

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    log_success "Service installed"

    read -p "Enable auto-start on boot? (Y/n): " autostart
    if [[ ! "$autostart" =~ ^[Nn]$ ]]; then
        sudo systemctl enable x1-aether
        AUTOSTART_ENABLED="true"
        log_success "Auto-start enabled"
    else
        AUTOSTART_ENABLED="false"
    fi

    read -p "Enable auto-updates? (y/N): " autoupdate
    if [[ "$autoupdate" =~ ^[Yy]$ ]]; then
        AUTOUPDATE_ENABLED="true"
        install_autoupdater
        log_success "Auto-updates enabled"
    else
        AUTOUPDATE_ENABLED="false"
    fi

    save_settings
}

print_completion() {
    clear
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   X1-Aether Installation Complete!                        ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}SAVE THIS INFORMATION:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  Identity Pubkey: $(solana-keygen pubkey $CONFIG_DIR/identity.json 2>/dev/null)"
    echo "  Identity File:   $CONFIG_DIR/identity.json"
    echo ""
    echo -e "${DIM}  Copy this information and store it somewhere safe.${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}COMMANDS (run from anywhere):${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  x1-aether start     Start the node"
    echo "  x1-aether stop      Stop the node"
    echo "  x1-aether logs      View live logs"
    echo "  x1-aether status    Check service status"
    echo "  x1-aether catchup   Check sync progress"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}CONFIGURATION:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  To change settings later, run: ${BOLD}x1-aether-config${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}UNINSTALL:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${DIM}  To completely remove X1-Aether:${NC}"
    echo -e "${DIM}  sudo systemctl stop x1-aether && sudo systemctl disable x1-aether${NC}"
    echo -e "${DIM}  sudo rm -rf /opt/x1-aether /mnt/x1-aether /etc/systemd/system/x1-aether.service${NC}"
    echo -e "${DIM}  sudo rm /usr/local/bin/x1-aether /usr/local/bin/x1-aether-config${NC}"
    echo -e "${DIM}  rm -rf ~/.config/x1-aether${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}To start your node now:  x1-aether start${NC}"
    echo ""
    echo -e "${DIM}This node does NOT vote or earn rewards.${NC}"
    echo ""
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${DIM}You are solely responsible for securing your private keys.${NC}"
    echo -e "${DIM}We do not store, manage, or have access to your keys.${NC}"
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════

main() {
    if [[ "$1" == "--config" ]] || [[ "$1" == "config" ]]; then
        show_config_menu
        exit 0
    fi

    # Ensure we can read from terminal even when piped
    exec < /dev/tty

    print_banner
    print_overview

    read -p "Ready to begin? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        exit 0
    fi

    check_requirements
    install_dependencies
    setup_identity
    setup_node_identity
    build_node
    configure_firewall
    setup_service
    print_completion
}

main "$@"
