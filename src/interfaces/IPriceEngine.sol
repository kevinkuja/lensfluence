// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IPriceEngine
 * @dev Interface for the PriceEngine contract, managing token prices and metrics.
 */
interface IPriceEngine {
  event GHODeposited(uint256 amount);
  event GHOWithdrawn(uint256 amount);
  event AllArtistsUpdated(uint256[] newPrices, uint256 availableLiquidity, uint256 treasuryGHO);
  /**
   * @dev Deposits GHO into the yield platform.
   */

  function depositGHO() external payable;

  /**
   * @dev Withdraws GHO from the yield platform.
   * @param amount The amount of GHO to withdraw.
   */
  function withdrawGHO(uint256 amount) external;

  /**
   * @dev Returns the mint price for an artist's token.
   * @param artist The artist's wallet address.
   * @return The price per token in GHO (wei).
   */
  function getPrice(address artist) external view returns (uint256);

  /**
   * @dev Updates prices and metrics for all artists.
   * @param artists Array of artist wallet addresses.
   * @param newMetrics Array of new metric values.
   */
  function updateAllArtists(address[] calldata artists, uint256[] calldata newMetrics) external;

  /**
   * @dev Returns the total released liquidity in the system.
   * @return The released liquidity in GHO (wei).
   */
  function getReleasedLiquidity() external view returns (uint256);

  /**
   * @dev Returns the total treasury in the system.
   * @return The treasury in GHO (wei).
   */
  function getTreasury() external view returns (uint256);
}
