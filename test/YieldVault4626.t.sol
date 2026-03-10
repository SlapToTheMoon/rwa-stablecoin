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
}
