// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IArtistToken} from '../interfaces/IArtistToken.sol';
import {IPriceEngine} from '../interfaces/IPriceEngine.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

import {console} from 'forge-std/console.sol';

/**
 * @title ArtistToken
 * @dev ERC20 token representing an artist's value, with dynamic pricing.
 */
contract ArtistToken is ERC20, Ownable, IArtistToken {
  using Math for uint256;

  uint256 public override maxSupply; // Maximum supply of the token
  IPriceEngine public priceEngine; // PriceEngine contract for pricing
  address public override artist; // Artist's wallet address

  /**
   * @dev Constructor to initialize the token.
   * @param name The token's name.
   * @param symbol The token's symbol.
   * @param _maxSupply The maximum supply.
   * @param _priceEngine The PriceEngine contract address.
   * @param _artist The artist's wallet address.
   * @param initialOwner The initial owner of the contract.
   */
  constructor(
    string memory name,
    string memory symbol,
    uint256 _maxSupply,
    address _priceEngine,
    address _artist,
    address initialOwner
  ) ERC20(name, symbol) Ownable(initialOwner) {
    require(_maxSupply <= 1_000_000, 'Supply too high');
    maxSupply = _maxSupply;
    priceEngine = IPriceEngine(_priceEngine);
    artist = _artist;
  }

  /**
   * @dev Mints tokens to a recipient, requiring GHO payment.
   * @param to The recipient's address.
   * @param amount The number of tokens to mint.
   */
  function mint(address to, uint256 amount) external payable override {
    require(totalSupply() + amount <= maxSupply, 'Exceeds max supply');
    uint256 pricePerToken = priceEngine.getPrice(artist);
    console.log('pricePerToken', pricePerToken);
    uint256 cost = amount.mulDiv(pricePerToken, 1e18);
    console.log('cost', cost);
    console.log('msg.value', msg.value);
    require(msg.value >= cost, 'Insufficient GHO');

    _mint(to, amount);
    priceEngine.depositGHO{value: msg.value}();
    // Note: Metrics are updated externally via updateAllArtists
  }

  /**
   * @dev Burns tokens from a holder, refunding GHO.
   * @param from The holder's address.
   * @param amount The number of tokens to burn.
   */
  function burn(address from, uint256 amount) external override {
    require(balanceOf(from) >= amount, 'Insufficient balance');
    uint256 pricePerToken = priceEngine.getPrice(artist);
    uint256 ghoToTransfer = amount.mulDiv(pricePerToken, 1e18);
    require(address(this).balance >= ghoToTransfer, 'Insufficient GHO in contract');
    _burn(from, amount);
    priceEngine.withdrawGHO(ghoToTransfer);
    payable(from).transfer(ghoToTransfer);
    // Note: Metrics are updated externally via updateAllArtists
  }

  /**
   * @dev Sets a new maximum supply.
   * @param newMaxSupply The new maximum supply.
   */
  function setMaxSupply(uint256 newMaxSupply) external override onlyOwner {
    require(newMaxSupply >= totalSupply(), 'Cannot reduce below current supply');
    require(newMaxSupply <= 10_000_000, 'New supply too high');
    maxSupply = newMaxSupply;
    emit MaxSupplyUpdated(newMaxSupply);
  }
}
