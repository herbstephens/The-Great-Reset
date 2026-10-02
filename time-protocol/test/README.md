# Tests

- `baseline.test.js`: the happy path. Calendars are soulbound, an owner can block and reopen
  their own hours, and a paid hour mints one TIME and one receipt only after it has ended and
  the buyer releases payment.
- `audit-findings.test.js`: regression tests for each finding from the contract review (open
  `bookSlot`, self-minting, burning an hour, the receipt's employer, escrow release, and the
  deployer's mint and admin roles). Two tests are labelled **NOT FIXED** and document what
  these changes do not close: public slot data, and wash trading by a colluding pair.
- `fixtures.js`: shared setup. It wires contracts with `scripts/wire.js`, the same code
  `scripts/deploy.js` uses, so the tests exercise the deployment wiring.
- `contracts/mocks/`: test-only mocks (World ID router, payment token). Do not deploy them.

## Running

```bash
npx hardhat test
```

On an Apple Silicon Mac without Rosetta, Hardhat's downloaded Intel `solc` cannot run
(`HH505` / "bad CPU type"). Install Rosetta (`softwareupdate --install-rosetta`) or compile
with the JavaScript build of solc by overriding `TASK_COMPILE_SOLIDITY_GET_SOLC_BUILD`.
