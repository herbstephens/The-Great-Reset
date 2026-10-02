const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

const DAY = 86400;
const HOUR = 3600;
const CATEGORY = ethers.keccak256(ethers.toUtf8Bytes("FREELANCE"));
const PROOF = Array(8).fill(0n);
const Status = { AVAILABLE: 0n, BOOKED: 1n, COMPLETED: 2n, CANCELLED: 3n };
const dayStart = (ts) => Math.floor(Number(ts) / DAY) * DAY;

/** Deploys the whole protocol wired the way scripts/deploy.js wires it, plus mocks. */
async function deployProtocol() {
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

  await calendar.setTIMEToken(await token.getAddress());
  await calendar.setWorkReceipt(await receipt.getAddress());
  await token.grantRole(await token.MINTER_ROLE(), await calendar.getAddress());
  await receipt.grantRole(await receipt.MINTER_ROLE(), await calendar.getAddress());

  return { deployer, alice, bob, mallory, carol, feeRecipient, worldId, calendar, token, receipt, pay, market };
}

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

module.exports = { DAY, HOUR, CATEGORY, PROOF, Status, dayStart, deployProtocol, withCalendars, middayTomorrow };
