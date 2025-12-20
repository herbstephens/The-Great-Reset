# IPFS Upload Instructions

## The Reset — IPFS Distribution Package

This folder contains all documents ready for permanent, decentralized distribution via IPFS.

---

## Contents

```
ipfs-ready/
├── index.html                      # Landing page (main entry point)
├── the-reset-pamphlet.html         # Pamphlet - HTML (styled, readable)
├── the-reset-pamphlet.pdf          # Pamphlet - PDF (printable)
├── the-reset-pamphlet.md           # Pamphlet - Markdown (for translation)
├── the-great-reset-book.html       # Book - HTML (styled, readable)
├── the-great-reset-book.pdf        # Book - PDF (printable)
├── the-great-reset-book.md         # Book - Markdown (for translation)
├── time-protocol-whitepaper.html   # White Paper - HTML
├── time-protocol-whitepaper.md     # White Paper - Markdown
├── land-valuation-methodology.html # Technical doc - HTML
├── land-valuation-methodology.md   # Technical doc - Markdown
└── README.md                       # This file
```

---

## Option 1: Upload via IPFS Desktop (Easiest)

1. **Download IPFS Desktop**: https://docs.ipfs.tech/install/ipfs-desktop/

2. **Install and launch** IPFS Desktop

3. **Click "Files"** in the sidebar

4. **Click "+ Import"** → **"Folder"**

5. **Select this entire `ipfs-ready` folder**

6. **Right-click the uploaded folder** → **"Copy CID"**

7. Your content is now available at:
   ```
   https://ipfs.io/ipfs/YOUR_CID_HERE/
   https://dweb.link/ipfs/YOUR_CID_HERE/
   https://cloudflare-ipfs.com/ipfs/YOUR_CID_HERE/
   ```

---

## Option 2: Upload via Command Line

### Install IPFS CLI

```bash
# macOS (Homebrew)
brew install ipfs

# Linux (snap)
sudo snap install ipfs

# Or download from: https://docs.ipfs.tech/install/command-line/
```

### Initialize and Start IPFS

```bash
# First time only
ipfs init

# Start the daemon (keep running in background)
ipfs daemon &
```

### Upload the Folder

```bash
# Navigate to parent directory of ipfs-ready
cd /path/to/parent/

# Add the entire folder recursively
ipfs add -r ipfs-ready

# Output will show CID for each file and the folder:
# added QmXxx... ipfs-ready/index.html
# added QmXxx... ipfs-ready/the-reset-pamphlet.html
# ...
# added QmYYY... ipfs-ready   <-- THIS IS YOUR FOLDER CID
```

### Pin to Keep Available

```bash
# Pin locally (keeps on your node)
ipfs pin add QmYOUR_FOLDER_CID

# For persistence without running your own node, use a pinning service:
# - Pinata (https://pinata.cloud) - Free tier available
# - Infura (https://infura.io)
# - Web3.Storage (https://web3.storage) - Free
```

---

## Option 3: Web3.Storage (Easiest for Permanence)

1. Go to https://web3.storage

2. Sign up (free, no credit card)

3. Click **"Upload Files"**

4. Drag the entire `ipfs-ready` folder

5. Get your CID automatically

6. Content is pinned on Filecoin (permanent storage)

---

## Option 4: Pinata (Professional)

1. Go to https://pinata.cloud

2. Sign up for free tier

3. Click **"Upload"** → **"Folder"**

4. Select `ipfs-ready` folder

5. Get CID and gateway URLs

---

## Accessing Your Content

Once uploaded, your content is accessible via multiple gateways:

```
# Public gateways (replace YOUR_CID with actual CID)
https://ipfs.io/ipfs/YOUR_CID/
https://dweb.link/ipfs/YOUR_CID/
https://cloudflare-ipfs.com/ipfs/YOUR_CID/
https://gateway.pinata.cloud/ipfs/YOUR_CID/

# Direct file access
https://ipfs.io/ipfs/YOUR_CID/the-reset-pamphlet.html
https://ipfs.io/ipfs/YOUR_CID/the-reset-pamphlet.pdf
```

---

## Sharing Links

**For maximum reach, share multiple gateway URLs:**

```markdown
# The Reset — A Plan for All of Us

Read online:
- https://ipfs.io/ipfs/YOUR_CID/
- https://dweb.link/ipfs/YOUR_CID/

Download PDF:
- https://ipfs.io/ipfs/YOUR_CID/the-reset-pamphlet.pdf

This content is permanently stored on IPFS and cannot be censored.
```

---

## Verifying Content Integrity

The CID (Content Identifier) is a cryptographic hash of the content. If anyone modifies even one character, the CID changes. This guarantees:

- **Authenticity**: Same CID = same content
- **Integrity**: Content cannot be tampered with
- **Permanence**: As long as one node has it, it exists

To verify:
```bash
ipfs cat YOUR_CID/the-reset-pamphlet.md | sha256sum
# Compare with original
```

---

## DNS Integration (Optional)

For a human-readable URL, you can link your domain to IPFS via DNSLink:

1. Add a TXT record to your domain:
   ```
   _dnslink.thereset.earth  TXT  "dnslink=/ipfs/YOUR_CID"
   ```

2. Access via:
   ```
   https://thereset.earth.ipfs.dweb.link/
   ```

Or use ENS (Ethereum Name Service) for `thereset.eth`

---

## Recommended Distribution Strategy

1. **IPFS** (you're here) — Permanent, decentralized archive
2. **Internet Archive** — Upload to archive.org for credibility
3. **GitHub Pages** — Clean URLs, easy updates
4. **Torrent** — For offline distribution
5. **Social media** — Share gateway links

---

## Questions?

- IPFS Documentation: https://docs.ipfs.tech
- Web3.Storage Docs: https://web3.storage/docs
- Pinata Docs: https://docs.pinata.cloud

---

**The ideas belong to everyone. Make them uncensorable.**

*TIME Protocol Foundation | December 2025*
