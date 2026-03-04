# GavCoin — Source Verification

Verified source code for the GavCoin contract deployed to Ethereum mainnet on April 26, 2016.

| | |
|---|---|
| **Contract** | [`0xb4abc1bfc403a7b82c777420c81269858a4b8aa4`](https://etherscan.io/address/0xb4abc1bfc403a7b82c777420c81269858a4b8aa4) |
| **Block** | [1,408,600](https://etherscan.io/block/1408600) |
| **Creation TX** | [`0xa16cdc85...`](https://etherscan.io/tx/0xa16cdc8579cfab8f14b5ee62c1454d6bab52e5a21aa79f2f95b0ebe2704bddd1) |
| **Compiler** | Solidity v0.3.1, optimizer enabled |
| **Author** | Likely [Gavin Wood](https://github.com/gavofyork) (from [`ethereum/dapp-bin`](https://github.com/ethereum/dapp-bin/blob/master/coin/coin.sol)) |

## Verify

```bash
./verify.sh
```

Requires `node` and `curl`. Downloads the solc binary automatically on first run.

```
✅ EXACT MATCH
   Runtime bytecode: 905 bytes
   Compiler: solc v0.3.1+commit.c492d9be (optimizer enabled)
   Contract: 0xb4abc1bfc403a7b82c777420c81269858a4b8aa4
```

## Source

[`GavCoin.sol`](GavCoin.sol) compiles to a byte-perfect match of the on-chain runtime bytecode (905 bytes).

The original source used `#require` directives from the [Mix IDE](https://github.com/ethereum/mix) preprocessor, which inlined standard library contracts before compilation. This reconstructed source is the flat equivalent - no inheritance, no events, matching the on-chain bytecode exactly.

## How It Works

GavCoin is a pre-ERC-20 token with:
- **Transferable balances** via `sendCoin` / `sendCoinFrom`
- **Approval system** for delegated transfers
- **Proof-of-work mining** - anyone can call `mine()` to mint 1,000 tokens per block (split between caller and block miner)
- **Name registration** - registers itself as "GavCoin" in the global [NameReg](https://etherscan.io/address/0x084f6a99003dae6d3906664fdbf43dd09930d0e3) contract
- **Initial supply** of 1,000,000 tokens to the deployer

## Function Selectors

| Selector | Function |
|----------|----------|
| `06005754` | `nameRegAddress()` |
| `1fa03a2b` | `isApprovedFor(address,address)` |
| `673448dd` | `isApproved(address)` |
| `67eae672` | `sendCoinFrom(address,uint256,address)` |
| `99f4b251` | `mine()` |
| `a550f86d` | `named(bytes32)` |
| `a6f9dae1` | `changeOwner(address)` |
| `bb34534c` | `addressOf(bytes32)` (internal NameReg call) |
| `bbd39ac0` | `coinBalanceOf(address)` |
| `c86a90fe` | `sendCoin(uint256,address)` |
| `d26c8a8a` | `coinBalance()` |
| `daea85c5` | `approve(address)` |

## Notes

- **Runtime bytecode**: exact match across solc v0.1.6 through v0.3.2
- **Creation bytecode**: 3-byte difference in constructor CODECOPY sequence (JS solc emits 197-byte constructor vs 200 on-chain). The contract was compiled with the native C++ solc, which uses a slightly different stack arrangement for the deployment wrapper. The runtime code produced is identical.
- Research history preserved on the [`research`](../../tree/research) branch.
