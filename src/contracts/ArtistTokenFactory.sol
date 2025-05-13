// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IArtistTokenFactory} from '../interfaces/IArtistTokenFactory.sol';
import {ArtistToken} from './ArtistToken.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title ArtistTokenFactory
 * @dev Factory contract for creating ArtistToken contracts.
 */
contract ArtistTokenFactory is Ownable, IArtistTokenFactory {
  /**
   * @dev Constructor to initialize the contract.
   * @param initialOwner The initial owner of the contract.
   */
  constructor(address initialOwner) Ownable(initialOwner) {}

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
  ) external override onlyOwner returns (address) {
    require(maxSupply <= 1_000_000, 'Supply too high');
    require(artist != address(0), 'Invalid artist address');
    require(artistToToken[artist] == address(0), 'Token already exists');

    ArtistToken token = new ArtistToken(name, symbol, maxSupply, priceEngine, artist, owner());
    artistToToken[artist] = address(token);
    emit TokenCreated(artist, address(token));
    return address(token);
  }

  mapping(address => address) public override artistToToken; // Maps artist address to their token
}
