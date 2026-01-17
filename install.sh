#!/bin/bash
# X1-Aether Installer
# Lightweight Non-Voting Verification Node for X1 Blockchain
#
# Usage: curl -sSfL https://raw.githubusercontent.com/fortiblox/X1-Aether/main/install.sh | bash
#
# X1-Aether runs the Tachyon validator in non-voting mode to verify
# the blockchain without participating in consensus or earning rewards.

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
    echo "  3. Generate or import your node identity keypair"
    echo "  4. Build the validator from source (compiles Tachyon)"
    echo "  5. Configure firewall ports (8000-8020, 8899)"
    echo "  6. Install systemd service for auto-start"
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
}

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

# ============================================================================
# STEP 1: System Requirements Check
# ============================================================================
check_requirements() {
    print_step 1 6 "Checking System Requirements"

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

    # RAM Check (8GB minimum for non-voting)
    if [[ $RAM_GB -ge 16 ]]; then
        log_success "RAM: ${RAM_GB}GB (recommended: 16GB+)"
    elif [[ $RAM_GB -ge 7 ]]; then
        log_warn "RAM: ${RAM_GB}GB (minimum met, 16GB recommended)"
        warnings=$((warnings + 1))
    else
        log_error "RAM: ${RAM_GB}GB (minimum 8GB required)"
        errors=$((errors + 1))
    fi

    # CPU Check (4 cores minimum)
    if [[ $CPU_CORES -ge 8 ]]; then
        log_success "CPU: ${CPU_CORES} cores (recommended: 8+)"
    elif [[ $CPU_CORES -ge 4 ]]; then
        log_warn "CPU: ${CPU_CORES} cores (minimum met, 8 recommended)"
        warnings=$((warnings + 1))
    else
        log_error "CPU: ${CPU_CORES} cores (minimum 4 required)"
        errors=$((errors + 1))
    fi

    # Disk Check (500GB minimum)
    if [[ $DISK_FREE_GB -ge 1000 ]]; then
        log_success "Disk: ${DISK_FREE_GB}GB free (recommended: 1TB+)"
    elif [[ $DISK_FREE_GB -ge 500 ]]; then
        log_warn "Disk: ${DISK_FREE_GB}GB free (minimum met, 1TB recommended)"
        warnings=$((warnings + 1))
    else
        log_error "Disk: ${DISK_FREE_GB}GB free (minimum 500GB required)"
        errors=$((errors + 1))
    fi

    # Network ports check
    if command -v ss &>/dev/null; then
        if ss -tuln | grep -q ':8899 '; then
            log_warn "Port 8899 already in use"
            warnings=$((warnings + 1))
        else
            log_success "Port 8899: Available"
        fi
    else
        log_success "Port check: Skipped (ss not available)"
    fi

    echo ""

    if [[ $errors -gt 0 ]]; then
        echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  System does not meet minimum requirements                ║${NC}"
        echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "X1-Aether requires: 8GB RAM, 4 CPU cores, 500GB disk"
        exit 1
    elif [[ $warnings -gt 0 ]]; then
        echo -e "${YELLOW}System meets minimum requirements with $warnings warning(s)${NC}"
    else
        echo -e "${GREEN}System meets all recommended requirements${NC}"
    fi
}

# ============================================================================
# STEP 2: Install Dependencies
# ============================================================================
install_dependencies() {
    print_step 2 6 "Installing Dependencies"

    log_info "Installing system packages..."

    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq
        sudo apt-get install -y -qq \
            build-essential \
            pkg-config \
            libssl-dev \
            libudev-dev \
            libclang-dev \
            protobuf-compiler \
            curl \
            wget \
            git \
            jq \
            zstd
    elif command -v yum &>/dev/null; then
        sudo yum install -y \
            gcc gcc-c++ make \
            pkgconfig openssl-devel systemd-devel clang \
            protobuf-compiler curl wget git jq zstd
    else
        log_error "Unsupported package manager. Install dependencies manually."
        exit 1
    fi

    log_success "System packages installed"

    # Install Rust
    if command -v rustc &>/dev/null; then
        log_success "Rust already installed: $(rustc --version)"
    else
        log_info "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        log_success "Rust installed"
    fi

    # Install Solana CLI (for keygen)
    if command -v solana-keygen &>/dev/null; then
        log_success "Solana CLI already installed"
    else
        log_info "Installing Solana CLI..."
        sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"
        export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
        log_success "Solana CLI installed"
    fi
}

# ============================================================================
# STEP 3: Setup Identity
# ============================================================================
setup_identity() {
    print_step 3 6 "Node Identity Setup"

    mkdir -p "$CONFIG_DIR"
    IDENTITY_PATH="$CONFIG_DIR/identity.json"

    # Check for existing identity
    if [[ -f "$IDENTITY_PATH" ]]; then
        EXISTING_PUBKEY=$(solana-keygen pubkey "$IDENTITY_PATH" 2>/dev/null || echo "unknown")
        echo "Existing identity found: $EXISTING_PUBKEY"
        echo ""
        echo "What would you like to do?"
        echo ""
        echo "  1) Keep existing identity"
        echo "  2) Import identity from another file"
        echo "  3) Import identity from private key bytes"
        echo "  4) Generate new identity (overwrites existing)"
        echo ""
        read -p "Select option [1-4]: " identity_choice
    else
        echo "No existing identity found."
        echo ""
        echo "What would you like to do?"
        echo ""
        echo "  1) Generate new identity"
        echo "  2) Import identity from another file"
        echo "  3) Import identity from private key bytes"
        echo ""
        read -p "Select option [1-3]: " identity_choice

        # Remap choices for no-existing-identity case
        case $identity_choice in
            1) identity_choice=4 ;;  # Generate new
            2) identity_choice=2 ;;  # Import file
            3) identity_choice=3 ;;  # Import bytes
        esac
    fi

    case $identity_choice in
        1)
            log_success "Keeping existing identity: $EXISTING_PUBKEY"
            ;;
        2)
            echo ""
            read -p "Enter path to identity.json file: " import_path
            import_path="${import_path/#\~/$HOME}"

            if [[ ! -f "$import_path" ]]; then
                log_error "File not found: $import_path"
                exit 1
            fi

            # Validate it's a valid keypair
            if solana-keygen pubkey "$import_path" &>/dev/null; then
                cp "$import_path" "$IDENTITY_PATH"
                chmod 600 "$IDENTITY_PATH"
                log_success "Identity imported: $(solana-keygen pubkey $IDENTITY_PATH)"
            else
                log_error "Invalid keypair file"
                exit 1
            fi
            ;;
        3)
            echo ""
            echo "Paste your private key bytes (JSON array format):"
            echo "Example: [123,45,67,...]"
            echo ""
            read -p "> " key_bytes

            echo "$key_bytes" > "$IDENTITY_PATH"
            chmod 600 "$IDENTITY_PATH"

            if solana-keygen pubkey "$IDENTITY_PATH" &>/dev/null; then
                log_success "Identity imported: $(solana-keygen pubkey $IDENTITY_PATH)"
            else
                log_error "Invalid private key bytes"
                rm -f "$IDENTITY_PATH"
                exit 1
            fi
            ;;
        4)
            if [[ -f "$IDENTITY_PATH" ]]; then
                # Backup existing
                mv "$IDENTITY_PATH" "$IDENTITY_PATH.backup.$(date +%s)"
                log_warn "Existing identity backed up"
            fi

            solana-keygen new -o "$IDENTITY_PATH" --no-passphrase --force
            chmod 600 "$IDENTITY_PATH"
            log_success "New identity generated: $(solana-keygen pubkey $IDENTITY_PATH)"
            ;;
        *)
            log_error "Invalid option"
            exit 1
            ;;
    esac

    echo ""
    echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  BACKUP YOUR IDENTITY FILE                                ║${NC}"
    echo -e "${YELLOW}╠═══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}║${NC}  Location: $CONFIG_DIR/identity.json"
    echo -e "${YELLOW}║${NC}  "
    echo -e "${YELLOW}║${NC}  Store a copy in secure offline storage."
    echo -e "${YELLOW}║${NC}  Loss of this file = loss of your node identity."
    echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    read -p "Press Enter to continue..."
}

# ============================================================================
# STEP 4: Build Validator
# ============================================================================
build_validator() {
    print_step 4 6 "Building X1-Aether"

    log_warn "Building from source. This takes 15-30 minutes..."
    echo ""

    # Create directories
    sudo mkdir -p "$INSTALL_DIR"/{bin,lib}
    sudo mkdir -p "$DATA_DIR"/ledger

    if [[ $EUID -ne 0 ]]; then
        sudo chown -R "$USER:$USER" "$DATA_DIR"
    fi

    cd /tmp
    rm -rf tachyon-build

    log_info "Cloning Tachyon repository..."
    git clone --depth 1 https://github.com/$TACHYON_REPO.git tachyon-build
    cd tachyon-build

    log_info "Compiling (this is the slow part)..."
    export RUSTFLAGS="-C target-cpu=native"
    cargo build --release -p tachyon-validator

    # Install binary
    sudo cp target/release/tachyon-validator "$INSTALL_DIR/bin/x1-aether"
    sudo chmod +x "$INSTALL_DIR/bin/x1-aether"

    # Cleanup
    cd /
    rm -rf /tmp/tachyon-build

    log_success "X1-Aether built successfully"
}

# ============================================================================
# STEP 5: Configure Firewall
# ============================================================================
configure_firewall() {
    print_step 5 6 "Configuring Firewall"

    log_info "Opening required ports..."
    echo ""
    echo "Required ports:"
    echo "  - 8000-8020 (UDP/TCP): Gossip and data transfer"
    echo "  - 8899 (TCP): RPC (local only)"
    echo ""

    # Detect and configure firewall
    if command -v ufw &>/dev/null && sudo ufw status | grep -q "Status: active"; then
        log_info "Detected UFW firewall, configuring..."
        sudo ufw allow 8000:8020/tcp >/dev/null 2>&1
        sudo ufw allow 8000:8020/udp >/dev/null 2>&1
        sudo ufw allow 8899/tcp >/dev/null 2>&1
        log_success "UFW rules added"

    elif command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld; then
        log_info "Detected firewalld, configuring..."
        sudo firewall-cmd --permanent --add-port=8000-8020/tcp >/dev/null 2>&1
        sudo firewall-cmd --permanent --add-port=8000-8020/udp >/dev/null 2>&1
        sudo firewall-cmd --permanent --add-port=8899/tcp >/dev/null 2>&1
        sudo firewall-cmd --reload >/dev/null 2>&1
        log_success "Firewalld rules added"

    elif command -v iptables &>/dev/null; then
        log_info "Configuring iptables..."
        sudo iptables -A INPUT -p tcp --dport 8000:8020 -j ACCEPT 2>/dev/null || true
        sudo iptables -A INPUT -p udp --dport 8000:8020 -j ACCEPT 2>/dev/null || true
        sudo iptables -A INPUT -p tcp --dport 8899 -j ACCEPT 2>/dev/null || true

        # Try to save rules
        if command -v netfilter-persistent &>/dev/null; then
            sudo netfilter-persistent save >/dev/null 2>&1 || true
        elif [[ -f /etc/sysconfig/iptables ]]; then
            sudo service iptables save >/dev/null 2>&1 || true
        fi
        log_success "iptables rules added"
    else
        log_warn "No firewall detected or firewall inactive"
        echo ""
        echo -e "${YELLOW}Please manually open these ports if you have a firewall:${NC}"
        echo "  - 8000-8020/tcp and 8000-8020/udp"
        echo "  - 8899/tcp"
    fi

    # Check cloud provider firewalls
    echo ""
    echo -e "${DIM}Note: If running on a cloud provider (AWS, GCP, Azure, etc.),${NC}"
    echo -e "${DIM}also configure the security group/firewall rules in your provider's console.${NC}"
}

# ============================================================================
# STEP 6: Configure and Install Service
# ============================================================================
install_service() {
    print_step 6 6 "Installing Service"

    # Create CLI wrapper
    log_info "Creating CLI wrapper..."

    sudo tee "$BIN_DIR/x1-aether" > /dev/null << 'WRAPPER'
#!/bin/bash
INSTALL_DIR="/opt/x1-aether"

case "$1" in
    start)   sudo systemctl start x1-aether ;;
    stop)    sudo systemctl stop x1-aether ;;
    restart) sudo systemctl restart x1-aether ;;
    status)  sudo systemctl status x1-aether ;;
    logs)    journalctl -u x1-aether -f ;;
    catchup) solana catchup --our-localhost ;;
    *)
        echo "X1-Aether - Non-Voting Verification Node"
        echo ""
        echo "Usage: x1-aether <command>"
        echo ""
        echo "Commands:"
        echo "  start    Start the verifier"
        echo "  stop     Stop the verifier"
        echo "  restart  Restart the verifier"
        echo "  status   Show status"
        echo "  logs     Follow logs"
        echo "  catchup  Show sync progress"
        ;;
esac
WRAPPER
    sudo chmod +x "$BIN_DIR/x1-aether"

    # Calculate ledger limit based on available disk
    DISK_FREE_GB=$(df -BG /mnt 2>/dev/null | awk 'NR==2 {print $4}' | tr -d 'G' || df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
    LEDGER_LIMIT=$((DISK_FREE_GB * 1000000 / 2))
    if [[ $LEDGER_LIMIT -gt 50000000 ]]; then
        LEDGER_LIMIT=50000000
    fi

    log_info "Installing systemd service..."

    sudo tee /etc/systemd/system/x1-aether.service > /dev/null << EOF
[Unit]
Description=X1-Aether Non-Voting Verification Node
After=network.target
Wants=network-online.target

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
    sudo systemctl enable x1-aether

    log_success "Service installed and enabled"
}

# ============================================================================
# Completion
# ============================================================================
print_completion() {
    IDENTITY_PUBKEY=$(solana-keygen pubkey "$CONFIG_DIR/identity.json" 2>/dev/null || echo "See config")

    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}║   ${BOLD}X1-Aether Installation Complete!${NC}                       ${GREEN}║${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Node Identity: $IDENTITY_PUBKEY"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Next Steps:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "1. Start the verification node:"
    echo "   sudo systemctl start x1-aether"
    echo ""
    echo "2. Monitor sync progress:"
    echo "   x1-aether logs      # Live logs"
    echo "   x1-aether catchup   # Sync status"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Note: Initial sync takes several hours.${NC}"
    echo -e "${YELLOW}This node does NOT vote or earn rewards.${NC}"
    echo -e "${YELLOW}For staking rewards, use X1-Forge instead.${NC}"
    echo ""
}

# ============================================================================
# Main
# ============================================================================
main() {
    print_banner
    print_overview

    read -p "Proceed with installation? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log_info "Installation cancelled"
        exit 0
    fi

    check_requirements
    install_dependencies
    setup_identity
    build_validator
    configure_firewall
    install_service
    print_completion
}

main "$@"
