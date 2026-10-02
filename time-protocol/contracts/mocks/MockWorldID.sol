// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @dev Test-only stand-in for the World ID router. Accepts any proof unless told to reject.
contract MockWorldID {
    bool public rejectProofs;

    function setRejectProofs(bool reject) external {
        rejectProofs = reject;
    }

    function verifyProof(
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256[8] calldata
    ) external view {
        require(!rejectProofs, "MockWorldID: invalid proof");
    }
}
