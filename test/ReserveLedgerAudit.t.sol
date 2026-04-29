// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FiatStable.sol";
import "../src/ReserveLedger.sol";
import "../src/MockReservesOracle.sol";

/// @title ReserveLedgerAuditTest
/// @notice Audit test suite documenting the oracle-compromise attack vector in the RWA stablecoin system.
/// @dev The collateralization guarantee of FiatStable rests entirely on the integrity of the oracle
///      data reported into ReserveLedger. If the oracle is compromised — or if an unpermissioned caller
///      can write to it — an attacker can inflate `reportedReserves` and mint fUSD beyond actual
///      backing assets. This suite documents that vulnerability with a reproducible proof-of-concept.
///
///      Remediation approaches to consider:
///        - Restrict oracle write access to a multi-sig or DAO-governed reporter.
///        - Add a time-lock or cooldown between reserve updates and minting.
///        - Integrate a secondary on-chain proof (e.g. attestation, ZK proof) for reserve data.
contract ReserveLedgerAuditTest is Test {
    ReserveLedger ledger;
    FiatStable stable;
    MockReservesOracle oracle;

    /// @dev Unprivileged recipient used as the mint target in the exploit scenario.
    address user = address(1);

    /// @notice Deploys the protocol stack with zero initial reserves before each test.
    function setUp() public {
        oracle = new MockReservesOracle();
        ledger = new ReserveLedger(address(this), oracle);
        stable = new FiatStable(ledger);
    }

    /// @dev Demonstrates that an attacker who controls the oracle can set arbitrarily high reserves,
    ///      sync them into the ledger, and mint the full reported amount without any real backing.
    ///      The test passes (no revert), confirming the vulnerability exists in the current design.
    function testCompromisedOracleAllowsExcessMint() public {
        oracle.setReserves(1_000_000e6);
        ledger.syncReservesFromOracle();

        stable.mint(user, 1_000_000e6);

        assertEq(stable.totalSupply(), 1_000_000e6);
        assertEq(stable.balanceOf(user), 1_000_000e6);
        assertEq(ledger.reportedReserves(), 1_000_000e6);
    }

    function testPauseContainsDamageAfterSuspiciousReserveSync() public {
        // attacker or bad oracle inflates reserves
        oracle.setReserves(1_000_000e6);
        ledger.syncReservesFromOracle();

        // governance reacts
        stable.pause();

        // mint should now fail even though reserves look high
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        stable.mint(user, 100e6);
    }

    function testCompromisedMinterCanMintUpToReserves() public {
        address attacker = address(99);

        oracle.setReserves(1_000_000e6);
        ledger.syncReservesFromOracle();

        stable.grantRole(stable.MINTER_ROLE(), attacker);

        vm.prank(attacker);
        stable.mint(attacker, 1_000_000e6);

        assertEq(stable.balanceOf(attacker), 1_000_000e6);
    }
}
