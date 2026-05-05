// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FiatStable.sol";
import "../src/ReserveLedger.sol";
import "../src/MockReservesOracle.sol";

contract FiatStableTest is Test {
    ReserveLedger ledger;
    FiatStable token;
    MockReservesOracle oracle;

    address user = address(1);

    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);

    function setUp() public {
        oracle = new MockReservesOracle();
        ledger = new ReserveLedger(address(this), oracle);
        token = new FiatStable(ledger);

        oracle.setReserves(1_000_000e6);
        ledger.syncReservesFromOracle();
    }

    function testInitialRoles() public {
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), address(this)));
        assertTrue(token.hasRole(token.MINTER_ROLE(), address(this)));
        assertTrue(token.hasRole(token.PAUSER_ROLE(), address(this)));
    }

    function testMintByMinter() public {
        token.mint(user, 100e6);

        assertEq(token.balanceOf(user), 100e6);
        assertEq(token.totalSupply(), 100e6);
    }

    function testIssuerBurnByMinter() public {
        token.mint(user, 100e6);
        token.issuerBurn(user, 40e6);

        assertEq(token.balanceOf(user), 60e6);
        assertEq(token.totalSupply(), 60e6);
    }

    function testUserCanSelfBurn() public {
        token.mint(user, 100e6);

        vm.prank(user);
        token.burn(40e6);

        assertEq(token.balanceOf(user), 60e6);
        assertEq(token.totalSupply(), 60e6);
    }

    function testNonMinterCannotMint() public {
        vm.prank(user);
        vm.expectRevert();
        token.mint(user, 100e6);
    }

    function testNonMinterCannotIssuerBurn() public {
        token.mint(user, 100e6);

        vm.prank(user);
        vm.expectRevert();
        token.issuerBurn(user, 40e6);
    }

    function testPauseBlocksMintAndBurn() public {
        token.pause();

        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        token.mint(user, 1e6);

        token.unpause();
        token.mint(user, 2e6);

        token.pause();

        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        token.issuerBurn(user, 1e6);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        token.burn(1e6);
    }

    function testMintEmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit Minted(user, 5e6);

        token.mint(user, 5e6);
    }

    function testIssuerBurnEmitsEvent() public {
        token.mint(user, 5e6);

        vm.expectEmit(true, false, false, true);
        emit Burned(user, 2e6);

        token.issuerBurn(user, 2e6);
    }

    function testSelfBurnEmitsEvent() public {
        token.mint(user, 5e6);

        vm.prank(user);
        vm.expectEmit(true, false, false, true);
        emit Burned(user, 2e6);

        token.burn(2e6);
    }
}
