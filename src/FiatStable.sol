// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReserveLedger} from "./ReserveLedger.sol";

contract FiatStable is ERC20, AccessControl, Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint256 public constant MAX_RESERVE_AGE = 1 days;

    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);

    ReserveLedger public immutable ledger;

    constructor(ReserveLedger ledger_) ERC20("Fiat Stable USD", "fUSD") {
        ledger = ledger_;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) whenNotPaused {
        require(block.timestamp - ledger.lastUpdated() <= MAX_RESERVE_AGE, "stale reserves");
        require(totalSupply() + amount <= ledger.reportedReserves(), "exceeds reserves");

        _mint(to, amount);
        emit Minted(to, amount);
    }

    // User-controlled burn
    function burn(uint256 amount) external whenNotPaused {
        _burn(msg.sender, amount);
        emit Burned(msg.sender, amount);
    }

    // Issuer-controlled burn
    function issuerBurn(address from, uint256 amount) external onlyRole(MINTER_ROLE) whenNotPaused {
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
