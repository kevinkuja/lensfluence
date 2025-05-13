// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IArtistTokenFactory
 * @dev Interface for the ArtistTokenFactory contract, creating ArtistToken contracts.
 */
interface IArtistTokenFactory {
  /**
   * @dev Creates a new ArtistToken contract.
   * @param name The token's name.
   * @param symbol The token's symbol.
   * @param maxSupply The maximum supply of the token.
   * @param priceEngine The PriceEngine contract address.
   * @param artist The artist's wallet address.
   * @return The address of the created ArtistToken contract.
   */
  function createArtistToken(
    string memory name,
    string memory symbol,
    uint256 maxSupply,
    address priceEngine,
    address artist
  ) external returns (address);

  /**
   * @dev Returns the ArtistToken contract address for an artist.
   * @param artist The artist's wallet address.
   * @return The ArtistToken contract address.
   */
  function artistToToken(address artist) external view returns (address);

  /**
   * @dev Emitted when a new ArtistToken is created.
   * @param artist The artist's wallet address.
   * @param token The ArtistToken contract address.
   */
  event TokenCreated(address artist, address token);
}
