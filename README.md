# X1-Aether

**Lightweight Verification Node for X1 Blockchain**

X1-Aether is a non-voting verification node that independently verifies the X1 blockchain on minimal hardware. Based on [Overclock's Mithril](https://github.com/Overclock-Validator/mithril), adapted for X1.

## What is X1-Aether?

X1-Aether downloads blocks from the X1 network and replays them locally to verify the blockchain state. It's like having your own "blockchain auditor" - you can independently confirm that the chain is valid without trusting anyone.

**Important:** X1-Aether does NOT:
- Participate in consensus
- Vote on blocks
- Earn staking rewards

If you want to stake and earn rewards, use [X1-Forge](https://github.com/fortiblox/X1-Forge) instead.

## Features

- **Lightweight**: Runs on 8GB RAM, 6 CPU cores
- **Independent**: Verify the chain without trusting validators
- **Simple**: One-command install, auto-configuration
- **Efficient**: Written in Go for optimal performance

## Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 6 cores, 3.0 GHz | 12 cores, 3.5 GHz |
| RAM | 8 GB | 16 GB |
| Storage | 1 TB NVMe | 2 TB NVMe |
| Network | 50 Mbps | 100 Mbps |
| OS | Ubuntu 22.04+ | Ubuntu 24.04 |
| Go | 1.23+ | 1.23+ |

## Quick Install

```bash
curl -sSfL https://raw.githubusercontent.com/fortiblox/X1-Aether/main/install.sh | bash
```

## What Gets Installed

- X1-Aether binary (Go-based verifier)
- Systemd service (`x1-aether.service`)
- Auto-tuned configuration
- Snapshot bootstrap automation

## Commands

```bash
# Check status
sudo systemctl status x1-aether

# View logs
journalctl -u x1-aether -f

# Check verification status
x1-aether status

# Check for updates
x1-aether update --check

# Perform upgrade
x1-aether update
```

## Configuration

Config file: `~/.config/x1-aether/config.toml`

```toml
[network]
cluster = "mainnet"

[rpc]
# X1 Mainnet RPC endpoint
endpoint = "https://rpc.mainnet.x1.xyz"

[paths]
data = "/mnt/x1-aether/data"
accountsdb = "/mnt/x1-aether/accountsdb"

[performance]
# Auto-tuned based on your hardware
txpar = 12  # Transaction parallelism
zstd_decoder_concurrency = 4
```

## How It Works

```
┌─────────────────────────────────────────────────────────┐
│                    X1 Network                            │
│   (Validators producing and voting on blocks)           │
└─────────────────────┬───────────────────────────────────┘
                      │
                      │ getBlock RPC calls
                      ▼
┌─────────────────────────────────────────────────────────┐
│                   X1-Aether                              │
│                                                          │
│   1. Fetches confirmed blocks from RPC                  │
│   2. Replays transactions locally                       │
│   3. Verifies state matches network                     │
│   4. Maintains independent AccountsDB                   │
│                                                          │
│   Result: Cryptographic proof chain is valid            │
└─────────────────────────────────────────────────────────┘
```

## Comparison: X1-Aether vs X1-Forge

| Feature | X1-Aether | X1-Forge |
|---------|-----------|----------|
| Purpose | Verify chain | Vote & earn |
| RAM Required | 8 GB | 64 GB |
| Earns Rewards | No | Yes |
| Votes | No | Yes |
| Consensus | No | Yes |
| Trust Model | Trustless verification | Network participant |

## Use Cases

- **Personal verification**: Confirm chain validity yourself
- **Research**: Study blockchain state and history
- **Development**: Test against verified state
- **Auditing**: Independent chain verification
- **Education**: Learn how Solana-style chains work

## Upgrading

X1-Aether tracks upstream Mithril releases:

```bash
# Check available updates
x1-aether update --check

# Upgrade
x1-aether update

# Rollback if issues
x1-aether rollback
```

## Troubleshooting

### Node not syncing
```bash
# Check RPC connectivity
curl -s https://rpc.mainnet.x1.xyz/health

# Check logs
journalctl -u x1-aether -n 100
```

### High memory usage
```bash
# Check current usage
x1-aether status

# Restart with fresh state
sudo systemctl restart x1-aether
```

## Support

- Issues: https://github.com/fortiblox/X1-Aether/issues
- Mithril upstream: https://github.com/Overclock-Validator/mithril

## License

Apache 2.0

## Credits

Based on [Overclock's Mithril](https://github.com/Overclock-Validator/mithril), adapted for X1 blockchain.
