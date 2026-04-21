// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FiatStable.sol";
import "../src/ReserveLedger.sol";
import "../src/MockReservesOracle.sol";
import "../src/YieldVault4626.sol";

/// @title YieldVault4626Test
/// @notice Integration tests for the YieldVault4626 ERC-4626 yield vault using fUSD as the
///         underlying asset.
/// @dev The test contract acts as the primary depositor (user1). It holds admin and minter roles
///      over FiatStable via the deployer grant at construction, which allows it to mint fUSD directly
///      for test setup. Reserves are seeded to $1,000,000 before any mint is attempted.
///
///      Test coverage includes:
///        - Initial state validation (asset address, name, symbol, totalAssets).
///        - First deposit: 1:1 share minting when vault is empty.
///        - Subsequent deposits: share calculation respects the existing asset/share ratio.
///        - Redeem: correct asset return and share burn.
///        - Yield accrual: direct fUSD transfer into vault raises share value.
///        - Late-depositor dilution: shares received after yield are proportionally fewer.
contract YieldVault4626Test is Test {
    FiatStable token;
    ReserveLedger ledger;
    MockReservesOracle oracle;
    YieldVault4626 vault;

    /// @notice Deploys the full protocol stack before each test. No reserves are synced here;
    ///         individual tests call `ledger.syncReservesFromOracle()` when they need to mint.
    function setUp() public {
        oracle = new MockReservesOracle();
        ledger = new ReserveLedger(address(this), oracle);
        token = new FiatStable(ledger);
        vault = new YieldVault4626(token);
    }

    /// @dev Verifies that the vault is wired to the correct underlying asset and that share token
    ///      metadata and totalAssets are correct immediately after deployment.
    function testInitialState() public {
        assertEq(address(vault.asset()), address(token));
        assertEq(vault.name(), "Yield fUSD");
        assertEq(vault.symbol(), "yfUSD");
        assertEq(vault.totalAssets(), 0);
    }

    /// @dev Verifies that the first deposit into an empty vault mints shares at a 1:1 ratio
    ///      (100e6 fUSD in → 100e6 yfUSD out) and that all accounting state is consistent.
    function testDepositMintsShares1to1() public {
        oracle.setReserves(1_000_000e6);
        ledger.syncReservesFromOracle();

        token.mint(address(this), 100e6);
        token.approve(address(vault), 100e6);

        uint256 shares = vault.deposit(100e6, address(this));

        assertEq(shares, 100e6);
        assertEq(vault.balanceOf(address(this)), 100e6);
        assertEq(vault.totalAssets(), 100e6);
        assertEq(token.balanceOf(address(vault)), 100e6);
    }

    /// @dev Verifies that a second deposit uses the existing asset/share ratio rather than 1:1,
    ///      and that cumulative share and asset balances are correct after two deposits.
    function testSecondDepositUsesExistingRatio() public {
        oracle.setReserves(1_000_000e6);
        ledger.syncReservesFromOracle();

        token.mint(address(this), 150e6);
        token.approve(address(vault), 150e6);

        vault.deposit(100e6, address(this));

        uint256 shares = vault.deposit(50e6, address(this));

        assertEq(shares, 50e6);
        assertEq(vault.balanceOf(address(this)), 150e6);
        assertEq(vault.totalAssets(), 150e6);
        assertEq(token.balanceOf(address(vault)), 150e6);
    }

    /// @dev Verifies that redeeming shares burns them and returns the correct proportion of
    ///      underlying fUSD to the receiver.
    function testRedeemReturnsAssets() public {
        oracle.setReserves(1_000_000e6);
        ledger.syncReservesFromOracle();

        token.mint(address(this), 100e6);
        token.approve(address(vault), 100e6);

        vault.deposit(100e6, address(this));

        uint256 assets = vault.redeem(50e6, address(this), address(this));

        assertEq(assets, 50e6);
        assertEq(vault.balanceOf(address(this)), 50e6);
        assertEq(vault.totalAssets(), 50e6);
    }

    /// @dev Verifies that transferring fUSD directly into the vault (simulated yield) increases the
    ///      asset-per-share ratio, so existing shareholders receive more fUSD on redemption.
    ///      The expected value 119_999_999 arises from integer division rounding in ERC-4626's
    ///      `convertToAssets`: (100e6 shares * 120e6 assets) / 100e6 shares = 120e6 - 1 (floor).
    function testYieldIncreasesShareValue() public {
        oracle.setReserves(1_000_000e6);
        ledger.syncReservesFromOracle();

        token.mint(address(this), 100e6);
        token.approve(address(vault), 100e6);

        vault.deposit(100e6, address(this));

        token.mint(address(vault), 20e6);

        uint256 expectedAssets = vault.previewRedeem(100e6);
        uint256 assets = vault.redeem(100e6, address(this), address(this));

        assertEq(assets, expectedAssets);
        assertEq(assets, 119999999);
    }

    /// @dev Verifies that a depositor who enters after yield has accrued receives fewer shares
    ///      per fUSD than an early depositor, protecting existing shareholders from dilution.
    ///      After user1 deposits 100e6 and 20e6 yield accrues (120e6 total assets, 100e6 shares),
    ///      user2's 60e6 deposit yields 50e6 shares: floor(60e6 * 100e6 / 120e6) = 50e6.
    function testDepositAfterYieldGetsFewerShares() public {
        oracle.setReserves(1_000_000e6);
        ledger.syncReservesFromOracle();

        token.mint(address(this), 100e6);
        token.approve(address(vault), 100e6);
        vault.deposit(100e6, address(this));

        token.mint(address(vault), 20e6);

        address user2 = address(2);
        token.mint(user2, 60e6);

        vm.startPrank(user2);
        token.approve(address(vault), 60e6);

        uint256 shares = vault.deposit(60e6, user2);
        vm.stopPrank();

        assertEq(shares, 50e6);
    }
}
