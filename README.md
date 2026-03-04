# GavCoin Bytecode Verification

Attempting to reproduce the exact bytecode of the GavCoin contract deployed to Ethereum mainnet on April 26, 2016.

**Contract:** [`0xb4abc1bfc403a7b82c777420c81269858a4b8aa4`](https://etherscan.io/address/0xb4abc1bfc403a7b82c777420c81269858a4b8aa4)  
**Block:** 1,408,600  
**Creation TX:** [`0xa16cdc8579cfab8f14b5ee62c1454d6bab52e5a21aa79f2f95b0ebe2704bddd1`](https://etherscan.io/tx/0xa16cdc8579cfab8f14b5ee62c1454d6bab52e5a21aa79f2f95b0ebe2704bddd1)

## The Problem

The GavCoin source uses a `#require` preprocessor directive that was part of early Ethereum tooling (Mix IDE / Mist browser). This system inlined standard library contracts (`named`, `owned`, `coin`) before passing the source to `solc`. The preprocessor no longer exists, so we need to manually reconstruct the flattened source and find the exact compiler version + settings to reproduce the on-chain bytecode.

## Source

The original source is from the official [`ethereum/dapp-bin`](https://github.com/ethereum/dapp-bin/blob/master/coin/coin.sol) repository, authored by Gavin Wood.

The standard library contracts (`owned`, `mortal`, `Config`, `NameReg`) are from the [`ethereum/mix`](https://github.com/ethereum/mix/tree/master/stdc) IDE's `stdc/` directory.

## What We Know

### Function Selectors (from on-chain bytecode)

| Selector | Function | Source |
|----------|----------|--------|
| `06005754` | `name()` | `named` base contract |
| `1fa03a2b` | `isApprovedFor(address,address)` | `BasicCoin` |
| `673448dd` | `isApproved(address)` | `BasicCoin` |
| `67eae672` | `sendCoinFrom(address,uint256,address)` | `BasicCoin` |
| `99f4b251` | `mine()` | `GavCoin` |
| `a550f86d` | `named(bytes32)` | `named` base contract |
| `a6f9dae1` | `setOwner(address)` | `owned` base contract |
| `bbd39ac0` | `coinBalanceOf(address)` | `BasicCoin` |
| `c86a90fe` | `sendCoin(uint256,address)` | `BasicCoin` |
| `d26c8a8a` | `coinBalance()` | `BasicCoin` |
| `daea85c5` | `approve(address)` | `BasicCoin` |

### Hardcoded Addresses

- `0x084f6a99003dae6d3906664fdbf43dd09930d0e3` — NameReg contract (used by `named` base contract for name registration and lookups)

### Key Observations

- Constructor calls `NameReg.register("GavCoin")` at `0x084f6a99003dae6d3906664fdbf43dd09930d0e3`
- The `named(bytes32)` function calls `NameReg.addressOf(bytes32)` (selector `bb34534c`)
- `tota` in the constructor (`m_balances[owner] = tota`) is a variable from the `coin` base contract (likely total supply = 0, since all GAV comes from mining)
- `hash()` was early Solidity's name for `sha3()`/`keccak256()`
- `log2()` and `log3()` are raw EVM log operations
- Bytecode starts with `6060604052` — typical of Solidity 0.2.x-0.3.x era

### Compiler Candidates

Deployed April 26, 2016. Solidity versions available at that time:
- `0.2.0` through `0.2.2`
- `0.3.0` through `0.3.6`

Most likely: **0.3.1 - 0.3.6** (0.3.x was current in April 2016).

## Repository Structure

```
src/
  GavCoin-original.sol    # Original source from dapp-bin (with #require)
  GavCoin-flattened.sol   # Reconstructed flattened source (base contracts inlined)
  std/
    owned.sol             # From ethereum/mix stdc/std.sol
    named.sol             # Reconstructed from bytecode analysis
    coin.sol              # Reconstructed from bytecode analysis
bytecode/
  creation-bytecode.txt   # On-chain creation bytecode
  runtime-bytecode.txt    # On-chain runtime bytecode
scripts/
  compare.sh              # Download solc versions, compile, and compare bytecodes
  try-version.sh          # Try a specific solc version
```

## Usage

```bash
# Try all candidate compiler versions
./scripts/compare.sh

# Try a specific version
./scripts/try-version.sh 0.3.6

# Try with optimization
./scripts/try-version.sh 0.3.6 --optimize
```

## Contributing

If you find the exact compiler version and settings that produce a bytecode match, please open a PR or issue.

## Status

**In Progress** — The base contracts (`named`, `coin`) need to be reconstructed from bytecode analysis and the Mix IDE source. The flattened source is a best-effort reconstruction.

## ✅ SOLVED: Exact Runtime Bytecode Match

**Date:** March 3, 2026

After exhaustive analysis, we achieved an **exact byte-for-byte match** of the runtime bytecode.

### Key Findings

1. **No events**: The original contract had zero event declarations. Our early attempts included `Transfer` and `Mined` events which added ~290 bytes.

2. **Flat contract**: No inheritance from `BasicCoin`. Direct implementation.

3. **Storage layout**: `m_balances` (slot 0) → `m_approved` (slot 1) → `owner` (slot 2) → `m_lastNumberMined` (slot 3).

4. **Function order matters**: `changeOwner` must be declared LAST. The Solidity 0.3.x compiler emits a shared return trampoline when it first encounters a function that needs it — `changeOwner` uses this pattern. Moving it last pushes the trampoline to byte 794 (end of code), matching the on-chain layout exactly.

5. **Compiler**: Solidity v0.3.0 through v0.3.2-nightly (any build from this range). Deployed April 26, 2016 — likely compiled with v0.3.1 or a contemporary nightly.

### Verified Source

`src/GavCoin-final.sol` — compiles to exact match with optimizer enabled (`-o 1`).

### Verification

```bash
node verify.js
```
