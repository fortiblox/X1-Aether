# X1-Aether

**The Silent Observer of the X1 Network**

In ancient philosophy, *Aether* was the pure essence that filled the universe—the medium through which light itself traveled. X1-Aether embodies this concept: an invisible, ever-present witness to every transaction on the X1 blockchain.

X1-Aether nodes silently observe and verify the network without participating in consensus. They ask for nothing in return—no votes, no rewards—just the quiet certainty that the chain remains true.

## What Does X1-Aether Do?

- **Watches everything** — Downloads and verifies every block on the X1 network
- **Trusts nothing** — Independently confirms the blockchain state is valid
- **Stays silent** — Does NOT vote on blocks or influence consensus
- **Asks nothing** — Does NOT earn staking rewards

*Aether nodes are the unseen guardians. They verify truth without seeking recognition.*

**Want to actively participate and earn rewards?** Use [X1-Forge](https://github.com/fortiblox/X1-Forge) to become a voting validator.

## Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 4 cores | 8 cores |
| RAM | 8 GB | 16 GB |
| Storage | 500 GB NVMe | 1 TB NVMe |
| Network | 50 Mbps | 100 Mbps |
| OS | Ubuntu 22.04+ | Ubuntu 24.04 |

**Additional requirements:**
- Linux only (Ubuntu/Debian or RHEL/CentOS)
- `sudo` access (root privileges needed for installation)
- Open ports: 8000-8020 (gossip), 8899 (RPC)
- Writable `/mnt` directory (or change data location)

## Installation

### Step 1: Run the Installer

```bash
curl -sSfL https://raw.githubusercontent.com/fortiblox/X1-Aether/main/install.sh | bash
```

The installer will:
1. Check your system meets requirements (RAM, CPU, disk)
2. Install build tools, Rust, and Solana CLI
3. Generate or import your node identity
4. Optionally set node branding (name, website, icon)
5. Build the node from source (~15-30 minutes)
6. Configure firewall ports automatically
7. Optionally install as systemd service

**Note:** The node does NOT start automatically after installation.

### Step 2: Start the Node

```bash
sudo systemctl start x1-aether
```

### Step 3: Monitor Sync Progress

```bash
# Watch the logs
x1-aether logs

# Check sync status
x1-aether catchup
```

Initial sync takes **several hours** depending on network speed.

## Commands

| Command | Description |
|---------|-------------|
| `x1-aether start` | Start the verification node |
| `x1-aether stop` | Stop the node |
| `x1-aether restart` | Restart the node |
| `x1-aether status` | Show service status |
| `x1-aether logs` | Follow live logs |
| `x1-aether catchup` | Show sync progress |
| `x1-aether-config` | Open configuration menu |

## Configuration

After installation, run `x1-aether-config` to access the configuration menu:

- **Identity Management** — View, import, or generate node identity
- **Node Branding** — Set name, website, and icon URL (published on-chain)
- **Auto-Start** — Toggle automatic startup on boot
- **Auto-Update** — Enable daily automatic updates from the repository
- **Rebuild Binary** — Recompile from latest source

## File Locations

| Path | Description |
|------|-------------|
| `/opt/x1-aether/bin/x1-aether` | Validator binary |
| `~/.config/x1-aether/identity.json` | Node identity keypair |
| `/mnt/x1-aether/ledger/` | Blockchain data |
| `/mnt/x1-aether/aether.log` | Log file |

## Troubleshooting

### Build fails with "out of memory"

The build needs ~4GB RAM free. Add swap if needed:

```bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
# Re-run installer
```

### Node won't start

```bash
x1-aether status
journalctl -u x1-aether -n 50
```

Common causes: port conflict (8000-8020, 8899), permission issues, missing identity file.

### Sync is stuck

1. Check network connectivity
2. Verify firewall allows ports 8000-8020
3. Check disk space: `df -h /mnt`
4. Restart: `x1-aether restart`

### How do I know it's working?

Once synced, `x1-aether catchup` shows you're close to network tip. Or query local RPC:

```bash
curl -s http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getSlot"}'
```

## How It Works

X1-Aether runs the same Tachyon validator as voting validators, but with `--no-voting`. It syncs and validates everything but doesn't submit votes.

## Aether vs Forge: Choose Your Role

| | X1-Aether | X1-Forge |
|---------|-----------|----------|
| **Role** | Silent Observer | Active Validator |
| **Purpose** | Verify the chain independently | Vote on blocks & earn rewards |
| **RAM Required** | 8 GB | 64 GB |
| **Earns Rewards** | No | Yes |
| **Participates in Consensus** | No | Yes |

*Aether watches. Forge decides. Both strengthen the network.*

## Uninstalling

```bash
sudo systemctl stop x1-aether
sudo systemctl disable x1-aether
sudo rm /etc/systemd/system/x1-aether.service
sudo rm -rf /opt/x1-aether /mnt/x1-aether
sudo rm /usr/local/bin/x1-aether
rm -rf ~/.config/x1-aether
sudo systemctl daemon-reload
```

## License

Apache 2.0
