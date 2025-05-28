# 🧠 PVZ Game — Solidity Learning Project

This project helps you master core Solidity techniques by building a turn-based game system.

### ✅ What You’re Practicing:

- `mapping` for on-chain game state
- `structs` to model plants, zombies, battles
- `modifiers` to restrict execution flow
- cooldown + frequency logic using `block.timestamp`
- custom `error` + `revert` usage instead of `require`
- gas-efficient storage layout (struct packing)
- event-driven state tracking for off-chain visibility

Built with [Foundry](https://book.getfoundry.sh/).

```bash
forge install
forge build
forge test
