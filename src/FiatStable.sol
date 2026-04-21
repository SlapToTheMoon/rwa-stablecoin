// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReserveLedger} from "./ReserveLedger.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/// @title FiatStable
/// @notice Fiat-collateralised USD stablecoin (fUSD) with reserve-backed minting, role-based access
///         control, and an emergency pause mechanism.
/// @dev Inherits OpenZeppelin ERC20, AccessControl, and Pausable.
///
///      Every mint is hard-capped to the reserve balance stored in the ReserveLedger:
///      `totalSupply() + amount <= ledger.reportedReserves()` must hold, enforcing a strict
///      1:1 USD collateralization ratio. Burning has no reserve constraint — it can only
///      reduce circulating supply toward zero.
///
///      The token uses 6 decimal places (matching USDC/USDT) rather than the ERC20 default of 18.
///      All amount parameters throughout this contract are in units of 10^-6 USD (i.e. 1e6 = $1.00).
///
///      Role summary:
///        DEFAULT_ADMIN_ROLE — Can grant and revoke all other roles.
///        MINTER_ROLE        — Can call `mint` and `burn`.
///        PAUSER_ROLE        — Can call `pause` and `unpause`.
///
///      All three roles are granted to the deployer at construction.
contract FiatStable is ERC20, AccessControl, Pausable {
    /// @notice Role identifier for accounts authorised to mint and burn fUSD.
    /// @dev Computed as keccak256("MINTER_ROLE").
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Role identifier for accounts authorised to pause and unpause the contract.
    /// @dev Computed as keccak256("PAUSER_ROLE").
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Emitted whenever new fUSD tokens are successfully minted.
    /// @param to     Recipient address that receives the minted tokens.
    /// @param amount Quantity minted, expressed in 6-decimal units.
    event Minted(address indexed to, uint256 amount);

    /// @notice Emitted whenever fUSD tokens are successfully burned.
    /// @param from   Address from which tokens were burned.
    /// @param amount Quantity burned, expressed in 6-decimal units.
    event Burned(address indexed from, uint256 amount);

    /// @notice The reserve ledger consulted on every mint to enforce the collateralization cap.
    /// @dev Immutable — changing the reserve source requires redeploying this contract.
    ReserveLedger public immutable ledger;

    /// @notice Deploys fUSD, wires it to the reserve ledger, and grants all roles to the deployer.
    /// @dev DEFAULT_ADMIN_ROLE, MINTER_ROLE, and PAUSER_ROLE are all assigned to `msg.sender`.
    ///      The ledger reference is set immutably; call `ReserveLedger.syncReservesFromOracle`
    ///      before minting to ensure a non-zero reserve is on record.
    /// @param ledger_ Deployed ReserveLedger instance holding the current reserve snapshot.
    constructor(ReserveLedger ledger_) ERC20("Fiat Stable USD", "fUSD") {
        ledger = ledger_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    /// @notice Returns the number of decimal places used by fUSD.
    /// @dev Overrides the ERC20 default of 18. Returns 6 to match the USDC/USDT convention and
    ///      to align with the 6-decimal denomination used throughout the reserve system.
    /// @return Always returns 6.
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    /// @notice Mints `amount` fUSD to `to`, provided the post-mint supply does not exceed reserves.
    /// @dev Reverts with "exceeds reserves" when `totalSupply() + amount > ledger.reportedReserves()`.
    ///      Reverts with {EnforcedPause} when the contract is paused.
    ///      Restricted to MINTER_ROLE. Emits {Minted} on success.
    /// @param to     Address that receives the newly minted tokens.
    /// @param amount Number of tokens to mint, in 6-decimal units.
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) whenNotPaused {
        require(totalSupply() + amount <= ledger.reportedReserves(), "exceeds reserves");
        _mint(to, amount);
        emit Minted(to, amount);
    }

    /// @notice Burns `amount` fUSD from `from`, reducing circulating supply.
    /// @dev No reserve check is applied — burning always moves supply toward zero.
    ///      Reverts with {EnforcedPause} when the contract is paused.
    ///      Reverts if `from` holds fewer than `amount` tokens (standard ERC20 underflow guard).
    ///      Restricted to MINTER_ROLE. Emits {Burned} on success.
    /// @param from   Address whose tokens are burned. Must have approved the caller or be the caller.
    /// @param amount Number of tokens to burn, in 6-decimal units.
    function burn(address from, uint256 amount) external onlyRole(MINTER_ROLE) whenNotPaused {
        _burn(from, amount);
        emit Burned(from, amount);
    }

    /// @notice Pauses all mint and burn operations.
    /// @dev Restricted to PAUSER_ROLE. Reverts if the contract is already paused.
    ///      Intended as an emergency circuit breaker — e.g. following an oracle compromise.
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Resumes mint and burn operations after a pause.
    /// @dev Restricted to PAUSER_ROLE. Reverts if the contract is not currently paused.
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}
