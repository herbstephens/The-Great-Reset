// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @title LandRegistry
 * @notice Registry of land parcels for the Land Commons Protocol
 * @dev Each parcel is an NFT representing a claim on land
 * 
 * The Land Commons Protocol distinguishes between:
 * - Land: The earth itself, which belongs to everyone (Commons)
 * - Structures: Improvements built on land, which belong to their creators
 * 
 * Landholders pay Commons fees based on automated valuations.
 * Fees are distributed equally to all verified humans.
 */
contract LandRegistry is ERC721, ERC721Enumerable, AccessControl, ReentrancyGuard {
    
    // ============ Roles ============
    
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");
    
    // ============ Enums ============
    
    enum LandType { 
        URBAN_CORE,      // 3.0x - 5.0x multiplier
        URBAN_GENERAL,   // 2.0x - 3.0x multiplier
        SUBURBAN,        // 1.2x - 2.0x multiplier
        RURAL,           // 0.5x - 1.2x multiplier
        AGRICULTURAL,    // 0.1x - 0.5x multiplier
        CONSERVATION     // 0x (may receive credits)
    }
    
    // ============ Structs ============
    
    struct Parcel {
        uint256 id;
        string locationHash;        // IPFS hash of location data
        uint256 areaSqMeters;
        LandType landType;
        uint256 baseValueUSD;       // Satellite-derived base value
        uint256 zonalMultiplier;    // Basis points (10000 = 1.0x)
        uint256 lastValuationTime;
        uint256 annualFeeRate;      // Basis points of value owed annually
        uint256 accruedFees;
        bool registered;
    }
    
    struct Valuation {
        uint256 baseValue;
        uint256 zonalMultiplier;
        uint256 totalValue;
        uint256 annualFee;
        uint256 timestamp;
        bytes32 dataHash;           // Hash of satellite/oracle data used
    }
    
    // ============ State Variables ============
    
    uint256 private _parcelIdCounter;
    
    // Default fee rate: 1% of land value annually (100 basis points)
    uint256 public defaultFeeRateBps = 100;
    
    // Fee rates by land type (basis points)
    mapping(LandType => uint256) public feeRatesByType;
    
    // Parcel data
    mapping(uint256 => Parcel) public parcels;
    mapping(string => uint256) public locationToParcel;
    
    // Valuation history
    mapping(uint256 => Valuation[]) public valuationHistory;
    
    // Fee collection
    address public feeCollector;
    uint256 public totalFeesCollected;
    
    // ============ Events ============
    
    event ParcelRegistered(
        uint256 indexed parcelId,
        address indexed owner,
        string locationHash,
        LandType landType,
        uint256 areaSqMeters
    );
    
    event ParcelValued(
        uint256 indexed parcelId,
        uint256 baseValue,
        uint256 zonalMultiplier,
        uint256 totalValue,
        uint256 annualFee
    );
    
    event FeesPaid(
        uint256 indexed parcelId,
        address indexed payer,
        uint256 amount
    );
    
    event FeesAccrued(
        uint256 indexed parcelId,
        uint256 amount
    );
    
    // ============ Errors ============
    
    error ParcelNotFound();
    error AlreadyRegistered();
    error InsufficientPayment();
    error NotParcelOwner();
    error InvalidLandType();
    
    // ============ Constructor ============
    
    constructor(address _feeCollector) ERC721("Land Commons Parcel", "LAND") {
        feeCollector = _feeCollector;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, msg.sender);
        _grantRole(REGISTRAR_ROLE, msg.sender);
        
        // Initialize fee rates by land type (basis points of value annually)
        feeRatesByType[LandType.URBAN_CORE] = 200;      // 2%
        feeRatesByType[LandType.URBAN_GENERAL] = 150;   // 1.5%
        feeRatesByType[LandType.SUBURBAN] = 100;        // 1%
        feeRatesByType[LandType.RURAL] = 75;            // 0.75%
        feeRatesByType[LandType.AGRICULTURAL] = 50;     // 0.5%
        feeRatesByType[LandType.CONSERVATION] = 0;      // 0%
    }
    
    // ============ External Functions ============
    
    /**
     * @notice Register a new land parcel
     * @param owner Address of the parcel owner
     * @param locationHash IPFS hash of location/boundary data
     * @param areaSqMeters Area in square meters
     * @param landType Type of land
     */
    function registerParcel(
        address owner,
        string calldata locationHash,
        uint256 areaSqMeters,
        LandType landType
    ) external onlyRole(REGISTRAR_ROLE) returns (uint256) {
        if (locationToParcel[locationHash] != 0) revert AlreadyRegistered();
        
        _parcelIdCounter++;
        uint256 parcelId = _parcelIdCounter;
        
        parcels[parcelId] = Parcel({
            id: parcelId,
            locationHash: locationHash,
            areaSqMeters: areaSqMeters,
            landType: landType,
            baseValueUSD: 0,
            zonalMultiplier: 10000, // 1.0x default
            lastValuationTime: block.timestamp,
            annualFeeRate: feeRatesByType[landType],
            accruedFees: 0,
            registered: true
        });
        
        locationToParcel[locationHash] = parcelId;
        
        _safeMint(owner, parcelId);
        
        emit ParcelRegistered(parcelId, owner, locationHash, landType, areaSqMeters);
        
        return parcelId;
    }
    
    /**
     * @notice Update parcel valuation (oracle function)
     * @param parcelId Parcel to update
     * @param baseValue New base value in USD (scaled by 1e18)
     * @param zonalMultiplier Zonal multiplier in basis points
     * @param dataHash Hash of the source data used
     */
    function updateValuation(
        uint256 parcelId,
        uint256 baseValue,
        uint256 zonalMultiplier,
        bytes32 dataHash
    ) external onlyRole(ORACLE_ROLE) {
        Parcel storage parcel = parcels[parcelId];
        if (!parcel.registered) revert ParcelNotFound();
        
        // Accrue any outstanding fees at old rate before updating
        _accrueFees(parcelId);
        
        parcel.baseValueUSD = baseValue;
        parcel.zonalMultiplier = zonalMultiplier;
        parcel.lastValuationTime = block.timestamp;
        
        uint256 totalValue = (baseValue * zonalMultiplier) / 10000;
        uint256 annualFee = (totalValue * parcel.annualFeeRate) / 10000;
        
        // Record valuation history
        valuationHistory[parcelId].push(Valuation({
            baseValue: baseValue,
            zonalMultiplier: zonalMultiplier,
            totalValue: totalValue,
            annualFee: annualFee,
            timestamp: block.timestamp,
            dataHash: dataHash
        }));
        
        emit ParcelValued(parcelId, baseValue, zonalMultiplier, totalValue, annualFee);
    }
    
    /**
     * @notice Pay accrued fees for a parcel
     * @param parcelId Parcel to pay fees for
     */
    function payFees(uint256 parcelId) external payable nonReentrant {
        Parcel storage parcel = parcels[parcelId];
        if (!parcel.registered) revert ParcelNotFound();
        
        // Accrue any outstanding fees
        _accrueFees(parcelId);
        
        uint256 amountToPay = parcel.accruedFees;
        if (msg.value < amountToPay) {
            amountToPay = msg.value;
        }
        
        parcel.accruedFees -= amountToPay;
        totalFeesCollected += amountToPay;
        
        // Transfer to fee collector (CommonsDistributor)
        (bool success, ) = feeCollector.call{value: amountToPay}("");
        require(success, "Fee transfer failed");
        
        // Refund excess
        if (msg.value > amountToPay) {
            (bool refundSuccess, ) = msg.sender.call{value: msg.value - amountToPay}("");
            require(refundSuccess, "Refund failed");
        }
        
        emit FeesPaid(parcelId, msg.sender, amountToPay);
    }
    
    /**
     * @notice Accrue fees for a parcel based on time elapsed
     */
    function accrueFees(uint256 parcelId) external {
        _accrueFees(parcelId);
    }
    
    // ============ Internal Functions ============
    
    function _accrueFees(uint256 parcelId) internal {
        Parcel storage parcel = parcels[parcelId];
        if (!parcel.registered) return;
        
        uint256 timeElapsed = block.timestamp - parcel.lastValuationTime;
        if (timeElapsed == 0) return;
        
        uint256 totalValue = (parcel.baseValueUSD * parcel.zonalMultiplier) / 10000;
        uint256 annualFee = (totalValue * parcel.annualFeeRate) / 10000;
        
        // Pro-rate for time elapsed (seconds in a year = 31536000)
        uint256 feesAccrued = (annualFee * timeElapsed) / 31536000;
        
        parcel.accruedFees += feesAccrued;
        parcel.lastValuationTime = block.timestamp;
        
        if (feesAccrued > 0) {
            emit FeesAccrued(parcelId, feesAccrued);
        }
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Get current parcel value
     */
    function getParcelValue(uint256 parcelId) external view returns (uint256) {
        Parcel storage parcel = parcels[parcelId];
        return (parcel.baseValueUSD * parcel.zonalMultiplier) / 10000;
    }
    
    /**
     * @notice Get current annual fee for a parcel
     */
    function getAnnualFee(uint256 parcelId) external view returns (uint256) {
        Parcel storage parcel = parcels[parcelId];
        uint256 totalValue = (parcel.baseValueUSD * parcel.zonalMultiplier) / 10000;
        return (totalValue * parcel.annualFeeRate) / 10000;
    }
    
    /**
     * @notice Get outstanding fees for a parcel
     */
    function getOutstandingFees(uint256 parcelId) external view returns (uint256) {
        Parcel storage parcel = parcels[parcelId];
        
        uint256 timeElapsed = block.timestamp - parcel.lastValuationTime;
        uint256 totalValue = (parcel.baseValueUSD * parcel.zonalMultiplier) / 10000;
        uint256 annualFee = (totalValue * parcel.annualFeeRate) / 10000;
        uint256 pendingFees = (annualFee * timeElapsed) / 31536000;
        
        return parcel.accruedFees + pendingFees;
    }
    
    /**
     * @notice Get valuation history for a parcel
     */
    function getValuationHistory(uint256 parcelId) external view returns (Valuation[] memory) {
        return valuationHistory[parcelId];
    }
    
    // ============ Admin Functions ============
    
    function setFeeCollector(address _collector) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeCollector = _collector;
    }
    
    function setFeeRateForType(LandType landType, uint256 rateBps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeRatesByType[landType] = rateBps;
    }
    
    // ============ Required Overrides ============
    
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
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
}
