// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IReservesOracle
/// @notice Interface for an oracle that reports the current off-chain reserve amount backing the stablecoin.
/// @dev Implementations must return reserves denominated in the stablecoin's smallest unit (6 decimals).
///      Any contract conforming to this interface can be plugged into ReserveLedger as the oracle source.
interface IReservesOracle {
    /// @notice Returns the current total reserves available to back stablecoin issuance.
    /// @dev The value is denominated in 6-decimal stablecoin units (e.g. 1_000_000e6 = $1,000,000 USD).
    ///      Callers should treat this value as a point-in-time snapshot; it may be stale between updates.
    /// @return reserves The total reserve amount expressed in 6-decimal units.
    function getReserves() external view returns (uint256 reserves);
}
