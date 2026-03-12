// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FiatStable.sol";
import "../src/ReserveLedger.sol";
import "../src/MockReservesOracle.sol";
import "../src/YieldVault4626.sol";

contract YieldVault4626Test is Test {
    FiatStable token;
    ReserveLedger ledger;
    MockReservesOracle oracle;
    YieldVault4626 vault;

    function setUp() public {
        oracle = new MockReservesOracle();
        ledger = new ReserveLedger(address(this), oracle);
        token = new FiatStable(ledger);
        vault = new YieldVault4626(token);
    }

    function testInitialState() public {
        assertEq(address(vault.asset()), address(token));
        assertEq(vault.name(), "Yield fUSD");
        assertEq(vault.symbol(), "yfUSD");
        assertEq(vault.totalAssets(), 0);
    }

    function testDepositMintsShares1to1() public {
        // arrange
        oracle.setReserves(1_000_000e6);
        ledger.syncReservesFromOracle();

        token.mint(address(this), 100e6);
        token.approve(address(vault), 100e6);

        // act
        uint256 shares = vault.deposit(100e6, address(this));

        // assert
        assertEq(shares, 100e6);
        assertEq(vault.balanceOf(address(this)), 100e6);
        assertEq(vault.totalAssets(), 100e6);
        assertEq(token.balanceOf(address(vault)), 100e6);
    }

    function testSecondDepositUsesExistingRatio() public {
        // arrange
        oracle.setReserves(1_000_000e6);
        ledger.syncReservesFromOracle();

        token.mint(address(this), 150e6);
        token.approve(address(vault), 150e6);

        vault.deposit(100e6, address(this));

        // act
        uint256 shares = vault.deposit(50e6, address(this));

        // assert
        assertEq(shares, 50e6);
        assertEq(vault.balanceOf(address(this)), 150e6);
        assertEq(vault.totalAssets(), 150e6);
        assertEq(token.balanceOf(address(vault)), 150e6);
    }
}
