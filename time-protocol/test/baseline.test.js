// Baseline: do the contracts do what the README says they do on the happy path?
// If these fail, the observation tests in audit-observations.test.js mean nothing.
const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { CATEGORY, PROOF, Status, DAY, dayStart, deployProtocol, withCalendars, middayTomorrow } = require("./fixtures");

describe("Baseline behaviour", () => {
  it("creates a soulbound calendar per verified human and rejects a repeated nullifier", async () => {
    const { calendar, alice, bob } = await loadFixture(deployProtocol);
    await calendar.connect(alice).createCalendar(1, 111, PROOF);
    expect(await calendar.balanceOf(alice.address)).to.equal(1n);
    await expect(calendar.connect(bob).createCalendar(1, 111, PROOF)).to.be.revertedWithCustomError(calendar, "AlreadyRegistered");
  });

  it("rejects a calendar when World ID rejects the proof", async () => {
    const { calendar, worldId, alice } = await loadFixture(deployProtocol);
    await worldId.setRejectProofs(true);
    await expect(calendar.connect(alice).createCalendar(1, 5, PROOF)).to.be.revertedWith("MockWorldID: invalid proof");
  });

  it("blocks calendar transfers (soulbound)", async () => {
    const { calendar, alice, bob, aliceCal } = await loadFixture(withCalendars);
    await expect(calendar.connect(alice).transferFrom(alice.address, bob.address, aliceCal))
      .to.be.revertedWithCustomError(calendar, "TransferNotAllowed");
  });

  it("has 24 slots per day and rejects an out-of-range slot", async () => {
    const { calendar, alice, aliceCal } = await loadFixture(withCalendars);
    expect(await calendar.SLOTS_PER_DAY()).to.equal(24n);
    const t = await middayTomorrow();
    await expect(calendar.connect(alice).bookSlot(aliceCal, dayStart(t) + DAY, 24, 1, CATEGORY))
      .to.be.revertedWithCustomError(calendar, "InvalidSlotIndex");
  });

  it("mints one TIME and one receipt when the owner completes a booked slot", async () => {
    const { calendar, token, receipt, alice, aliceCal } = await loadFixture(withCalendars);
    const t = await middayTomorrow();
    const date = dayStart(t) + DAY;
    await calendar.connect(alice).bookSlot(aliceCal, date, 9, 50n, CATEGORY);
    await calendar.connect(alice).completeSlot(aliceCal, date, 9);
    expect(await token.balanceOf(alice.address)).to.equal(10n ** 18n);
    expect(await receipt.balanceOf(alice.address)).to.equal(1n);
    expect((await calendar.getSlot(aliceCal, date, 9)).status).to.equal(Status.COMPLETED);
  });

  it("only the calendar owner can complete a slot", async () => {
    const { calendar, alice, mallory, aliceCal } = await loadFixture(withCalendars);
    const t = await middayTomorrow();
    const date = dayStart(t) + DAY;
    await calendar.connect(alice).bookSlot(aliceCal, date, 2, 1n, CATEGORY);
    await expect(calendar.connect(mallory).completeSlot(aliceCal, date, 2)).to.be.revertedWithCustomError(calendar, "NotCalendarOwner");
  });
});
