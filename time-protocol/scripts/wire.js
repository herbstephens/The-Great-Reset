/**
 * Wires a freshly deployed protocol together and removes the deployer's powers.
 * Used by scripts/deploy.js and by the tests, so the tests exercise the same wiring.
 *
 *  - registers the calendar's token, receipt and marketplace;
 *  - lets only the calendar mint TIME and receipts, and strips the deployer's minter role;
 *  - hands administration to `admin` (a multisig of hardware keys on real networks) and
 *    steps down, so no single deployer key can mint, forge receipts or repoint contracts.
 */
async function wireProtocol({ deployer, admin, timeToken, workReceipt, calendar, marketplace, distributor }) {
  const wait = async (tx) => (await tx).wait();
  const minter = await timeToken.MINTER_ROLE();
  const adminRole = await calendar.DEFAULT_ADMIN_ROLE();
  const calendarAddress = await calendar.getAddress();

  await wait(calendar.setTIMEToken(await timeToken.getAddress()));
  await wait(calendar.setWorkReceipt(await workReceipt.getAddress()));
  await wait(calendar.setMarketplace(await marketplace.getAddress(), true));
  await wait(timeToken.grantRole(minter, calendarAddress));
  await wait(workReceipt.grantRole(minter, calendarAddress));

  // The deployer must not keep the ability to mint TIME or receipts.
  await wait(timeToken.renounceRole(minter, deployer.address));
  await wait(workReceipt.renounceRole(minter, deployer.address));

  const newAdmin = admin && admin.toLowerCase() !== deployer.address.toLowerCase() ? admin : null;
  if (newAdmin) {
    const contracts = [timeToken, workReceipt, calendar, marketplace];
    if (distributor) contracts.push(distributor);
    for (const c of contracts) {
      await wait(c.grantRole(adminRole, newAdmin));
    }
    if (distributor) {
      for (const role of [await distributor.DEPOSITOR_ROLE(), await distributor.ORACLE_ROLE()]) {
        await wait(distributor.grantRole(role, newAdmin));
        await wait(distributor.renounceRole(role, deployer.address));
      }
    }
    for (const c of contracts) {
      await wait(c.renounceRole(adminRole, deployer.address));
    }
  }
}

module.exports = { wireProtocol };
