# RWA Stablecoin System

A reserve-backed stablecoin with an ERC-4626 vault that enforces supply constraints and enables yield via share-based accounting.

---

## Overview

This system is composed of four core components:

- **Reserve Oracle** — Reports total reserves backing the system  
- **Reserve Ledger** — Syncs and stores reserves on-chain, enforcing constraints  
- **Stablecoin (FiatStable)** — Mintable only up to reported reserves  
- **ERC-4626 Vault (YieldVault4626)** — Wraps the asset and tracks yield via share price  

Data flow:

Oracle → Ledger → Stablecoin → Vault

---

## Core Invariant

totalSupply <= reportedReserves


This ensures that every unit of the stablecoin is backed by verified reserves, preventing over-issuance and enforcing supply integrity.

---

## Vault Mechanics (ERC-4626)


shares = assets * totalSupply / totalAssets
assets = shares * totalAssets / totalSupply


Yield is represented by an increase in `totalAssets` without increasing `totalSupply`, causing share price to rise over time.

---

## Why This Matters

This system demonstrates how real-world assets can be:

- **Tokenized** → represented on-chain with verifiable backing  
- **Constrained** → supply tied to external reserve data  
- **Productive** → wrapped in a vault to generate yield  
- **Composable** → usable across DeFi (DEXs, lending, etc.)  

This is the foundation for bringing structured financial assets on-chain.

---

## Deployment

### Local (Anvil)

Start local node:
```bash
anvil

Deploy:

forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://127.0.0.1:8545 \
  --account deployer \
  --broadcast -vvvv
```
## Testnet (Fuji / Base Sepolia) 

Configured in foundry.toml:
```toml
[rpc_endpoints]
fuji = "https://api.avax-test.network/ext/bc/C/rpc"
base_sepolia = "https://sepolia.base.org"
```
## Deploy:

```bash
forge script script/Deploy.s.sol:Deploy \
  --rpc-url <network> \
  --account deployer \
  --broadcast -vvvv
```
## Verification

Check vault underlying asset:

```bash
cast call <VAULT_ADDRESS> "asset()(address)" --rpc-url <network>
```
Check reported reserves:
```bash
cast call <LEDGER_ADDRESS> "reportedReserves()(uint256)" --rpc-url <network>
```
Expected output:

Vault correctly references stablecoin
Ledger reflects initialized reserves

## Key Concepts Demonstrated

Reserve-backed minting constraints
Oracle → ledger synchronization pattern
ERC-4626 share-based accounting
Yield via asset growth (not supply inflation)
Multi-network deployment with Foundry
Secure key management via keystore

## Tech Stack

Solidity (0.8.x)
Foundry (forge, cast, anvil)
OpenZeppelin (ERC20, AccessControl, ERC4626)


## Next Steps

Integrate real oracle feeds (e.g. Chainlink)
Add strategy logic for vault yield generation
Introduce multisig / governance controls
Conduct security review and invariant fuzz testing
License

MIT

