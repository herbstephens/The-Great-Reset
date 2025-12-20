// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IUniversalCalendar {
    function isNullifierUsed(uint256 nullifierHash) external view returns (bool);
    function getCalendarId(address owner) external view returns (uint256);
}

/**
 * @title CommonsDistributor
 * @notice Distributes Land Commons dividends to verified humans
 * @dev Part of The Great Reset infrastructure
 * 
 * The Commons Dividend is separate from TIME tokens:
 * - TIME tokens: Earned through labor (1 TIME = 1 hour worked)
 * - Commons Dividend: Received by existence (equal share for all verified humans)
 * 
 * Commons fees collected from land holders are pooled and distributed
 * equally to all verified humans who have claimed their Universal Calendar.
 */
contract CommonsDistributor is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    // ============ Roles ============
    
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    
    // ============ State Variables ============
    
    IUniversalCalendar public calendar;
    IERC20 public dividendToken; // Stablecoin (USDC, DAI, etc.)
    
    // Distribution tracking
    uint256 public currentEpoch;
    uint256 public epochDuration = 30 days; // Monthly distributions
    uint256 public lastDistributionTime;
    
    // Per-epoch data
    mapping(uint256 => uint256) public epochPool;          // Total pool for epoch
    mapping(uint256 => uint256) public epochClaimants;     // Verified humans at epoch start
    mapping(uint256 => uint256) public epochShareAmount;   // Per-person share
    mapping(uint256 => bool) public epochFinalized;
    
    // Claim tracking
    mapping(address => uint256) public lastClaimedEpoch;
    mapping(address => uint256) public totalClaimed;
    
    // Global stats
    uint256 public totalDistributed;
    uint256 public registeredHumans;
    
    // ============ Events ============
    
    event EpochStarted(uint256 indexed epoch, uint256 timestamp);
    event FundsDeposited(uint256 indexed epoch, uint256 amount, address depositor);
    event EpochFinalized(uint256 indexed epoch, uint256 totalPool, uint256 claimants, uint256 shareAmount);
    event DividendClaimed(address indexed claimer, uint256 indexed epoch, uint256 amount);
    event HumanRegistered(address indexed human, uint256 calendarId);
    
    // ============ Errors ============
    
    error NotVerified();
    error EpochNotFinalized();
    error AlreadyClaimed();
    error NothingToClaim();
    error EpochAlreadyFinalized();
    error InvalidAmount();
    error NoClaimants();
    
    // ============ Constructor ============
    
    constructor(
        address _calendar,
        address _dividendToken
    ) {
        calendar = IUniversalCalendar(_calendar);
        dividendToken = IERC20(_dividendToken);
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEPOSITOR_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, msg.sender);
        
        currentEpoch = 1;
        lastDistributionTime = block.timestamp;
        
        emit EpochStarted(1, block.timestamp);
    }
    
    // ============ External Functions ============
    
    /**
     * @notice Deposit funds into the current epoch's pool
     * @dev Called by Land Commons fee collectors
     * @param amount Amount of dividend tokens to deposit
     */
    function deposit(uint256 amount) external onlyRole(DEPOSITOR_ROLE) nonReentrant {
        if (amount == 0) revert InvalidAmount();
        
        dividendToken.safeTransferFrom(msg.sender, address(this), amount);
        epochPool[currentEpoch] += amount;
        
        emit FundsDeposited(currentEpoch, amount, msg.sender);
    }
    
    /**
     * @notice Finalize the current epoch and calculate per-person share
     * @dev Called by oracle when epoch ends
     * @param totalVerifiedHumans Total number of verified humans at epoch end
     */
    function finalizeEpoch(uint256 totalVerifiedHumans) external onlyRole(ORACLE_ROLE) {
        if (epochFinalized[currentEpoch]) revert EpochAlreadyFinalized();
        if (totalVerifiedHumans == 0) revert NoClaimants();
        
        uint256 epoch = currentEpoch;
        uint256 pool = epochPool[epoch];
        
        epochClaimants[epoch] = totalVerifiedHumans;
        epochShareAmount[epoch] = pool / totalVerifiedHumans;
        epochFinalized[epoch] = true;
        registeredHumans = totalVerifiedHumans;
        
        emit EpochFinalized(epoch, pool, totalVerifiedHumans, epochShareAmount[epoch]);
        
        // Start new epoch
        currentEpoch++;
        lastDistributionTime = block.timestamp;
        
        emit EpochStarted(currentEpoch, block.timestamp);
    }
    
    /**
     * @notice Claim dividend for a finalized epoch
     * @param epoch Epoch to claim from
     */
    function claimDividend(uint256 epoch) external nonReentrant {
        // Verify caller is a verified human with a calendar
        uint256 calendarId = calendar.getCalendarId(msg.sender);
        if (calendarId == 0) revert NotVerified();
        
        if (!epochFinalized[epoch]) revert EpochNotFinalized();
        if (lastClaimedEpoch[msg.sender] >= epoch) revert AlreadyClaimed();
        
        uint256 share = epochShareAmount[epoch];
        if (share == 0) revert NothingToClaim();
        
        lastClaimedEpoch[msg.sender] = epoch;
        totalClaimed[msg.sender] += share;
        totalDistributed += share;
        
        dividendToken.safeTransfer(msg.sender, share);
        
        emit DividendClaimed(msg.sender, epoch, share);
    }
    
    /**
     * @notice Claim all available dividends across multiple epochs
     */
    function claimAllDividends() external nonReentrant {
        uint256 calendarId = calendar.getCalendarId(msg.sender);
        if (calendarId == 0) revert NotVerified();
        
        uint256 lastClaimed = lastClaimedEpoch[msg.sender];
        uint256 totalToClaim = 0;
        uint256 latestEpochClaimed = lastClaimed;
        
        for (uint256 epoch = lastClaimed + 1; epoch < currentEpoch; epoch++) {
            if (epochFinalized[epoch] && epochShareAmount[epoch] > 0) {
                totalToClaim += epochShareAmount[epoch];
                latestEpochClaimed = epoch;
            }
        }
        
        if (totalToClaim == 0) revert NothingToClaim();
        
        lastClaimedEpoch[msg.sender] = latestEpochClaimed;
        totalClaimed[msg.sender] += totalToClaim;
        totalDistributed += totalToClaim;
        
        dividendToken.safeTransfer(msg.sender, totalToClaim);
        
        emit DividendClaimed(msg.sender, latestEpochClaimed, totalToClaim);
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Calculate pending dividends for a verified human
     */
    function pendingDividends(address human) external view returns (uint256) {
        uint256 calendarId = calendar.getCalendarId(human);
        if (calendarId == 0) return 0;
        
        uint256 lastClaimed = lastClaimedEpoch[human];
        uint256 pending = 0;
        
        for (uint256 epoch = lastClaimed + 1; epoch < currentEpoch; epoch++) {
            if (epochFinalized[epoch]) {
                pending += epochShareAmount[epoch];
            }
        }
        
        return pending;
    }
    
    /**
     * @notice Get epoch details
     */
    function getEpochInfo(uint256 epoch) external view returns (
        uint256 pool,
        uint256 claimants,
        uint256 shareAmount,
        bool finalized
    ) {
        return (
            epochPool[epoch],
            epochClaimants[epoch],
            epochShareAmount[epoch],
            epochFinalized[epoch]
        );
    }
    
    /**
     * @notice Get current epoch pool size
     */
    function getCurrentPoolSize() external view returns (uint256) {
        return epochPool[currentEpoch];
    }
    
    /**
     * @notice Estimate share if epoch were finalized now
     */
    function estimateCurrentShare() external view returns (uint256) {
        if (registeredHumans == 0) return 0;
        return epochPool[currentEpoch] / registeredHumans;
    }
    
    /**
     * @notice Time until next distribution
     */
    function timeUntilNextDistribution() external view returns (uint256) {
        uint256 nextDistribution = lastDistributionTime + epochDuration;
        if (block.timestamp >= nextDistribution) return 0;
        return nextDistribution - block.timestamp;
    }
    
    // ============ Admin Functions ============
    
    function setEpochDuration(uint256 _duration) external onlyRole(DEFAULT_ADMIN_ROLE) {
        epochDuration = _duration;
    }
    
    function setCalendar(address _calendar) external onlyRole(DEFAULT_ADMIN_ROLE) {
        calendar = IUniversalCalendar(_calendar);
    }
    
    function setDividendToken(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        dividendToken = IERC20(_token);
    }
    
    function updateRegisteredHumans(uint256 _count) external onlyRole(ORACLE_ROLE) {
        registeredHumans = _count;
    }
    
    /**
     * @notice Emergency withdraw (admin only, for migration)
     */
    function emergencyWithdraw(address to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        dividendToken.safeTransfer(to, amount);
    }
}
