// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FiatStable.sol";
import "../src/ReserveLedger.sol";
import "../src/MockReservesOracle.sol";

/// @title ReserveLedgerTest
/// @notice Unit tests verifying that FiatStable correctly enforces the reserve collateralization cap
///         maintained by ReserveLedger.
/// @dev Tests exercise the two critical boundary conditions of the reserve constraint:
///        1. Minting is blocked when the requested amount would push totalSupply above reportedReserves.
///        2. Minting is permitted for any cumulative amount up to and including reportedReserves.
contract ReserveLedgerTest is Test {
    ReserveLedger ledger;
    FiatStable stable;
    MockReservesOracle oracle;

    /// @dev Unprivileged recipient used as the mint target.
    address user = address(1);

    /// @notice Deploys the protocol stack with zero initial reserves before each test.
    /// @dev reportedReserves starts at 0 because syncReservesFromOracle is not called in setUp,
    ///      giving individual tests full control over the reserve state.
    function setUp() public {
        oracle = new MockReservesOracle();
        ledger = new ReserveLedger(address(this), oracle);
        stable = new FiatStable(ledger);
    }

    /// @dev Verifies that minting reverts with "exceeds reserves" when reportedReserves is zero
    ///      and an amount greater than zero is requested.
    function testMintBlockedWhenExceedsReserves() public {
        oracle = new MockReservesOracle();
        ledger = new ReserveLedger(address(this), oracle);

        vm.expectRevert(bytes("exceeds reserves"));
        stable.mint(user, 100e6);
    }

    /// @dev Verifies that sequential mints summing exactly to reportedReserves all succeed,
    ///      and that totalSupply matches the expected amount after both mints.
    function testMintAllowedUpToReserves() public {
        oracle.setReserves(100e6);
        ledger.syncReservesFromOracle();
        stable.mint(user, 60e6);
        stable.mint(user, 40e6);

        assertEq(stable.totalSupply(), 100e6);
        assertEq(stable.balanceOf(user), 100e6);
    }
}
