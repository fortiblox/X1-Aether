#!/bin/bash
# X1-Aether Installer
# Lightweight Verification Node for X1 Blockchain
#
# Usage: curl -sSfL https://raw.githubusercontent.com/fortiblox/X1-Aether/main/install.sh | bash
#
# This script will:
# 1. Check system requirements
# 2. Install Go and dependencies
# 3. Build X1-Aether from source
# 4. Configure and start the verifier

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
AETHER_VERSION="1.0.0"
AETHER_REPO="fortiblox/X1-Aether"
UPSTREAM_REPO="Overclock-Validator/mithril"
INSTALL_DIR="/opt/x1-aether"
CONFIG_DIR="$HOME/.config/x1-aether"
DATA_DIR="/mnt/x1-aether"
BIN_DIR="/usr/local/bin"
GO_VERSION="1.23.0"

# X1 Mainnet RPC endpoint
RPC_ENDPOINTS=(
    "https://rpc.mainnet.x1.xyz"
)

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Print banner
print_banner() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}                                                           ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}   ${GREEN}X1-Aether${NC} - Verification Node for X1 Blockchain      ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}   Version: ${AETHER_VERSION}                                         ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}                                                           ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Note: X1-Aether verifies the chain but does NOT vote or earn rewards.${NC}"
    echo -e "${YELLOW}For staking rewards, use X1-Forge instead.${NC}"
    echo ""
}

# Detect system
detect_system() {
    log_info "Detecting system specifications..."

    OS=$(uname -s)
    ARCH=$(uname -m)

    if [[ "$OS" != "Linux" ]]; then
        log_error "X1-Aether only supports Linux. Detected: $OS"
        exit 1
    fi

    CPU_CORES=$(nproc)
    RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    RAM_GB=$((RAM_KB / 1024 / 1024))
    DISK_FREE_GB=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')

    echo ""
    echo "System Specifications:"
    echo "  OS:        $OS ($ARCH)"
    echo "  CPU:       $CPU_CORES cores"
    echo "  RAM:       ${RAM_GB}GB"
    echo "  Disk Free: ${DISK_FREE_GB}GB"
    echo ""
}

# Check requirements (much lower than X1-Forge)
check_requirements() {
    log_info "Checking minimum requirements..."

    local errors=0

    # Check RAM (minimum 8GB for Aether)
    if [[ $RAM_GB -lt 7 ]]; then
        log_error "Insufficient RAM: ${RAM_GB}GB (minimum 8GB required)"
        errors=$((errors + 1))
    else
        log_success "RAM: ${RAM_GB}GB"
    fi

    # Check CPU (minimum 4 cores)
    if [[ $CPU_CORES -lt 4 ]]; then
        log_error "Insufficient CPU: ${CPU_CORES} cores (minimum 4 required)"
        errors=$((errors + 1))
    else
        log_success "CPU: ${CPU_CORES} cores"
    fi

    # Check disk (minimum 500GB)
    if [[ $DISK_FREE_GB -lt 500 ]]; then
        log_warn "Low disk space: ${DISK_FREE_GB}GB (1TB+ recommended)"
    else
        log_success "Disk: ${DISK_FREE_GB}GB free"
    fi

    if [[ $errors -gt 0 ]]; then
        log_error "System does not meet minimum requirements"
        exit 1
    fi

    log_success "All requirements met!"
}

# Install Go
install_go() {
    if command -v go &>/dev/null; then
        GO_INSTALLED=$(go version | grep -oP 'go\d+\.\d+' | head -1)
        log_success "Go already installed: $GO_INSTALLED"
        return
    fi

    log_info "Installing Go $GO_VERSION..."

    local GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"
    cd /tmp
    wget -q "https://go.dev/dl/$GO_TARBALL"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "$GO_TARBALL"
    rm "$GO_TARBALL"

    # Add to PATH
    export PATH=$PATH:/usr/local/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.bashrc"
    echo 'export PATH=$PATH:$HOME/go/bin' >> "$HOME/.bashrc"

    log_success "Go $GO_VERSION installed"
}

# Install dependencies
install_dependencies() {
    log_info "Installing system dependencies..."

    if command -v apt-get &>/dev/null; then
        sudo apt-get update
        sudo apt-get install -y \
            build-essential \
            git \
            curl \
            wget \
            jq \
            libzstd-dev \
            pkg-config
    elif command -v yum &>/dev/null; then
        sudo yum install -y \
            gcc \
            gcc-c++ \
            make \
            git \
            curl \
            wget \
            jq \
            libzstd-devel \
            pkgconfig
    fi

    log_success "Dependencies installed"
}

# Create directories
create_directories() {
    log_info "Creating directory structure..."

    sudo mkdir -p "$INSTALL_DIR"/{bin,lib}
    mkdir -p "$CONFIG_DIR"
    sudo mkdir -p "$DATA_DIR"/{data,accountsdb}

    if [[ $EUID -ne 0 ]]; then
        sudo chown -R "$USER:$USER" "$DATA_DIR"
    fi

    log_success "Directories created"
}

# Build X1-Aether from source
build_aether() {
    log_info "Building X1-Aether from source..."
    log_warn "This will take 5-10 minutes..."

    cd /tmp
    rm -rf aether-build

    # Clone upstream
    git clone --depth 1 https://github.com/$UPSTREAM_REPO.git aether-build
    cd aether-build

    # Build with optimizations
    export CGO_ENABLED=1
    export GOAMD64=v3

    go build -ldflags="-s -w" -o x1-aether ./cmd/mithril

    # Install binary
    sudo cp x1-aether "$INSTALL_DIR/bin/"
    sudo chmod +x "$INSTALL_DIR/bin/x1-aether"

    # Cleanup
    cd /
    rm -rf /tmp/aether-build

    log_success "X1-Aether built successfully"
}

# Create CLI wrapper
create_wrapper() {
    log_info "Creating CLI wrapper..."

    sudo tee "$BIN_DIR/x1-aether" > /dev/null << 'WRAPPER'
#!/bin/bash
# X1-Aether CLI wrapper

INSTALL_DIR="/opt/x1-aether"
CONFIG_DIR="$HOME/.config/x1-aether"

case "$1" in
    start)
        sudo systemctl start x1-aether
        ;;
    stop)
        sudo systemctl stop x1-aether
        ;;
    restart)
        sudo systemctl restart x1-aether
        ;;
    status)
        if systemctl is-active --quiet x1-aether; then
            echo "X1-Aether: Running"
            # Show current slot if available
            if [[ -f "$CONFIG_DIR/status.json" ]]; then
                cat "$CONFIG_DIR/status.json" | jq .
            fi
        else
            echo "X1-Aether: Stopped"
        fi
        ;;
    logs)
        journalctl -u x1-aether -f
        ;;
    update)
        shift
        $INSTALL_DIR/bin/x1-aether-update "$@"
        ;;
    rollback)
        $INSTALL_DIR/bin/x1-aether-rollback
        ;;
    run)
        # Direct run (for debugging)
        shift
        $INSTALL_DIR/bin/x1-aether "$@"
        ;;
    *)
        echo "X1-Aether - Verification Node for X1"
        echo ""
        echo "Usage: x1-aether <command>"
        echo ""
        echo "Commands:"
        echo "  start      Start the verifier"
        echo "  stop       Stop the verifier"
        echo "  restart    Restart the verifier"
        echo "  status     Show verifier status"
        echo "  logs       Follow verifier logs"
        echo "  update     Check for and apply updates"
        echo "  rollback   Rollback to previous version"
        echo "  run        Run directly (for debugging)"
        ;;
esac
WRAPPER
    sudo chmod +x "$BIN_DIR/x1-aether"

    log_success "CLI wrapper created"
}

# Generate configuration
generate_config() {
    log_info "Generating configuration..."

    # Calculate optimal settings
    local TXPAR=$((CPU_CORES * 2))
    if [[ $TXPAR -gt 32 ]]; then
        TXPAR=32
    fi

    cat > "$CONFIG_DIR/config.toml" << EOF
# X1-Aether Configuration
# Generated: $(date -u +'%Y-%m-%dT%H:%M:%SZ')
# Hardware: ${CPU_CORES} cores, ${RAM_GB}GB RAM

[network]
cluster = "mainnet"

[rpc]
# X1 Mainnet RPC endpoint
endpoint = "https://rpc.mainnet.x1.xyz"
timeout = 30
retry_attempts = 3

[paths]
data = "$DATA_DIR/data"
accountsdb = "$DATA_DIR/accountsdb"

[replay]
# Transaction parallelism (auto-tuned for $CPU_CORES cores)
txpar = $TXPAR

[tuning]
# Optimized for ${RAM_GB}GB RAM
zstd_decoder_concurrency = $((CPU_CORES / 2))
flusher_limit = 50
arena_size = "128MB"
EOF

    log_success "Configuration saved to $CONFIG_DIR/config.toml"
}

# Install systemd service
install_systemd_service() {
    log_info "Installing systemd service..."

    sudo tee /etc/systemd/system/x1-aether.service > /dev/null << EOF
[Unit]
Description=X1-Aether Verification Node
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=$USER
Environment="PATH=/usr/local/go/bin:$HOME/go/bin:/usr/local/bin:/usr/bin"
Environment="GOGC=100"
Environment="GOMEMLIMIT=${RAM_GB}GiB"
WorkingDirectory=$DATA_DIR

ExecStart=$INSTALL_DIR/bin/x1-aether run \\
    --config $CONFIG_DIR/config.toml

# Resource limits (lightweight)
MemoryMax=${RAM_GB}G
CPUQuota=80%
LimitNOFILE=100000

# Restart behavior
Restart=on-failure
RestartSec=30
TimeoutStartSec=300

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=x1-aether

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable x1-aether

    log_success "Systemd service installed"
}

# Print completion
print_completion() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}                                                           ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   ${GREEN}X1-Aether Installation Complete!${NC}                       ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                                           ${GREEN}║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Configuration: $CONFIG_DIR/config.toml"
    echo "Data directory: $DATA_DIR"
    echo ""
    echo "Next steps:"
    echo ""
    echo "  1. Start the verifier"
    echo "     sudo systemctl start x1-aether"
    echo ""
    echo "  2. Monitor progress"
    echo "     journalctl -u x1-aether -f"
    echo ""
    echo "Commands:"
    echo "  x1-aether start    - Start verifier"
    echo "  x1-aether stop     - Stop verifier"
    echo "  x1-aether status   - Check status"
    echo "  x1-aether logs     - View logs"
    echo "  x1-aether update   - Check for updates"
    echo ""
    echo -e "${YELLOW}Note: Initial sync may take several hours depending on your hardware.${NC}"
    echo ""
}

# Main
main() {
    print_banner

    detect_system
    check_requirements

    echo ""
    read -p "Proceed with installation? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log_info "Installation cancelled"
        exit 0
    fi

    install_dependencies
    install_go
    create_directories
    build_aether
    create_wrapper
    generate_config
    install_systemd_service

    print_completion
}

main "$@"
