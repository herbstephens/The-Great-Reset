// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
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

interface IVolunteerProofNFT {
    function mint(address to, uint256 entryId, uint256 hours_, string calldata organization, string calldata description) external returns (uint256);
}

interface ITIMEToken {
    function mint(address to, uint256 amount) external;
}

/**
 * @title VolunteerEngine
 * @notice Core contract for logging and verifying volunteer hours
 * @dev Integrates World ID for human verification, mints NFT proofs
 */
contract VolunteerEngine is Ownable, ReentrancyGuard {
    
    // ============ State Variables ============
    
    IWorldID public immutable worldId;
    IVolunteerProofNFT public volunteerProofNFT;
    ITIMEToken public timeToken;
    
    uint256 public immutable groupId = 1;
    uint256 public immutable externalNullifier;
    
    // Volunteer entry struct
    struct VolunteerEntry {
        uint256 id;
        address volunteer;
        uint256 hours;          // Hours in whole numbers (multiply by 1e18 for TIME)
        string organization;
        string description;
        uint256 timestamp;
        bool minted;            // Has NFT been minted
        bool claimed;           // Has TIME been claimed
    }
    
    // Mappings
    mapping(address => bool) public isVerified;
    mapping(address => uint256) public nullifierHashes;
    mapping(uint256 => VolunteerEntry) public entries;
    mapping(address => uint256[]) public volunteerEntries;
    
    uint256 public entryCounter;
    
    // TIME earning rate: 1 hour = 1 TIME (1e18 wei)
    uint256 public constant TIME_PER_HOUR = 1e18;
    
    // ============ Events ============
    
    event HumanVerified(address indexed volunteer, uint256 nullifierHash);
    event HoursLogged(uint256 indexed entryId, address indexed volunteer, uint256 hours, string organization);
    event ProofMinted(uint256 indexed entryId, address indexed volunteer, uint256 tokenId);
    event TIMEClaimed(address indexed volunteer, uint256 amount);
    
    // ============ Errors ============
    
    error NotVerified();
    error AlreadyVerified();
    error InvalidProof();
    error EntryNotFound();
    error AlreadyMinted();
    error AlreadyClaimed();
    error InvalidHours();
    
    // ============ Constructor ============
    
    constructor(
        address _worldId,
        string memory _appId,
        string memory _actionId
    ) Ownable(msg.sender) {
        worldId = IWorldID(_worldId);
        externalNullifier = uint256(keccak256(abi.encodePacked(_appId, _actionId)));
    }
    
    // ============ External Functions ============
    
    /**
     * @notice Verify humanity via World ID
     * @param root Merkle root from World ID
     * @param nullifierHash Unique identifier for this human
     * @param proof ZK proof from World ID
     */
    function verifyHuman(
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) external {
        if (isVerified[msg.sender]) revert AlreadyVerified();
        
        // Verify the World ID proof
        worldId.verifyProof(
            root,
            groupId,
            uint256(uint160(msg.sender)),
            nullifierHash,
            externalNullifier,
            proof
        );
        
        isVerified[msg.sender] = true;
        nullifierHashes[msg.sender] = nullifierHash;
        
        emit HumanVerified(msg.sender, nullifierHash);
    }
    
    /**
     * @notice Log volunteer hours
     * @param hours Number of hours volunteered
     * @param organization Name of organization
     * @param description Brief description of work done
     */
    function logHours(
        uint256 hours,
        string calldata organization,
        string calldata description
    ) external nonReentrant returns (uint256) {
        if (!isVerified[msg.sender]) revert NotVerified();
        if (hours == 0 || hours > 24) revert InvalidHours();
        
        entryCounter++;
        uint256 entryId = entryCounter;
        
        entries[entryId] = VolunteerEntry({
            id: entryId,
            volunteer: msg.sender,
            hours: hours,
            organization: organization,
            description: description,
            timestamp: block.timestamp,
            minted: false,
            claimed: false
        });
        
        volunteerEntries[msg.sender].push(entryId);
        
        emit HoursLogged(entryId, msg.sender, hours, organization);
        
        return entryId;
    }
    
    /**
     * @notice Mint a VolunteerProof NFT for an entry
     * @param entryId The entry to mint proof for
     */
    function mintProof(uint256 entryId) external nonReentrant returns (uint256) {
        VolunteerEntry storage entry = entries[entryId];
        
        if (entry.volunteer != msg.sender) revert EntryNotFound();
        if (entry.minted) revert AlreadyMinted();
        
        entry.minted = true;
        
        uint256 tokenId = volunteerProofNFT.mint(
            msg.sender,
            entryId,
            entry.hours,
            entry.organization,
            entry.description
        );
        
        emit ProofMinted(entryId, msg.sender, tokenId);
        
        return tokenId;
    }
    
    /**
     * @notice Claim TIME tokens for logged hours
     * @param entryId The entry to claim TIME for
     */
    function claimTIME(uint256 entryId) external nonReentrant {
        VolunteerEntry storage entry = entries[entryId];
        
        if (entry.volunteer != msg.sender) revert EntryNotFound();
        if (entry.claimed) revert AlreadyClaimed();
        
        entry.claimed = true;
        
        uint256 timeAmount = entry.hours * TIME_PER_HOUR;
        timeToken.mint(msg.sender, timeAmount);
        
        emit TIMEClaimed(msg.sender, timeAmount);
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Get all entries for a volunteer
     */
    function getVolunteerEntries(address volunteer) external view returns (uint256[] memory) {
        return volunteerEntries[volunteer];
    }
    
    /**
     * @notice Get total hours for a volunteer
     */
    function getTotalHours(address volunteer) external view returns (uint256) {
        uint256[] memory entryIds = volunteerEntries[volunteer];
        uint256 total = 0;
        
        for (uint256 i = 0; i < entryIds.length; i++) {
            total += entries[entryIds[i]].hours;
        }
        
        return total;
    }
    
    /**
     * @notice Get unclaimed TIME amount for a volunteer
     */
    function getUnclaimedTIME(address volunteer) external view returns (uint256) {
        uint256[] memory entryIds = volunteerEntries[volunteer];
        uint256 unclaimed = 0;
        
        for (uint256 i = 0; i < entryIds.length; i++) {
            if (!entries[entryIds[i]].claimed) {
                unclaimed += entries[entryIds[i]].hours * TIME_PER_HOUR;
            }
        }
        
        return unclaimed;
    }
    
    // ============ Admin Functions ============
    
    function setVolunteerProofNFT(address _nft) external onlyOwner {
        volunteerProofNFT = IVolunteerProofNFT(_nft);
    }
    
    function setTIMEToken(address _time) external onlyOwner {
        timeToken = ITIMEToken(_time);
    }
}
