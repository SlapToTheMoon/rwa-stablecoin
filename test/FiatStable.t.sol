// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FiatStable.sol";

contract FiatStableTest is Test {
    FiatStable token;

    address user = address(1);

    function setUp() public {
        token = new FiatStable();
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
}