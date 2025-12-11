# TIME Protocol: World Chain Deployment

**Status: Live on World Chain** ✅  
All smart contracts are deployed and verified.

---

## Verified Contracts

| Contract | Purpose | Address |
|----------|---------|---------|
| **HumanBond** | Core Engine | [`0x6494daa4e693F748Eb0a16041ECfCEd51392bB13`](https://worldscan.org/address/0x6494daa4e693F748Eb0a16041ECfCEd51392bB13) |
| **TIME Token** | ERC-20 | [`0x261f6d89491cbadff7813303363a514f4b226a82`](https://worldscan.org/address/0x261f6d89491cbadff7813303363a514f4b226a82) |
| **VowNFT** | Soulbound Marriage NFT | [`0xa1650cc531c2780fb8c006f4b8d314018f7f9ac9`](https://worldscan.org/address/0xa1650cc531c2780fb8c006f4b8d314018f7f9ac9) |
| **MilestoneNFT** | Anniversary NFTs | [`0x0a2759241d0cb610e3e61db351813ddf8a52f14c`](https://worldscan.org/address/0x0a2759241d0cb610e3e61db351813ddf8a52f14c) |

---

## Architecture

### HumanBond (Core Engine)

The main contract that coordinates the full marriage flow:

- Handles World ID verification for both partners
- Both sides can view proposals sent and received
- Manages the proposal → acceptance lifecycle plus divorce
- Mints the VowNFT when partners get married
- Calculates TIME yield internally
- Mints TIME tokens only when one partner claims (or at divorce)
- Users can trigger MilestoneNFTs on anniversaries

This is the logic layer—everything passes through HumanBond.

### TIME Token (ERC-20)

A yield-style token earned by the couple over time:

- Yield is calculated inside HumanBond
- Minting only happens when the couple chooses to claim
- Cannot be minted arbitrarily—strictly controlled by HumanBond

### VowNFT (Soulbound Marriage NFT)

Dynamic metadata NFT representing the marriage itself:

- Stores the two partner addresses
- Stores the timestamp of marriage + unique marriage ID
- Intentionally non-transferable (soulbound)
- Metadata can be updated by the contract to reflect state changes

### MilestoneNFT (Anniversary NFTs)

Configurable milestone NFTs for anniversaries:

- 1, 2, 3, 4+ year CIDs already mapped
- Dynamic, updatable metadata—IPFS links can be updated post-deployment
- Minting triggered by HumanBond on milestone checks

---

## Current Status

| Component | Status |
|-----------|--------|
| Smart contracts (v2) | ✅ Deployed + verified |
| Architecture | ✅ Complete and functional |
| Frontend integration | 🔄 v1 flow only (v2 pending) |
| World App mini-app | ⏳ Ready after frontend integration |

### Demo Notes

- **Frontend demos:** Use v1 flow (currently integrated)
- **Technical/protocol review:** Reference v2 contracts above

---

## Links

- [HumanBond on WorldScan](https://worldscan.org/address/0x6494daa4e693F748Eb0a16041ECfCEd51392bB13)
- [TIME Token on WorldScan](https://worldscan.org/address/0x261f6d89491cbadff7813303363a514f4b226a82)
- [VowNFT on WorldScan](https://worldscan.org/address/0xa1650cc531c2780fb8c006f4b8d314018f7f9ac9)
- [MilestoneNFT on WorldScan](https://worldscan.org/address/0x0a2759241d0cb610e3e61db351813ddf8a52f14c)
