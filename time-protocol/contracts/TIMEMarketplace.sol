// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IUniversalCalendar {
    function getCalendarId(address owner) external view returns (uint256);
    function bookSlotFor(
        uint256 calendarId,
        uint256 date,
        uint256 slotIndex,
        uint256 rate,
        bytes32 workCategory,
        address buyer
    ) external;
    function completeSlot(uint256 calendarId, uint256 date, uint256 slotIndex) external;
    function cancelSlot(uint256 calendarId, uint256 date, uint256 slotIndex) external;
}

/**
 * @title TIMEMarketplace
 * @notice Decentralized marketplace for buying and selling human time
 * @dev Connects time buyers with verified humans who have available slots
 * 
 * Workers list their available time with rates and categories.
 * Buyers browse listings and book slots directly.
 * Payment held in escrow until work completion.
 */
contract TIMEMarketplace is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    // ============ Structs ============
    
    struct Listing {
        uint256 id;
        address worker;
        uint256 calendarId;
        uint256 ratePerHour;        // In payment token units
        bytes32[] categories;        // Work categories offered
        string description;
        bool active;
        uint256 createdAt;
    }
    
    struct Booking {
        uint256 id;
        uint256 listingId;
        address buyer;
        address worker;
        uint256 calendarId;
        uint256 date;
        uint256 slotIndex;
        uint256 amount;
        bytes32 category;
        BookingStatus status;
        uint256 createdAt;
    }
    
    enum BookingStatus { PENDING, CONFIRMED, COMPLETED, CANCELLED, DISPUTED }
    
    // ============ State Variables ============
    
    IUniversalCalendar public calendar;
    IERC20 public paymentToken;
    
    uint256 private _listingIdCounter;
    uint256 private _bookingIdCounter;
    
    /// @notice After the hour ends, a worker can claim payment if the buyer has neither released nor disputed.
    uint256 public constant RELEASE_TIMEOUT = 7 days;

    // Fee configuration (basis points, 100 = 1%)
    uint256 public platformFeeBps = 250; // 2.5%
    address public feeRecipient;
    
    // Mappings
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Booking) public bookings;
    mapping(address => uint256) public workerListingId;
    mapping(address => uint256[]) public workerBookings;
    mapping(address => uint256[]) public buyerBookings;
    
    // Category index for discovery
    mapping(bytes32 => uint256[]) public categoryListings;
    
    // ============ Events ============
    
    event ListingCreated(uint256 indexed listingId, address indexed worker, uint256 ratePerHour);
    event ListingUpdated(uint256 indexed listingId, uint256 ratePerHour, bool active);
    event BookingCreated(uint256 indexed bookingId, uint256 indexed listingId, address buyer, uint256 date, uint256 slot);
    event BookingConfirmed(uint256 indexed bookingId);
    event BookingCompleted(uint256 indexed bookingId, uint256 workerPayout, uint256 platformFee);
    event BookingCancelled(uint256 indexed bookingId, address cancelledBy);
    event BookingDisputed(uint256 indexed bookingId);
    
    // ============ Errors ============
    
    error NotVerified();
    error ListingNotFound();
    error ListingNotActive();
    error BookingNotFound();
    error InvalidStatus();
    error NotAuthorized();
    error InvalidAmount();
    error AlreadyHasListing();
    error InvalidSlot();
    error InvalidDate();
    error TooEarly();
    
    // ============ Constructor ============
    
    constructor(
        address _calendar,
        address _paymentToken,
        address _feeRecipient
    ) {
        calendar = IUniversalCalendar(_calendar);
        paymentToken = IERC20(_paymentToken);
        feeRecipient = _feeRecipient;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    // ============ Worker Functions ============
    
    /**
     * @notice Create a listing to offer time for sale
     * @param ratePerHour Rate in payment token units per hour
     * @param categories Array of work categories offered
     * @param description Description of services offered
     */
    function createListing(
        uint256 ratePerHour,
        bytes32[] calldata categories,
        string calldata description
    ) external nonReentrant returns (uint256) {
        uint256 calendarId = calendar.getCalendarId(msg.sender);
        if (calendarId == 0) revert NotVerified();
        if (workerListingId[msg.sender] != 0) revert AlreadyHasListing();
        
        _listingIdCounter++;
        uint256 listingId = _listingIdCounter;
        
        listings[listingId] = Listing({
            id: listingId,
            worker: msg.sender,
            calendarId: calendarId,
            ratePerHour: ratePerHour,
            categories: categories,
            description: description,
            active: true,
            createdAt: block.timestamp
        });
        
        workerListingId[msg.sender] = listingId;
        
        // Index by category
        for (uint256 i = 0; i < categories.length; i++) {
            categoryListings[categories[i]].push(listingId);
        }
        
        emit ListingCreated(listingId, msg.sender, ratePerHour);
        
        return listingId;
    }
    
    /**
     * @notice Update listing rate and status
     */
    function updateListing(
        uint256 ratePerHour,
        bool active
    ) external {
        uint256 listingId = workerListingId[msg.sender];
        if (listingId == 0) revert ListingNotFound();
        
        Listing storage listing = listings[listingId];
        listing.ratePerHour = ratePerHour;
        listing.active = active;
        
        emit ListingUpdated(listingId, ratePerHour, active);
    }
    
    // ============ Buyer Functions ============
    
    /**
     * @notice Book a time slot from a listing
     * @param listingId ID of the listing to book from
     * @param date Date for the booking (unix timestamp, normalized to day)
     * @param slotIndex Hour slot (0-23)
     * @param category Work category for this booking
     */
    function bookTime(
        uint256 listingId,
        uint256 date,
        uint256 slotIndex,
        bytes32 category
    ) external nonReentrant returns (uint256) {
        Listing storage listing = listings[listingId];
        if (listing.id == 0) revert ListingNotFound();
        if (!listing.active) revert ListingNotActive();
        if (msg.sender == listing.worker) revert NotAuthorized();
        if (slotIndex >= 24) revert InvalidSlot();
        if ((date / 1 days) * 1 days < (block.timestamp / 1 days) * 1 days) revert InvalidDate();
        
        uint256 amount = listing.ratePerHour;
        if (amount == 0) revert InvalidAmount();
        
        // Transfer payment to escrow
        paymentToken.safeTransferFrom(msg.sender, address(this), amount);
        
        _bookingIdCounter++;
        uint256 bookingId = _bookingIdCounter;
        
        bookings[bookingId] = Booking({
            id: bookingId,
            listingId: listingId,
            buyer: msg.sender,
            worker: listing.worker,
            calendarId: listing.calendarId,
            date: date,
            slotIndex: slotIndex,
            amount: amount,
            category: category,
            status: BookingStatus.PENDING,
            createdAt: block.timestamp
        });
        
        workerBookings[listing.worker].push(bookingId);
        buyerBookings[msg.sender].push(bookingId);
        
        emit BookingCreated(bookingId, listingId, msg.sender, date, slotIndex);
        
        return bookingId;
    }
    
    /**
     * @notice Worker confirms the booking (books slot on calendar)
     */
    function confirmBooking(uint256 bookingId) external nonReentrant {
        Booking storage booking = bookings[bookingId];
        if (booking.id == 0) revert BookingNotFound();
        if (booking.worker != msg.sender) revert NotAuthorized();
        if (booking.status != BookingStatus.PENDING) revert InvalidStatus();
        
        // Book the slot on the calendar
        calendar.bookSlotFor(
            booking.calendarId,
            booking.date,
            booking.slotIndex,
            booking.amount,
            booking.category,
            booking.buyer
        );
        
        booking.status = BookingStatus.CONFIRMED;
        
        emit BookingConfirmed(bookingId);
    }
    
    /**
     * @notice Complete the booking and release payment
     * @dev Called by the buyer once the hour has ended. Completing the slot mints TIME
     *      and a receipt to the worker, so TIME exists only for an hour that was paid.
     */
    function completeBooking(uint256 bookingId) external nonReentrant {
        Booking storage booking = bookings[bookingId];
        if (booking.id == 0) revert BookingNotFound();
        if (booking.buyer != msg.sender) revert NotAuthorized();
        if (booking.status != BookingStatus.CONFIRMED) revert InvalidStatus();
        
        _settle(booking, bookingId);
    }

    /**
     * @notice Worker claims payment when the buyer has neither released nor disputed
     * @dev Possible once RELEASE_TIMEOUT has passed after the hour ended, so a buyer
     *      cannot withhold payment indefinitely.
     */
    function claimAfterTimeout(uint256 bookingId) external nonReentrant {
        Booking storage booking = bookings[bookingId];
        if (booking.id == 0) revert BookingNotFound();
        if (booking.worker != msg.sender) revert NotAuthorized();
        if (booking.status != BookingStatus.CONFIRMED) revert InvalidStatus();
        if (block.timestamp < _hourEnd(booking) + RELEASE_TIMEOUT) revert TooEarly();
        
        _settle(booking, bookingId);
    }

    /**
     * @notice Cancel a booking
     * @dev Buyer can cancel pending, worker can cancel pending/confirmed
     */
    function cancelBooking(uint256 bookingId) external nonReentrant {
        Booking storage booking = bookings[bookingId];
        if (booking.id == 0) revert BookingNotFound();
        
        bool isBuyer = booking.buyer == msg.sender;
        bool isWorker = booking.worker == msg.sender;
        
        if (!isBuyer && !isWorker) revert NotAuthorized();
        
        // Buyer can only cancel PENDING
        if (isBuyer && booking.status != BookingStatus.PENDING) revert InvalidStatus();
        
        // Worker can cancel PENDING or CONFIRMED
        if (isWorker && booking.status != BookingStatus.PENDING && booking.status != BookingStatus.CONFIRMED) {
            revert InvalidStatus();
        }
        
        bool slotHeld = booking.status == BookingStatus.CONFIRMED;
        booking.status = BookingStatus.CANCELLED;
        
        // Reopen the hour if it was reserved, then refund the buyer
        if (slotHeld) {
            calendar.cancelSlot(booking.calendarId, booking.date, booking.slotIndex);
        }
        paymentToken.safeTransfer(booking.buyer, booking.amount);
        
        emit BookingCancelled(bookingId, msg.sender);
    }
    
    /**
     * @notice Raise a dispute on a booking
     */
    function disputeBooking(uint256 bookingId) external {
        Booking storage booking = bookings[bookingId];
        if (booking.id == 0) revert BookingNotFound();
        if (booking.buyer != msg.sender && booking.worker != msg.sender) revert NotAuthorized();
        if (booking.status != BookingStatus.CONFIRMED) revert InvalidStatus();
        
        booking.status = BookingStatus.DISPUTED;
        
        emit BookingDisputed(bookingId);
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Get listings by category
     */
    function getListingsByCategory(bytes32 category) external view returns (uint256[] memory) {
        return categoryListings[category];
    }
    
    /**
     * @notice Get worker's bookings
     */
    function getWorkerBookings(address worker) external view returns (uint256[] memory) {
        return workerBookings[worker];
    }
    
    /**
     * @notice Get buyer's bookings
     */
    function getBuyerBookings(address buyer) external view returns (uint256[] memory) {
        return buyerBookings[buyer];
    }
    
    /**
     * @notice Get listing categories
     */
    function getListingCategories(uint256 listingId) external view returns (bytes32[] memory) {
        return listings[listingId].categories;
    }
    
    // ============ Admin Functions ============
    
    function setPlatformFee(uint256 _feeBps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_feeBps <= 1000, "Fee too high"); // Max 10%
        platformFeeBps = _feeBps;
    }
    
    function setFeeRecipient(address _recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeRecipient = _recipient;
    }
    
    /**
     * @notice Resolve a disputed booking (admin only)
     * @param bookingId Booking to resolve
     * @param refundBuyer If true, refund buyer; if false, pay worker
     */
    function resolveDispute(
        uint256 bookingId,
        bool refundBuyer
    ) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        Booking storage booking = bookings[bookingId];
        if (booking.status != BookingStatus.DISPUTED) revert InvalidStatus();
        
        if (refundBuyer) {
            booking.status = BookingStatus.CANCELLED;
            calendar.cancelSlot(booking.calendarId, booking.date, booking.slotIndex);
            paymentToken.safeTransfer(booking.buyer, booking.amount);
            emit BookingCancelled(bookingId, msg.sender);
        } else {
            // Paying the worker completes the slot, which needs the hour to have ended.
            _settle(booking, bookingId);
        }
    }

    // ============ Internal ============

    function _hourEnd(Booking storage booking) internal view returns (uint256) {
        return (booking.date / 1 days) * 1 days + (booking.slotIndex + 1) * 1 hours;
    }

    /// @dev Completes the calendar slot (mints TIME and a receipt) and pays the worker.
    function _settle(Booking storage booking, uint256 bookingId) internal {
        booking.status = BookingStatus.COMPLETED;
        
        calendar.completeSlot(booking.calendarId, booking.date, booking.slotIndex);
        
        uint256 platformFee = (booking.amount * platformFeeBps) / 10000;
        uint256 workerPayout = booking.amount - platformFee;
        paymentToken.safeTransfer(booking.worker, workerPayout);
        if (platformFee > 0) {
            paymentToken.safeTransfer(feeRecipient, platformFee);
        }
        
        emit BookingCompleted(bookingId, workerPayout, platformFee);
    }
}
