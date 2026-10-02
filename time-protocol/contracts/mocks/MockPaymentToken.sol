// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev Test-only payment token for the marketplace escrow tests.
contract MockPaymentToken is ERC20 {
    constructor() ERC20("Mock Payment", "MOCK") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
