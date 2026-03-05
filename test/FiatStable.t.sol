// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FiatStable.sol";
import "../src/ReserveLedger.sol";

contract FiatStableTest is Test {
    ReserveLedger ledger;
    FiatStable token;

    address user = address(1);

    function setUp() public {
        ledger = new ReserveLedger(address(this));
        token = new FiatStable(ledger);
        ledger.reportReserves(1_000_000e6);
    }

    function testInitialRoles() public {
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), address(this)));
        assertTrue(token.hasRole(token.MINTER_ROLE(), address(this)));
    }

    function testMintByMinter() public {
        token.mint(user, 100e6); // 100.000000 with 6 decimals

        assertEq(token.balanceOf(user), 100e6);
        assertEq(token.totalSupply(), 100e6);
    }

    function testBurnByMinter() public {
        token.mint(user, 100e6);
        token.burn(user, 40e6);

        assertEq(token.balanceOf(user), 60e6);
        assertEq(token.totalSupply(), 60e6);
    }

    function testNonMinterCannotMint() public {
        vm.prank(user);
        vm.expectRevert();
        token.mint(user, 100e6);
    }

    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);

    function testPauseBlocksMintAndBurn() public {
        token.pause();

        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        token.mint(user, 1e6);

        // mint first, then pause, then try burn
        token.unpause();
        token.mint(user, 2e6);

        token.pause();
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        token.burn(user, 1e6);
    }

    function testMintEmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit Minted(user, 5e6);
        token.mint(user, 5e6);
    }

    function testBurnEmitsEvent() public {
        token.mint(user, 5e6);

        vm.expectEmit(true, false, false, true);
        emit Burned(user, 2e6);
        token.burn(user, 2e6);
    }
}
