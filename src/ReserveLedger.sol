// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IReservesOracle} from "./IReservesOracle.sol";

/// @title ReserveLedger
/// @notice On-chain record of verified reserves that caps fUSD issuance to a 1:1 collateralization ratio.
/// @dev Acts as the single source of truth for `reportedReserves`, which FiatStable reads on every
///      mint call to enforce `totalSupply() + amount <= reportedReserves`.
///
///      Reserve data is pulled from an IReservesOracle and stored locally so FiatStable reads are
///      a cheap storage lookup rather than an external call. Updates are permissioned: only accounts
///      holding RESERVE_REPORTER_ROLE may call `syncReservesFromOracle`.
///
///      Security consideration: the collateralization guarantee is only as strong as the oracle.
///      A compromised oracle can report inflated reserves, enabling uncollateralised minting.
///      See ReserveLedgerAudit.t.sol for a concrete demonstration of this attack vector.
contract ReserveLedger is AccessControl {
    /// @notice Role required to pull a fresh reserve snapshot from the oracle.
    /// @dev Computed as keccak256("RESERVE_REPORTER_ROLE"). Granted to the admin at construction;
    ///      additional reporters can be added via AccessControl role management.
    bytes32 public constant RESERVE_REPORTER_ROLE = keccak256("RESERVE_REPORTER_ROLE");

    /// @notice The oracle consulted when syncing reserves.
    /// @dev Immutable — the oracle source cannot be swapped without redeploying this contract.
    IReservesOracle public immutable oracle;

    /// @notice The most recent reserve amount pulled from the oracle, in 6-decimal stablecoin units.
    /// @dev Updated exclusively by `syncReservesFromOracle`. FiatStable reads this on every mint.
    ///      A value of zero means no reserves have been reported yet, blocking all minting.
    uint256 public reportedReserves;

    uint256 public lastUpdated;

    /// @notice Emitted when `reportedReserves` is updated via a successful oracle sync.
    /// @param newReserves The reserve amount written to storage, in 6-decimal stablecoin units.
    event ReservesReported(uint256 newReserves);

    /// @notice Deploys the ledger, binds it to an oracle, and configures initial role assignments.
    /// @dev Grants both DEFAULT_ADMIN_ROLE and RESERVE_REPORTER_ROLE to `admin`. The admin can
    ///      subsequently delegate the reporter role to a separate automation account if desired.
    /// @param admin  Address receiving admin and initial reserve-reporter privileges.
    /// @param oracle_ Oracle contract conforming to IReservesOracle that will supply reserve data.
    constructor(address admin, IReservesOracle oracle_) {
        oracle = oracle_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(RESERVE_REPORTER_ROLE, admin);
    }

    /// @notice Fetches the current reserve amount from the oracle and persists it on-chain.
    /// @dev Restricted to RESERVE_REPORTER_ROLE. The caller is responsible for ensuring the
    ///      oracle holds a fresh, valid value before invoking this function — stale or inflated
    ///      oracle data will be accepted without further validation. Emits {ReservesReported}.
    function syncReservesFromOracle() external onlyRole(RESERVE_REPORTER_ROLE) {
        uint256 newReserves = oracle.getReserves();
        reportedReserves = newReserves;
        lastUpdated = block.timestamp;
        emit ReservesReported(newReserves);
    }
}
