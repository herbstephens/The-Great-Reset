// Each test below demonstrates one observation from reading the contracts
// (docs/product-alpha/time-protocol-and-hito.md in the GroundState repo).
//
// These are CHARACTERIZATION tests: they assert what the code does TODAY, so they
// pass. Where the behaviour is a problem, the test title says so. The skipped block at
// the bottom lists the behaviour we want instead; enable each one as its fix lands and
// flip the matching characterization test.
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { DAY, CATEGORY, Status, dayStart, withCalendars, middayTomorrow } = require("./fixtures");

const ONE = 10n ** 18n;
const RATE = 100n * ONE;

describe("Observations from the contract review", () => {
  describe("OBS-1: bookSlot has no access control", () => {
    it("lets any address book any available slot on someone else's calendar, at any rate", async () => {
      const { calendar, mallory, aliceCal } = await loadFixture(withCalendars);
      const t = await middayTomorrow();
      const date = dayStart(t) + DAY;
      await calendar.connect(mallory).bookSlot(aliceCal, date, 5, 0, CATEGORY);
      const slot = await calendar.getSlot(aliceCal, date, 5);
      expect(slot.status).to.equal(Status.BOOKED);
      expect(slot.bookedBy).to.equal(mallory.address);
      expect(slot.agreedRate).to.equal(0n);
    });
  });

  describe("OBS-2: the owner can mint TIME with no counterparty", () => {
    it("books an hour from a second address, completes it, and receives TIME and a receipt for no work and no payment", async () => {
      const { calendar, token, receipt, pay, alice, bob, aliceCal } = await loadFixture(withCalendars);
      const t = await middayTomorrow();
      const date = dayStart(t) + DAY;
      await calendar.connect(bob).bookSlot(aliceCal, date, 0, 0, CATEGORY);   // "bob" is just a second address
      await calendar.connect(alice).completeSlot(aliceCal, date, 0);
      expect(await token.balanceOf(alice.address)).to.equal(ONE);
      expect(await receipt.balanceOf(alice.address)).to.equal(1n);
      expect(await pay.balanceOf(alice.address)).to.equal(0n);                 // nothing was ever paid
    });

    it("can repeat that for all 24 hours of a day, minting 24 TIME with no counterparty", async () => {
      const { calendar, token, alice, bob, aliceCal } = await loadFixture(withCalendars);
      const t = await middayTomorrow();
      const date = dayStart(t) + DAY;
      for (let slot = 0; slot < 24; slot++) {
        await calendar.connect(bob).bookSlot(aliceCal, date, slot, 0, CATEGORY);
        await calendar.connect(alice).completeSlot(aliceCal, date, slot);
      }
      expect(await token.balanceOf(alice.address)).to.equal(24n * ONE);
      expect(await token.totalHoursMinted()).to.equal(24n);
      expect((await calendar.getCalendar(aliceCal)).totalHoursWorked).to.equal(24n);
    });

    it("completeSlot does not check that the hour has happened yet (it works for a slot 24 hours in the future)", async () => {
      const { calendar, token, alice, aliceCal } = await loadFixture(withCalendars);
      const t = await middayTomorrow();
      const future = dayStart(t) + 5 * DAY;
      await calendar.connect(alice).bookSlot(aliceCal, future, 3, 0, CATEGORY);
      await calendar.connect(alice).completeSlot(aliceCal, future, 3);        // "work" for a day five days from now
      expect(await token.balanceOf(alice.address)).to.equal(ONE);
    });
  });

  describe("OBS-3: a booker can permanently burn someone else's hour", () => {
    it("books and cancels a slot in two calls; the slot is then unbookable by anyone, including its owner", async () => {
      const { calendar, alice, bob, mallory, aliceCal } = await loadFixture(withCalendars);
      const t = await middayTomorrow();
      const date = dayStart(t) + DAY;
      await calendar.connect(mallory).bookSlot(aliceCal, date, 7, 0, CATEGORY);
      await calendar.connect(mallory).cancelSlot(aliceCal, date, 7);
      expect((await calendar.getSlot(aliceCal, date, 7)).status).to.equal(Status.CANCELLED);
      await expect(calendar.connect(alice).bookSlot(aliceCal, date, 7, 1n, CATEGORY)).to.be.revertedWithCustomError(calendar, "SlotNotAvailable");
      await expect(calendar.connect(bob).bookSlot(aliceCal, date, 7, 1n, CATEGORY)).to.be.revertedWithCustomError(calendar, "SlotNotAvailable");
    });

    it("has no function that reopens a cancelled slot", async () => {
      const { calendar } = await loadFixture(withCalendars);
      const names = calendar.interface.fragments.filter((f) => f.type === "function").map((f) => f.name);
      expect(names.filter((n) => /reopen|reset|release|clear|restore/i.test(n))).to.deep.equal([]);
    });
  });

  describe("OBS-4: only the current UTC day onward can be booked", () => {
    it("rejects yesterday and earlier, and accepts the start of today", async () => {
      const { calendar, alice, aliceCal } = await loadFixture(withCalendars);
      const t = await middayTomorrow();                                         // 12:00 UTC
      const today = dayStart(t);
      await expect(calendar.connect(alice).bookSlot(aliceCal, today - DAY, 1, 1n, CATEGORY)).to.be.revertedWithCustomError(calendar, "InvalidDate");
      await expect(calendar.connect(alice).bookSlot(aliceCal, t - DAY, 1, 1n, CATEGORY)).to.be.revertedWithCustomError(calendar, "InvalidDate");
      await expect(calendar.connect(alice).bookSlot(aliceCal, today - 2 * DAY, 1, 1n, CATEGORY)).to.be.revertedWithCustomError(calendar, "InvalidDate");
      await calendar.connect(alice).bookSlot(aliceCal, today, 1, 1n, CATEGORY);   // today at 00:00 is allowed
      expect((await calendar.getSlot(aliceCal, today, 1)).status).to.equal(Status.BOOKED);
    });
  });

  describe("OBS-5: calendar and receipt data is public", () => {
    it("exposes who booked an hour, at what rate, and in what category, to any reader", async () => {
      const { calendar, alice, carol, aliceCal } = await loadFixture(withCalendars);
      const t = await middayTomorrow();
      const date = dayStart(t) + DAY;
      await calendar.connect(alice).bookSlot(aliceCal, date, 4, 42n, CATEGORY);
      const seenByStranger = await calendar.connect(carol).getSlot(aliceCal, date, 4);
      expect(seenByStranger.bookedBy).to.equal(alice.address);
      expect(seenByStranger.agreedRate).to.equal(42n);
      expect(seenByStranger.workCategory).to.equal(CATEGORY);
    });

    it("records the calendar contract as the receipt's 'employer', not the buyer", async () => {
      const { calendar, receipt, alice, aliceCal } = await loadFixture(withCalendars);
      const t = await middayTomorrow();
      const date = dayStart(t) + DAY;
      await calendar.connect(alice).bookSlot(aliceCal, date, 6, 10n, CATEGORY);
      await calendar.connect(alice).completeSlot(aliceCal, date, 6);
      const r = await receipt.receipts(1);
      expect(r.worker).to.equal(alice.address);
      expect(r.employer).to.equal(await calendar.getAddress());                // a data-integrity bug: whoever booked is not recorded
      expect(r.employer).to.not.equal(alice.address);
      expect(r.rate).to.equal(10n);
      expect(r.date).to.equal(BigInt(date));
    });

    it("accepts but discards the buyer commitment and worker nullifier in the TIME mint metadata", async () => {
      const { calendar, token, alice, aliceCal } = await loadFixture(withCalendars);
      const t = await middayTomorrow();
      const date = dayStart(t) + DAY;
      await calendar.connect(alice).bookSlot(aliceCal, date, 8, 1n, CATEGORY);
      await calendar.connect(alice).completeSlot(aliceCal, date, 8);
      const [ev] = await token.queryFilter(token.filters.TIMEMinted());
      expect(ev.fragment.inputs.map((i) => i.name)).to.deep.equal(["worker", "amount", "numHours", "workCategory", "timestamp"]);
    });
  });

  describe("OBS-6: marketplace escrow", () => {
    async function listed() {
      const p = await withCalendars();
      const t = await middayTomorrow();
      const date = dayStart(t) + DAY;
      await p.pay.mint(p.bob.address, 1000n * ONE);
      await p.market.connect(p.alice).createListing(RATE, [CATEGORY], "freelance");
      const listingId = await p.market.workerListingId(p.alice.address);
      await p.pay.connect(p.bob).approve(await p.market.getAddress(), 1000n * ONE);
      await p.market.connect(p.bob).bookTime(listingId, date, 3, CATEGORY);
      return { ...p, date, bookingId: 1n };
    }

    it("pays the worker 97.5% and the fee recipient 2.5% when the buyer completes the booking", async () => {
      const { market, pay, alice, bob, feeRecipient, bookingId } = await loadFixture(listed);
      await market.connect(alice).confirmBooking(bookingId);
      await market.connect(bob).completeBooking(bookingId);
      expect(await pay.balanceOf(alice.address)).to.equal(RATE * 975n / 1000n);
      expect(await pay.balanceOf(feeRecipient.address)).to.equal(RATE * 25n / 1000n);
      expect(await pay.balanceOf(await market.getAddress())).to.equal(0n);
    });

    it("lets the buyer withhold release forever: the worker cannot release, and the funds stay locked until an admin resolves a dispute", async () => {
      const { market, pay, alice, deployer, bookingId } = await loadFixture(listed);
      await market.connect(alice).confirmBooking(bookingId);
      await expect(market.connect(alice).completeBooking(bookingId)).to.be.revertedWithCustomError(market, "NotAuthorized");
      expect(await pay.balanceOf(await market.getAddress())).to.equal(RATE);      // no timeout, nothing moves
      await market.connect(alice).disputeBooking(bookingId);
      expect(await pay.balanceOf(await market.getAddress())).to.equal(RATE);      // still locked
      await market.connect(deployer).resolveDispute(bookingId, false);            // only the admin can unlock it
      expect(await pay.balanceOf(alice.address)).to.equal(RATE * 975n / 1000n);
    });

    it("lets the worker mint TIME for a confirmed booking whose payment has not been released", async () => {
      const { calendar, market, token, pay, alice, date, aliceCal, bookingId } = await loadFixture(listed);
      await market.connect(alice).confirmBooking(bookingId);
      await calendar.connect(alice).completeSlot(aliceCal, date, 3);
      expect(await token.balanceOf(alice.address)).to.equal(ONE);
      expect(await pay.balanceOf(await market.getAddress())).to.equal(RATE);      // buyer has not approved anything
    });

    it("lets the worker keep the TIME after cancelling the booking and refunding the buyer", async () => {
      const { calendar, market, token, pay, alice, bob, date, aliceCal, bookingId } = await loadFixture(listed);
      await market.connect(alice).confirmBooking(bookingId);
      await market.connect(alice).cancelBooking(bookingId);                       // buyer refunded
      expect(await pay.balanceOf(bob.address)).to.equal(1000n * ONE);
      expect((await calendar.getSlot(aliceCal, date, 3)).status).to.equal(Status.BOOKED);   // marketplace never cancels the slot
      await calendar.connect(alice).completeSlot(aliceCal, date, 3);
      expect(await token.balanceOf(alice.address)).to.equal(ONE);                 // minted for a refunded booking
    });

    it("does not let a buyer cancel once the worker has confirmed", async () => {
      const { market, alice, bob, bookingId } = await loadFixture(listed);
      await market.connect(alice).confirmBooking(bookingId);
      await expect(market.connect(bob).cancelBooking(bookingId)).to.be.revertedWithCustomError(market, "InvalidStatus");
    });
  });

  describe("OBS-7: deployment leaves privileged roles with the deployer", () => {
    it("keeps MINTER_ROLE on TIMEToken with the deployer, who can mint any amount", async () => {
      const { token, deployer } = await loadFixture(withCalendars);
      expect(await token.hasRole(await token.MINTER_ROLE(), deployer.address)).to.equal(true);
      await token.connect(deployer)["mint(address,uint256)"](deployer.address, 1000n * ONE);
      expect(await token.balanceOf(deployer.address)).to.equal(1000n * ONE);
      expect(await token.totalHoursMinted()).to.equal(1000n);
    });

    it("lets the deployer forge a receipt for work that never happened, with any employer", async () => {
      const { receipt, deployer, alice, bob, aliceCal } = await loadFixture(withCalendars);
      await receipt.connect(deployer).mintWithEmployer(alice.address, bob.address, aliceCal, 0, 0, CATEGORY, 999n);
      expect(await receipt.totalHoursProven(alice.address)).to.equal(1n);
      expect((await receipt.receipts(1)).employer).to.equal(bob.address);
    });

    it("keeps the deployer's admin role on the calendar, which can repoint the token contract", async () => {
      const { calendar, deployer } = await loadFixture(withCalendars);
      expect(await calendar.hasRole(await calendar.DEFAULT_ADMIN_ROLE(), deployer.address)).to.equal(true);
    });
  });
});

// Desired behaviour once the fixes land. Enable each test and update the matching
// characterization test above when its fix ships.
describe.skip("Desired behaviour after fixes (pending)", () => {
  it("bookSlot is restricted to the calendar owner or the marketplace");
  it("completeSlot requires a booking the counterparty has confirmed, and a slot whose hour has passed");
  it("a cancelled slot can be reopened by the calendar owner");
  it("a booker cannot cancel a slot booked by someone else's offer, and cannot burn it");
  it("receipts record the real buyer, not the calendar contract");
  it("TIME is not minted for a cancelled or refunded booking");
  it("marketplace escrow has a timeout so a buyer cannot withhold release indefinitely");
  it("deployer roles are renounced or time-locked after deployment");
});
