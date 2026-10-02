// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title WorkReceipt
 * @notice ERC-721 NFT representing proof of completed work
 * @dev Each completed time slot generates a WorkReceipt NFT
 * 
 * WorkReceipts serve as:
 * - Immutable proof of work completion
 * - Portable work history across employers
 * - Foundation for worker ownership accumulation
 * - Verifiable credentials for reputation systems
 */
contract WorkReceipt is ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl, ReentrancyGuard {
    using Strings for uint256;
    
    // ============ Roles ============
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    // ============ Structs ============
    
    struct Receipt {
        uint256 calendarId;
        uint256 slotIndex;
        uint256 date;
        bytes32 workCategory;
        uint256 rate;
        uint256 mintedAt;
        address worker;
        address employer;
    }
    
    // ============ State Variables ============
    
    uint256 private _tokenIdCounter;
    
    mapping(uint256 => Receipt) public receipts;
    mapping(address => uint256) public totalReceipts;
    mapping(address => uint256) public totalHoursProven;
    
    // Category labels for display
    mapping(bytes32 => string) public categoryLabels;
    
    // ============ Events ============
    
    event ReceiptMinted(
        uint256 indexed tokenId,
        address indexed worker,
        uint256 calendarId,
        uint256 date,
        bytes32 workCategory
    );
    
    event CategoryLabelSet(bytes32 indexed category, string label);
    
    // ============ Errors ============
    
    error InvalidReceipt();
    error ReceiptNotFound();
    
    // ============ Constructor ============
    
    constructor() ERC721("Work Receipt", "WORK") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        
        // Set default category labels
        categoryLabels[keccak256("VOLUNTEER")] = "Volunteer Work";
        categoryLabels[keccak256("FREELANCE")] = "Freelance";
        categoryLabels[keccak256("EMPLOYMENT")] = "Employment";
        categoryLabels[keccak256("CAREGIVING")] = "Caregiving";
        categoryLabels[keccak256("EDUCATION")] = "Education";
        categoryLabels[keccak256("CREATIVE")] = "Creative Work";
        categoryLabels[keccak256("COMMUNITY")] = "Community Service";
    }
    
    // ============ External Functions ============
    
    /**
     * @notice Mint a work receipt recording the real worker and the real employer (the paying buyer)
     * @dev Only callable by authorized minters (UniversalCalendar)
     */
    function mintWithEmployer(
        address worker,
        address employer,
        uint256 calendarId,
        uint256 slotIndex,
        uint256 date,
        bytes32 workCategory,
        uint256 rate
    ) external onlyRole(MINTER_ROLE) nonReentrant returns (uint256) {
        _tokenIdCounter++;
        uint256 tokenId = _tokenIdCounter;
        
        receipts[tokenId] = Receipt({
            calendarId: calendarId,
            slotIndex: slotIndex,
            date: date,
            workCategory: workCategory,
            rate: rate,
            mintedAt: block.timestamp,
            worker: worker,
            employer: employer
        });
        
        totalReceipts[worker]++;
        totalHoursProven[worker]++;
        
        _safeMint(worker, tokenId);
        
        emit ReceiptMinted(tokenId, worker, calendarId, date, workCategory);
        
        return tokenId;
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Get receipt details
     */
    function getReceipt(uint256 tokenId) external view returns (Receipt memory) {
        if (_ownerOf(tokenId) == address(0)) revert ReceiptNotFound();
        return receipts[tokenId];
    }
    
    /**
     * @notice Get all receipt IDs for a worker
     */
    function getWorkerReceipts(address worker) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(worker);
        uint256[] memory tokenIds = new uint256[](balance);
        
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(worker, i);
        }
        
        return tokenIds;
    }
    
    /**
     * @notice Get work statistics for a worker
     */
    function getWorkerStats(address worker) external view returns (
        uint256 totalReceiptsCount,
        uint256 totalHours,
        uint256 avgRate
    ) {
        totalReceiptsCount = totalReceipts[worker];
        totalHours = totalHoursProven[worker];
        
        if (totalReceiptsCount == 0) return (0, 0, 0);
        
        uint256 balance = balanceOf(worker);
        uint256 totalRates = 0;
        
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(worker, i);
            totalRates += receipts[tokenId].rate;
        }
        
        avgRate = totalRates / balance;
    }
    
    /**
     * @notice Generate on-chain SVG for the receipt
     */
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        if (_ownerOf(tokenId) == address(0)) revert ReceiptNotFound();
        
        Receipt memory r = receipts[tokenId];
        string memory categoryLabel = categoryLabels[r.workCategory];
        if (bytes(categoryLabel).length == 0) {
            categoryLabel = "Work";
        }
        
        string memory svg = generateSVG(tokenId, r, categoryLabel);
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "Work Receipt #', tokenId.toString(),
            '", "description": "Proof of 1 hour of verified human work",',
            '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)),
            '", "attributes": [',
            '{"trait_type": "Category", "value": "', categoryLabel, '"},',
            '{"trait_type": "Date", "value": "', r.date.toString(), '"},',
            '{"trait_type": "Hour", "value": "', r.slotIndex.toString(), '"},',
            '{"trait_type": "Rate", "value": "', r.rate.toString(), '"}',
            ']}'
        ))));
        
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
    
    function generateSVG(
        uint256 tokenId,
        Receipt memory r,
        string memory categoryLabel
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 500">',
            '<defs><linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">',
            '<stop offset="0%" style="stop-color:#1a1a2e"/>',
            '<stop offset="100%" style="stop-color:#16213e"/>',
            '</linearGradient></defs>',
            '<rect width="400" height="500" fill="url(#bg)"/>',
            '<text x="200" y="60" font-family="monospace" font-size="24" fill="#00d4ff" text-anchor="middle">WORK RECEIPT</text>',
            '<text x="200" y="100" font-family="monospace" font-size="16" fill="#888" text-anchor="middle">#', tokenId.toString(), '</text>',
            '<rect x="40" y="130" width="320" height="2" fill="#00d4ff" opacity="0.3"/>',
            '<text x="200" y="180" font-family="monospace" font-size="48" fill="#fff" text-anchor="middle">1 HOUR</text>',
            '<text x="200" y="220" font-family="monospace" font-size="14" fill="#00d4ff" text-anchor="middle">VERIFIED HUMAN WORK</text>',
            '<rect x="40" y="250" width="320" height="2" fill="#00d4ff" opacity="0.3"/>',
            '<text x="60" y="290" font-family="monospace" font-size="12" fill="#888">CATEGORY</text>',
            '<text x="60" y="310" font-family="monospace" font-size="14" fill="#fff">', categoryLabel, '</text>',
            '<text x="60" y="350" font-family="monospace" font-size="12" fill="#888">SLOT</text>',
            '<text x="60" y="370" font-family="monospace" font-size="14" fill="#fff">', r.slotIndex.toString(), ':00 UTC</text>',
            '<text x="200" y="460" font-family="monospace" font-size="10" fill="#444" text-anchor="middle">TIME PROTOCOL</text>',
            '</svg>'
        ));
    }
    
    // ============ Admin Functions ============
    
    function setCategoryLabel(bytes32 category, string calldata label) external onlyRole(DEFAULT_ADMIN_ROLE) {
        categoryLabels[category] = label;
        emit CategoryLabelSet(category, label);
    }
    
    function addMinter(address minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, minter);
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
    ) public view override(ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
