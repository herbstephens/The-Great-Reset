# THE GREAT RESET
## Technical Specification v3.0

**December 2025**

---

# Table of Contents

1. System Overview
2. Identity Layer
3. Claim System
4. TIME Token
5. Governance System
6. Tax System
7. Position Database
8. Smart Contracts
9. Timeline

---

# 1. System Overview

## 1.1 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    THE GREAT RESET                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  IDENTITY LAYER                                             │
│  └── World ID (Proof of Humanity)                           │
│                                                             │
│  CLAIM LAYER                                                │
│  ├── Home Registry                                          │
│  ├── Work Registry                                          │
│  ├── Local Registry                                         │
│  └── TIME Distribution                                      │
│                                                             │
│  GOVERNANCE LAYER                                           │
│  ├── Position Database (global)                             │
│  ├── Staking System                                         │
│  ├── Quadratic Voting                                       │
│  └── Clout System                                           │
│                                                             │
│  ECONOMIC LAYER                                             │
│  ├── TIME Token (ERC-20)                                    │
│  ├── Tax System                                             │
│  ├── Treasury                                               │
│  └── Marketplace (TIMEdao)                                  │
│                                                             │
│  ACTIVATION LAYER                                           │
│  └── January 1, 2030 Trigger                                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 1.2 Core Principles

- **One human, one claim:** World ID ensures unique identity
- **Soulbound governance:** Lifetime TIME = voting weight (non-transferable for voting)
- **Transferable economy:** TIME spendable in marketplace
- **Tax-free peers:** Human ↔ Human = 0% tax
- **Open democracy:** Anyone can be nominated/elected
- **Real-time results:** Live vote counts, always visible

---

# 2. Identity Layer

## 2.1 World ID Integration

```
VERIFICATION FLOW:
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   World ID  │ →  │   Verify    │ →  │   Claim     │
│   (Orb/App) │    │   Humanity  │    │   Eligible  │
└─────────────┘    └─────────────┘    └─────────────┘
```

**Data Extracted:**
- Unique human identifier (nullifier hash)
- Date of birth (for TIME calculation)
- Verification status

**Privacy:**
- No personal data stored on-chain
- Zero-knowledge proofs for verification
- User controls data disclosure

## 2.2 Address Classification

| Address Type | Description | Tax Status |
|--------------|-------------|------------|
| World ID Verified | Linked to verified human | Tax-free peer transactions |
| Registered Entity | Business/org with tax ID | Taxable transactions |
| Unverified | Not linked to World ID | Default: taxable (incentive to verify) |

---

# 3. Claim System

## 3.1 Claim Sequence

```
STEP 1: IDENTITY
├── World ID verification
├── Birthday extracted
└── Status: VERIFIED

STEP 2: HOME
├── Enter residence address
├── Jurisdictions auto-derived (Local/Regional/National)
└── Status: HOME CLAIMED

STEP 3: WORK
├── Add employer(s) (if org > 1 person)
├── Add partner (mutual claim required)
├── Add volunteer org(s)
└── Status: WORK CLAIMED

STEP 4: TIME GRANTED
├── Lump sum calculated (days alive × 1 TIME)
├── Auto-staked to current incumbents
└── Status: LOCKED

STEP 5: REVIEW & UNLOCK
├── View LOCAL tier (required)
├── View REGIONAL tier (required)
├── View NATIONAL tier (required)
├── View GLOBAL tier (required)
├── Take ≥1 action (confirm/modify/abstain)
└── Status: UNLOCKED

POST-UNLOCK:
├── Daily UBI begins (1 TIME/day)
├── Marketplace access enabled
├── Full governance participation
└── Tax-free peer transactions enabled
```

## 3.2 Claim Data Schema

```json
{
  "claim_id": "0x...",
  "world_id": "nullifier_hash",
  "birthday": "1980-03-15",
  "days_alive": 16425,
  "time_granted": 16425,
  
  "home": {
    "address": "Rua da Liberdade 42, Belas",
    "coordinates": [38.7749, -9.2614],
    "jurisdiction_local": "sintra",
    "jurisdiction_regional": "lisboa",
    "jurisdiction_national": "portugal",
    "jurisdiction_continental": "eu",
    "claimed_at": "2027-06-15T10:30:00Z"
  },
  
  "work": {
    "employers": ["democracy_earth_foundation"],
    "partnership": {
      "partner_id": "0x...",
      "status": "confirmed",
      "terms": {
        "assets": "50/50",
        "income": "pooled",
        "decisions": "unanimous",
        "exit": "50/50",
        "disputes": "arbitration"
      }
    },
    "volunteer": []
  },
  
  "status": "unlocked",
  "unlocked_at": "2027-06-15T10:35:00Z"
}
```

---

# 4. TIME Token

## 4.1 Token Properties

| Property | Value |
|----------|-------|
| Name | TIME |
| Symbol | TIME |
| Decimals | 18 |
| Standard | ERC-20 |
| Minting | Only via claims + daily UBI |
| Burning | None (fixed supply growth) |

## 4.2 Supply Model

```
INITIAL SUPPLY: 0

GROWTH:
├── Lump sum claims: days_alive × 1 TIME (one-time per human)
├── Daily UBI: 1 TIME per verified human per day
└── Total theoretical max: ~8B × 27,375 = ~219 trillion TIME (full adoption, avg lifespan)

SUPPLY IS BOUNDED BY:
├── Population (only verified humans mint)
└── Time (only 1 TIME/person/day)
```

## 4.3 Token Functions

```
GOVERNANCE (Soulbound)
├── lifetime_earned: Total TIME ever received
├── governance_weight: lifetime_earned (never decreases)
├── staked: TIME allocated to positions
└── Cannot be transferred; used for voting weight

ECONOMIC (Transferable)
├── balance: Current spendable TIME
├── transfer(): Send to other addresses
├── marketplace: Buy/sell goods and services
└── 0.1% protocol fee on all transfers
```

## 4.4 Wallet Structure

```
┌─────────────────────────────────────────────────────────────┐
│  USER WALLET                                                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  LIFETIME EARNED: 16,425 TIME (governance weight)           │
│  ─────────────────────────────────────────────────────────  │
│                                                             │
│  AVAILABLE: 8,420 TIME                                      │
│  ├── Spendable in marketplace                               │
│  ├── Transferable to other humans (tax-free)                │
│  └── Usable for commercial purchases (taxed)                │
│                                                             │
│  TAX HOLD: 2,580 TIME (self-controlled)                     │
│  ├── Auto-withheld from commercial transactions             │
│  ├── User controls release                                  │
│  └── Breakdown by jurisdiction                              │
│                                                             │
│  STAKED: 14,800 TIME (governance)                           │
│  ├── Allocated to positions                                 │
│  ├── 24hr cooldown to reallocate                            │
│  └── Can stake up to LIFETIME EARNED                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

# 5. Governance System

## 5.1 Position Hierarchy

```
GLOBAL
├── UN Secretary-General
├── Global Issues (Climate, Commons, etc.)

CONTINENTAL
├── EU Parliament, Commission
├── AU Assembly
├── Other regional bodies

NATIONAL (195 countries)
├── Head of State
├── Head of Government
├── Legislature (all seats)

REGIONAL (thousands)
├── State/Province executives
├── Regional assemblies

LOCAL (millions)
├── Mayors
├── City councils
├── School boards, etc.
```

## 5.2 Candidate Tiers

| Tier | Description | Auto-Listed |
|------|-------------|-------------|
| Incumbent | Currently holds position | Yes |
| Challenger | Ran in last general election | Yes |
| Primary | Ran in last primary (any party) | Yes |
| Nominated | Any resident nominated by claimant | On first stake |
| Self-Nominated | Any resident who self-nominates | On registration |

## 5.3 Staking Mechanics

```
ALLOCATION:
├── Minimum stake: 1 TIME
├── Maximum stake: Lifetime earned
├── Candidates per position: Unlimited
├── Positions per user: All in jurisdiction

QUADRATIC VOTING:
├── Votes = √(TIME staked)
├── 1 TIME = 1 vote
├── 100 TIME = 10 votes
├── 10,000 TIME = 100 votes

COOLDOWN:
├── Re-stake cooldown: 24 hours
├── New stakes: Immediate
└── Position changes: 24hr delay

DEFAULT ALLOCATION:
├── New claimants: 100% to incumbents
├── Spread equally across all positions
├── Must review all tiers to unlock
```

## 5.4 Clout System

```
BASE WEIGHT: Staked TIME (always counts)

PARTICIPATION MULTIPLIER:
├── 1-5 votes/month: 1.0×
├── 5-20 votes/month: 1.25×
├── 20-50 votes/month: 1.5×
├── 50+ votes/month: 2.0× (cap)

DECAY:
├── No votes for 30 days: Drop one tier
├── No votes for 90 days: Return to 1.0×
└── Stake still counts, just no bonus

EFFECTIVE VOTES = √(TIME staked) × Clout Multiplier
```

## 5.5 Live Results

```
RESULTS UPDATE: Real-time (every block)

DISPLAY:
├── Vote count per candidate
├── Percentage of total
├── Rank order
├── Trend (↑↓→)
├── Comparison to last official election

VISIBILITY: Public (all results visible to all)
```

---

# 6. Tax System

## 6.1 Transaction Classification

| Sender | Receiver | Tax Status |
|--------|----------|------------|
| World ID | World ID | TAX-FREE |
| World ID | Non-World ID | Sales/VAT (buyer withholds) |
| Non-World ID | World ID | Income tax (receiver withholds) |
| Non-World ID | Non-World ID | B2B tax (both withhold) |

## 6.2 Rate Structure

```
GLOBAL DEFAULTS:
├── Income tax: 25%
├── Sales/VAT: 10%
└── Protocol fee: 0.1% (all transactions)

LOCAL OVERRIDES:
├── Any jurisdiction can register custom rates
├── 0% overrides allowed
└── Override applies to residents

MULTI-JURISDICTION (50/50 split):
├── Buyer's jurisdiction: 50% of tax calculation
└── Seller's jurisdiction: 50% of tax calculation
```

## 6.3 Self-Withholding

```
BEHAVIOR:
├── Auto-split ON by default
├── User can disable in settings
├── Tax portion → Tax Hold folder
├── User controls Tax Hold funds

TAX HOLD ACTIONS:
├── VIEW: See breakdown by jurisdiction
├── RELEASE: Move to Available
├── PAY: Send to jurisdiction (if opted in)
└── EXPORT: Download for traditional filing
```

## 6.4 Jurisdiction Record Schema

```json
{
  "jurisdiction_id": "PT",
  "name": "Portugal",
  "type": "national",
  "parent": null,
  "rates": {
    "income": 0.28,
    "vat": 0.23,
    "capital_gains": 0.28
  },
  "split": {
    "national": 0.70,
    "regional": 0.15,
    "local": 0.15
  },
  "treasury_address": null,
  "adoption_tier": 1,
  "updated": "2027-01-15T00:00:00Z"
}
```

## 6.5 Government Adoption Tiers

| Tier | Features |
|------|----------|
| 0: Not Adopted | Global defaults, self-withholding only |
| 1: Rates Registered | Custom rates in protocol |
| 2: Treasury Registered | Direct payment option |
| 3: Full Adoption | Protocol tax = legal tax, no filing |

---

# 7. Position Database

## 7.1 Data Sources

- Public election records
- Government databases
- Wikipedia/open sources
- Community submissions (verified)
- Self-nominations

## 7.2 Position Record Schema

```json
{
  "position_id": "pt-sintra-mayor",
  "title": "Mayor of Sintra",
  "jurisdiction": "sintra",
  "jurisdiction_type": "local",
  "term_years": 4,
  "last_election": "2021-09-26",
  "next_election": "2025-09-28",
  
  "incumbent": {
    "name": "Basílio Horta",
    "party": "PS",
    "elected": "2021-09-26",
    "world_id": null
  },
  
  "candidates": [
    {
      "name": "Basílio Horta",
      "party": "PS",
      "tier": "incumbent",
      "last_result": 0.51,
      "world_id": null,
      "current_votes": 142847
    },
    {
      "name": "Ana Santos",
      "party": "PSD",
      "tier": "challenger",
      "last_result": 0.42,
      "world_id": null,
      "current_votes": 98421
    },
    {
      "name": "Maria Joaquina Silva",
      "party": null,
      "tier": "nominated",
      "last_result": null,
      "world_id": "0x...",
      "current_votes": 52891
    }
  ],
  
  "total_votes": 374102,
  "total_stakers": 284721
}
```

## 7.3 Estimated Scale

| Level | Estimated Positions |
|-------|---------------------|
| Global | ~50 |
| Continental | ~500 |
| National | ~50,000 |
| Regional | ~200,000 |
| Local | ~2,000,000 |
| **Total** | **~2.5 million** |

---

# 8. Smart Contracts

## 8.1 Contract Architecture

```
TIMEToken.sol
├── ERC-20 implementation
├── mint() - only callable by ClaimRegistry
├── lifetimeEarned mapping
└── 0.1% transfer fee

ClaimRegistry.sol
├── claim() - main claim function
├── verifyWorldID()
├── calculateTimeLumpSum()
├── registerHome()
├── registerWork()
└── unlock()

GovernanceStaking.sol
├── stake()
├── unstake() (24hr cooldown)
├── calculateVotes() (quadratic)
├── getClout()
└── getLiveResults()

PositionRegistry.sol
├── addPosition()
├── nominate()
├── selfNominate()
├── acceptNomination()
├── declineNomination()

TaxSystem.sol
├── classifyTransaction()
├── calculateTax()
├── autoWithhold()
├── releaseTaxHold()
├── payToJurisdiction()

Treasury.sol
├── collectProtocolFees()
├── distributeToFoundation()
└── emergencyWithdraw() (multisig)

ResetTrigger.sol
├── activationTimestamp: 1735689600 (Jan 1, 2030 00:00:00 UTC)
├── activate() - callable after timestamp
├── executeHomeTransfers()
├── executeWorkEquity()
└── cancelDebts()
```

## 8.2 Deployment

```
CHAINS:
├── Primary: Ethereum mainnet (security)
├── L2: Base/Optimism (low fees for daily use)
├── Bridge: Cross-chain TIME transfers

UPGRADABILITY:
├── Proxy pattern for critical contracts
├── Timelock on upgrades (7 days)
├── Multisig governance (Foundation)
```

---

# 9. Timeline

## 9.1 Development Phases

| Phase | Period | Milestones |
|-------|--------|------------|
| Build | 2025-Q3 2026 | Protocol development, World ID integration, testnet |
| Pilot | Q4 2026-Q2 2027 | Limited geography beta (Portugal? Argentina?) |
| Launch | Q3 2027 | Global claims open |
| Growth | 2027-2029 | Mass adoption, parallel elections |
| Lock | Dec 2029 | Final claiming period |
| Reset | Jan 1, 2030 | All claims activate |
| Resolve | Q1 2030 | Dispute resolution |
| Expand | 2030+ | Government adoption, global democracy |

## 9.2 Key Dates

| Date | Event |
|------|-------|
| 2027-07-01 | Claims open globally |
| 2028-11-05 | US midterm parallel election |
| 2029-12-31 | Final claim deadline |
| 2030-01-01 00:00:00 UTC | THE GREAT RESET |
| 2030-03-31 | Dispute resolution closes |

---

# Appendix A: Glossary

| Term | Definition |
|------|------------|
| TIME | Token representing one hour of human existence |
| Claim | The act of registering for The Great Reset |
| Stake | TIME allocated to a governance position |
| Clout | Participation multiplier (1.0× to 2.0×) |
| Soulbound | Non-transferable for governance purposes |
| Tax Hold | Self-controlled withholding for tax obligations |
| Incumbent | Current holder of a political position |
| Shadow Government | TIME Protocol election results vs. official |

---

# Appendix B: Contact

**Democracy Earth Foundation**
- Website: democracy.earth
- GitHub: github.com/democracyearth

**TIME Protocol**
- Website: timeprotocol.org
- GitHub: github.com/timeprotocol

**The Great Reset**
- Website: thegreatreset.earth
- Registry: claim.thegreatreset.earth

---

*End of Technical Specification*
