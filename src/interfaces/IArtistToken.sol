// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IArtistToken
 * @dev Interface for the ArtistToken ERC20 contract.
 */
interface IArtistToken {
  /**
   * @dev Mints tokens to a recipient.
   * @param to The recipient's address.
   * @param amount The number of tokens to mint.
   */
  function mint(address to, uint256 amount) external payable;

  /**
   * @dev Burns tokens from a holder.
   * @param from The holder's address.
   * @param amount The number of tokens to burn.
   */
  function burn(address from, uint256 amount) external;

  /**
   * @dev Sets a new maximum supply for the token.
   * @param newMaxSupply The new maximum supply.
   */
  function setMaxSupply(uint256 newMaxSupply) external;

  /**
   * @dev Returns the maximum supply of the token.
   * @return The maximum supply.
   */
  function maxSupply() external view returns (uint256);

  /**
   * @dev Returns the artist's wallet address.
   * @return The artist's address.
   */
  function artist() external view returns (address);

  /**
   * @dev Emitted when the maximum supply is updated.
   * @param newMaxSupply The new maximum supply.
   */
  event MaxSupplyUpdated(uint256 newMaxSupply);
}
