# Tests

- `baseline.test.js`: do the contracts do what the README says on the happy path?
- `audit-observations.test.js`: one characterization test per observation from the
  contract review (`GroundState: docs/product-alpha/time-protocol-and-hito.md`). They
  assert what the code does **today**, so they pass; the titles say which behaviours are
  problems. The skipped block at the bottom lists the behaviour we want instead. When a
  fix ships, enable the matching pending test and flip or delete the characterization one.
- `contracts/mocks/` holds test-only mocks (World ID router, payment token). Do not deploy them.

Only the tests whose title is about the exploit (OBS-1, OBS-2, OBS-3) use a stranger
booking someone else's slot; every other test books through the calendar owner so it
keeps working after `bookSlot` is restricted.

## Running

```bash
npx hardhat test
```

On an Apple Silicon Mac without Rosetta, Hardhat's downloaded Intel `solc` cannot run
(`HH505` / "bad CPU type"). Either install Rosetta (`softwareupdate --install-rosetta`)
or compile with the JavaScript build of solc; a wrapper config that does that is a few
lines (see how `hardhat.config.js` could override `TASK_COMPILE_SOLIDITY_GET_SOLC_BUILD`).
