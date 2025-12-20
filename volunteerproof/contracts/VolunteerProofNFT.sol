// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title VolunteerProofNFT
 * @notice Soulbound NFT representing verified volunteer work
 * @dev Non-transferable, dynamic metadata
 */
contract VolunteerProofNFT is ERC721, Ownable {
    using Strings for uint256;
    
    // ============ State Variables ============
    
    address public volunteerEngine;
    uint256 private _tokenIdCounter;
    
    struct VolunteerProof {
        uint256 entryId;
        address volunteer;
        uint256 hours;
        string organization;
        string description;
        uint256 timestamp;
    }
    
    mapping(uint256 => VolunteerProof) public proofs;
    mapping(address => uint256[]) public volunteerTokens;
    
    // ============ Events ============
    
    event ProofMinted(uint256 indexed tokenId, address indexed volunteer, uint256 hours, string organization);
    
    // ============ Errors ============
    
    error OnlyEngine();
    error SoulboundToken();
    
    // ============ Modifiers ============
    
    modifier onlyEngine() {
        if (msg.sender != volunteerEngine) revert OnlyEngine();
        _;
    }
    
    // ============ Constructor ============
    
    constructor() ERC721("VolunteerProof", "VPROOF") Ownable(msg.sender) {}
    
    // ============ External Functions ============
    
    /**
     * @notice Mint a new VolunteerProof NFT
     * @dev Only callable by VolunteerEngine
     */
    function mint(
        address to,
        uint256 entryId,
        uint256 hours_,
        string calldata organization,
        string calldata description
    ) external onlyEngine returns (uint256) {
        _tokenIdCounter++;
        uint256 tokenId = _tokenIdCounter;
        
        proofs[tokenId] = VolunteerProof({
            entryId: entryId,
            volunteer: to,
            hours: hours_,
            organization: organization,
            description: description,
            timestamp: block.timestamp
        });
        
        volunteerTokens[to].push(tokenId);
        
        _safeMint(to, tokenId);
        
        emit ProofMinted(tokenId, to, hours_, organization);
        
        return tokenId;
    }
    
    /**
     * @notice Get token metadata URI
     * @dev Generates on-chain SVG and JSON metadata
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        
        VolunteerProof memory proof = proofs[tokenId];
        
        string memory svg = generateSVG(proof);
        
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":"VolunteerProof #',
                        tokenId.toString(),
                        '","description":"Verified volunteer work: ',
                        proof.hours.toString(),
                        ' hours at ',
                        proof.organization,
                        '","image":"data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '","attributes":[{"trait_type":"Hours","value":',
                        proof.hours.toString(),
                        '},{"trait_type":"Organization","value":"',
                        proof.organization,
                        '"},{"trait_type":"Verified","value":"World ID"}]}'
                    )
                )
            )
        );
        
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
    
    /**
     * @notice Generate SVG image for the NFT
     */
    function generateSVG(VolunteerProof memory proof) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 500">',
                '<defs><linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">',
                '<stop offset="0%" style="stop-color:#0a0f1a"/><stop offset="100%" style="stop-color:#111827"/>',
                '</linearGradient></defs>',
                '<rect width="400" height="500" fill="url(#bg)"/>',
                '<circle cx="200" cy="120" r="50" fill="none" stroke="#10b981" stroke-width="3"/>',
                '<path d="M175 120 L190 135 L230 95" fill="none" stroke="#10b981" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>',
                '<text x="200" y="200" font-family="Arial" font-size="24" fill="#10b981" text-anchor="middle" font-weight="bold">VolunteerPROOF</text>',
                '<text x="200" y="260" font-family="Arial" font-size="64" fill="white" text-anchor="middle" font-weight="bold">',
                proof.hours.toString(),
                '</text>',
                '<text x="200" y="290" font-family="Arial" font-size="16" fill="#94a3b8" text-anchor="middle">VERIFIED HOURS</text>',
                '<text x="200" y="350" font-family="Arial" font-size="18" fill="white" text-anchor="middle">',
                bytes(proof.organization).length > 25 ? string(abi.encodePacked(substring(proof.organization, 0, 22), "...")) : proof.organization,
                '</text>',
                '<rect x="100" y="420" width="200" height="40" rx="20" fill="#10b981" fill-opacity="0.2" stroke="#10b981"/>',
                '<text x="200" y="446" font-family="Arial" font-size="14" fill="#10b981" text-anchor="middle" font-weight="bold">WORLD ID VERIFIED</text>',
                '</svg>'
            )
        );
    }
    
    /**
     * @notice Helper to substring
     */
    function substring(string memory str, uint256 startIndex, uint256 endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }
    
    /**
     * @notice Get all tokens for a volunteer
     */
    function getVolunteerTokens(address volunteer) external view returns (uint256[] memory) {
        return volunteerTokens[volunteer];
    }
    
    /**
     * @notice Get total verified hours for a volunteer across all proofs
     */
    function getTotalVerifiedHours(address volunteer) external view returns (uint256) {
        uint256[] memory tokens = volunteerTokens[volunteer];
        uint256 total = 0;
        
        for (uint256 i = 0; i < tokens.length; i++) {
            total += proofs[tokens[i]].hours;
        }
        
        return total;
    }
    
    // ============ Soulbound Overrides ============
    
    /**
     * @notice Prevent transfers (soulbound)
     */
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        
        // Allow minting (from == address(0)) but not transfers
        if (from != address(0) && to != address(0)) {
            revert SoulboundToken();
        }
        
        return super._update(to, tokenId, auth);
    }
    
    // ============ Admin Functions ============
    
    function setVolunteerEngine(address _engine) external onlyOwner {
        volunteerEngine = _engine;
    }
}
