// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IReservesOracle} from "./IReservesOracle.sol";

contract ReserveLedger is AccessControl {
    bytes32 public constant RESERVE_REPORTER_ROLE = keccak256("RESERVE_REPORTER_ROLE");
    IReservesOracle public immutable oracle;
    uint256 public reportedReserves; // in stablecoin smallest units (6 decimals)

    event ReservesReported(uint256 newReserves);

    constructor(address admin, IReservesOracle oracle_) {
        oracle = oracle_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(RESERVE_REPORTER_ROLE, admin);
    }

    function syncReservesFromOracle() external onlyRole(RESERVE_REPORTER_ROLE) {
        uint256 newReserves = oracle.getReserves();
        reportedReserves = newReserves;
        emit ReservesReported(newReserves);
    }
}
