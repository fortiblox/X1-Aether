# X1-Aether

**Non-Voting Verification Node for X1 Blockchain**

X1-Aether lets you verify the X1 blockchain independently without participating in consensus or earning rewards. It runs the Tachyon validator in non-voting mode on minimal hardware.

## What Does X1-Aether Do?

- Downloads and verifies every block on the X1 network
- Confirms the blockchain state is valid
- Does NOT vote on blocks
- Does NOT earn staking rewards

**Want to earn rewards?** Use [X1-Forge](https://github.com/fortiblox/X1-Forge) instead.

## Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 4 cores | 8 cores |
| RAM | 8 GB | 16 GB |
| Storage | 500 GB NVMe | 1 TB NVMe |
| Network | 50 Mbps | 100 Mbps |
| OS | Ubuntu 22.04+ | Ubuntu 24.04 |

## Quick Install

```bash
curl -sSfL https://raw.githubusercontent.com/fortiblox/X1-Aether/main/install.sh | bash
```

The installer will:
1. Install Rust and dependencies
2. Build from Tachyon source (x1-labs/tachyon)
3. Generate node identity
4. Configure systemd service with `--no-voting` mode

## Commands

```bash
# Start verification node
sudo systemctl start x1-aether

# Check status
x1-aether status

# View logs
x1-aether logs

# Check sync progress
x1-aether catchup
```

## How It Works

X1-Aether runs the same Tachyon validator software as voting validators, but with the `--no-voting` flag. This means:

- It syncs the full blockchain
- It validates all transactions
- It does NOT submit votes
- It uses less resources than a voting validator

## Comparison: X1-Aether vs X1-Forge

| Feature | X1-Aether | X1-Forge |
|---------|-----------|----------|
| Purpose | Verify chain | Vote & earn rewards |
| RAM Required | 8 GB | 64 GB |
| Earns Rewards | No | Yes |
| Votes | No | Yes |
| `--no-voting` | Yes | No |

## Use Cases

- **Personal verification**: Trustlessly verify the blockchain
- **Development**: Test against verified chain state
- **Research**: Study blockchain data
- **Learning**: Understand how Solana-style validators work

## License

Apache 2.0
