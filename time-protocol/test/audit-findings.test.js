// Regression tests for the fixes to the findings from the contract review
// (OBS-1 to OBS-7 in the earlier characterization tests, which asserted the old behaviour).
// Each test names the finding it closes. Two tests document what is NOT fixed.
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { DAY, HOUR, CATEGORY, Status, ONE, RATE, dayStart, deployProtocol, deployProtocolWith, withCalendars, middayTomorrow, paidBooking, passHour } = require("./fixtures");

const tomorrow = async () => dayStart(await middayTomorrow()) + DAY;

describe("Fixes for the contract review findings", () => {
  describe("#1 booking is access-controlled", () => {
    it("rejects a stranger booking someone else's slot, directly or as a marketplace", async () => {
      const { calendar, mallory, aliceCal } = await loadFixture(withCalendars);
      const date = await tomorrow();
      await expect(calendar.connect(mallory).bookSlot(aliceCal, date, 5, 0, CATEGORY)).to.be.revertedWithCustomError(calendar, "NotCalendarOwner");
      await expect(calendar.connect(mallory).bookSlotFor(aliceCal, date, 5, 0, CATEGORY, mallory.address)).to.be.revertedWithCustomError(calendar, "NotMarketplace");
    });

    it("refuses the calendar owner as the paying buyer", async () => {
      const { calendar, deployer, carol, alice, aliceCal } = await loadFixture(withCalendars);
      await calendar.connect(deployer).setMarketplace(carol.address, true);       // carol stands in for a marketplace
      await expect(calendar.connect(carol).bookSlotFor(aliceCal, await tomorrow(), 1, 1n, CATEGORY, alice.address))
        .to.be.revertedWithCustomError(calendar, "SelfBooking");
    });
  });

  describe("#2 TIME cannot be minted without a counterparty", () => {
    it("lets an owner block their own hours but never complete them", async () => {
      const { calendar, token, alice, aliceCal } = await loadFixture(withCalendars);
      const date = await tomorrow();
      await calendar.connect(alice).bookSlot(aliceCal, date, 0, 0, CATEGORY);
      await expect(calendar.connect(alice).completeSlot(aliceCal, date, 0)).to.be.revertedWithCustomError(calendar, "NotMarketplace");
      expect(await token.totalHoursMinted()).to.equal(0n);
    });

    it("does not let even a marketplace complete a self-booked slot", async () => {
      const { calendar, deployer, carol, alice, aliceCal } = await loadFixture(withCalendars);
      await calendar.connect(deployer).setMarketplace(carol.address, true);
      const date = await tomorrow();
      await calendar.connect(alice).bookSlot(aliceCal, date, 0, 0, CATEGORY);
      await expect(calendar.connect(carol).completeSlot(aliceCal, date, 0)).to.be.revertedWithCustomError(calendar, "NotAuthorized");
    });

    it("mints only after the hour has ended, and only when the buyer releases a real payment", async () => {
      const p = await loadFixture(withCalendars);
      const { calendar, token, market, bob } = p;
      const { date, slot, bookingId } = await paidBooking(p);
      await expect(market.connect(bob).completeBooking(bookingId)).to.be.revertedWithCustomError(calendar, "HourNotEnded");
      expect(await token.totalHoursMinted()).to.equal(0n);
      await passHour(date, slot);
      await market.connect(bob).completeBooking(bookingId);
      expect(await token.totalHoursMinted()).to.equal(1n);
    });

    it("limits booking to 90 days ahead", async () => {
      const { calendar, alice, aliceCal } = await loadFixture(withCalendars);
      const today = dayStart(await middayTomorrow());
      await calendar.connect(alice).bookSlot(aliceCal, today + 90 * DAY, 1, 0, CATEGORY);
      await expect(calendar.connect(alice).bookSlot(aliceCal, today + 91 * DAY, 1, 0, CATEGORY)).to.be.revertedWithCustomError(calendar, "DateTooFar");
    });
  });

  describe("#3 no one can burn an hour", () => {
    it("reopens a cancelled slot so it can be booked again", async () => {
      const { calendar, alice, aliceCal } = await loadFixture(withCalendars);
      const date = await tomorrow();
      await calendar.connect(alice).bookSlot(aliceCal, date, 7, 0, CATEGORY);
      await calendar.connect(alice).cancelSlot(aliceCal, date, 7);
      await calendar.connect(alice).bookSlot(aliceCal, date, 7, 0, CATEGORY);
      expect((await calendar.getSlot(aliceCal, date, 7)).status).to.equal(Status.BOOKED);
    });

    it("lets a stranger neither book nor cancel, and a buyer cannot cancel an escrowed slot directly", async () => {
      const p = await loadFixture(withCalendars);
      const { calendar, bob, mallory, aliceCal } = p;
      const { date, slot } = await paidBooking(p);
      await expect(calendar.connect(mallory).cancelSlot(aliceCal, date, slot)).to.be.revertedWithCustomError(calendar, "NotAuthorized");
      await expect(calendar.connect(bob).cancelSlot(aliceCal, date, slot)).to.be.revertedWithCustomError(calendar, "NotAuthorized");
    });
  });

  describe("#4 booking window (unchanged)", () => {
    it("accepts the current UTC day onward and rejects yesterday", async () => {
      const { calendar, alice, aliceCal } = await loadFixture(withCalendars);
      const t = await middayTomorrow();
      const today = dayStart(t);
      await expect(calendar.connect(alice).bookSlot(aliceCal, today - DAY, 1, 1n, CATEGORY)).to.be.revertedWithCustomError(calendar, "InvalidDate");
      await calendar.connect(alice).bookSlot(aliceCal, today, 1, 1n, CATEGORY);
    });
  });

  describe("#5 receipts record the real buyer", () => {
    it("sets the receipt's employer to the buyer, not the calendar contract", async () => {
      const p = await loadFixture(withCalendars);
      const { receipt, market, calendar, alice, bob } = p;
      const { date, slot, bookingId } = await paidBooking(p);
      await passHour(date, slot);
      await market.connect(bob).completeBooking(bookingId);
      const r = await receipt.receipts(1);
      expect(r.worker).to.equal(alice.address);
      expect(r.employer).to.equal(bob.address);
      expect(r.employer).to.not.equal(await calendar.getAddress());
    });

    it("NOT FIXED: slot data is still public (privacy needs a design change, not a patch)", async () => {
      const p = await loadFixture(withCalendars);
      const { calendar, carol, bob, aliceCal } = p;
      const { date, slot } = await paidBooking(p);
      const seen = await calendar.connect(carol).getSlot(aliceCal, date, slot);
      expect(seen.bookedBy).to.equal(bob.address);
      expect(seen.agreedRate).to.equal(RATE);
    });
  });

  describe("#6 escrow", () => {
    it("lets the worker claim after the timeout if the buyer neither releases nor disputes", async () => {
      const p = await loadFixture(withCalendars);
      const { market, token, pay, alice } = p;
      const { date, slot, bookingId } = await paidBooking(p);
      await passHour(date, slot);
      await expect(market.connect(alice).claimAfterTimeout(bookingId)).to.be.revertedWithCustomError(market, "TooEarly");
      await time.increase(7 * DAY);
      await market.connect(alice).claimAfterTimeout(bookingId);
      expect(await pay.balanceOf(alice.address)).to.equal(RATE * 975n / 1000n);
      expect(await token.balanceOf(alice.address)).to.equal(ONE);
    });

    it("only the worker can claim after the timeout", async () => {
      const p = await loadFixture(withCalendars);
      const { market, bob } = p;
      const { date, slot, bookingId } = await paidBooking(p);
      await passHour(date, slot);
      await time.increase(7 * DAY);
      await expect(market.connect(bob).claimAfterTimeout(bookingId)).to.be.revertedWithCustomError(market, "NotAuthorized");
    });

    it("mints no TIME for a cancelled booking: the buyer is refunded and the hour reopens", async () => {
      const p = await loadFixture(withCalendars);
      const { market, calendar, token, pay, alice, bob, aliceCal } = p;
      const { date, slot, bookingId } = await paidBooking(p);
      await market.connect(alice).cancelBooking(bookingId);
      expect(await pay.balanceOf(bob.address)).to.equal(1000n * ONE);
      expect((await calendar.getSlot(aliceCal, date, slot)).status).to.equal(Status.AVAILABLE);
      await passHour(date, slot);
      await expect(market.connect(bob).completeBooking(bookingId)).to.be.revertedWithCustomError(market, "InvalidStatus");
      expect(await token.totalHoursMinted()).to.equal(0n);
    });

    it("resolves a dispute for the buyer by refunding and reopening the hour", async () => {
      const p = await loadFixture(withCalendars);
      const { market, calendar, deployer, alice, bob, pay, aliceCal } = p;
      const { date, slot, bookingId } = await paidBooking(p);
      await market.connect(alice).disputeBooking(bookingId);
      await market.connect(deployer).resolveDispute(bookingId, true);
      expect(await pay.balanceOf(bob.address)).to.equal(1000n * ONE);
      expect((await calendar.getSlot(aliceCal, date, slot)).status).to.equal(Status.AVAILABLE);
    });

    it("resolves a dispute for the worker only once the hour has ended, and then mints", async () => {
      const p = await loadFixture(withCalendars);
      const { market, calendar, token, deployer, alice } = p;
      const { date, slot, bookingId } = await paidBooking(p);
      await market.connect(alice).disputeBooking(bookingId);
      await expect(market.connect(deployer).resolveDispute(bookingId, false)).to.be.revertedWithCustomError(calendar, "HourNotEnded");
      await passHour(date, slot);
      await market.connect(deployer).resolveDispute(bookingId, false);
      expect(await token.balanceOf(alice.address)).to.equal(ONE);
    });

    it("validates a booking before taking payment", async () => {
      const p = await loadFixture(withCalendars);
      const { market, pay, alice, bob } = p;
      const date = await tomorrow();
      await pay.mint(bob.address, 1000n * ONE);
      await market.connect(alice).createListing(RATE, [CATEGORY], "freelance");
      const id = await market.workerListingId(alice.address);
      await pay.connect(bob).approve(await market.getAddress(), 1000n * ONE);
      await expect(market.connect(bob).bookTime(id, date, 24, CATEGORY)).to.be.revertedWithCustomError(market, "InvalidSlot");
      await expect(market.connect(bob).bookTime(id, date - 3 * DAY, 1, CATEGORY)).to.be.revertedWithCustomError(market, "InvalidDate");
      await expect(market.connect(alice).bookTime(id, date, 1, CATEGORY)).to.be.revertedWithCustomError(market, "NotAuthorized");
    });

    it("does not let a buyer cancel once the worker has confirmed", async () => {
      const p = await loadFixture(withCalendars);
      const { market, bob } = p;
      const { bookingId } = await paidBooking(p);
      await expect(market.connect(bob).cancelBooking(bookingId)).to.be.revertedWithCustomError(market, "InvalidStatus");
    });
  });

  describe("#7 deployment leaves no single key able to mint", () => {
    it("strips the deployer's minter role on the token and the receipts", async () => {
      const { token, receipt, deployer, alice, aliceCal } = await loadFixture(withCalendars);
      expect(await token.hasRole(await token.MINTER_ROLE(), deployer.address)).to.equal(false);
      expect(await receipt.hasRole(await receipt.MINTER_ROLE(), deployer.address)).to.equal(false);
      await expect(receipt.connect(deployer).mintWithEmployer(alice.address, alice.address, aliceCal, 0, 0, CATEGORY, 1n))
        .to.be.revertedWithCustomError(receipt, "AccessControlUnauthorizedAccount");
    });

    it("has no unbounded mint on the token and no receipt mint that records the caller as employer", async () => {
      const { token, receipt } = await loadFixture(withCalendars);
      expect(token.interface.getFunction("mint(address,uint256)")).to.equal(null);
      expect(receipt.interface.fragments.filter((f) => f.type === "function" && f.name === "mint")).to.deep.equal([]);
    });

    it("lets only the calendar mint", async () => {
      const { token, calendar } = await loadFixture(withCalendars);
      expect(await token.hasRole(await token.MINTER_ROLE(), await calendar.getAddress())).to.equal(true);
    });

    it("hands administration to a multisig on every contract, including the distributor", async () => {
      const [, , , , carol] = await ethers.getSigners();
      const p = await deployProtocolWith(carol.address);
      const adminRole = await p.calendar.DEFAULT_ADMIN_ROLE();
      for (const c of [p.token, p.receipt, p.calendar, p.market, p.distributor]) {
        expect(await c.hasRole(adminRole, carol.address)).to.equal(true);
        expect(await c.hasRole(adminRole, p.deployer.address)).to.equal(false);
      }
      expect(await p.distributor.hasRole(await p.distributor.ORACLE_ROLE(), p.deployer.address)).to.equal(false);
    });
  });

  describe("residual risk (NOT closed by these fixes)", () => {
    it("a colluding pair can still wash-trade an hour, at a cost of only the 2.5% fee", async () => {
      const p = await loadFixture(withCalendars);
      const { market, pay, token, alice, bob, feeRecipient } = p;
      const { date, slot, bookingId } = await paidBooking(p);                     // "bob" is alice's second wallet
      await passHour(date, slot);
      await market.connect(bob).completeBooking(bookingId);
      expect(await token.balanceOf(alice.address)).to.equal(ONE);                 // TIME minted for a sham hour
      expect(await pay.balanceOf(feeRecipient.address)).to.equal(RATE * 25n / 1000n);
    });

    it("at a tiny rate the fee rounds to zero, so a sham hour is free", async () => {
      const p = await loadFixture(withCalendars);
      const { market, pay, token, alice, bob, feeRecipient } = p;
      const { date, slot, bookingId } = await paidBooking(p, { rate: 1n });
      await passHour(date, slot);
      await market.connect(bob).completeBooking(bookingId);
      expect(await token.balanceOf(alice.address)).to.equal(ONE);
      expect(await pay.balanceOf(feeRecipient.address)).to.equal(0n);
    });
  });
});
