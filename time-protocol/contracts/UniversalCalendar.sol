// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IWorldID {
    function verifyProof(
        uint256 root,
        uint256 groupId,
        uint256 signalHash,
        uint256 nullifierHash,
        uint256 externalNullifierHash,
        uint256[8] calldata proof
    ) external view;
}

interface ITIMEToken {
    struct MintMetadata {
        uint256 mintTimestamp;
        uint256 workerNullifierHash;
        bytes32 buyerCommitment;
        bytes32 workCategory;
        uint256 originalRate;
    }
    
    function mint(address to, uint256 numHours, MintMetadata calldata metadata) external returns (uint256);
}

interface IWorkReceipt {
    function mint(
        address to,
        uint256 calendarId,
        uint256 slotIndex,
        uint256 date,
        bytes32 workCategory,
        uint256 rate
    ) external returns (uint256);
}

/**
 * @title UniversalCalendar
 * @notice Soulbound NFT representing a human's 24-hour daily capacity
 * @dev Each verified human receives exactly one calendar. Calendars cannot be transferred.
 * 
 * The calendar enforces physical time constraints cryptographically:
 * - 24 hourly slots per day (00:00-23:59 UTC)
 * - Each slot can only be booked once per day
 * - Double-booking is impossible at the protocol level
 */
contract UniversalCalendar is ERC721, ERC721Enumerable, AccessControl, ReentrancyGuard {
    
    // ============ Enums ============
    
    enum SlotStatus { AVAILABLE, BOOKED, COMPLETED, CANCELLED }
    
    // ============ Structs ============
    
    struct TimeSlot {
        SlotStatus status;
        address bookedBy;
        uint256 agreedRate;
        bytes32 workCategory;
        uint256 bookedAt;
        uint256 completedAt;
    }
    
    struct Calendar {
        uint256 nullifierHash;      // World ID reference
        uint256 createdAt;
        uint256 totalHoursWorked;
        bool active;
    }
    
    // ============ Constants ============
    
    uint256 public constant SLOTS_PER_DAY = 24;
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    
    // ============ State Variables ============
    
    IWorldID public immutable worldId;
    ITIMEToken public timeToken;
    IWorkReceipt public workReceipt;
    
    uint256 public immutable groupId;
    uint256 public immutable externalNullifier;
    
    uint256 private _calendarIdCounter;
    
    // Mappings
    mapping(uint256 => Calendar) public calendars;
    mapping(uint256 => bool) public nullifierHashUsed;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => TimeSlot))) public slots;
    // slots[calendarId][date][slotIndex] => TimeSlot
    
    // ============ Events ============
    
    event CalendarCreated(
        uint256 indexed calendarId,
        address indexed owner,
        uint256 nullifierHash,
        uint256 timestamp
    );
    
    event SlotBooked(
        uint256 indexed calendarId,
        uint256 indexed date,
        uint256 slotIndex,
        address bookedBy,
        uint256 rate,
        bytes32 workCategory
    );
    
    event SlotCompleted(
        uint256 indexed calendarId,
        uint256 indexed date,
        uint256 slotIndex,
        uint256 timeMinted
    );
    
    event SlotCancelled(
        uint256 indexed calendarId,
        uint256 indexed date,
        uint256 slotIndex
    );
    
    // ============ Errors ============
    
    error AlreadyRegistered();
    error InvalidProof();
    error CalendarNotFound();
    error NotCalendarOwner();
    error SlotNotAvailable();
    error SlotNotBooked();
    error InvalidSlotIndex();
    error InvalidDate();
    error NotAuthorized();
    error TransferNotAllowed();
    
    // ============ Constructor ============
    
    constructor(
        address _worldId,
        string memory _appId,
        string memory _actionId,
        uint256 _groupId
    ) ERC721("Universal Calendar", "UCAL") {
        worldId = IWorldID(_worldId);
        groupId = _groupId;
        externalNullifier = uint256(keccak256(abi.encodePacked(_appId, _actionId)));
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(VERIFIER_ROLE, msg.sender);
    }
    
    // ============ External Functions ============
    
    /**
     * @notice Create a soulbound calendar for a verified human
     * @param root Merkle root from World ID
     * @param nullifierHash Unique identifier for this human
     * @param proof ZK proof from World ID
     */
    function createCalendar(
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) external nonReentrant returns (uint256) {
        if (nullifierHashUsed[nullifierHash]) revert AlreadyRegistered();
        
        // Verify the World ID proof
        worldId.verifyProof(
            root,
            groupId,
            uint256(uint160(msg.sender)),
            nullifierHash,
            externalNullifier,
            proof
        );
        
        nullifierHashUsed[nullifierHash] = true;
        
        _calendarIdCounter++;
        uint256 calendarId = _calendarIdCounter;
        
        calendars[calendarId] = Calendar({
            nullifierHash: nullifierHash,
            createdAt: block.timestamp,
            totalHoursWorked: 0,
            active: true
        });
        
        _safeMint(msg.sender, calendarId);
        
        emit CalendarCreated(calendarId, msg.sender, nullifierHash, block.timestamp);
        
        return calendarId;
    }
    
    /**
     * @notice Book a time slot
     * @param calendarId Calendar to book on
     * @param date Unix timestamp representing the day (normalized to midnight UTC)
     * @param slotIndex Hour index (0-23)
     * @param rate Agreed payment rate for this slot
     * @param workCategory Category of work to be performed
     */
    function bookSlot(
        uint256 calendarId,
        uint256 date,
        uint256 slotIndex,
        uint256 rate,
        bytes32 workCategory
    ) external nonReentrant {
        if (!_exists(calendarId)) revert CalendarNotFound();
        if (slotIndex >= SLOTS_PER_DAY) revert InvalidSlotIndex();
        
        // Normalize date to midnight UTC
        uint256 normalizedDate = (date / 1 days) * 1 days;
        if (normalizedDate < block.timestamp - 1 days) revert InvalidDate();
        
        TimeSlot storage slot = slots[calendarId][normalizedDate][slotIndex];
        if (slot.status != SlotStatus.AVAILABLE) revert SlotNotAvailable();
        
        slot.status = SlotStatus.BOOKED;
        slot.bookedBy = msg.sender;
        slot.agreedRate = rate;
        slot.workCategory = workCategory;
        slot.bookedAt = block.timestamp;
        
        emit SlotBooked(calendarId, normalizedDate, slotIndex, msg.sender, rate, workCategory);
    }
    
    /**
     * @notice Mark a slot as completed and mint TIME + WorkReceipt
     * @param calendarId Calendar ID
     * @param date Date of the slot
     * @param slotIndex Hour index (0-23)
     */
    function completeSlot(
        uint256 calendarId,
        uint256 date,
        uint256 slotIndex
    ) external nonReentrant {
        if (!_exists(calendarId)) revert CalendarNotFound();
        if (ownerOf(calendarId) != msg.sender) revert NotCalendarOwner();
        if (slotIndex >= SLOTS_PER_DAY) revert InvalidSlotIndex();
        
        uint256 normalizedDate = (date / 1 days) * 1 days;
        TimeSlot storage slot = slots[calendarId][normalizedDate][slotIndex];
        
        if (slot.status != SlotStatus.BOOKED) revert SlotNotBooked();
        
        slot.status = SlotStatus.COMPLETED;
        slot.completedAt = block.timestamp;
        
        calendars[calendarId].totalHoursWorked++;
        
        // Mint TIME token
        ITIMEToken.MintMetadata memory metadata = ITIMEToken.MintMetadata({
            mintTimestamp: block.timestamp,
            workerNullifierHash: calendars[calendarId].nullifierHash,
            buyerCommitment: keccak256(abi.encodePacked(slot.bookedBy)),
            workCategory: slot.workCategory,
            originalRate: slot.agreedRate
        });
        
        uint256 timeMinted = timeToken.mint(msg.sender, 1, metadata);
        
        // Mint WorkReceipt NFT
        if (address(workReceipt) != address(0)) {
            workReceipt.mint(
                msg.sender,
                calendarId,
                slotIndex,
                normalizedDate,
                slot.workCategory,
                slot.agreedRate
            );
        }
        
        emit SlotCompleted(calendarId, normalizedDate, slotIndex, timeMinted);
    }
    
    /**
     * @notice Cancel a booked slot
     * @param calendarId Calendar ID
     * @param date Date of the slot
     * @param slotIndex Hour index (0-23)
     */
    function cancelSlot(
        uint256 calendarId,
        uint256 date,
        uint256 slotIndex
    ) external nonReentrant {
        if (!_exists(calendarId)) revert CalendarNotFound();
        if (slotIndex >= SLOTS_PER_DAY) revert InvalidSlotIndex();
        
        uint256 normalizedDate = (date / 1 days) * 1 days;
        TimeSlot storage slot = slots[calendarId][normalizedDate][slotIndex];
        
        // Only owner or booker can cancel
        bool isOwner = ownerOf(calendarId) == msg.sender;
        bool isBooker = slot.bookedBy == msg.sender;
        if (!isOwner && !isBooker) revert NotAuthorized();
        
        if (slot.status != SlotStatus.BOOKED) revert SlotNotBooked();
        
        slot.status = SlotStatus.CANCELLED;
        
        emit SlotCancelled(calendarId, normalizedDate, slotIndex);
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Get slot status for a specific day and hour
     */
    function getSlot(
        uint256 calendarId,
        uint256 date,
        uint256 slotIndex
    ) external view returns (TimeSlot memory) {
        uint256 normalizedDate = (date / 1 days) * 1 days;
        return slots[calendarId][normalizedDate][slotIndex];
    }
    
    /**
     * @notice Get all slots for a calendar on a specific day
     */
    function getDaySlots(
        uint256 calendarId,
        uint256 date
    ) external view returns (TimeSlot[24] memory daySlots) {
        uint256 normalizedDate = (date / 1 days) * 1 days;
        for (uint256 i = 0; i < SLOTS_PER_DAY; i++) {
            daySlots[i] = slots[calendarId][normalizedDate][i];
        }
        return daySlots;
    }
    
    /**
     * @notice Get calendar details
     */
    function getCalendar(uint256 calendarId) external view returns (Calendar memory) {
        return calendars[calendarId];
    }
    
    /**
     * @notice Check if a nullifier hash has been used
     */
    function isNullifierUsed(uint256 nullifierHash) external view returns (bool) {
        return nullifierHashUsed[nullifierHash];
    }
    
    /**
     * @notice Get calendar ID for an address (returns 0 if none)
     */
    function getCalendarId(address owner) external view returns (uint256) {
        if (balanceOf(owner) == 0) return 0;
        return tokenOfOwnerByIndex(owner, 0);
    }
    
    // ============ Admin Functions ============
    
    function setTIMEToken(address _timeToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        timeToken = ITIMEToken(_timeToken);
    }
    
    function setWorkReceipt(address _workReceipt) external onlyRole(DEFAULT_ADMIN_ROLE) {
        workReceipt = IWorkReceipt(_workReceipt);
    }
    
    // ============ Soulbound Overrides ============
    
    /**
     * @notice Calendars are soulbound - transfers are not allowed
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        address from = _ownerOf(tokenId);
        
        // Allow minting (from == address(0)) but not transfers
        if (from != address(0) && to != address(0)) {
            revert TransferNotAllowed();
        }
        
        return super._update(to, tokenId, auth);
    }
    
    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }
    
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
}
