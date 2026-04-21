// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MockReservesOracle.sol";
import "../src/ReserveLedger.sol";
import "../src/FiatStable.sol";
import "../src/YieldVault4626.sol";

/// @title Deploy
/// @notice Foundry deployment script that provisions the full RWA stablecoin stack in a single broadcast.
/// @dev Execution order:
///        1. Deploy MockReservesOracle (oracle data source).
///        2. Deploy ReserveLedger, wiring it to the oracle and granting admin rights to the ADMIN env var address.
///        3. Deploy FiatStable (fUSD), wired to the ledger.
///        4. Deploy YieldVault4626 (yfUSD), accepting fUSD as its underlying asset.
///        5. Seed the oracle with $1,000,000 USD of reserves and sync the ledger so minting is immediately available.
///
///      Requires the ADMIN environment variable to be set to the desired admin address before running:
///        ADMIN=0xYourAddress forge script script/Deploy.s.sol --broadcast
///
///      The MockReservesOracle is used here for local and testnet deployments. Replace it with a
///      production oracle implementation before deploying to mainnet.
contract Deploy is Script {
    /// @notice Deploys and wires all protocol contracts, then logs their addresses.
    /// @dev Reads ADMIN from the environment via `vm.envAddress`. The broadcast signer (set via
    ///      Foundry CLI flags such as --private-key or --ledger) becomes the transaction sender,
    ///      but `admin` controls protocol roles.
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
        console.log("Vault: ", address(vault));
    }
}
