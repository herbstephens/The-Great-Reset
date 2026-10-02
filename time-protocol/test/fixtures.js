const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { wireProtocol } = require("../scripts/wire");

const DAY = 86400;
const HOUR = 3600;
const CATEGORY = ethers.keccak256(ethers.toUtf8Bytes("FREELANCE"));
const PROOF = Array(8).fill(0n);
const Status = { AVAILABLE: 0n, BOOKED: 1n, COMPLETED: 2n, CANCELLED: 3n };
const dayStart = (ts) => Math.floor(Number(ts) / DAY) * DAY;

/** Deploys the whole protocol and wires it with the same script deploy.js uses. */
async function deployProtocolWith(adminAddress) {
  const [deployer, alice, bob, mallory, carol, feeRecipient] = await ethers.getSigners();

  const worldId = await (await ethers.getContractFactory("MockWorldID")).deploy();
  const calendar = await (await ethers.getContractFactory("UniversalCalendar")).deploy(
    await worldId.getAddress(), "app_test", "create-calendar", 1
  );
  const token = await (await ethers.getContractFactory("TIMEToken")).deploy();
  const receipt = await (await ethers.getContractFactory("WorkReceipt")).deploy();
  const pay = await (await ethers.getContractFactory("MockPaymentToken")).deploy();
  const market = await (await ethers.getContractFactory("TIMEMarketplace")).deploy(
    await calendar.getAddress(), await pay.getAddress(), feeRecipient.address
  );
  const distributor = await (await ethers.getContractFactory("CommonsDistributor")).deploy(
    await calendar.getAddress(), await pay.getAddress()
  );

  await wireProtocol({
    deployer, admin: adminAddress || deployer.address,
    timeToken: token, workReceipt: receipt, calendar, marketplace: market, distributor,
  });

  return { deployer, alice, bob, mallory, carol, feeRecipient, worldId, calendar, token, receipt, pay, market, distributor };
}
const deployProtocol = () => deployProtocolWith();

/** Protocol plus a calendar owned by alice (nullifier 1) and bob (nullifier 2). */
async function withCalendars() {
  const p = await deployProtocol();
  await p.calendar.connect(p.alice).createCalendar(1, 1, PROOF);
  await p.calendar.connect(p.bob).createCalendar(1, 2, PROOF);
  const aliceCal = await p.calendar.getCalendarId(p.alice.address);
  const bobCal = await p.calendar.getCalendarId(p.bob.address);
  return { ...p, aliceCal, bobCal };
}

/** Moves the chain to 12:00 UTC on a fresh day so date arithmetic is unambiguous. */
async function middayTomorrow() {
  const now = await time.latest();
  const t = dayStart(now) + DAY + 12 * HOUR;
  await time.increaseTo(t);
  return t;
}

const ONE = 10n ** 18n;
const RATE = 100n * ONE;

/** alice lists, bob funds and books, alice confirms. Returns the booking and its slot. */
async function paidBooking(p, { slot = 3, rate = RATE } = {}) {
  const t = await middayTomorrow();
  const date = dayStart(t) + DAY;
  await p.pay.mint(p.bob.address, 1000n * ONE);
  await p.market.connect(p.alice).createListing(rate, [CATEGORY], "freelance");
  const listingId = await p.market.workerListingId(p.alice.address);
  await p.pay.connect(p.bob).approve(await p.market.getAddress(), 1000n * ONE);
  await p.market.connect(p.bob).bookTime(listingId, date, slot, CATEGORY);
  const bookingId = await p.market.getBuyerBookings(p.bob.address).then((ids) => ids[ids.length - 1]);
  await p.market.connect(p.alice).confirmBooking(bookingId);
  return { date, slot, bookingId, rate };
}

/** Moves the chain just past the end of the given hour. */
async function passHour(date, slot) {
  await time.increaseTo(date + (slot + 1) * HOUR + 1);
}

module.exports = { ONE, RATE, paidBooking, passHour, deployProtocolWith, DAY, HOUR, CATEGORY, PROOF, Status, dayStart, deployProtocol, withCalendars, middayTomorrow };
