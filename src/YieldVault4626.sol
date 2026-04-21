// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title YieldVault4626
/// @notice ERC-4626 tokenised yield vault that accepts fUSD (FiatStable) as its underlying asset
///         and issues yfUSD share tokens to depositors.
/// @dev A minimal, unmodified ERC-4626 wrapper around FiatStable. All vault accounting —
///      deposit, withdraw, mint, redeem, and share/asset conversions — is inherited directly
///      from OpenZeppelin's ERC4626 base contract without customisation.
///
///      Share token metadata: name = "Yield fUSD", symbol = "yfUSD".
///      Underlying asset: fUSD (FiatStable), which uses 6 decimal places.
///
///      Yield mechanics: when fUSD is transferred directly into the vault (e.g. via an external
///      reward distribution), `totalAssets()` increases while `totalSupply()` (shares) remains
///      constant, raising the asset-per-share ratio for all existing holders. New depositors
///      arriving after a yield event receive proportionally fewer shares, preventing dilution of
///      early participants. See YieldVault4626.t.sol for test coverage of this behaviour.
contract YieldVault4626 is ERC4626 {
    /// @notice Deploys the vault and designates `asset_` as the depositable underlying token.
    /// @dev Share token name and symbol are fixed at deployment time ("Yield fUSD" / "yfUSD").
    ///      `asset_` should be the deployed FiatStable contract. Passing a zero address or a
    ///      non-ERC20-compliant address will cause downstream deposit/withdraw calls to revert.
    /// @param asset_ The ERC-20 token (fUSD) that depositors contribute and later redeem.
    constructor(IERC20 asset_) ERC20("Yield fUSD", "yfUSD") ERC4626(asset_) {}
}
