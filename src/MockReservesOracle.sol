// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IReservesOracle} from "./IReservesOracle.sol";

/// @title MockReservesOracle
/// @notice Test double of IReservesOracle that allows arbitrary reserve values to be injected by callers.
/// @dev Used exclusively in tests and local deployment scripts to simulate oracle behaviour without an
///      external data source. The setter is unprotected — any address can call it — which is intentional
///      for test flexibility. Do NOT deploy this contract to production or any public network.
contract MockReservesOracle is IReservesOracle {
    /// @dev Backing storage for the mocked reserve value.
    uint256 private _reserves;

    /// @notice Overrides the reported reserve amount with `newReserves`.
    /// @dev Unprotected; any caller may update the value. This mirrors how a compromised or
    ///      unvalidated oracle could inflate reserves — see ReserveLedgerAudit.t.sol.
    /// @param newReserves The reserve amount to report, denominated in 6-decimal stablecoin units.
    function setReserves(uint256 newReserves) external {
        _reserves = newReserves;
    }

    /// @inheritdoc IReservesOracle
    function getReserves() external view returns (uint256) {
        return _reserves;
    }
}
