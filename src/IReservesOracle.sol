// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IReservesOracle {
    function getReserves() external view returns (uint256);
}
