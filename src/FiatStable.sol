// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReserveLedger} from "./ReserveLedger.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

// Based on OpenZeppelin ERC20 + AccessControl pattern
// Source: OpenZeppelin/openzeppelin-contracts @ fd81a96f01cc42ef1c9a5399364968d0e07e9e90
contract FiatStable is ERC20, AccessControl, Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);

    ReserveLedger public immutable ledger;

    constructor(ReserveLedger ledger_) ERC20("Fiat Stable USD", "fUSD") {
        ledger = ledger_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        // TODO: also grant MINTER_ROLE to deployer
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function decimals() public pure override returns (uint8) {
        return 6; // fiat-style, like USDC
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) whenNotPaused {
        // supply-after-mint must be <= reserves
        require(totalSupply() + amount <= ledger.reportedReserves(), "exceeds reserves");
        _mint(to, amount);
        emit Minted(to, amount);
    }

    function burn(address from, uint256 amount) external onlyRole(MINTER_ROLE) whenNotPaused {
        // TODO: burn from address `from`
        _burn(from, amount);
        emit Burned(from, amount);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}
