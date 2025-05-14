// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IMockYieldPlatform
 * @dev Interface for the MockYieldPlatform contract, simulating a yield-generating platform.
 */
interface IMockYieldPlatform {
  /**
   * @dev Deposits GHO into the platform.
   */
  function deposit(uint256 amount) external;

  /**
   * @dev Withdraws GHO from the platform.
   * @param amount The amount of GHO to withdraw (wei).
   */
  function withdraw(uint256 amount) external;

  /**
   * @dev Returns the deposited balance for an account.
   * @param account The account's address.
   * @return The deposited balance in GHO (wei).
   */
  function getBalance(address account) external view returns (uint256);

  /**
   * @dev Returns the yield for an account.
   * @param account The account's address.
   * @return The yield in GHO (wei).
   */
  function getYield(address account) external view returns (uint256);
}
