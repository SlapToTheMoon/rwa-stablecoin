// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FiatStable.sol";
import "../src/ReserveLedger.sol";

contract ReserveLedgerTest is Test {
    ReserveLedger ledger;
    FiatStable stable;

    address user = address(1);

    function setUp() public {
        ledger = new ReserveLedger(address(this));
        stable = new FiatStable(ledger);
    }

    function testMintBlockedWhenExceedsReserves() public {
        ledger.reportReserves(50e6); // $50.000000

        // trying to mint $100 should revert
        vm.expectRevert();
        stable.mint(user, 100e6);
    }

    function testMintAllowedUpToReserves() public {
        ledger.reportReserves(100e6);

        stable.mint(user, 60e6);
        stable.mint(user, 40e6);

        assertEq(stable.totalSupply(), 100e6);
        assertEq(stable.balanceOf(user), 100e6);
    }
}
