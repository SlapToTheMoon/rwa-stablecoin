// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FiatStable.sol";
import "../src/ReserveLedger.sol";
import "../src/MockReservesOracle.sol";

contract ReserveLedgerTest is Test {
    ReserveLedger ledger;
    FiatStable stable;
    MockReservesOracle oracle;

    address user = address(1);

    function setUp() public {
        oracle = new MockReservesOracle();
        ledger = new ReserveLedger(address(this), oracle);
        stable = new FiatStable(ledger);
    }

    function testMintBlockedWhenExceedsReserves() public {
        oracle = new MockReservesOracle();
        ledger = new ReserveLedger(address(this), oracle); // $50.000000

        vm.expectRevert(bytes("exceeds reserves"));
        stable.mint(user, 100e6);
    }

    function testMintAllowedUpToReserves() public {
        oracle.setReserves(100e6);
        ledger.syncReservesFromOracle();
        stable.mint(user, 60e6);
        stable.mint(user, 40e6);

        assertEq(stable.totalSupply(), 100e6);
        assertEq(stable.balanceOf(user), 100e6);
    }
}
