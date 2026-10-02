// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title TIMEToken
 * @notice ERC-20 token representing verified human work hours
 * @dev 1 TIME = 1 hour of verified human work
 * 
 * TIME tokens are minted only upon verified work completion through
 * the UniversalCalendar contract. Unlike speculative cryptocurrencies,
 * TIME has a direct relationship to real-world value - each token
 * represents an actual hour of human labor.
 */
contract TIMEToken is ERC20, ERC20Burnable, AccessControl, ReentrancyGuard {
    
    // ============ Roles ============
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant CALENDAR_ROLE = keccak256("CALENDAR_ROLE");
    
    // ============ State Variables ============
    
    /// @notice Total hours of human work represented by all TIME ever minted
    uint256 public totalHoursMinted;
    
    /// @notice Mapping of addresses to their cumulative hours worked
    mapping(address => uint256) public hoursWorked;
    
    // ============ Structs ============
    
    struct MintMetadata {
        uint256 mintTimestamp;
        uint256 workerNullifierHash;  // World ID reference (privacy-preserving)
        bytes32 buyerCommitment;       // Privacy-preserving buyer ID
        bytes32 workCategory;
        uint256 originalRate;          // Rate at mint time (for historical reference)
    }
    
    // ============ Events ============
    
    event TIMEMinted(
        address indexed worker,
        uint256 amount,
        uint256 numHours,
        bytes32 indexed workCategory,
        uint256 timestamp
    );
    
    event TIMEBurned(
        address indexed holder,
        uint256 amount,
        string reason
    );
    
    // ============ Errors ============
    
    error InvalidAmount();
    error InvalidHours();
    error Unauthorized();
    
    // ============ Constructor ============
    
    constructor() ERC20("TIME", "TIME") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }
    
    // ============ External Functions ============
    
    /**
     * @notice Mint TIME tokens upon verified work completion
     * @dev Only callable by authorized minters (UniversalCalendar, authorized apps)
     * @param to Address to mint tokens to (the worker)
     * @param numHours Number of hours worked (mints numHours * 1e18 tokens)
     * @param metadata Additional metadata about the work
     */
    function mint(
        address to,
        uint256 numHours,
        MintMetadata calldata metadata
    ) external onlyRole(MINTER_ROLE) nonReentrant returns (uint256) {
        if (numHours == 0 || numHours > 24) revert InvalidHours();

        uint256 amount = numHours * 1e18;

        _mint(to, amount);

        totalHoursMinted += numHours;
        hoursWorked[to] += numHours;

        emit TIMEMinted(
            to,
            amount,
            numHours,
            metadata.workCategory,
            block.timestamp
        );

        return amount;
    }
    
    /**
     * @notice Simplified mint for backward compatibility
     * @param to Address to mint tokens to
     * @param amount Amount of TIME to mint (in wei, 1e18 = 1 TIME = 1 hour)
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        if (amount == 0) revert InvalidAmount();

        uint256 numHours = amount / 1e18;

        _mint(to, amount);

        totalHoursMinted += numHours;
        hoursWorked[to] += numHours;

        emit TIMEMinted(
            to,
            amount,
            numHours,
            bytes32(0),
            block.timestamp
        );
    }
    
    /**
     * @notice Burn TIME tokens with reason tracking
     * @param amount Amount to burn
     * @param reason Reason for burning (e.g., "marketplace_purchase", "redemption")
     */
    function burnWithReason(uint256 amount, string calldata reason) external {
        _burn(msg.sender, amount);
        emit TIMEBurned(msg.sender, amount, reason);
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Get the hours equivalent of a TIME amount
     * @param amount TIME amount in wei
     * @return hours Number of hours
     */
    function toHours(uint256 amount) external pure returns (uint256) {
        return amount / 1e18;
    }
    
    /**
     * @notice Get the TIME amount for given hours
     * @param numHours Number of hours
     * @return amount TIME amount in wei
     */
    function fromHours(uint256 numHours) external pure returns (uint256) {
        return numHours * 1e18;
    }
    
    /**
     * @notice Get cumulative hours worked by an address
     * @param worker Worker address
     * @return Total hours worked
     */
    function getHoursWorked(address worker) external view returns (uint256) {
        return hoursWorked[worker];
    }
    
    // ============ Admin Functions ============
    
    /**
     * @notice Grant minter role to an address (e.g., UniversalCalendar)
     * @param minter Address to grant minter role
     */
    function addMinter(address minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, minter);
    }
    
    /**
     * @notice Revoke minter role from an address
     * @param minter Address to revoke minter role from
     */
    function removeMinter(address minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MINTER_ROLE, minter);
    }
}
