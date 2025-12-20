# Land Commons Protocol

Smart contracts for the Land Commons Protocol — returning the earth to everyone.

## Overview

The Land Commons Protocol implements a system where:

- **Land** (the earth itself) enters a shared Commons
- **Structures** (improvements) remain private property
- **Fees** are collected based on automated land valuations
- **Dividends** are distributed equally to all verified humans

## Core Concepts

### The Earth Belongs to Everyone

No human created the earth. Land existed before us and will exist after us. The Land Commons Protocol recognizes this by treating land as a shared inheritance of humanity.

### Structures vs. Land

| | **Structures** | **Land** |
|---|---|---|
| Created by | Humans | Nature |
| Ownership | Private | Commons |
| Fees | None | Based on value |
| Transfer | Freely tradeable | Use rights only |

### Hybrid Valuation System

Land values are determined through fully automated valuation with no self-assessment:

1. **Satellite Assessment**: Global imagery analyzed by ML models
2. **Infrastructure Proximity**: Distance to roads, utilities, transit
3. **Zonal Overlays**: Location premiums for specific areas
4. **Market Calibration**: Real transaction data validation

## Contracts

### LandRegistry.sol

Registry of land parcels with automated fee accrual.

```solidity
// Register a parcel
registerParcel(owner, locationHash, areaSqMeters, landType)

// Update valuation (oracle)
updateValuation(parcelId, baseValue, zonalMultiplier, dataHash)

// Pay accrued fees
payFees(parcelId)
```

### LandValuationOracle.sol

Oracle for receiving and validating land valuations from off-chain sources.

## Land Types & Fee Rates

| Land Type | Zonal Multiplier | Annual Fee Rate |
|-----------|------------------|-----------------|
| Urban Core | 3.0x - 5.0x | 2.0% |
| Urban General | 2.0x - 3.0x | 1.5% |
| Suburban | 1.2x - 2.0x | 1.0% |
| Rural | 0.5x - 1.2x | 0.75% |
| Agricultural | 0.1x - 0.5x | 0.5% |
| Conservation | N/A | 0% (may receive credits) |

## Integration with TIME Protocol

Fees collected by the Land Commons Protocol flow to the `CommonsDistributor` contract, which distributes them equally to all verified humans as Commons Dividends.

**Important**: Commons Dividends are separate from TIME tokens:

- **TIME tokens**: Earned through labor (1 TIME = 1 hour worked)
- **Commons Dividend**: Received by existence (equal share for all humans)

## Installation

```bash
npm install
npx hardhat compile
```

## Deploy

```bash
npx hardhat run scripts/deploy.js --network <network>
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   LAND COMMONS ARCHITECTURE                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ┌──────────────────┐      ┌──────────────────┐            │
│   │  Satellite Data  │      │  Market Data     │            │
│   └────────┬─────────┘      └────────┬─────────┘            │
│            │                         │                       │
│            └────────────┬────────────┘                       │
│                         ▼                                    │
│              ┌──────────────────┐                           │
│              │  Valuation       │                           │
│              │  Oracle          │                           │
│              └────────┬─────────┘                           │
│                       ▼                                      │
│              ┌──────────────────┐                           │
│              │  Land Registry   │                           │
│              │  ────────────────│                           │
│              │  parcels         │                           │
│              │  valuations      │                           │
│              │  fees            │                           │
│              └────────┬─────────┘                           │
│                       ▼                                      │
│              ┌──────────────────┐                           │
│              │  Commons         │                           │
│              │  Distributor     │──────▶ Verified Humans    │
│              └──────────────────┘                           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## License

MIT License

---

**Democracy Earth Foundation**

*The earth belongs to everyone.*
