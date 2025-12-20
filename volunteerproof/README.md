# VolunteerPROOF

**Verify your humanity. Log your impact. Mint your proof.**

A World miniapp for tracking and verifying volunteer hours on-chain.

[![World Chain](https://img.shields.io/badge/World%20Chain-Live-10b981?style=for-the-badge)](https://worldchain.org)
[![World ID](https://img.shields.io/badge/World%20ID-Verified-000?style=for-the-badge)](https://worldcoin.org/world-id)

---

## Overview

VolunteerPROOF allows verified humans to:

1. **Log volunteer hours** — Record time spent helping organizations
2. **Build a verified history** — All entries linked to World ID
3. **Mint proof NFTs** — Create permanent, verifiable records of impact

Every hour logged is tied to a unique human identity, eliminating fake volunteer claims and creating trustworthy impact credentials.

---

## How It Works

```
┌─────────────────────────────────────────────────────────┐
│                    VolunteerPROOF                       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. VERIFY                                              │
│     └── World ID verification (proof of personhood)    │
│                                                         │
│  2. LOG                                                 │
│     └── Record hours, organization, description        │
│     └── Stored on World Chain                          │
│                                                         │
│  3. MINT                                                │
│     └── Convert logged hours to VolunteerProof NFT     │
│     └── Permanent, verifiable credential               │
│                                                         │
│  4. EARN (Coming Soon)                                  │
│     └── Receive TIME tokens for verified hours         │
│     └── 1 TIME = 1 verified hour of contribution       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Component | Technology |
|-----------|------------|
| **Blockchain** | World Chain |
| **Identity** | World ID (Proof of Personhood) |
| **Frontend** | React / Next.js |
| **Smart Contracts** | Solidity |
| **Token Standard** | ERC-721 (Proof NFTs), ERC-20 (TIME) |

---

## Smart Contracts

### VolunteerEngine (Core)

The main contract coordinating the volunteer flow:

- Handles World ID verification
- Stores volunteer hour entries
- Calculates TIME yield
- Mints VolunteerProof NFTs

### VolunteerProof NFT (ERC-721)

Soulbound NFT representing verified volunteer work:

- Stores volunteer address, hours, organization
- Non-transferable (soulbound)
- Dynamic metadata reflecting total impact

### TIME Token Integration

Connects to TIME Protocol for earning:

- Volunteer hours earn TIME tokens
- Claimable at any time
- 1 verified hour = 1 TIME

---

## Development

### Prerequisites

- Node.js 18+
- World App (for testing World ID)
- World Chain testnet access

### Installation

```bash
# Clone the repo
git clone https://github.com/timeprotocol/volunteerproof.git
cd volunteerproof

# Install dependencies
npm install

# Run development server
npm run dev
```

### Environment Variables

```env
NEXT_PUBLIC_WORLD_APP_ID=app_xxx
NEXT_PUBLIC_WORLD_ACTION_ID=volunteer_verify
NEXT_PUBLIC_CONTRACT_ADDRESS=0x...
```

---

## File Structure

```
volunteerproof/
├── contracts/
│   ├── VolunteerEngine.sol
│   ├── VolunteerProofNFT.sol
│   └── interfaces/
├── frontend/
│   ├── components/
│   │   └── VolunteerProof.jsx
│   ├── pages/
│   └── styles/
├── index.html          # Standalone demo
└── README.md
```

---

## Roadmap

- [x] World ID verification
- [x] Hour logging interface
- [x] NFT minting flow
- [ ] TIME token integration
- [ ] Organization verification
- [ ] Leaderboards
- [ ] Impact certificates (PDF export)
- [ ] Multi-signature hour verification

---

## Part of TIME Protocol

VolunteerPROOF is part of the TIME Protocol ecosystem:

| App | Purpose |
|-----|---------|
| **MarriageProof** | Verify relationships, earn TIME together |
| **VolunteerPROOF** | Log volunteer hours, mint impact proofs |
| **WorkProof** | Verify employment, claim work receipts |

All apps use World ID for human verification and contribute to the global TIME economy.

---

## Links

- [TIME Protocol](https://timeprotocol.org)
- [Democracy Earth Foundation](https://democracy.earth)
- [World Chain](https://worldchain.org)
- [World ID](https://worldcoin.org/world-id)

---

## License

MIT

---

**TIME Protocol Labs** • **Democracy Earth Foundation**

*Building the infrastructure for human time.*
