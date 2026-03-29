// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MockReservesOracle.sol";
import "../src/ReserveLedger.sol";
import "../src/FiatStable.sol";
import "../src/YieldVault4626.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        address admin = vm.envAddress("ADMIN");
        MockReservesOracle oracle = new MockReservesOracle();
        ReserveLedger ledger = new ReserveLedger(admin, oracle);
        FiatStable stable = new FiatStable(ledger);
        YieldVault4626 vault = new YieldVault4626(stable);

        oracle.setReserves(1_000_000e6);
        ledger.syncReservesFromOracle();

        vm.stopBroadcast();

        console.log("Oracle:", address(oracle));
        console.log("Ledger:", address(ledger));                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
        console.log("Stable:", address(stable));
        console.log("Vault:", address(vault));
    }
}
