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



