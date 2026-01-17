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
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

print_banner() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}                                                           ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}   ${GREEN}X1-Aether${NC} - Verification Node for X1 Blockchain      ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}   Version: ${AETHER_VERSION}                                         ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}                                                           ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}X1-Aether verifies the blockchain but does NOT vote or earn rewards.${NC}"
    echo -e "${YELLOW}For staking rewards, use X1-Forge instead.${NC}"
    echo ""
}

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

check_requirements() {
    log_info "Checking minimum requirements..."

    local errors=0

    # Minimum 8GB RAM for non-voting mode
    if [[ $RAM_GB -lt 7 ]]; then
        log_error "Insufficient RAM: ${RAM_GB}GB (minimum 8GB required)"
        errors=$((errors + 1))
    else
        log_success "RAM: ${RAM_GB}GB"
    fi

    # Minimum 4 cores
    if [[ $CPU_CORES -lt 4 ]]; then
        log_error "Insufficient CPU: ${CPU_CORES} cores (minimum 4 required)"
        errors=$((errors + 1))
    else
        log_success "CPU: ${CPU_CORES} cores"
    fi

    # Minimum 500GB disk
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

install_dependencies() {
    log_info "Installing system dependencies..."

    if command -v apt-get &>/dev/null; then
        sudo apt-get update
        sudo apt-get install -y \
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
    fi

    log_success "Dependencies installed"
}

install_rust() {
    if command -v rustc &>/dev/null; then
        log_success "Rust already installed: $(rustc --version)"
    else
        log_info "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        log_success "Rust installed"
    fi
}

create_directories() {
    log_info "Creating directory structure..."

    sudo mkdir -p "$INSTALL_DIR"/{bin,lib}
    mkdir -p "$CONFIG_DIR"
    sudo mkdir -p "$DATA_DIR"/ledger

    if [[ $EUID -ne 0 ]]; then
        sudo chown -R "$USER:$USER" "$DATA_DIR"
    fi

    log_success "Directories created"
}

build_validator() {
    log_info "Building X1-Aether (Tachyon non-voting validator)..."
    log_warn "This will take 15-30 minutes on first build..."

    cd /tmp
    rm -rf tachyon-build

    git clone --depth 1 https://github.com/$TACHYON_REPO.git tachyon-build
    cd tachyon-build

    # Build with optimizations
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

generate_identity() {
    log_info "Generating node identity..."

    IDENTITY_PATH="$CONFIG_DIR/identity.json"

    if [[ -f "$IDENTITY_PATH" ]]; then
        log_warn "Identity already exists at $IDENTITY_PATH"
    else
        # Install solana CLI for keygen
        if ! command -v solana-keygen &>/dev/null; then
            sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"
            export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
        fi

        solana-keygen new -o "$IDENTITY_PATH" --no-passphrase --force
        chmod 600 "$IDENTITY_PATH"
        log_success "Identity generated: $(solana-keygen pubkey $IDENTITY_PATH)"
    fi
}

create_wrapper() {
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
    log_success "CLI wrapper created"
}

install_systemd_service() {
    log_info "Installing systemd service..."

    # Calculate ledger limit based on available disk
    LEDGER_LIMIT=$((DISK_FREE_GB * 1000000 / 2))
    if [[ $LEDGER_LIMIT -gt 50000000 ]]; then
        LEDGER_LIMIT=50000000
    fi

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

    log_success "Systemd service installed"
}

print_completion() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}   ${GREEN}X1-Aether Installation Complete!${NC}                       ${GREEN}║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Node Identity: $(solana-keygen pubkey $CONFIG_DIR/identity.json 2>/dev/null || echo 'Generated')"
    echo ""
    echo "Start the verifier:"
    echo "  sudo systemctl start x1-aether"
    echo ""
    echo "Monitor progress:"
    echo "  x1-aether logs"
    echo "  x1-aether catchup"
    echo ""
    echo -e "${YELLOW}Note: Initial sync takes several hours. This node does NOT earn rewards.${NC}"
    echo ""
}

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
    install_rust
    create_directories
    build_validator
    generate_identity
    create_wrapper
    install_systemd_service
    print_completion
}

main "$@"
