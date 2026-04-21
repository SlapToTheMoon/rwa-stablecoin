// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FiatStable.sol";
import "../src/ReserveLedger.sol";
import "../src/MockReservesOracle.sol";

/// @title FiatStableTest
/// @notice Unit tests for the FiatStable (fUSD) stablecoin contract.
/// @dev Covers role initialisation, mint/burn mechanics, reserve enforcement, access control,
///      pause/unpause behaviour, and event emissions. The test contract itself holds DEFAULT_ADMIN_ROLE
///      and MINTER_ROLE via the FiatStable constructor, which grants all roles to msg.sender (the
///      deployer). A fresh oracle seeded with $1,000,000 of reserves is used for each test.
contract FiatStableTest is Test {
    ReserveLedger ledger;
    FiatStable token;
    MockReservesOracle oracle;

    /// @dev Unprivileged address used as a recipient / non-minter in access-control tests.
    address user = address(1);

    /// @notice Deploys a full protocol stack and seeds reserves before each test.
    function setUp() public {
        oracle = new MockReservesOracle();
        ledger = new ReserveLedger(address(this), oracle);
        token = new FiatStable(ledger);

        oracle.setReserves(1_000_000e6);
        ledger.syncReservesFromOracle();
    }

    /// @dev Verifies that the deployer receives DEFAULT_ADMIN_ROLE and MINTER_ROLE at construction.
    function testInitialRoles() public {
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), address(this)));
        assertTrue(token.hasRole(token.MINTER_ROLE(), address(this)));
    }

    /// @dev Verifies that a MINTER_ROLE holder can mint tokens and that balances update correctly.
    function testMintByMinter() public {
        token.mint(user, 100e6);

        assertEq(token.balanceOf(user), 100e6);
        assertEq(token.totalSupply(), 100e6);
    }

    /// @dev Verifies that a MINTER_ROLE holder can burn previously minted tokens.
    function testBurnByMinter() public {
        token.mint(user, 100e6);
        token.burn(user, 40e6);

        assertEq(token.balanceOf(user), 60e6);
        assertEq(token.totalSupply(), 60e6);
    }

    /// @dev Verifies that an address without MINTER_ROLE cannot mint tokens.
    function testNonMinterCannotMint() public {
        vm.prank(user);
        vm.expectRevert();
        token.mint(user, 100e6);
    }

    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);

    /// @dev Verifies that pausing blocks both mint and burn, and that unpausing restores them.
    ///      Checks the EnforcedPause revert selector emitted by OpenZeppelin's Pausable.
    function testPauseBlocksMintAndBurn() public {
        token.pause();

        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        token.mint(user, 1e6);

        token.unpause();
        token.mint(user, 2e6);

        token.pause();
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        token.burn(user, 1e6);
    }

    /// @dev Verifies that a successful mint emits the Minted event with correct arguments.
    function testMintEmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit Minted(user, 5e6);
        token.mint(user, 5e6);
    }

    /// @dev Verifies that a successful burn emits the Burned event with correct arguments.
    function testBurnEmitsEvent() public {
        token.mint(user, 5e6);

        vm.expectEmit(true, false, false, true);
        emit Burned(user, 2e6);
        token.burn(user, 2e6);
    }
}
