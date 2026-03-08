// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IReservesOracle} from "./IReservesOracle.sol";

contract MockReservesOracle is IReservesOracle {
    uint256 private _reserves;

    function setReserves(uint256 newReserves) external {
        _reserves = newReserves;
    }

    function getReserves() external view returns (uint256) {
        return _reserves;
    }
}
