# TIME Protocol

A Global Human Time Ledger — transforming time from an invisible resource into a tokenized, verifiable, and tradeable asset.

**1 TIME = 1 hour of verified human work**

## Overview

TIME Protocol establishes the world's first global, immutable ledger for human time. Built on proof-of-humanity verification (World ID), blockchain infrastructure, and cross-chain interoperability, TIME Protocol creates a universal standard where every hour of verified human work is recognized and valued.

## Core Components

### Smart Contracts

| Contract | Description |
|----------|-------------|
| `TIMEToken.sol` | ERC-20 TIME token with work-verified minting |
| `UniversalCalendar.sol` | Soulbound NFT calendar (24 UTC slots per human) |
| `WorkReceipt.sol` | ERC-721 proof-of-work NFTs |
| `WorldIDVerifier.sol` | World ID integration for human verification |
| `CommonsDistributor.sol` | Land Commons dividend distribution |
| `TIMEMarketplace.sol` | Decentralized time trading marketplace |

### Key Features

- **One Human, One Calendar**: World ID verification ensures each person has exactly one calendar
- **Fixed Capacity**: 24 hourly slots enforce physical time constraints cryptographically
- **1:1 Minting**: TIME tokens are minted only upon verified work completion
- **Privacy-Preserving**: Zero-knowledge proofs enable selective disclosure
- **Cross-Chain**: LayerZero integration for omnichain functionality

## Installation

```bash
npm install
```

## Compile

```bash
npx hardhat compile
```

## Test

```bash
npx hardhat test
```

## Deploy

```bash
# Deploy to World Chain testnet
npx hardhat run scripts/deploy.js --network worldchain-sepolia

# Deploy to World Chain mainnet
npx hardhat run scripts/deploy.js --network worldchain
```

## Contract Addresses

### World Chain (Mainnet)
| Contract | Address |
|----------|---------|
| TIMEToken | `TBD` |
| UniversalCalendar | `TBD` |
| WorkReceipt | `TBD` |

### World Chain Sepolia (Testnet)
| Contract | Address |
|----------|---------|
| TIMEToken | `TBD` |
| UniversalCalendar | `TBD` |
| WorkReceipt | `TBD` |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    TIME PROTOCOL ARCHITECTURE                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────┐      ┌──────────────────┐            │
│  │  WorldIDVerifier │      │  UniversalCalendar│            │
│  │  ────────────────│      │  ────────────────│            │
│  │  verifyProof()   │─────▶│  createCalendar() │            │
│  │  registerHuman() │      │  bookSlot()       │            │
│  └──────────────────┘      │  completeSlot()   │            │
│                            └────────┬─────────┘            │
│                                     │                       │
│                                     ▼                       │
│  ┌──────────────────┐      ┌──────────────────┐            │
│  │  TIMEToken       │◀─────│  WorkReceipt     │            │
│  │  ────────────────│      │  ────────────────│            │
│  │  mint()          │      │  createReceipt() │            │
│  │  transfer()      │      │  zkVerify()      │            │
│  │  burn()          │      └──────────────────┘            │
│  └──────────────────┘                                       │
│                                                              │
│  ┌──────────────────┐      ┌──────────────────┐            │
│  │  CommonsDistributor│    │  TIMEMarketplace  │            │
│  │  ────────────────│      │  ────────────────│            │
│  │  claimDividend() │      │  listTime()      │            │
│  │  calculateShare()│      │  purchaseTime()  │            │
│  └──────────────────┘      └──────────────────┘            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Integration with The Great Reset

TIME Protocol serves as critical infrastructure for the coordinated global economic restructuring scheduled for January 1, 2030:

- **Distribution mechanism** for Land Commons fees to all verified humans
- **Dignity floor** ensuring minimum value for all human time
- **Worker ownership tracking** for transparent equity accumulation
- **Universal identity layer** connecting all Reset components

## Documentation

- [White Paper](https://democracy.earth/whitepaper)
- [Technical Specification](./docs/SPECIFICATION.md)
- [API Reference](./docs/API.md)

## Security

- Audited by: `TBD`
- Bug bounty program: `TBD`

## License

MIT License - see [LICENSE](./LICENSE)

## Links

- Website: [democracy.earth](https://democracy.earth)
- Documentation: [docs.democracy.earth](https://docs.democracy.earth)
- Discord: [discord.gg/democracyearth](https://discord.gg/democracyearth)
- Twitter: [@democikiracyearth](https://twitter.com/democracyearth)

---

**Democracy Earth Foundation**

*The earth belongs to everyone. Your work belongs to you. Your time has value.*
