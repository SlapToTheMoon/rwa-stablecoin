// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

// Based on OpenZeppelin ERC20 + AccessControl pattern
// Source: OpenZeppelin/openzeppelin-contracts @ fd81a96f01cc42ef1c9a5399364968d0e07e9e90
contract FiatStable is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("Fiat Stable USD", "fUSD") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // TODO: also grant MINTER_ROLE to deployer
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function decimals() public pure override returns (uint8) {
        return 6; // fiat-style, like USDC
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        // TODO: mint to address `to`
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyRole(MINTER_ROLE) {
        // TODO: burn from address `from`
        _burn(from, amount);
    }
}
