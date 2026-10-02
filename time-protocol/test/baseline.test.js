// Baseline: does the protocol do what the README says on the happy path?
const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { CATEGORY, PROOF, Status, DAY, ONE, RATE, dayStart, deployProtocol, withCalendars, middayTomorrow, paidBooking, passHour } = require("./fixtures");

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

  it("lets the owner block one of their own hours and reopen it", async () => {
    const { calendar, alice, aliceCal } = await loadFixture(withCalendars);
    const date = dayStart(await middayTomorrow()) + DAY;
    await calendar.connect(alice).bookSlot(aliceCal, date, 9, 0, CATEGORY);
    expect((await calendar.getSlot(aliceCal, date, 9)).status).to.equal(Status.BOOKED);
    await calendar.connect(alice).cancelSlot(aliceCal, date, 9);
    expect((await calendar.getSlot(aliceCal, date, 9)).status).to.equal(Status.AVAILABLE);
  });

  it("mints one TIME and one receipt, and pays the worker, once a booked hour has ended and the buyer releases payment", async () => {
    const p = await loadFixture(withCalendars);
    const { token, receipt, pay, market, alice, bob, feeRecipient } = p;
    const { date, slot, bookingId } = await paidBooking(p);
    await passHour(date, slot);
    await market.connect(bob).completeBooking(bookingId);
    expect(await token.balanceOf(alice.address)).to.equal(ONE);
    expect(await receipt.balanceOf(alice.address)).to.equal(1n);
    expect(await pay.balanceOf(alice.address)).to.equal(RATE * 975n / 1000n);
    expect(await pay.balanceOf(feeRecipient.address)).to.equal(RATE * 25n / 1000n);
  });

  it("only a registered marketplace can complete a slot", async () => {
    const { calendar, alice, aliceCal } = await loadFixture(withCalendars);
    const date = dayStart(await middayTomorrow()) + DAY;
    await calendar.connect(alice).bookSlot(aliceCal, date, 2, 1n, CATEGORY);
    await expect(calendar.connect(alice).completeSlot(aliceCal, date, 2)).to.be.revertedWithCustomError(calendar, "NotMarketplace");
  });
});
