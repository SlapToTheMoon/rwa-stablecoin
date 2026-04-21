// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FiatStable.sol";
import "../src/ReserveLedger.sol";
import "../src/MockReservesOracle.sol";

contract ReserveLedgerAuditTest is Test {
    ReserveLedger ledger;
    FiatStable stable;
    MockReservesOracle oracle;

    address user = address(1);

    function setUp() public {
        oracle = new MockReservesOracle();
        ledger = new ReserveLedger(address(this), oracle);
        stable = new FiatStable(ledger);
    }

    function testCompromisedOracleAllowsExcessMint() public {
    oracle.setReserves(1_000_000e6);
    ledger.syncReservesFromOracle();

    stable.mint(user, 1_000_000e6);

    assertEq(stable.totalSupply(), 1_000_000e6);
    assertEq(stable.balanceOf(user), 1_000_000e6);
    assertEq(ledger.reportedReserves(), 1_000_000e6);
}
}
